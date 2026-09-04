import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/risco_provider.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'favoritos_screen.dart';

/// Ecrã principal adaptativo:
/// - No PC/Tablet (ecrã largo >= 720px): Mostra uma barra de navegação lateral (NavigationRail) moderna
///   com o novo logotipo, permitindo alternar instantaneamente entre Dashboard, Mapa, Pesquisa e Favoritos.
/// - No Telemóvel (< 720px): Apresenta a barra de navegação inferior (NavigationBar) limpa e intuitiva.
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _indiceSelecionado = 0;

  void _mudarAba(int index) {
    setState(() {
      _indiceSelecionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final numFavoritos = provider.favoritos.length;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    // Páginas principais
    final List<Widget> paginas = [
      HomeScreen(
        onNavigateToSearch: () => _mudarAba(2),
      ),
      const MapScreen(showAppBar: false),
      SearchScreen(
        isEmbedded: true,
        onConcelhoSelected: (dico) {
          _mudarAba(0); // Volta ao Dashboard principal
        },
      ),
      FavoritosScreen(
        isEmbedded: true,
        onConcelhoSelected: (dico) {
          _mudarAba(0); // Volta ao Dashboard principal
        },
      ),
    ];

    if (isDesktop) {
      // Layout Desktop com NavigationRail moderno à esquerda
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _indiceSelecionado,
              onDestinationSelected: _mudarAba,
              labelType: MediaQuery.of(context).size.width >= 1050
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              extended: MediaQuery.of(context).size.width >= 1050,
              minExtendedWidth: 200,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logopirapp.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Início'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: Text('Mapa de Risco'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: Text('Pesquisa'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: numFavoritos > 0,
                    label: Text('$numFavoritos'),
                    child: const Icon(Icons.favorite_border),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: numFavoritos > 0,
                    label: Text('$numFavoritos'),
                    child: const Icon(Icons.favorite),
                  ),
                  label: const Text('Favoritos'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Área de conteúdo principal
            Expanded(
              child: IndexedStack(
                index: _indiceSelecionado,
                children: paginas,
              ),
            ),
          ],
        ),
      );
    }

    // Layout Mobile com NavigationBar na base
    return Scaffold(
      body: IndexedStack(
        index: _indiceSelecionado,
        children: paginas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSelecionado,
        onDestinationSelected: _mudarAba,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Pesquisa',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: numFavoritos > 0,
              label: Text('$numFavoritos'),
              child: const Icon(Icons.favorite_border),
            ),
            selectedIcon: Badge(
              isLabelVisible: numFavoritos > 0,
              label: Text('$numFavoritos'),
              child: const Icon(Icons.favorite),
            ),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
