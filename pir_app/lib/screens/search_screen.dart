import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/risco_provider.dart';
import '../widgets/concelho_tile.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<String>? onConcelhoSelected;
  final bool isEmbedded;

  const SearchScreen({
    super.key,
    this.onConcelhoSelected,
    this.isEmbedded = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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

    final filteredConcelhos = provider.concelhos.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.matchesSearch(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: TextField(
          controller: _searchController,
          autofocus: !widget.isEmbedded,
          decoration: InputDecoration(
            hintText: 'Pesquisar concelho...',
            border: InputBorder.none,
            suffixText: '${filteredConcelhos.length} resultados',
            suffixStyle: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: filteredConcelhos.isEmpty
          ? Center(
              child: Text(
                'Nenhum concelho encontrado',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              itemCount: filteredConcelhos.length,
              itemBuilder: (context, index) {
                final concelho = filteredConcelhos[index];
                final riscoHoje = provider.getRiscoHoje(concelho.dico);

                return ConcelhoTile(
                  concelho: concelho,
                  rcm: riscoHoje?.rcm,
                  isFavorite: provider.isFavorito(concelho.dico),
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
                );
              },
            ),
    );
  }
}
