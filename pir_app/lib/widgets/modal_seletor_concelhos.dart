import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/concelho.dart';
import '../providers/risco_provider.dart';
import 'risco_badge.dart';

/// Modal centralizado com pesquisa em tempo real para selecionar qualquer um dos
/// 278 concelhos de Portugal Continental, com destaque para concelhos favoritos.
class ModalSeletorConcelhos extends StatefulWidget {
  final VoidCallback? onIrParaPesquisa;

  const ModalSeletorConcelhos({
    super.key,
    this.onIrParaPesquisa,
  });

  static Future<void> exibir(BuildContext context, {VoidCallback? onIrParaPesquisa}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ModalSeletorConcelhos(onIrParaPesquisa: onIrParaPesquisa),
      ),
    );
  }

  @override
  State<ModalSeletorConcelhos> createState() => _ModalSeletorConcelhosState();
}

class _ModalSeletorConcelhosState extends State<ModalSeletorConcelhos> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _termoPesquisa = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _termoPesquisa = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final concelhoAtual = provider.concelhoPrincipal;
    final favoritos = provider.favoritos;
    final todosConcelhos = List<Concelho>.from(provider.concelhos)
      ..sort((a, b) => a.nome.compareTo(b.nome));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Filtra concelhos se houver pesquisa ativa
    final bool estaPesquisando = _termoPesquisa.isNotEmpty;
    final List<Concelho> concelhosFiltrados = estaPesquisando
        ? todosConcelhos.where((c) => c.matchesSearch(_termoPesquisa)).toList()
        : todosConcelhos;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
        maxWidth: 520,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(26),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabeçalho do Diálogo
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isDark ? kBrandDark : kBrand).withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: isDark ? kBrandDark : kBrand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trocar Concelho',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Seleciona entre todos os 278 concelhos do país',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 2. Barra de Pesquisa de Concelhos
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Pesquisar concelho ou distrito...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: cs.outline.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: cs.outline,
                ),
                suffixIcon: _termoPesquisa.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
                    width: 0.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? kBrandDark : kBrand,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.35),
          ),

          // 3. Lista de Concelhos
          Flexible(
            child: estaPesquisando
                ? _buildListaFiltrada(
                    context,
                    provider,
                    concelhosFiltrados,
                    concelhoAtual,
                    isDark,
                    cs,
                  )
                : _buildListaCompletaComFavoritos(
                    context,
                    provider,
                    favoritos,
                    todosConcelhos,
                    concelhoAtual,
                    isDark,
                    cs,
                  ),
          ),
        ],
      ),
    );
  }

  /// Constrói a lista quando o utilizador está a pesquisar
  Widget _buildListaFiltrada(
    BuildContext context,
    RiscoProvider provider,
    List<Concelho> concelhos,
    Concelho? concelhoAtual,
    bool isDark,
    ColorScheme cs,
  ) {
    if (concelhos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: cs.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum concelho encontrado',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tenta pesquisar por outro nome ou distrito.',
              style: TextStyle(
                fontSize: 13,
                color: cs.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: concelhos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final concelho = concelhos[index];
        return _buildConcelhoItem(
          context,
          provider,
          concelho,
          concelhoAtual,
          isDark,
          cs,
        );
      },
    );
  }

  /// Constrói a lista com secção de Favoritos (se existirem) seguida por Todos os Concelhos
  Widget _buildListaCompletaComFavoritos(
    BuildContext context,
    RiscoProvider provider,
    List<Concelho> favoritos,
    List<Concelho> todosConcelhos,
    Concelho? concelhoAtual,
    bool isDark,
    ColorScheme cs,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        // Secção de Favoritos no topo (se houver)
        if (favoritos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: Color(0xFFFF453A),
                ),
                const SizedBox(width: 6),
                Text(
                  'FAVORITOS (${favoritos.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFFFF453A),
                  ),
                ),
              ],
            ),
          ),
          ...favoritos.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildConcelhoItem(
                  context,
                  provider,
                  c,
                  concelhoAtual,
                  isDark,
                  cs,
                ),
              )),
          const SizedBox(height: 8),
          Divider(
            height: 16,
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
          ),
          const SizedBox(height: 4),
        ],

        // Secção de Todos os Concelhos
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              Icon(
                Icons.map_outlined,
                size: 14,
                color: cs.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'TODOS OS CONCELHOS (${todosConcelhos.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ),
        ...todosConcelhos.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildConcelhoItem(
                context,
                provider,
                c,
                concelhoAtual,
                isDark,
                cs,
              ),
            )),
      ],
    );
  }

  /// Item individual de concelho
  Widget _buildConcelhoItem(
    BuildContext context,
    RiscoProvider provider,
    Concelho concelho,
    Concelho? concelhoAtual,
    bool isDark,
    ColorScheme cs,
  ) {
    final isSelected = concelho.dico == concelhoAtual?.dico;
    final isFav = provider.isFavorito(concelho.dico);
    final riscoHoje = provider.getRiscoHoje(concelho.dico);
    final rcm = riscoHoje?.rcm;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          provider.selecionarConcelho(concelho.dico);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? kBrandDark.withValues(alpha: 0.16)
                    : kBrand.withValues(alpha: 0.10))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isDark ? kBrandDark : kBrand).withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              if (rcm != null)
                RiscoBadge(rcm: rcm, size: 30)
              else
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: cs.outline,
                    size: 16,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            concelho.nome,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? kBrandDark : kBrand)
                                  : cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? kBrandDark : kBrand)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Atual',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? kBrandDark : kBrand,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      concelho.distrito,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? const Color(0xFFFF453A) : cs.outline.withValues(alpha: 0.4),
                  size: 18,
                ),
                tooltip: isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  provider.toggleFavorito(concelho.dico);
                },
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: isDark ? kBrandDark : kBrand,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
