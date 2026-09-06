import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/concelho.dart';
import '../models/concelho_geometry.dart';
import '../models/risco_incendio.dart';
import '../providers/acessibilidade_provider.dart';
import '../providers/risco_provider.dart';
import '../services/map_geometry_service.dart';
import '../utils/risco_helpers.dart';
import '../widgets/portugal_map_painter.dart';
import '../widgets/risco_badge.dart';

class MapScreen extends StatefulWidget {
  final bool showAppBar;
  final String? initialDico;

  const MapScreen({
    super.key,
    this.showAppBar = true,
    this.initialDico,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapGeometryService _geometryService = MapGeometryService();
  final TransformationController _transformationController =
      TransformationController();

  AnimationController? _animController;
  Animation<Matrix4>? _matrixAnimation;

  List<ConcelhoGeometry> _geometries = [];
  bool _isLoading = true;
  int _diaSelecionadoIndex = 0;
  String? _dicoSelecionado;

  // Ajuste de zoom e centramento
  Size? _lastViewportSize;
  bool _hasInitialFit = false;

  // Controlos de Pesquisa Integrada
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  int? _filtroNivelRisco; // null = todos, 1 a 5 = filtrar por nível de risco
  bool _mostrandoDropdownPesquisa = false;

  @override
  void initState() {
    super.initState();
    _dicoSelecionado = widget.initialDico;
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() => _mostrandoDropdownPesquisa = true);
      }
    });
    _carregarMapa();
  }

  Future<void> _carregarMapa() async {
    final list = await _geometryService.carregarGeometrias();
    if (mounted) {
      setState(() {
        _geometries = list;
        _isLoading = false;
      });

      if (_lastViewportSize != null && !_hasInitialFit) {
        _hasInitialFit = true;
        _transformationController.value =
            _calcularMatrizAjuste(_lastViewportSize!);
      }

      if (_dicoSelecionado != null) {
        final geo =
            _geometries.where((g) => g.dico == _dicoSelecionado).firstOrNull;
        if (geo != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _focarConcelho(geo, animado: false);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _transformationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Calcula a matriz ideal para enquadrar e centrar Portugal por completo na janela
  Matrix4 _calcularMatrizAjuste(Size viewportSize) {
    final isNarrow = viewportSize.width < 680;
    // Reserva espaço para coluna de dias à direita e margens
    final disponivelW = isNarrow ? (viewportSize.width - 32) : (viewportSize.width - 240);
    final disponivelH = viewportSize.height - 80;

    final escalaW = disponivelW / MapGeometryService.canvasWidth;
    final escalaH = disponivelH / MapGeometryService.canvasHeight;
    final escala = math.min(escalaW, escalaH).clamp(0.28, 1.4);

    // O centróide geográfico de Portugal continental no canvas 1000x1600 situa-se em (500, 820)
    // Em desktop, posiciona o centro ligeiramente à esquerda para equilibrar a coluna de dias à direita
    final centroX = isNarrow ? (viewportSize.width / 2.0) : ((viewportSize.width - 210) / 2.0 + 10);
    final centroY = (viewportSize.height + 20) / 2.0;

    return Matrix4.identity()
      ..translate(centroX, centroY)
      ..scale(escala)
      ..translate(-500.0, -820.0);
  }

  void _resetZoom() {
    HapticFeedback.selectionClick();
    if (_lastViewportSize != null) {
      _animarParaMatriz(_calcularMatrizAjuste(_lastViewportSize!));
    } else {
      _animarParaMatriz(Matrix4.identity());
    }
  }

  void _focarConcelho(ConcelhoGeometry geo, {bool animado = true}) {
    HapticFeedback.selectionClick();
    setState(() {
      _dicoSelecionado = geo.dico;
      _mostrandoDropdownPesquisa = false;
    });
    _searchFocusNode.unfocus();

    final size = _lastViewportSize ?? MediaQuery.of(context).size;
    final targetScale = 2.2;
    final offsetX = size.width / 2.0;
    // Compensa ligeiramente o centro para dar espaço ao cartão inferior
    final offsetY = (size.height - 50) / 2.0;

    final targetX = geo.bounds.center.dx;
    final targetY = geo.bounds.center.dy;

    final targetMatrix = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(targetScale)
      ..translate(-targetX, -targetY);

    if (animado) {
      _animarParaMatriz(targetMatrix);
    } else {
      _transformationController.value = targetMatrix;
    }
  }

  void _animarParaMatriz(Matrix4 targetMatrix) {
    final acc = context.read<AcessibilidadeProvider>();
    if (acc.reduzirAnimacoes) {
      _animController?.stop();
      _transformationController.value = targetMatrix;
      return;
    }

    _animController?.dispose();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _matrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOutCubic,
    ));

    _animController!.addListener(() {
      if (_matrixAnimation != null) {
        _transformationController.value = _matrixAnimation!.value;
      }
    });

    _animController!.forward();
  }

  void _zoom(double factor) {
    HapticFeedback.selectionClick();
    final matrix = _transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.3, 6.0);
    final actualFactor = targetScale / currentScale;

    if (actualFactor != 1.0) {
      final size = _lastViewportSize ?? MediaQuery.of(context).size;
      final focalX = size.width / 2.0;
      final focalY = size.height / 2.0;

      final translationToOrigin = Matrix4.translationValues(-focalX, -focalY, 0);
      final scaleMatrix = Matrix4.diagonal3Values(actualFactor, actualFactor, 1.0);
      final translationBack = Matrix4.translationValues(focalX, focalY, 0);

      _animarParaMatriz(
          translationBack * scaleMatrix * translationToOrigin * matrix);
    }
  }

  void _zoomIn() => _zoom(1.35);
  void _zoomOut() => _zoom(1 / 1.35);

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double scaleChange = event.scrollDelta.dy < 0 ? 1.15 : 0.87;
      final Matrix4 currentMatrix = _transformationController.value;
      final double currentScale = currentMatrix.getMaxScaleOnAxis();
      final double targetScale = (currentScale * scaleChange).clamp(0.25, 6.0);
      final double factor = targetScale / currentScale;

      if (factor != 1.0) {
        final focalPoint = event.localPosition;
        // Transforma o ponto do cursor relativo ao viewport mantendo a cena fixa sob o rato
        final Matrix4 newMatrix = Matrix4.identity()
          ..translate(focalPoint.dx, focalPoint.dy)
          ..scale(factor)
          ..translate(-focalPoint.dx, -focalPoint.dy)
          ..multiply(currentMatrix);

        _transformationController.value = newMatrix;
      }
    }
  }

  void _aoTocarNoMapa(Offset scenePoint) {
    // Se o dropdown de pesquisa estiver aberto, tocar fora fecha-o
    if (_mostrandoDropdownPesquisa) {
      setState(() => _mostrandoDropdownPesquisa = false);
      _searchFocusNode.unfocus();
      return;
    }

    if (_geometries.isEmpty) return;

    for (final geo in _geometries) {
      if (geo.contains(scenePoint)) {
        HapticFeedback.selectionClick();
        setState(() {
          _dicoSelecionado = geo.dico;
        });
        return;
      }
    }

    setState(() {
      _dicoSelecionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final accProvider = context.watch<AcessibilidadeProvider>();
    final diasDisponiveis = _obterDiasDisponiveis(provider);

    if (_diaSelecionadoIndex >= diasDisponiveis.length &&
        diasDisponiveis.isNotEmpty) {
      _diaSelecionadoIndex = 0;
    }

    final dadosRiscoDia = _obterDadosDoDia(provider, _diaSelecionadoIndex);

    final concelhoGeoSelecionado = _dicoSelecionado != null
        ? _geometries.where((g) => g.dico == _dicoSelecionado).firstOrNull
        : null;

    final riscoConcelho = concelhoGeoSelecionado != null && dadosRiscoDia != null
        ? dadosRiscoDia.getRisco(concelhoGeoSelecionado.dico)
        : null;

    // Filtragem de concelhos para a pesquisa
    final normalizedQuery = Concelho.normalize(_searchQuery);
    final filteredConcelhos = provider.concelhos.where((c) {
      if (_filtroNivelRisco != null && dadosRiscoDia != null) {
        final r = dadosRiscoDia.getRisco(c.dico);
        if (r == null || r.rcm != _filtroNivelRisco) return false;
      }
      if (normalizedQuery.isEmpty) return true;
      return c.matchesSearch(normalizedQuery, queryIsNormalized: true);
    }).toList();

    final mapShortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
        _searchFocusNode.requestFocus();
        if (_searchController.text.isNotEmpty) {
          setState(() => _mostrandoDropdownPesquisa = true);
        }
      },
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (_mostrandoDropdownPesquisa) {
          setState(() => _mostrandoDropdownPesquisa = false);
          _searchFocusNode.unfocus();
        } else if (_dicoSelecionado != null) {
          setState(() => _dicoSelecionado = null);
        }
      },
      const SingleActivator(LogicalKeyboardKey.equal): _zoomIn,
      const SingleActivator(LogicalKeyboardKey.add): _zoomIn,
      const SingleActivator(LogicalKeyboardKey.minus): _zoomOut,
      const SingleActivator(LogicalKeyboardKey.numpadSubtract): _zoomOut,
      const SingleActivator(LogicalKeyboardKey.digit0): _resetZoom,
      const SingleActivator(LogicalKeyboardKey.numpad0): _resetZoom,
    };

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Mapa & Pesquisa'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: 'Centrar / Repor Zoom (0)',
                  onPressed: _resetZoom,
                ),
              ],
            )
          : null,
      body: CallbackShortcuts(
        bindings: mapShortcuts,
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
          final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          _lastViewportSize = viewportSize;

          if (!_hasInitialFit && _geometries.isNotEmpty) {
            _hasInitialFit = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _transformationController.value =
                    _calcularMatrizAjuste(viewportSize);
              }
            });
          }

          final isNarrow = viewportSize.width < 680;
          final cs = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Stack(
            children: [
              // 1. O Mapa Interativo de Portugal (Ocupa o ecrã inteiro)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF101318)
                      : const Color(0xFFE5EAF0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Listener(
                          onPointerDown: (_) {
                            if (_mostrandoDropdownPesquisa) {
                              setState(() => _mostrandoDropdownPesquisa = false);
                              _searchFocusNode.unfocus();
                            }
                          },
                          onPointerSignal: _onPointerSignal,
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            panEnabled: true,
                            scaleEnabled: true,
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            minScale: 0.20,
                            maxScale: 6.0,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.grab,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) =>
                                    _aoTocarNoMapa(details.localPosition),
                                child: SizedBox(
                                  width: MapGeometryService.canvasWidth,
                                  height: MapGeometryService.canvasHeight,
                                  child: CustomPaint(
                                    isComplex: true,
                                    willChange: false,
                                    size: const Size(
                                      MapGeometryService.canvasWidth,
                                      MapGeometryService.canvasHeight,
                                    ),
                                    painter: PortugalMapPainter(
                                      geometries: _geometries,
                                      dadosRisco: dadosRiscoDia,
                                      dicoSelecionado: _dicoSelecionado,
                                      isDark: Theme.of(context).brightness ==
                                          Brightness.dark,
                                      altoContraste: accProvider.altoContraste,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // 2. Barra de Pesquisa Flutuante no Topo Esquerdo
              Positioned(
                left: 14,
                top: 14,
                right: isNarrow ? 14 : null,
                child: _buildSearchBar(isNarrow, accProvider.elementosGrandes),
              ),

              // 3. Dropdown Flutuante de Resultados de Pesquisa (quando ativo)
              if (_mostrandoDropdownPesquisa)
                Positioned(
                  left: 14,
                  right: isNarrow ? 14 : null,
                  top: accProvider.elementosGrandes ? 68 : 62,
                  child: _buildSearchDropdown(
                    provider,
                    dadosRiscoDia,
                    filteredConcelhos,
                    isNarrow,
                  ),
                ),

              // 4. Seletor de Dias em Coluna Vertical no Topo Direito
              if (diasDisponiveis.isNotEmpty)
                Positioned(
                  right: 14,
                  top: isNarrow ? (accProvider.elementosGrandes ? 72 : 66) : 14,
                  child: _buildDiasVerticalColumn(
                    diasDisponiveis,
                    provider,
                    viewportSize,
                  ),
                ),

              // Dica contextual de navegação (quando ativada nas opções de Acessibilidade)
              if (accProvider.dicasContextuais && concelhoGeoSelecionado == null)
                Positioned(
                  left: 14,
                  bottom: isNarrow ? 150 : 135,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: isDark ? 0.90 : 0.94),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pan_tool_outlined, size: 13, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Arrasta para mover • Usa scroll para zoom',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 5. Botões de Zoom e Repor
              Positioned(
                left: 14,
                bottom: concelhoGeoSelecionado != null ? 100 : 20,
                child: _buildZoomControls(accProvider.elementosGrandes),
              ),

              // 6. Legenda Compacta de Risco
              Positioned(
                right: 14,
                bottom: concelhoGeoSelecionado != null ? 100 : 20,
                child: _buildLegendaCard(),
              ),

              // 7. Cartão do Concelho Selecionado (quando ativo)
              if (concelhoGeoSelecionado != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _buildSelectedConcelhoCard(
                    provider,
                    concelhoGeoSelecionado,
                    riscoConcelho,
                  ),
                ),
            ],
          );
        },
      ),
    ),
  ),
);
}

  /// Barra de pesquisa flutuante elegante no canto superior esquerdo
  Widget _buildSearchBar(bool isNarrow, [bool isGrandes = false]) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: isNarrow ? null : (isGrandes ? 310 : 290),
      height: isGrandes ? 48 : 42,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: isDark ? 0.92 : 0.97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0x16000000),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: isNarrow
              ? 'Pesquisar concelho...'
              : 'Pesquisar concelho ou distrito... (Ctrl+F)',
          hintStyle: TextStyle(
            fontSize: 12,
            color: cs.outline.withValues(alpha: 0.8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _mostrandoDropdownPesquisa = true;
          });
        },
      ),
    );
  }

  /// Coluna vertical de seleção de dias flutuante no topo direito (estilo lista Apple)
  Widget _buildDiasVerticalColumn(
    List<DiaOpcao> diasDisponiveis,
    RiscoProvider provider,
    Size viewportSize,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final concelhoRef = _dicoSelecionado != null
        ? _geometries.where((g) => g.dico == _dicoSelecionado).firstOrNull
        : null;

    // Altura máxima para não sobrepor aos botões de zoom ou à base em janelas compactas
    final maxHeight = (viewportSize.height - 120).clamp(160.0, 480.0);

    return Container(
      width: 175,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: isDark ? 0.92 : 0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0x16000000),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho da coluna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isDark ? kBrandDark : kBrand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DIAS (${diasDisponiveis.length})',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.6),

            // Lista vertical com scroll suave
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: diasDisponiveis.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 8,
                  endIndent: 8,
                  color: cs.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.20),
                ),
                itemBuilder: (context, index) {
                  final dia = diasDisponiveis[index];
                  final isSelected = index == _diaSelecionadoIndex;

                  // Se houver concelho selecionado ou principal, exibe o nível de risco desse concelho no dia
                  final dadosDoDia = _obterDadosDoDia(provider, index);
                  final dicoRef = concelhoRef?.dico ?? provider.concelhoPrincipal?.dico;
                  final rcm = dicoRef != null ? dadosDoDia?.getRisco(dicoRef)?.rcm : null;

                  final corDestaque = isDark ? kBrandDark : kBrand;

                  return Material(
                    color: isSelected
                        ? (isDark
                            ? corDestaque.withValues(alpha: 0.18)
                            : corDestaque.withValues(alpha: 0.12))
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _diaSelecionadoIndex = index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            // Indicador visual de seleção
                            Container(
                              width: 3.5,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isSelected ? corDestaque : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 7),

                            // Rótulo do dia
                            Expanded(
                              child: Text(
                                dia.rotulo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? Colors.white : corDestaque)
                                      : cs.onSurface,
                                ),
                              ),
                            ),

                            // Badge com cor de risco do concelho (se disponível) ou chevron
                            if (rcm != null && rcm > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: corDoRiscoContextual(
                                    rcm,
                                    Theme.of(context).brightness,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$rcm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: corDoRiscoTexto(rcm),
                                  ),
                                ),
                              )
                            else if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: corDestaque,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Painel flutuante de resultados de pesquisa (abre por baixo da caixa de pesquisa)
  /// Painel flutuante de resultados de pesquisa (abre por baixo da caixa de pesquisa)
  Widget _buildSearchDropdown(
    RiscoProvider provider,
    DadosRisco? dadosRiscoDia,
    List<Concelho> filteredConcelhos,
    bool isNarrow,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: isNarrow ? null : 310,
      constraints: const BoxConstraints(maxHeight: 370),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: isDark ? 0.96 : 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x28FFFFFF) : const Color(0x18000000),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filtros rápidos por risco
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildRiskFilterChip(null, 'Todos', Colors.grey),
                  const SizedBox(width: 4),
                  _buildRiskFilterChip(5, 'Máximo', corDoRiscoMapa(5)),
                  const SizedBox(width: 4),
                  _buildRiskFilterChip(4, 'M. Elevado', corDoRiscoMapa(4)),
                  const SizedBox(width: 4),
                  _buildRiskFilterChip(3, 'Elevado', corDoRiscoMapa(3)),
                  const SizedBox(width: 4),
                  _buildRiskFilterChip(2, 'Moderado', corDoRiscoMapa(2)),
                  const SizedBox(width: 4),
                  _buildRiskFilterChip(1, 'Reduzido', corDoRiscoMapa(1)),
                ],
              ),
            ),
          ),

          // Contador de resultados e botão de fechar dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredConcelhos.length} concelhos',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _mostrandoDropdownPesquisa = false);
                    _searchFocusNode.unfocus();
                  },
                  child: Text(
                    'Fechar',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.6),

          // Lista de resultados
          Flexible(
            child: filteredConcelhos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Nenhum concelho encontrado',
                      style: TextStyle(fontSize: 12, color: cs.outline),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredConcelhos.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.4, indent: 46),
                    itemBuilder: (context, index) {
                      final concelho = filteredConcelhos[index];
                      final isSelected = concelho.dico == _dicoSelecionado;
                      final isFavorito = provider.isFavorito(concelho.dico);
                      final risco = dadosRiscoDia?.getRisco(concelho.dico);
                      final geo = _geometries
                          .where((g) => g.dico == concelho.dico)
                          .firstOrNull;

                      return InkWell(
                        onTap: () {
                          if (geo != null) {
                            _focarConcelho(geo);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          color: isSelected
                              ? cs.primary.withValues(
                                  alpha: isDark ? 0.20 : 0.12,
                                )
                              : Colors.transparent,
                          child: Row(
                            children: [
                              if (risco != null)
                                RiscoBadge(rcm: risco.rcm, size: 28)
                              else
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.help_outline, size: 14),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      concelho.nome,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${concelho.distrito}${risco?.tMin != null && risco?.tMax != null ? " • ${risco!.tMin!.round()}°/${risco.tMax!.round()}°C" : ""}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: cs.outline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFavorito
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 17,
                                  color: isFavorito
                                      ? const Color(0xFFFF453A)
                                      : cs.outline.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  provider.toggleFavorito(concelho.dico);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFilterChip(int? nivel, String label, Color color) {
    final isSelected = _filtroNivelRisco == nivel;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() {
          _filtroNivelRisco = isSelected ? null : nivel;
        });
      },
      selectedColor: nivel == null ? Colors.grey[800] : color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      side: BorderSide(
        color: color.withValues(alpha: isSelected ? 0.8 : 0.25),
        width: 0.8,
      ),
    );
  }

  Widget _buildLegendaCard() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: isDark ? 0.90 : 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0x16000000),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legenda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5),
          ),
          const SizedBox(height: 3),
          _buildLegendaItem(1, 'Reduzido'),
          _buildLegendaItem(2, 'Moderado'),
          _buildLegendaItem(3, 'Elevado'),
          _buildLegendaItem(4, 'Muito Elevado'),
          _buildLegendaItem(5, 'Máximo'),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(int rcm, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: corDoRiscoMapa(rcm),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls([bool isGrandes = false]) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconSize = isGrandes ? 23.0 : 19.0;
    final btnPadding = isGrandes ? const EdgeInsets.all(12) : const EdgeInsets.all(8);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: isDark ? 0.90 : 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x22FFFFFF) : const Color(0x16000000),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: btnPadding,
            icon: Icon(Icons.add, size: iconSize),
            tooltip: 'Aumentar Zoom (+)',
            onPressed: _zoomIn,
          ),
          const Divider(height: 1, thickness: 0.8),
          IconButton(
            padding: btnPadding,
            icon: Icon(Icons.remove, size: iconSize),
            tooltip: 'Diminuir Zoom (-)',
            onPressed: _zoomOut,
          ),
          const Divider(height: 1, thickness: 0.8),
          IconButton(
            padding: btnPadding,
            icon: Icon(Icons.center_focus_strong, size: iconSize),
            tooltip: 'Centrar Portugal / Repor Zoom (0)',
            onPressed: _resetZoom,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedConcelhoCard(
    RiscoProvider provider,
    ConcelhoGeometry concelhoGeo,
    RiscoLocal? riscoConcelho,
  ) {
    final isFavorito = provider.isFavorito(concelhoGeo.dico);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (riscoConcelho != null)
              RiscoBadge(rcm: riscoConcelho.rcm, size: 38)
            else
              const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.help_outline, color: Colors.white),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    concelhoGeo.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    concelhoGeo.distrito,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 11.5,
                    ),
                  ),
                  if (riscoConcelho != null) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(
                          textoDoRisco(riscoConcelho.rcm),
                          style: TextStyle(
                            color: corDoRiscoTextoEmFundoClaro(riscoConcelho.rcm),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        if (riscoConcelho.tMin != null && riscoConcelho.tMax != null)
                          Text(
                            ' • ${riscoConcelho.tMin!.round()}° / ${riscoConcelho.tMax!.round()}°C',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorito ? const Color(0xFFFF453A) : null,
                size: 20,
              ),
              tooltip: isFavorito ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
              onPressed: () {
                HapticFeedback.selectionClick();
                provider.toggleFavorito(concelhoGeo.dico);
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Fechar seleção',
              onPressed: () => setState(() => _dicoSelecionado = null),
            ),
          ],
        ),
      ),
    );
  }

  List<DiaOpcao> _obterDiasDisponiveis(RiscoProvider provider) {
    final list = <DiaOpcao>[];

    if (provider.previsaoAlargada.isNotEmpty) {
      for (int i = 0; i < provider.previsaoAlargada.length; i++) {
        final dados = provider.previsaoAlargada[i];
        final rotulo = formatarRotuloDia(dados.dataPrev, i, incluirMes: false);
        list.add(DiaOpcao(index: i, rotulo: rotulo, dataPrev: dados.dataPrev));
      }
    } else {
      if (provider.riscoHoje != null) {
        list.add(DiaOpcao(
          index: 0,
          rotulo: 'Hoje',
          dataPrev: provider.riscoHoje!.dataPrev,
        ));
      }
      if (provider.riscoAmanha != null) {
        list.add(DiaOpcao(
          index: 1,
          rotulo: 'Amanhã',
          dataPrev: provider.riscoAmanha!.dataPrev,
        ));
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

