import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/concelho_geometry.dart';
import '../models/risco_incendio.dart';
import '../providers/risco_provider.dart';
import '../services/map_geometry_service.dart';
import '../utils/risco_helpers.dart';
import '../widgets/risco_badge.dart';

class MapScreen extends StatefulWidget {
  final bool showAppBar;
  const MapScreen({super.key, this.showAppBar = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapGeometryService _geometryService = MapGeometryService();
  final TransformationController _transformationController =
      TransformationController();

  List<ConcelhoGeometry> _geometries = [];
  bool _isLoading = true;
  int _diaSelecionadoIndex = 0;
  String? _dicoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarMapa();
  }

  Future<void> _carregarMapa() async {
    final list = await _geometryService.carregarGeometrias();
    if (mounted) {
      setState(() {
        _geometries = list;
        _isLoading = false;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _aoTocarNoMapa(TapUpDetails details) {
    if (_geometries.isEmpty) return;

    // Converte a posição no ecrã para coordenadas do canvas (1000x1600)
    final scenePoint =
        _transformationController.toScene(details.localPosition);

    for (final geo in _geometries) {
      if (geo.contains(scenePoint)) {
        setState(() {
          _dicoSelecionado = geo.dico;
        });
        return;
      }
    }

    // Se tocou fora de qualquer concelho (ex: mar/Espanha), desseleciona
    setState(() {
      _dicoSelecionado = null;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final diasDisponiveis = _obterDiasDisponiveis(provider);

    // Garante que o índice selecionado é válido
    if (_diaSelecionadoIndex >= diasDisponiveis.length &&
        diasDisponiveis.isNotEmpty) {
      _diaSelecionadoIndex = 0;
    }

    // Obter os dados de risco do dia selecionado
    final dadosRiscoDia = _obterDadosDoDia(provider, _diaSelecionadoIndex);

    // Concelho selecionado (para o cartão de detalhes)
    final concelhoGeoSelecionado = _dicoSelecionado != null
        ? _geometries.cast<ConcelhoGeometry?>().firstWhere(
              (g) => g!.dico == _dicoSelecionado,
              orElse: () => null,
            )
        : null;

    final riscoConcelho = concelhoGeoSelecionado != null && dadosRiscoDia != null
        ? dadosRiscoDia.getRisco(concelhoGeoSelecionado.dico)
        : null;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Mapa de Risco (PIR)'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: 'Centrar / Repor Zoom',
                  onPressed: _resetZoom,
                ),
              ],
            )
          : null,
      floatingActionButton: !widget.showAppBar
          ? FloatingActionButton.small(
              heroTag: 'map_reset_zoom',
              tooltip: 'Centrar / Repor Zoom',
              onPressed: _resetZoom,
              child: const Icon(Icons.center_focus_strong),
            )
          : null,
      body: Column(
        children: [
          // 1. Barra seletora de dias no topo
          if (diasDisponiveis.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: diasDisponiveis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final dia = diasDisponiveis[index];
                  final isSelected = index == _diaSelecionadoIndex;
                  return ChoiceChip(
                    label: Text(dia.rotulo),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _diaSelecionadoIndex = index;
                        });
                      }
                    },
                    selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFFF6B35)
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // 2. Área do mapa interativo
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('A carregar mapa oficial de Portugal...'),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      // O Mapa
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFFE2EAF1),
                          child: GestureDetector(
                            onTapUp: _aoTocarNoMapa,
                            child: InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              minScale: 0.4,
                              maxScale: 6.0,
                              boundaryMargin: const EdgeInsets.all(200),
                            child: SizedBox(
                              width: MapGeometryService.canvasWidth,
                              height: MapGeometryService.canvasHeight,
                              child: CustomPaint(
                                size: const Size(
                                  MapGeometryService.canvasWidth,
                                  MapGeometryService.canvasHeight,
                                ),
                                painter: _PortugalMapPainter(
                                  geometries: _geometries,
                                  dadosRisco: dadosRiscoDia,
                                  dicoSelecionado: _dicoSelecionado,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),

                      // Legenda no canto inferior esquerdo
                      Positioned(
                        left: 12,
                        bottom: concelhoGeoSelecionado != null ? 140 : 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Legenda de Risco',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildLegendaItem(1, 'Reduzido'),
                              _buildLegendaItem(2, 'Moderado'),
                              _buildLegendaItem(3, 'Elevado'),
                              _buildLegendaItem(4, 'Muito Elevado'),
                              _buildLegendaItem(5, 'Máximo'),
                            ],
                          ),
                        ),
                      ),

                      // Cartão de Concelho Selecionado no fundo
                      if (concelhoGeoSelecionado != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  if (riscoConcelho != null)
                                    RiscoBadge(
                                      rcm: riscoConcelho.rcm,
                                      size: 42,
                                    )
                                  else
                                    const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      child: Icon(
                                        Icons.help_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          concelhoGeoSelecionado.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          concelhoGeoSelecionado.distrito,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (riscoConcelho != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                textoDoRisco(riscoConcelho.rcm),
                                                style: TextStyle(
                                                  color:
                                                      corDoRiscoTextoEmFundoClaro(
                                                    riscoConcelho.rcm,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (riscoConcelho.tMin != null &&
                                                  riscoConcelho.tMax != null)
                                                Text(
                                                  ' • ${riscoConcelho.tMin!.round()}° / ${riscoConcelho.tMax!.round()}°C',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Botão para definir como principal
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.check),
                                    tooltip: 'Definir como Concelho Principal',
                                    onPressed: () {
                                      provider.selecionarConcelho(
                                        concelhoGeoSelecionado.dico,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${concelhoGeoSelecionado.nome} selecionado como principal!',
                                          ),
                                          duration:
                                              const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Fechar',
                                    onPressed: () {
                                      setState(() {
                                        _dicoSelecionado = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(int rcm, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: corDoRiscoMapa(rcm),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  List<_DiaOpcao> _obterDiasDisponiveis(RiscoProvider provider) {
    final list = <_DiaOpcao>[];

    if (provider.previsaoAlargada.isNotEmpty) {
      for (int i = 0; i < provider.previsaoAlargada.length; i++) {
        final dados = provider.previsaoAlargada[i];
        String rotulo;
        if (i == 0) {
          rotulo = 'Hoje';
        } else if (i == 1) {
          rotulo = 'Amanhã';
        } else {
          try {
            final dt = DateTime.parse(dados.dataPrev);
            const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
            rotulo = '${weekdays[dt.weekday - 1]}, ${dt.day}';
          } catch (_) {
            rotulo = dados.dataPrev;
          }
        }
        list.add(_DiaOpcao(index: i, rotulo: rotulo));
      }
    } else {
      if (provider.riscoHoje != null) {
        list.add(const _DiaOpcao(index: 0, rotulo: 'Hoje'));
      }
      if (provider.riscoAmanha != null) {
        list.add(const _DiaOpcao(index: 1, rotulo: 'Amanhã'));
      }
    }

    return list;
  }

  DadosRisco? _obterDadosDoDia(RiscoProvider provider, int index) {
    if (provider.previsaoAlargada.isNotEmpty &&
        index < provider.previsaoAlargada.length) {
      return provider.previsaoAlargada[index];
    }
    if (index == 0) return provider.riscoHoje;
    if (index == 1) return provider.riscoAmanha;
    return null;
  }
}

class _DiaOpcao {
  final int index;
  final String rotulo;

  const _DiaOpcao({required this.index, required this.rotulo});
}

/// CustomPainter responsável por pintar os 278 concelhos com cores oficiais
class _PortugalMapPainter extends CustomPainter {
  final List<ConcelhoGeometry> geometries;
  final DadosRisco? dadosRisco;
  final String? dicoSelecionado;

  _PortugalMapPainter({
    required this.geometries,
    required this.dadosRisco,
    required this.dicoSelecionado,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo suave de oceano
    final oceanPaint = Paint()..color = const Color(0xFFE2EAF1);
    canvas.drawRect(Offset.zero & size, oceanPaint);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF372D24).withValues(alpha: 0.70)
      ..strokeWidth = 2.0;

    final selectedStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 4.5;

    ConcelhoGeometry? selectedGeometry;

    for (final geo in geometries) {
      final isSelected = geo.dico == dicoSelecionado;
      if (isSelected) {
        selectedGeometry = geo;
        continue;
      }

      final rcm = dadosRisco?.getRisco(geo.dico)?.rcm ?? 0;
      fillPaint.color =
          rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);

      canvas.drawPath(geo.path, fillPaint);
      canvas.drawPath(geo.path, strokePaint);
    }

    // Pinta o concelho selecionado por último com destaque
    if (selectedGeometry != null) {
      final rcm = dadosRisco?.getRisco(selectedGeometry.dico)?.rcm ?? 0;
      fillPaint.color =
          rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);

      canvas.drawPath(selectedGeometry.path, fillPaint);
      canvas.drawPath(selectedGeometry.path, selectedStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PortugalMapPainter oldDelegate) {
    return oldDelegate.dadosRisco != dadosRisco ||
        oldDelegate.dicoSelecionado != dicoSelecionado ||
        oldDelegate.geometries != geometries;
  }
}
