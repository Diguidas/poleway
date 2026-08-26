/// Normaliza as chaves do JSON vindo do SAP (que às vezes vêm em MAIÚSCULO,
/// às vezes em minúsculo) para minúsculo, facilitando o parsing.
Map<String, dynamic> normalizarChaves(Map<String, dynamic> json) {
  return json.map((key, value) => MapEntry(key.toLowerCase(), value));
}

String _texto(Map<String, dynamic> json, String chave) {
  final valor = json[chave];
  return valor?.toString().trim() ?? '';
}

double _numero(Map<String, dynamic> json, String chave) {
  final texto = _texto(json, chave).replaceAll(',', '.');
  return double.tryParse(texto) ?? 0;
}

DateTime? _data(Map<String, dynamic> json, String chave) {
  final texto = _texto(json, chave);
  if (texto.length != 8) return null;
  final ano = int.tryParse(texto.substring(0, 4));
  final mes = int.tryParse(texto.substring(4, 6));
  final dia = int.tryParse(texto.substring(6, 8));
  if (ano == null || mes == null || dia == null) return null;
  return DateTime(ano, mes, dia);
}

class ItemPedido {
  final String item;
  final String material;
  final String denominacao;
  final String grupo;
  final double quantidade;
  final String unidadeVenda;
  final double valorUnitario;

  ItemPedido({
    required this.item,
    required this.material,
    required this.denominacao,
    required this.grupo,
    required this.quantidade,
    required this.unidadeVenda,
    required this.valorUnitario,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> jsonBruto) {
    final json = normalizarChaves(jsonBruto);
    return ItemPedido(
      item: _texto(json, 'item'),
      material: _texto(json, 'material'),
      denominacao: _texto(json, 'denominacao'),
      grupo: _texto(json, 'grupo'),
      quantidade: _numero(json, 'quantidade'),
      unidadeVenda: _texto(json, 'unidade_venda'),
      valorUnitario: _numero(json, 'valor_unitario'),
    );
  }

  double get valorTotal => quantidade * valorUnitario;
}

class Pedido {
  final String ordem;
  final double valor;
  final DateTime? dataCriacao;
  final DateTime? dataEntrega;
  final String notaFiscal;
  final String status;
  final String tipoPedido;

  Pedido({
    required this.ordem,
    required this.valor,
    required this.dataCriacao,
    required this.dataEntrega,
    required this.notaFiscal,
    required this.status,
    required this.tipoPedido,
  });

  factory Pedido.fromJson(Map<String, dynamic> jsonBruto) {
    final json = normalizarChaves(jsonBruto);
    return Pedido(
      ordem: _texto(json, 'ordem'),
      valor: _numero(json, 'valor'),
      dataCriacao: _data(json, 'dt_criacao'),
      dataEntrega: _data(json, 'dt_entrega'),
      notaFiscal: _texto(json, 'nota_fiscal'),
      status: _texto(json, 'status'),
      tipoPedido: _texto(json, 'tp_ped'),
    );
  }

  /// Pedidos "Faturado" contam como concluídos; qualquer outro status
  /// (Recusado, Em processamento, etc.) fica na aba "Em aberto" por enquanto.
  /// TODO: revisar quando soubermos todos os status possíveis do SAP.
  bool get concluido => status.toLowerCase() == 'faturado';
}
