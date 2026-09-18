import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/risco_helpers.dart';
import 'risco_badge.dart';

/// Modal estilo Apple BottomSheet com a explicacao detalhada de cada um dos 5 niveis de risco
/// e as regras legais aplicaveis segundo o ICNF / Dec.-Lei n.º 82/2021.
class ModalNiveisRisco extends StatefulWidget {
  final int nivelInicial;

  const ModalNiveisRisco({
    super.key,
    this.nivelInicial = 1,
  });

  static Future<void> exibir(BuildContext context, {int nivelInicial = 1}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ModalNiveisRisco(nivelInicial: nivelInicial),
      ),
    );
  }

  @override
  State<ModalNiveisRisco> createState() => _ModalNiveisRiscoState();
}

class _ModalNiveisRiscoState extends State<ModalNiveisRisco> {
  late int _nivelSelecionado;

  @override
  void initState() {
    super.initState();
    _nivelSelecionado = widget.nivelInicial.clamp(1, 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final restricoes = obterRestricoesRisco(_nivelSelecionado);
    final nomeNivel = textoDoRisco(_nivelSelecionado);
    final cor = corDoRiscoContextual(_nivelSelecionado, Theme.of(context).brightness);
    final corDestaque = isDark ? cor : corDoRiscoTextoEmFundoClaro(_nivelSelecionado);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 640,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titulo e botao fechar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Níveis de Risco & Regras',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Regulamento Oficial do ICNF / DL 82/2021',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.outline,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Seletor horizontal dos 5 niveis estilo capsulas Apple
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(5, (index) {
                  final nivel = index + 1;
                  final isSelected = _nivelSelecionado == nivel;
                  final nivelCor = corDoRiscoContextual(nivel, Theme.of(context).brightness);
                  final nivelTextoCor = isDark ? nivelCor : corDoRiscoTextoEmFundoClaro(nivel);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _nivelSelecionado = nivel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? nivelCor.withValues(alpha: isDark ? 0.22 : 0.16)
                                : (isDark ? const Color(0xFF14161C) : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? nivelCor.withValues(alpha: 0.6)
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              RiscoBadge(rcm: nivel, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                textoDoRisco(nivel),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? nivelTextoCor
                                      : (isDark ? Colors.white60 : Colors.black54),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.35),
            ),

            // Conteudo explicativo com scroll suave
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cartao de Resumo do Nivel Ativo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: cor.withValues(alpha: isDark ? 0.35 : 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            iconeDoRisco(_nivelSelecionado),
                            color: corDestaque,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nível $_nivelSelecionado • $nomeNivel',
                                  style: TextStyle(
                                    color: corDestaque,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _obterResumoNivel(_nivelSelecionado),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lista detalhada de regras e proibicoes
                    _buildItemRegra(
                      context,
                      icone: CupertinoIcons.flame,
                      titulo: 'Queimas e Queimadas de Sobrantes',
                      descricao: restricoes.queimas,
                      permitido: restricoes.queimasPermitidas,
                    ),
                    const SizedBox(height: 14),
                    _buildItemRegra(
                      context,
                      icone: CupertinoIcons.gear_alt,
                      titulo: 'Maquinaria Agrícola e Florestal',
                      descricao: restricoes.maquinaria,
                      permitido: !restricoes.maquinariaCondicionada,
                    ),
                    const SizedBox(height: 14),
                    _buildItemRegra(
                      context,
                      icone: CupertinoIcons.sparkles,
                      titulo: 'Fogo de Artifício e Pirotecnia',
                      descricao: restricoes.pirotecnia,
                      permitido: restricoes.pirotecniaPermitida,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Concluir'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _obterResumoNivel(int nivel) {
    switch (nivel) {
      case 1:
        return 'Perigo reduzido de incêndio. Condições meteorológicas favoráveis à segurança.';
      case 2:
        return 'Perigo moderado. Atenção redobrada nas atividades no espaço rural.';
      case 3:
        return 'Perigo elevado. Grande facilidade de ignição e propagação. Restrições ativas.';
      case 4:
        return 'Perigo muito elevado. Queimas e pirotecnia proibidas por lei.';
      case 5:
        return 'Perigo máximo. Risco extremo de propagação rápida. Máxima prontidão e restrições totais.';
      default:
        return '';
    }
  }

  Widget _buildItemRegra(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String descricao,
    required bool permitido,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusCor = permitido
        ? const Color(0xFF34C759)
        : const Color(0xFFFF453A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x12000000),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusCor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icone,
              size: 20,
              color: statusCor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusCor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        permitido ? 'Permitido' : 'Proibido / Restrito',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusCor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
