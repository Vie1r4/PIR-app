import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/concelho.dart';
import '../providers/risco_provider.dart';
import '../widgets/concelho_tile.dart';

class FavoritosScreen extends StatefulWidget {
  final ValueChanged<String>? onConcelhoSelected;
  final bool isEmbedded;

  const FavoritosScreen({
    super.key,
    this.onConcelhoSelected,
    this.isEmbedded = false,
  });

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final favoritos = provider.favoritos;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final normalizedQuery = Concelho.normalize(_searchQuery);
    final favoritosFiltrados = favoritos.where((c) {
      if (normalizedQuery.isEmpty) return true;
      return c.matchesSearch(normalizedQuery, queryIsNormalized: true);
    }).toList();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Concelhos Favoritos'),
            ),
      body: favoritos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.heart,
                      size: 32,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum favorito guardado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Guarda os teus concelhos frequentes para consulta rápida',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Barra de pesquisa de favoritos
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar nos favoritos...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: cs.outline.withValues(alpha: 0.8),
                        ),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                        prefixIconConstraints: const BoxConstraints(minWidth: 38),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),

                // Lista de favoritos filtrados
                Expanded(
                  child: favoritosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.search,
                                size: 36,
                                color: cs.outline.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhum concelho encontrado para "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: favoritosFiltrados.length,
                          itemBuilder: (context, index) {
                            final concelho = favoritosFiltrados[index];
                            final riscoHoje = provider.getRiscoHoje(concelho.dico);

                            return Dismissible(
                              key: Key(concelho.dico),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(CupertinoIcons.trash_fill, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                provider.toggleFavorito(concelho.dico);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${concelho.nome} removido dos favoritos',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: ConcelhoTile(
                                concelho: concelho,
                                rcm: riscoHoje?.rcm,
                                isFavorite: true,
                                onTap: () {
                                  provider.selecionarConcelho(concelho.dico);
                                  if (widget.onConcelhoSelected != null) {
                                    widget.onConcelhoSelected!(concelho.dico);
                                  } else if (!widget.isEmbedded && Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                                onFavoriteToggle: () {
                                  provider.toggleFavorito(concelho.dico);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
