import 'package:flutter/material.dart';

import '../models/concelho_geometry.dart';
import '../models/risco_incendio.dart';
import '../utils/risco_helpers.dart';

/// Representação de uma opção de dia para seleção no mapa (Hoje, Amanhã, etc.)
class DiaOpcao {
  final int index;
  final String rotulo;
  final String dataPrev;

  const DiaOpcao({
    required this.index,
    required this.rotulo,
    required this.dataPrev,
  });
}

/// CustomPainter dedicado à renderização vetorial de alta performance de Portugal continental
/// no Canvas 1000x1600. Utiliza agrupamento de geometrias por cor para reduzir
/// as draw calls de 556 para apenas 6 por frame, garantindo 60/120fps fluidos no zoom.
class PortugalMapPainter extends CustomPainter {
  final List<ConcelhoGeometry> geometries;
  final DadosRisco? dadosRisco;
  final String? dicoSelecionado;
  final bool isDark;
  final bool altoContraste;

  final Paint _oceanPaint = Paint();
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _selectedStrokePaint = Paint()..style = PaintingStyle.stroke;

  // Agrupamento de paths pré-calculados por nível de RCM (0=sem dados, 1..5)
  final Map<int, Path> _groupedFillPaths = {};
  final Path _allBordersPath = Path();
  ConcelhoGeometry? _selectedGeometry;

  PortugalMapPainter({
    required this.geometries,
    required this.dadosRisco,
    required this.dicoSelecionado,
    required this.isDark,
    this.altoContraste = false,
  }) {
    _oceanPaint.color = isDark ? const Color(0xFF101318) : const Color(0xFFE5EAF0);

    if (altoContraste) {
      _strokePaint.strokeWidth = 2.8;
      _strokePaint.color = Colors.black;
      _selectedStrokePaint.strokeWidth = 5.0;
    } else {
      // Meio termo suave e elegante: divisão percetível entre concelhos sem linhas duras
      _strokePaint.strokeWidth = 1.4;
      _strokePaint.color = isDark
          ? Colors.black.withValues(alpha: 0.45)
          : const Color(0xFF1B2230).withValues(alpha: 0.35);
      _selectedStrokePaint.strokeWidth = 4.0;
    }

    _selectedStrokePaint.color = isDark ? Colors.white : const Color(0xFF002F6C);

    // Agrupar previamente todos os 278 concelhos por nível de risco
    // Reduz centenas de draw calls a apenas 6 chamadas de GPU ultrarrápidas!
    for (final geo in geometries) {
      if (geo.dico == dicoSelecionado) {
        _selectedGeometry = geo;
        continue;
      }
      final rcm = dadosRisco?.getRisco(geo.dico)?.rcm ?? 0;
      final pathGroup = _groupedFillPaths.putIfAbsent(rcm, () => Path());
      pathGroup.addPath(geo.path, Offset.zero);
      _allBordersPath.addPath(geo.path, Offset.zero);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Oceano / Fundo
    canvas.drawRect(Offset.zero & size, _oceanPaint);

    // 2. Preenchimentos agrupados por nível de risco (apenas 5-6 draw calls!)
    _groupedFillPaths.forEach((rcm, combinedPath) {
      _fillPaint.color = rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);
      canvas.drawPath(combinedPath, _fillPaint);
    });

    // 3. Contornos consolidados (1 única chamada para todas as fronteiras de Portugal)
    if (geometries.isNotEmpty) {
      canvas.drawPath(_allBordersPath, _strokePaint);
    }

    // 4. Concelho selecionado (desenhado com destaque no topo)
    if (_selectedGeometry != null) {
      final rcm = dadosRisco?.getRisco(_selectedGeometry!.dico)?.rcm ?? 0;
      _fillPaint.color = rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);

      canvas.drawPath(_selectedGeometry!.path, _fillPaint);
      canvas.drawPath(_selectedGeometry!.path, _selectedStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PortugalMapPainter oldDelegate) {
    return oldDelegate.dadosRisco != dadosRisco ||
        oldDelegate.dicoSelecionado != dicoSelecionado ||
        oldDelegate.geometries != geometries ||
        oldDelegate.isDark != isDark ||
        oldDelegate.altoContraste != altoContraste;
  }
}
