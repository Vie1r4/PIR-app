import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/risco_incendio.dart';
import '../utils/risco_helpers.dart';
import 'risco_badge.dart';

/// Cartão de previsão alargada com suporte a modo compacto (carrossel horizontal Apple Weather)
/// e modo expandido (lista vertical detalhada com todos os dias).
class PrevisaoAlargadaCard extends StatefulWidget {
  final List<RiscoPrevisaoDia> dias;
  final bool initialExpanded;

  const PrevisaoAlargadaCard({
    super.key,
    required this.dias,
    this.initialExpanded = false,
  });

  @override
  State<PrevisaoAlargadaCard> createState() => _PrevisaoAlargadaCardState();
}

class _PrevisaoAlargadaCardState extends State<PrevisaoAlargadaCard> {
  late bool _expandido;

  @override
  void initState() {
    super.initState();
    _expandido = widget.initialExpanded;
  }

  void _alternarExpansao() {
    HapticFeedback.lightImpact();
    setState(() {
      _expandido = !_expandido;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dias.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.35),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabeçalho Interativo com Botão de Minimizar / Expandir ──
          InkWell(
            onTap: _alternarExpansao,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 15,
                    color: isDark ? kBrandDark : kBrand,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRÓXIMOS DIAS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? kBrandDark : kBrand).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.dias.length} dias',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? kBrandDark : kBrand,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Botão estilo Pílula Apple para alternar visualização
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expandido ? 'Minimizar' : 'Ver lista',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expandido
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Transição Fluida entre Carrossel Compacto e Lista Detalhada ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildCarrosselCompacto(context, isDark, cs),
            secondChild: _buildListaDetalhada(context, isDark, cs),
          ),
        ],
      ),
    );
  }

  /// Carrossel Horizontal Compacto (Estilo Apple Weather - não ocupa espaço vertical)
  Widget _buildCarrosselCompacto(
    BuildContext context,
    bool isDark,
    ColorScheme cs,
  ) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.dias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = widget.dias[index];
          final isAmanha = item.diaIndex == 1;
          final corTexto = isDark
              ? corDoRiscoContextual(item.risco.rcm, Brightness.dark)
              : corDoRiscoTextoEmFundoClaro(item.risco.rcm);

          // Rótulo compacto: ex: Amanhã ou Seg 21
          String rotuloCurto;
          if (isAmanha) {
            rotuloCurto = 'Amanhã';
          } else {
            try {
              final dt = DateTime.parse(item.dataPrev);
              rotuloCurto = '${diasDaSemanaAbrev[dt.weekday - 1]} ${dt.day}';
            } catch (_) {
              rotuloCurto = item.dataPrev;
            }
          }

          return Container(
            width: 84,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: isDark ? 0.16 : 0.28),
                width: 0.6,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dia da semana
                Text(
                  rotuloCurto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isAmanha ? FontWeight.bold : FontWeight.w600,
                    color: isAmanha
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Badge oficial do nível de risco
                RiscoBadge(
                  rcm: item.risco.rcm,
                  size: 26,
                ),

                // Nome do risco
                Text(
                  textoDoRisco(item.risco.rcm),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: corTexto,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Temperaturas
                if (item.risco.tMin != null && item.risco.tMax != null)
                  Text(
                    '${item.risco.tMin!.round()}° / ${item.risco.tMax!.round()}°',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                else
                  Text(
                    '—',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: cs.outline.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Lista Vertical Detalhada com Todos os Dias
  Widget _buildListaDetalhada(
    BuildContext context,
    bool isDark,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.dias.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 0.6,
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.22),
          ),
          itemBuilder: (context, index) {
            final item = widget.dias[index];
            final cor = corDoRiscoContextual(
              item.risco.rcm,
              Theme.of(context).brightness,
            );
            final corTexto = isDark
                ? cor
                : corDoRiscoTextoEmFundoClaro(item.risco.rcm);
            final isAmanha = item.diaIndex == 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
              child: Row(
                children: [
                  // Coluna do Dia (ex: Amanhã, Sex, 19 Set)
                  SizedBox(
                    width: 96,
                    child: Text(
                      item.rotuloDia,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isAmanha ? FontWeight.bold : FontWeight.w500,
                        letterSpacing: -0.1,
                        color: isAmanha
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge discreto com o nível de perigo
                  RiscoBadge(
                    rcm: item.risco.rcm,
                    size: 26,
                  ),
                  const SizedBox(width: 10),

                  // Nome do Risco
                  Expanded(
                    child: Text(
                      textoDoRisco(item.risco.rcm),
                      style: TextStyle(
                        color: corTexto,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Temperaturas Mín / Máx
                  if (item.risco.tMin != null && item.risco.tMax != null)
                    Text(
                      '${item.risco.tMin!.round()}° / ${item.risco.tMax!.round()}°C',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  else
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.outline.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Botão subtil para recolher de volta ao carrossel
        Center(
          child: TextButton.icon(
            onPressed: _alternarExpansao,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: isDark ? Colors.white60 : Colors.black54,
            ),
            icon: const Icon(CupertinoIcons.chevron_up, size: 13),
            label: const Text(
              'Minimizar previsão',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
