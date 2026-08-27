import 'pedido.dart';

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

class DocumentoFinanceiro {
  final String docnum;
  final String nfe;
  final String status;
  final double valor;
  final DateTime? vencimento;
  final String ordem;

  DocumentoFinanceiro({
    required this.docnum,
    required this.nfe,
    required this.status,
    required this.valor,
    required this.vencimento,
    required this.ordem,
  });

  factory DocumentoFinanceiro.fromJson(Map<String, dynamic> jsonBruto) {
    final json = normalizarChaves(jsonBruto);
    return DocumentoFinanceiro(
      docnum: _texto(json, 'docnum'),
      nfe: _texto(json, 'nfe'),
      status: _texto(json, 'status'),
      valor: _numero(json, 'valor'),
      vencimento: _data(json, 'vencimento'),
      ordem: _texto(json, 'ordem'),
    );
  }

  bool get pendente => status.toLowerCase() != 'pago' && status.toLowerCase() != 'liquidado';

  bool get vencido => pendente && vencimento != null && vencimento!.isBefore(DateTime.now());
}
