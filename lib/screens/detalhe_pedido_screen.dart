import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/status_chip.dart';
import 'rastreamento_screen.dart';

class DetalhePedidoScreen extends StatefulWidget {
  final Pedido pedido;

  const DetalhePedidoScreen({super.key, required this.pedido});

  @override
  State<DetalhePedidoScreen> createState() => _DetalhePedidoScreenState();
}

class _DetalhePedidoScreenState extends State<DetalhePedidoScreen> {
  final ApiService _api = ApiService();
  late Future<List<ItemPedido>> _futureItens;

  @override
  void initState() {
    super.initState();
    _futureItens = _api.getItens(widget.pedido.ordem);
  }

  bool get _finalizado => widget.pedido.concluido;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido ${widget.pedido.ordem}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: p.borda),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final larguraConteudo = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
            final margemLateral = (constraints.maxWidth - larguraConteudo) / 2 + 20;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: margemLateral, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumo(p),
                  const SizedBox(height: 16),
                  if (!_finalizado) ...[
                    _buildAndamento(p),
                    const SizedBox(height: 16),
                  ],
                  _buildItens(p),
                  const SizedBox(height: 16),
                  _buildDocumentos(p),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumo(AppPalette p) {
    final pedido = widget.pedido;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedido ${pedido.ordem}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.texto)),
                  const SizedBox(height: 6),
                  Text(
                    'Realizado em ${_formatarData(pedido.dataCriacao)}',
                    style: TextStyle(color: p.textoSuave, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  StatusChip(status: pedido.status),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Valor total', style: TextStyle(color: p.textoSuave, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${pedido.valor.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.laranja),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndamento(AppPalette p) {
    final pedido = widget.pedido;
    final etapas = [
      ('Pedido confirmado', true),
      ('Em processamento', true),
      ('Faturado', pedido.status.toLowerCase() == 'faturado'),
      ('Entregue', false),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Andamento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: p.texto)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: p.textoSuave),
                const SizedBox(width: 4),
                Text(
                  'Previsão de entrega: ${_formatarData(pedido.dataEntrega)}',
                  style: TextStyle(color: p.textoSuave, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < etapas.length; i++)
              _EtapaTile(
                label: etapas[i].$1,
                concluida: etapas[i].$2,
                ultima: i == etapas.length - 1,
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RastreamentoScreen(ordem: pedido.ordem),
                    ),
                  );
                },
                icon: Icon(Icons.local_shipping_outlined, color: p.laranja),
                label: Text('Rastrear caminhão', style: TextStyle(color: p.laranja)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.laranja),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItens(AppPalette p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Itens do pedido', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: p.texto)),
            const SizedBox(height: 12),
            FutureBuilder<List<ItemPedido>>(
              future: _futureItens,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: p.laranja)),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Não foi possível carregar os itens.', style: TextStyle(color: p.textoSuave));
                }
                final itens = snapshot.data ?? [];
                if (itens.isEmpty) {
                  return Text('Nenhum item encontrado.', style: TextStyle(color: p.textoSuave));
                }
                return Column(
                  children: [for (final item in itens) _buildItemRow(p, item)],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(AppPalette p, ItemPedido item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.denominacao, style: TextStyle(fontSize: 14, color: p.texto)),
          ),
          Expanded(
            child: Text('${item.quantidade.toStringAsFixed(0)} ${item.unidadeVenda}',
                textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              'R\$ ${item.valorTotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.texto),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentos(AppPalette p) {
    final pedido = widget.pedido;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: p.texto)),
            const SizedBox(height: 12),
            _DocumentoTile(
              icone: Icons.receipt_long_outlined,
              titulo: 'Nota fiscal',
              subtitulo: pedido.notaFiscal.isNotEmpty ? pedido.notaFiscal : 'Ainda não emitida',
              disponivel: pedido.notaFiscal.isNotEmpty,
            ),
            const SizedBox(height: 10),
            const _DocumentoTile(
              icone: Icons.description_outlined,
              titulo: 'Boleto',
              subtitulo: 'Endpoint ainda não disponível',
              disponivel: false,
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _EtapaTile extends StatelessWidget {
  final String label;
  final bool concluida;
  final bool ultima;

  const _EtapaTile({required this.label, required this.concluida, required this.ultima});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final cor = concluida ? p.laranja : p.textoSuave.withValues(alpha: 0.4);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: concluida ? p.laranja : p.superficie,
                  shape: BoxShape.circle,
                  border: Border.all(color: cor, width: 2),
                ),
              ),
              if (!ultima)
                Expanded(
                  child: Container(width: 2, color: cor.withValues(alpha: 0.4)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: concluida ? FontWeight.w600 : FontWeight.w400,
                color: concluida ? p.texto : p.textoSuave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentoTile extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final bool disponivel;

  const _DocumentoTile({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.disponivel,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.laranjaSuave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, color: p.laranja),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: p.texto)),
                Text(subtitulo, style: TextStyle(color: p.textoSuave, fontSize: 12)),
              ],
            ),
          ),
          if (disponivel)
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: p.laranja,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Baixar'),
            ),
        ],
      ),
    );
  }
}
