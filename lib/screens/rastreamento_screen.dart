import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme.dart';

class RastreamentoScreen extends StatefulWidget {
  final String ordem;

  const RastreamentoScreen({super.key, required this.ordem});

  @override
  State<RastreamentoScreen> createState() => _RastreamentoScreenState();
}

class _RastreamentoScreenState extends State<RastreamentoScreen> with SingleTickerProviderStateMixin {
  // Coordenadas de teste: origem (caminhão) até destino (cliente).
  static const _origem = LatLng(-3.846631134405548, -38.66692505096813); // Av. Paulista, SP
  static const _destino = LatLng(-3.8747090097492856, -38.599987842744945); // Consolação/Higienópolis, SP

  final _mapController = MapController();
  late final AnimationController _animController;
  late final Animation<double> _progresso;
  LatLng _posicaoCaminhao = _origem;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    _progresso = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _progresso.addListener(_atualizarPosicao);
    _animController.forward();
  }

  void _atualizarPosicao() {
    final t = _progresso.value;
    setState(() {
      _posicaoCaminhao = LatLng(
        _origem.latitude + (_destino.latitude - _origem.latitude) * t,
        _origem.longitude + (_destino.longitude - _origem.longitude) * t,
      );
    });
    _mapController.move(_posicaoCaminhao, _mapController.camera.zoom);
  }

  double get _rotacaoCaminhao {
    final dy = _destino.latitude - _origem.latitude;
    final dx = _destino.longitude - _origem.longitude;
    return atan2(dx, dy);
  }

  @override
  void dispose() {
    _progresso.removeListener(_atualizarPosicao);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chegou = _progresso.value >= 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rastreamento • Pedido ${widget.ordem}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: p.borda),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _origem,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.poleway.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_origem, _destino],
                          strokeWidth: 4,
                          color: p.laranja.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _destino,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.home, color: p.azul, size: 34),
                        ),
                        Marker(
                          point: _posicaoCaminhao,
                          width: 46,
                          height: 46,
                          child: Transform.rotate(
                            angle: _rotacaoCaminhao,
                            child: Icon(Icons.local_shipping, color: p.laranja, size: 34),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recentralizar',
                    backgroundColor: p.superficie,
                    foregroundColor: p.texto,
                    onPressed: () => _mapController.move(_posicaoCaminhao, 14),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: p.superficie,
            child: Row(
              children: [
                Icon(
                  chegou ? Icons.check_circle : Icons.local_shipping_outlined,
                  color: chegou ? p.verde : p.laranja,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chegou ? 'Caminhão chegou ao destino' : 'Caminhão a caminho do endereço de entrega',
                    style: TextStyle(fontWeight: FontWeight.w600, color: p.texto),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
