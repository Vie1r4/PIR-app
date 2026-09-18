import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../utils/risco_helpers.dart';
import 'risco_badge.dart';

/// Card widget displaying the fire risk level with color, icon, and date
class RiscoCard extends StatelessWidget {
  final String titulo;
  final int rcm;
  final String data;
  final bool isCompact;
  final double? tMin;
  final double? tMax;

  const RiscoCard({
    super.key,
    required this.titulo,
    required this.rcm,
    required this.data,
    this.isCompact = false,
    this.tMin,
    this.tMax,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cor = corDoRiscoContextual(rcm, Theme.of(context).brightness);
    final corDestaque = isDark ? cor : corDoRiscoTextoEmFundoClaro(rcm);
    final cardBg = isDark
        ? Color.alphaBlend(cor.withValues(alpha: 0.10), kDarkCard)
        : Color.alphaBlend(cor.withValues(alpha: 0.04), Colors.white);
    final borderCor = cor.withValues(alpha: isDark ? 0.28 : 0.22);
    final isHoje = titulo.toLowerCase().contains('hoje');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderCor, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: cardBg,
        padding: EdgeInsets.all(isCompact ? 16 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho: etiqueta com ícone sutil + badge à direita
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isHoje ? CupertinoIcons.calendar_today : CupertinoIcons.calendar,
                      size: 15,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      titulo.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                RiscoBadge(rcm: rcm, size: isCompact ? 32 : 36),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 18),

            // Nível de risco — tipografia Apple Weather: limpa, imponente e respirada
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  iconeDoRisco(rcm),
                  color: corDestaque,
                  size: isCompact ? 30 : 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    textoDoRisco(rcm),
                    style: TextStyle(
                      color: corDestaque,
                      fontSize: isCompact ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Data e Temperaturas estilo Apple Footnote
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Row(
                children: [
                  Text(
                    formatarData(data),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (tMin != null && tMax != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white38 : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tMin!.round()}° / ${tMax!.round()}°C',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
