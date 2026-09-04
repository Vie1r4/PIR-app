import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cartão oficial de aviso de Situação de Alerta (Proteção Civil / IPMA)
class AlertaGovernoCard extends StatelessWidget {
  const AlertaGovernoCard({super.key});

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 10),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD32F2F),
              size: 20,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A3B2C),
                  height: 1.35,
                ),
                children: [
                  const TextSpan(text: 'Em caso de '),
                  TextSpan(
                    text: 'Situação de Alerta',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Color(0xFFC62828),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _abrirProCiv,
                  ),
                  const TextSpan(
                    text:
                        ', decretada pelo governo, as condicionantes associadas à mesma sobrepõem-se às definidas pelas classes de Perigo de Incêndio Rural (PIR).',
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
