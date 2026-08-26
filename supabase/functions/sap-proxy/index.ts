// Proxy entre o Flutter (Pole Way) e o middleware SAP.
// A x-api-key fica guardada como secret aqui no servidor e nunca chega ao cliente web.

const MIDDLEWARE_BASE = "https://middleware.polealimentos.com.br/api/v1";

const ROTAS: Record<string, { path: string; param: string }> = {
  cliente: { path: "clienteSAP", param: "codigo" },
  pedidos: { path: "pedidosSAP", param: "cliente" },
  itens: { path: "itensSAP", param: "ordem" },
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
        message: "Parâmetros inválidos. Use ?recurso=cliente|pedidos|itens&valor=...",
      }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const apiKey = Deno.env.get("SAP_MIDDLEWARE_API_KEY");
  if (!apiKey) {
    return new Response(
      JSON.stringify({ success: false, message: "SAP_MIDDLEWARE_API_KEY não configurada." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const alvo = `${MIDDLEWARE_BASE}/${rota.path}?${rota.param}=${encodeURIComponent(valor)}`;

  const resposta = await fetch(alvo, {
    headers: { "x-api-key": apiKey },
  });

  const corpo = await resposta.text();

  return new Response(corpo, {
    status: resposta.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
