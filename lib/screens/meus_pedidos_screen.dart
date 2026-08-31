import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/documento.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/poleway_header.dart';
import '../widgets/status_chip.dart';
import 'detalhe_pedido_screen.dart';

class MeusPedidosScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeMode;
  final Cliente cliente;

  const MeusPedidosScreen({
    super.key,
    required this.themeMode,
    required this.cliente,
  });

  @override
  State<MeusPedidosScreen> createState() => _MeusPedidosScreenState();
}

class _MeusPedidosScreenState extends State<MeusPedidosScreen> {
  final ApiService _api = ApiService();
  late Future<_DadosPedidos> _futureDados;

  @override
  void initState() {
    super.initState();
    _futureDados = _carregarDados();
  }

  Future<_DadosPedidos> _carregarDados() async {
    final resultados = await Future.wait([
      _api.getPedidos(widget.cliente.codigo),
      _api.getDocumentos(widget.cliente.codigo),
    ]);
    final pedidos = resultados[0] as List<Pedido>;
    final documentos = resultados[1] as List<DocumentoFinanceiro>;
    // Só interessam documentos cuja ordem bate com algum pedido do cliente;
    // o restante é descartado.
    final ordensDosPedidos = pedidos.map((ped) => ped.ordem).toSet();
    final documentoPorOrdem = {
      for (final doc in documentos)
        if (ordensDosPedidos.contains(doc.ordem)) doc.ordem: doc,
    };
    return _DadosPedidos(
      pedidos: pedidos,
      documentoPorOrdem: documentoPorOrdem,
    );
  }

  Future<void> _recarregar() async {
    setState(() {
      _futureDados = _carregarDados();
    });
    await _futureDados;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final largura = MediaQuery.of(context).size.width;
    final isDesktop = largura >= 900;

    return Scaffold(
      appBar: PolewayAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PerfilMenu(themeMode: widget.themeMode),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_DadosPedidos>(
          future: _futureDados,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: p.laranja));
            }

            if (snapshot.hasError) {
              return _buildErro(p, snapshot.error.toString());
            }

            final dados =
                snapshot.data ??
                const _DadosPedidos(pedidos: [], documentoPorOrdem: {});
            final pedidos = dados.pedidos;
            final abertos = pedidos.where((ped) => !ped.concluido).toList();
            final entregues = pedidos.where((ped) => ped.concluido).toList();

