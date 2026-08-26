import 'pedido.dart';

class Cliente {
  final String codigo;
  final String nomeFantasia;
  final String razaoSocial;
  final String endereco;
  final String telefone;
  final double limiteTotal;
  final double limiteDisponivel;
  final int documentosAbertos;
  final int documentosPendentes;
  final String diasEntrega;
  final String condPagamento;

  Cliente({
    required this.codigo,
    required this.nomeFantasia,
    required this.razaoSocial,
    required this.endereco,
    required this.telefone,
    required this.limiteTotal,
    required this.limiteDisponivel,
    required this.documentosAbertos,
    required this.documentosPendentes,
    required this.diasEntrega,
    required this.condPagamento,
  });

  factory Cliente.fromJson(Map<String, dynamic> jsonBruto) {
    final json = normalizarChaves(jsonBruto);
    final condPagamento = json['cond_pagamento'];
    final descricaoCondPagamento = condPagamento is Map
        ? normalizarChaves(condPagamento.cast<String, dynamic>())['descricao']?.toString() ?? ''
        : '';

    return Cliente(
      codigo: (json['codigocli'] ?? '').toString().trim(),
      nomeFantasia: (json['nome_fantasia'] ?? '').toString().trim(),
      razaoSocial: (json['razao_social'] ?? '').toString().trim(),
      endereco: (json['endereco'] ?? '').toString().trim(),
      telefone: (json['telefone'] ?? '').toString().trim(),
      limiteTotal: double.tryParse((json['limite_total'] ?? '').toString().trim()) ?? 0,
      limiteDisponivel: double.tryParse((json['limite_disponivel'] ?? '').toString().trim()) ?? 0,
      documentosAbertos: int.tryParse((json['documentos_abertos'] ?? '').toString().trim()) ?? 0,
      documentosPendentes: int.tryParse((json['documentos_pendentes'] ?? '').toString().trim()) ?? 0,
      diasEntrega: (json['dias_entrega'] ?? '').toString().trim(),
      condPagamento: descricaoCondPagamento,
    );
  }
}
