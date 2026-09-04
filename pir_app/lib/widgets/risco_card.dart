import 'package:flutter/material.dart';

import '../utils/risco_helpers.dart';
import 'risco_badge.dart';

/// Card widget displaying the fire risk level with color, icon, and date
class RiscoCard extends StatelessWidget {
  final String titulo;
  final int rcm;
  final String data;
  final bool isCompact;

  const RiscoCard({
    super.key,
    required this.titulo,
    required this.rcm,
    required this.data,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = corDoRisco(rcm);
    final corTexto = corDoRiscoTexto(rcm);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cor,
              cor.withValues(alpha: 0.85),
            ],
          ),
        ),
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: corTexto.withValues(alpha: 0.8),
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                RiscoBadge(rcm: rcm, size: isCompact ? 32 : 40),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 16),

            // Risk level text + icon
            Row(
              children: [
                Icon(
                  iconeDoRisco(rcm),
                  color: corTexto,
                  size: isCompact ? 28 : 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    textoDoRisco(rcm),
                    style: TextStyle(
                      color: corTexto,
                      fontSize: isCompact ? 22 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 12),

            // Date
            Text(
              formatarData(data),
              style: TextStyle(
                color: corTexto.withValues(alpha: 0.7),
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
