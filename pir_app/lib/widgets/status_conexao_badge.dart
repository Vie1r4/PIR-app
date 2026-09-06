import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/risco_provider.dart';
import '../utils/risco_helpers.dart';

/// Badge moderna que indica visualmente se os dados são em tempo real (Online)
/// ou provenientes da cache local (Offline), permitindo forçar a atualização ao tocar.
class StatusConexaoBadge extends StatelessWidget {
  final bool compact;

  const StatusConexaoBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final isOnline = provider.isOnline;
    // Cores do sistema iOS: verde para Online, laranja para Offline
    final corDot = isOnline ? const Color(0xFF34C759) : const Color(0xFFFF9500);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _mostrarDetalhesConexao(context, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: corDot.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ponto indicador com sombra suave de destaque
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: corDot,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: corDot.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              provider.statusConexaoDescricao,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (provider.isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhesConexao(BuildContext context, RiscoProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isOnline = provider.isOnline;
        final corDot =
            isOnline ? const Color(0xFF34C759) : const Color(0xFFFF9500);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: corDot,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: corDot.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOnline
                          ? 'Ligado aos Servidores do IPMA'
                          : 'A Funcionar em Modo Offline',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isOnline
                      ? 'A aplicação está sincronizada e a receber em direto os dados oficiais de perigo de incêndio rural do IPMA.'
                      : 'Não foi possível ligar à rede do IPMA no momento. A aplicação está a funcionar normalmente em modo offline com a última previsão guardada no dispositivo.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.ultimaAtualizacao != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history_toggle_off, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Último Registo Válido',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                formatarDateTime(provider.ultimaAtualizacao!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await provider.carregarDados();
                          },
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      provider.isLoading
                          ? 'A sincronizar...'
                          : 'Atualizar Dados Agora',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
