import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/risco_provider.dart';

/// Card de contingência amigável exibido quando o IPMA está inacessível
/// e não existem dados prévios em cache (primeiro acesso offline).
class ContingenciaOfflineCard extends StatelessWidget {
  final RiscoProvider provider;

  const ContingenciaOfflineCard({
    super.key,
    required this.provider,
  });

  Future<void> _fazerChamada112() async {
    final uri = Uri.parse('tel:112');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _abrirProCiv() async {
    final uri = Uri.parse('https://prociv.gov.pt/pt/home/');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final horaTentativa = DateTime.now();
    final horaFormatada =
        '${horaTentativa.hour.toString().padLeft(2, '0')}:${horaTentativa.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1917)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.4)
              : const Color(0xFFFDE68A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.wifi_slash,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serviço Oficial Temporariamente Inacessível',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Última tentativa de ligação às $horaFormatada',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.brown.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Não foi possível estabelecer contacto com os servidores do IPMA e ainda não existem dados em cache neste dispositivo. Por motivos de segurança pública, a aplicação não projeta riscos fictícios.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.brown.shade800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              FilledButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        provider.carregarDados(forcar: true);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(CupertinoIcons.arrow_clockwise, size: 15),
                label: const Text(
                  'Tentar Novamente',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _abrirProCiv,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(CupertinoIcons.info_circle, size: 15),
                label: const Text(
                  'ANEPC / ProCiv',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          InkWell(
            onTap: _fazerChamada112,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.phone_fill,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Em caso de fumo ou incêndio florestal, ligue de imediato para o 112',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                    ),
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
