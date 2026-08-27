import 'package:flutter/material.dart';
import '../config.dart';
import '../models/cliente.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/poleway_header.dart';
import 'meus_pedidos_screen.dart';

class SelecionarClienteScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeMode;

  const SelecionarClienteScreen({super.key, required this.themeMode});

  @override
  State<SelecionarClienteScreen> createState() =>
      _SelecionarClienteScreenState();
}

class _SelecionarClienteScreenState extends State<SelecionarClienteScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _buscaController = TextEditingController();
  late Future<List<Cliente>> _futureClientes;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaController.addListener(() {
      setState(() => _busca = _buscaController.text);
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _carregar() {
    _futureClientes = _api.getClientes(codigoClienteTeste);
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futureClientes;
  }

  List<Cliente> _filtrar(List<Cliente> clientes) {
    final termo = _normalizar(_busca);
    if (termo.isEmpty) return clientes;
    return clientes.where((c) {
      return _normalizar(c.nomeFantasia).contains(termo) ||
          _normalizar(c.razaoSocial).contains(termo) ||
          _normalizar(c.cnpjCpf).contains(termo) ||
          _normalizar(c.codigo).contains(termo);
    }).toList();
  }

  String _normalizar(String texto) {
    return texto.toLowerCase().replaceAll(RegExp(r'[./\-\s]'), '');
  }

  void _selecionar(Cliente cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MeusPedidosScreen(themeMode: widget.themeMode, cliente: cliente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: const PolewayAppBar(),
      body: SafeArea(
        child: FutureBuilder<List<Cliente>>(
          future: _futureClientes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: p.laranja));
            }

            if (snapshot.hasError) {
              return _buildErro(p, snapshot.error.toString());
            }

            final clientes = snapshot.data ?? [];

            if (clientes.isEmpty) {
              return _buildErro(p, 'Nenhum cliente encontrado.');
            }

            final filtrados = _filtrar(clientes);

            return LayoutBuilder(
              builder: (context, constraints) {
                final larguraConteudo = constraints.maxWidth > 900
                    ? 900.0
                    : constraints.maxWidth;
                final margemLateral =
                    (constraints.maxWidth - larguraConteudo) / 2 + 20;

                return RefreshIndicator(
                  onRefresh: _recarregar,
                  color: p.laranja,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: margemLateral,
                      vertical: 32,
                    ),
                    children: [
                      const Text(
                        'Selecione um cliente',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Escolha o cliente para ver os pedidos.',
                        style: TextStyle(color: p.textoSuave, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _buscaController,
                        decoration: InputDecoration(
                          hintText:
                              'Buscar por nome, razão social, CNPJ ou código',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _busca.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: _buscaController.clear,
                                ),
                          filled: true,
                          fillColor: p.superficie,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: p.borda),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: p.borda),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (filtrados.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: p.superficie,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: p.borda),
                          ),
                          child: Center(
                            child: Text(
                              'Nenhum cliente encontrado para "$_busca".',
                              style: TextStyle(color: p.textoSuave),
                            ),
                          ),
                        )
                      else
                        for (final cliente in filtrados) ...[
                          _ClienteTile(
                            cliente: cliente,
                            onTap: () => _selecionar(cliente),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErro(AppPalette p, String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: p.textoSuave, size: 40),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, color: p.texto),
            ),
            const SizedBox(height: 4),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textoSuave, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _recarregar,
              style: FilledButton.styleFrom(backgroundColor: p.laranja),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteTile extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;

  const _ClienteTile({required this.cliente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.laranjaSuave,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront_outlined, color: p.laranja),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nomeFantasia.isNotEmpty
                          ? cliente.nomeFantasia
                          : cliente.razaoSocial,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: p.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cliente.razaoSocial,
                      style: TextStyle(color: p.textoSuave, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (cliente.cnpjCpf.isNotEmpty) cliente.cnpjCpf,
                        if (cliente.codigo.isNotEmpty) 'Cód. ${cliente.codigo}',
                      ].join(' · '),
                      style: TextStyle(color: p.textoSuave, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textoSuave),
            ],
          ),
        ),
      ),
    );
  }
}