            return RefreshIndicator(
              onRefresh: _recarregar,
              color: p.laranja,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final larguraConteudo = constraints.maxWidth > 1500
                      ? 1500.0
                      : constraints.maxWidth;
                  final margemLateral =
                      (constraints.maxWidth - larguraConteudo) / 2 +
                      (isDesktop ? 32 : 20);

                  return ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: margemLateral,
                      vertical: 32,
                    ),
                    children: [
                      const Text(
                        'Meus pedidos',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Acompanhe o status, itens, nota fiscal e boleto dos seus pedidos.',
                        style: TextStyle(color: p.textoSuave, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      _ClienteCard(cliente: widget.cliente),
                      const SizedBox(height: 28),
                      _buildResumo(
                        p,
                        pedidos.length,
                        abertos.length,
                        entregues.length,
                        isDesktop,
                      ),
                      const SizedBox(height: 36),
                      _buildSecao(
                        p,
                        'Em aberto',
                        abertos,
                        dados.documentoPorOrdem,
                        isDesktop,
                      ),
                      const SizedBox(height: 40),
                      _buildSecao(
                        p,
                        'Finalizados',
                        entregues,
                        dados.documentoPorOrdem,
                        isDesktop,
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
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
              'Não foi possível carregar seus pedidos.',
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

  Widget _buildResumo(
    AppPalette p,
    int total,
    int abertos,
    int entregues,
    bool isDesktop,
  ) {
    final cards = [
      _ResumoCard(
        icone: Icons.local_shipping_outlined,
        label: 'Em aberto',
        valor: '$abertos',
        cor: p.laranja,
      ),
      _ResumoCard(
        icone: Icons.check_circle_outline,
        label: 'Finalizados',
        valor: '$entregues',
        cor: p.verde,
      ),
      _ResumoCard(
        icone: Icons.receipt_long_outlined,
        label: 'Total de pedidos',
        valor: '$total',
        cor: p.azul,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSecao(
    AppPalette p,
    String titulo,
    List<Pedido> pedidos,
    Map<String, DocumentoFinanceiro> documentoPorOrdem,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: p.laranjaSuave,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pedidos.length}',
                style: TextStyle(
                  color: p.laranja,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (pedidos.isEmpty)
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
                'Nenhum pedido aqui.',
                style: TextStyle(color: p.textoSuave),
              ),
            ),
          )
        else if (isDesktop)
          Column(
            children: [
              for (var i = 0; i < pedidos.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PedidoCard(
                          pedido: pedidos[i],
                          documento: documentoPorOrdem[pedidos[i].ordem],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: i + 1 < pedidos.length
                            ? _PedidoCard(
                                pedido: pedidos[i + 1],
                                documento: documentoPorOrdem[pedidos[i + 1].ordem],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          )
        else
          Column(
            children: [
              for (final ped in pedidos) ...[
                _PedidoCard(
                  pedido: ped,
                  documento: documentoPorOrdem[ped.ordem],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _PerfilMenu extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeMode;

  const _PerfilMenu({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        final escuro = mode == ThemeMode.dark;

        return PopupMenuButton<String>(
          tooltip: 'Conta',
          offset: const Offset(0, 44),
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente Pole Alimentos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'cliente@empresa.com.br',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, setMenuState) {
                  return SwitchListTile(
                    value: escuro,
                    onChanged: (v) {
                      themeMode.value = v ? ThemeMode.dark : ThemeMode.light;
                      setMenuState(() {});
                    },
                    activeThumbColor: p.laranja,
                    title: const Text(
                      'Modo escuro',
                      style: TextStyle(fontSize: 14),
                    ),
                    secondary: Icon(
                      escuro
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 20,
                    ),
                    dense: true,
                  );
                },
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'sair',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: p.vermelho),
                  const SizedBox(width: 12),
                  Text('Sair', style: TextStyle(color: p.vermelho)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'sair') {
              // TODO: integrar com logout do Supabase Auth
            }
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: p.laranjaClaro,
            child: Icon(Icons.person, color: p.laranja, size: 18),
          ),
        );
      },
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente cliente;

  const _ClienteCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.laranjaSuave,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.superficie,
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
                  cliente.endereco.isNotEmpty
                      ? cliente.endereco
                      : 'Endereço não informado',
                  style: TextStyle(color: p.textoSuave, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    _infoItem(p, 'Telefone', cliente.telefone),
                    _infoItem(
                      p,
                      'Limite total',
                      'R\$ ${cliente.limiteTotal.toStringAsFixed(2)}',
                    ),
                    _infoItem(
                      p,
                      'Documentos abertos',
                      '${cliente.documentosAbertos}',
                    ),
                    _infoItem(
                      p,
                      'Documentos pendentes',
                      '${cliente.documentosPendentes}',
                    ),
                    _infoItem(p, 'Dias de entrega', cliente.diasEntrega),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(AppPalette p, String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: p.textoSuave, fontSize: 11)),
        Text(
          valor.isNotEmpty ? valor : '--',
          style: TextStyle(
            color: p.texto,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;
  final Color cor;

  const _ResumoCard({
    required this.icone,
    required this.label,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borda),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: p.texto,
                ),
              ),
              Text(label, style: TextStyle(color: p.textoSuave, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final DocumentoFinanceiro? documento;

  const _PedidoCard({required this.pedido, this.documento});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final doc = documento;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DetalhePedidoScreen(pedido: pedido, documento: doc),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.laranjaSuave,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_outlined, color: p.laranja),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido ${pedido.ordem}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: p.texto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatarData(pedido.dataCriacao)} · R\$ ${pedido.valor.toStringAsFixed(2)}',
                          style: TextStyle(color: p.textoSuave, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: pedido.status),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: p.textoSuave),
                ],
              ),
              if (doc != null) ...[
                const SizedBox(height: 12),
                _SituacaoFinanceira(documento: doc),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _DadosPedidos {
  final List<Pedido> pedidos;
  final Map<String, DocumentoFinanceiro> documentoPorOrdem;

  const _DadosPedidos({required this.pedidos, required this.documentoPorOrdem});
}

class _SituacaoFinanceira extends StatelessWidget {
  final DocumentoFinanceiro documento;

  const _SituacaoFinanceira({required this.documento});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final cor = documento.vencido
        ? p.vermelho
        : (documento.pendente ? p.laranja : p.verde);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: cor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              documento.vencido
                  ? 'Vencido em ${_formatarData(documento.vencimento)}'
                  : '${documento.status} · vencimento ${_formatarData(documento.vencimento)}',
              style: TextStyle(
                color: cor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'R\$ ${documento.valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
