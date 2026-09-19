import 'package:flutter/material.dart';

import '../models/concelho_geometry.dart';
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
/// no Canvas 1000x1600. Utiliza agrupamento de geometrias por cor e fronteiras pré-compiladas
/// para reduzir as draw calls a ~8 por frame, garantindo 60/120fps fluidos no zoom e pan.
class PortugalMapPainter extends CustomPainter {
  final Path allBordersPath;
  final Map<int, Path> groupedFillPaths;
  final ConcelhoGeometry? selectedGeometry;
  final int? riscoSelecionadoRcm;
  final bool isDark;
  final bool altoContraste;

  final Paint _oceanPaint = Paint();
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _selectedStrokePaint = Paint()..style = PaintingStyle.stroke;

  PortugalMapPainter({
    required this.allBordersPath,
    required this.groupedFillPaths,
    required this.selectedGeometry,
    required this.riscoSelecionadoRcm,
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
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Oceano / Fundo
    canvas.drawRect(Offset.zero & size, _oceanPaint);

    // 2. Preenchimentos agrupados por nível de risco (apenas 5-6 draw calls!)
    groupedFillPaths.forEach((rcm, combinedPath) {
      _fillPaint.color = rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);
      canvas.drawPath(combinedPath, _fillPaint);
    });

    // 3. Contornos consolidados (1 única chamada para todas as fronteiras de Portugal continental)
    canvas.drawPath(allBordersPath, _strokePaint);

    // 4. Concelho selecionado (desenhado com destaque no topo)
    if (selectedGeometry != null) {
      final rcm = riscoSelecionadoRcm ?? 0;
      _fillPaint.color = rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);

      canvas.drawPath(selectedGeometry!.path, _fillPaint);
      canvas.drawPath(selectedGeometry!.path, _selectedStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PortugalMapPainter oldDelegate) {
    return oldDelegate.groupedFillPaths != groupedFillPaths ||
        oldDelegate.allBordersPath != allBordersPath ||
        oldDelegate.selectedGeometry != selectedGeometry ||
        oldDelegate.riscoSelecionadoRcm != riscoSelecionadoRcm ||
        oldDelegate.isDark != isDark ||
        oldDelegate.altoContraste != altoContraste;
  }
}
