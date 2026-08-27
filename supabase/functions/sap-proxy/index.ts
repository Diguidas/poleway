// Proxy entre o Flutter (Pole Way) e o gateway SAP (erpgateway).
// Usuário e senha ficam guardados como secrets aqui no servidor e nunca chegam ao cliente web.
// Também resolve CORS, já que o gateway SAP não libera chamadas direto do navegador.

const ROTAS: Record<string, { path: string; param: string }> = {
  cliente: { path: "get_clientes_agrupados", param: "codigocli" },
  pedidos: { path: "get_pedidos", param: "codigocli" },
  itens: { path: "get_itens", param: "ordem" },
  documentos: { path: "get_documentos", param: "codigocli" },
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const recurso = url.searchParams.get("recurso");
  const valor = url.searchParams.get("valor");

  const rota = recurso ? ROTAS[recurso] : undefined;

  if (!rota || !valor) {
    return new Response(
      JSON.stringify({
        success: false,
        message: "Parâmetros inválidos. Use ?recurso=cliente|pedidos|itens|documentos&valor=...",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // SAP_ENV troca entre "qas" e "prd" sem precisar reimplantar a function.
  const ambiente = Deno.env.get("SAP_ENV") ?? "qas";
  const usuario = Deno.env.get("SAP_USUARIO") ?? "abap";
  const senha = Deno.env.get("SAP_SENHA");

  if (!senha) {
    return new Response(
      JSON.stringify({ success: false, message: "SAP_SENHA não configurada." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const base = `https://api${ambiente}.sap.sladm.com.br/sap/bc/apis_pole/erpgateway`;
  const alvo = `${base}/${rota.path}?${rota.param}=${encodeURIComponent(valor)}`;
  const auth = `Basic ${btoa(`${usuario}:${senha}`)}`;

  const resposta = await fetch(alvo, {
    headers: { Authorization: auth },
  });

  const corpo = await resposta.text();

  return new Response(corpo, {
    status: resposta.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
