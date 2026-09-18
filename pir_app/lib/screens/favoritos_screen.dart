import 'package:flutter/cupertino.dart';
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
      appBar: isEmbedded
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                    child: const Icon(CupertinoIcons.trash_fill, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    provider.toggleFavorito(concelho.dico);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${concelho.nome} removido dos favoritos',
                        ),
                      ),
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
