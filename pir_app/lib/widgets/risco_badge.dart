import 'package:flutter/material.dart';

import '../utils/risco_helpers.dart';

/// Small circular badge showing the risk level number with the appropriate color
class RiscoBadge extends StatelessWidget {
  final int rcm;
  final double size;

  const RiscoBadge({
    super.key,
    required this.rcm,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: corDoRisco(rcm),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: corDoRisco(rcm).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rcm',
          style: TextStyle(
            color: corDoRiscoTexto(rcm),
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}
