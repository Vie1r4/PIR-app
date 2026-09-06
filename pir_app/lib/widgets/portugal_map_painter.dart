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

/// CustomPainter dedicado à renderização vetorial precisa de Portugal continental
/// no Canvas 1000x1600, com suporte a alto contraste e cores de risco dinâmicas.
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
      _strokePaint.strokeWidth = 1.5;
      _strokePaint.color = isDark
          ? Colors.black.withValues(alpha: 0.45)
          : const Color(0xFF1B2230).withValues(alpha: 0.35);
      _selectedStrokePaint.strokeWidth = 4.0;
    }

    _selectedStrokePaint.color = isDark ? Colors.white : const Color(0xFF002F6C);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _oceanPaint);

    ConcelhoGeometry? selectedGeometry;

    for (final geo in geometries) {
      final isSelected = geo.dico == dicoSelecionado;
      if (isSelected) {
        selectedGeometry = geo;
        continue;
      }

      final rcm = dadosRisco?.getRisco(geo.dico)?.rcm ?? 0;
      _fillPaint.color =
          rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);

      canvas.drawPath(geo.path, _fillPaint);
      canvas.drawPath(geo.path, _strokePaint);
    }

    if (selectedGeometry != null) {
      final rcm = dadosRisco?.getRisco(selectedGeometry.dico)?.rcm ?? 0;
      _fillPaint.color =
          rcm > 0 ? corDoRiscoMapa(rcm) : const Color(0xFFDCDFE3);

      canvas.drawPath(selectedGeometry.path, _fillPaint);
      canvas.drawPath(selectedGeometry.path, _selectedStrokePaint);
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
