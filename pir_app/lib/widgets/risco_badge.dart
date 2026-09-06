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
    final brightness = Theme.of(context).brightness;
    final cor = corDoRiscoContextual(rcm, brightness);
    final corTexto = corDoRiscoTexto(rcm);
    final corTextoEfetiva = (rcm == 2 && brightness == Brightness.dark)
        ? const Color(0xFF1E1B18)
        : corTexto;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cor,
        shape: BoxShape.circle,
        border: Border.all(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '$rcm',
          style: TextStyle(
            color: corTextoEfetiva,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.44,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

