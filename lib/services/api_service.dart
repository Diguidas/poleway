import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cliente.dart';
import '../models/documento.dart';
import '../models/pedido.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Fala com a Edge Function `sap-proxy` do Supabase, que guarda usuário e senha
/// do gateway SAP no servidor e nunca os expõe ao app web.
class ApiService {
  static const _baseUrl = 'https://aeqvfzxmkwabgseqeiqk.supabase.co/functions/v1/sap-proxy';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlcXZmenhta3dhYmdzZXFlaXFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3MDc2ODksImV4cCI6MjEwMzI4MzY4OX0.--1K_MpTaycX4A3EjbOW195WlzQ6oBOtSuAHhcVB-nY';

  Future<dynamic> _get(String recurso, String valor) async {
    final uri = Uri.parse('$_baseUrl?recurso=$recurso&valor=${Uri.encodeComponent(valor)}');
    final resposta = await http.get(uri, headers: {'apikey': _anonKey});

    if (resposta.statusCode != 200) {
      throw ApiException('Falha ao consultar $recurso (HTTP ${resposta.statusCode}).');
    }

    return jsonDecode(resposta.body);
  }

  Future<List<Cliente>> getClientes(String codigo) async {
    final data = await _get('cliente', codigo) as List;
    return data.map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Pedido>> getPedidos(String codigoCliente) async {
    final bruto = await _get('pedidos', codigoCliente) as Map<String, dynamic>;
    final data = normalizarChaves(bruto);
    final lista = (data['pedidos'] as List?) ?? [];
    return lista.map((e) => Pedido.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ItemPedido>> getItens(String ordem) async {
    final bruto = await _get('itens', ordem) as Map<String, dynamic>;
    final data = normalizarChaves(bruto);
    final lista = (data['itens'] as List?) ?? [];
    return lista.map((e) => ItemPedido.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DocumentoFinanceiro>> getDocumentos(String codigoCliente) async {
    final bruto = await _get('documentos', codigoCliente) as Map<String, dynamic>;
    final data = normalizarChaves(bruto);
    final lista = (data['documentos'] as List?) ?? [];
    return lista.map((e) => DocumentoFinanceiro.fromJson(e as Map<String, dynamic>)).toList();
  }
}
