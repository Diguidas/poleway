import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
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
  static const _origem = LatLng(-3.846631134405548, -38.66692505096813);
  static const _destino = LatLng(-3.8747090097492856, -38.599987842744945);

  final _mapController = MapController();
  final _distancia = const Distance();
  late final AnimationController _animController;
  late final Animation<double> _progresso;

  List<LatLng> _rota = [_origem, _destino];
  List<double> _distanciasAcumuladas = [0, 0];
  bool _carregandoRota = true;
  LatLng _posicaoCaminhao = _origem;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    _progresso = CurvedAnimation(parent: _animController, curve: Curves.linear);
    _progresso.addListener(_atualizarPosicao);
    _carregarRota();
  }

  Future<void> _carregarRota() async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_origem.longitude},${_origem.latitude};${_destino.longitude},${_destino.latitude}'
        '?overview=full&geometries=geojson',
      );
      final resposta = await http.get(uri);
      if (resposta.statusCode != 200) {
        throw Exception('HTTP ${resposta.statusCode}');
      }
      final corpo = jsonDecode(resposta.body) as Map<String, dynamic>;
      final rotas = corpo['routes'] as List?;
      if (rotas == null || rotas.isEmpty) {
        throw Exception('Sem rota retornada.');
      }
      final coordenadas = (rotas.first['geometry']['coordinates'] as List)
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();

      setState(() {
        _rota = coordenadas;
        _distanciasAcumuladas = _calcularAcumuladas(coordenadas);
        _posicaoCaminhao = coordenadas.first;
        _carregandoRota = false;
      });
    } catch (_) {
      // Sem rota real disponível (ex.: sem internet para o serviço de roteamento):
      // cai de volta para a linha reta como aproximação.
      setState(() {
        _rota = [_origem, _destino];
        _distanciasAcumuladas = _calcularAcumuladas(_rota);
        _carregandoRota = false;
      });
    }
    _animController.forward();
  }

  List<double> _calcularAcumuladas(List<LatLng> pontos) {
    final acumuladas = <double>[0];
    for (var i = 1; i < pontos.length; i++) {
      acumuladas.add(acumuladas.last + _distancia(pontos[i - 1], pontos[i]));
    }
    return acumuladas;
  }

  void _atualizarPosicao() {
    final distanciaTotal = _distanciasAcumuladas.last;
    final distanciaAlvo = distanciaTotal * _progresso.value;

    var i = 0;
    while (i < _distanciasAcumuladas.length - 1 && _distanciasAcumuladas[i + 1] < distanciaAlvo) {
      i++;
    }

    LatLng posicao;
    if (i >= _rota.length - 1) {
      posicao = _rota.last;
    } else {
      final distanciaSegmento = _distanciasAcumuladas[i + 1] - _distanciasAcumuladas[i];
      final t = distanciaSegmento == 0 ? 0.0 : (distanciaAlvo - _distanciasAcumuladas[i]) / distanciaSegmento;
      posicao = LatLng(
        _rota[i].latitude + (_rota[i + 1].latitude - _rota[i].latitude) * t,
        _rota[i].longitude + (_rota[i + 1].longitude - _rota[i].longitude) * t,
      );
    }

    setState(() => _posicaoCaminhao = posicao);
    _mapController.move(posicao, _mapController.camera.zoom);
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
                          points: _rota,
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
                if (_carregandoRota)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: p.superficie,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.laranja),
                          ),
                          const SizedBox(width: 8),
                          Text('Calculando rota...', style: TextStyle(color: p.textoSuave, fontSize: 12)),
                        ],
                      ),
                    ),
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
