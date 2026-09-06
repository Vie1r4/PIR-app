import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cartão oficial de aviso de Situação de Alerta (Proteção Civil / IPMA)
class AlertaGovernoCard extends StatefulWidget {
  const AlertaGovernoCard({super.key});

  @override
  State<AlertaGovernoCard> createState() => _AlertaGovernoCardState();
}

class _AlertaGovernoCardState extends State<AlertaGovernoCard> {
  late final TapGestureRecognizer _gestureRecognizer;

  @override
  void initState() {
    super.initState();
    _gestureRecognizer = TapGestureRecognizer()..onTap = _abrirProCiv;
  }

  @override
  void dispose() {
    _gestureRecognizer.dispose();
    super.dispose();
  }

  Future<void> _abrirProCiv() async {
    final uri = Uri.parse('https://prociv.gov.pt/pt/home/');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falha silenciosa caso o browser não abra
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberCor = isDark ? const Color(0xFFFFB340) : const Color(0xFFD97706);
    final bgCor = isDark
        ? const Color(0xFF18191E)
        : const Color(0xFFFFFBEB);
    final borderCor = amberCor.withValues(alpha: isDark ? 0.30 : 0.40);
    final textCor = isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF451A03);

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgCor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderCor,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 12),
            child: Icon(
              Icons.warning_amber_rounded,
              color: amberCor,
              size: 20,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: textCor,
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
                children: [
                  const TextSpan(text: 'Em caso de '),
                  TextSpan(
                    text: 'Situação de Alerta',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      color: amberCor,
                    ),
                    recognizer: _gestureRecognizer,
                  ),
                  const TextSpan(
                    text:
                        ' decretada pela Proteção Civil / Governo, as condicionantes dessa situação sobrepõem-se às classes de Perigo de Incêndio Rural (PIR).',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
