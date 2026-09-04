import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/risco_provider.dart';
import '../widgets/concelho_tile.dart';

class FavoritosScreen extends StatelessWidget {
  final ValueChanged<String>? onConcelhoSelected;
  final bool isEmbedded;

  const FavoritosScreen({
    super.key,
    this.onConcelhoSelected,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final favoritos = provider.favoritos;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isEmbedded,
        title: const Text('Favoritos'),
      ),
      body: favoritos.isEmpty
          ? const Center(
              child: Text(
                'Sem favoritos.\n\nAdicione concelhos aos favoritos\nna pesquisa ou ecrã principal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: favoritos.length,
              itemBuilder: (context, index) {
                final concelho = favoritos[index];
                final riscoHoje = provider.getRiscoHoje(concelho.dico);
                
                return Dismissible(
                  key: Key(concelho.dico),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    provider.toggleFavorito(concelho.dico);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${concelho.nome} removido dos favoritos')),
                    );
                  },
                  child: ConcelhoTile(
                    concelho: concelho,
                    rcm: riscoHoje?.rcm,
                    isFavorite: true,
                    onTap: () {
                      provider.selecionarConcelho(concelho.dico);
                      if (onConcelhoSelected != null) {
                        onConcelhoSelected!(concelho.dico);
                      } else if (!isEmbedded && Navigator.canPop(context)) {
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
    );
  }
}
