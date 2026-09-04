import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/risco_incendio.dart';
import '../providers/risco_provider.dart';
import '../utils/risco_helpers.dart';
import '../widgets/alerta_governo_card.dart';
import '../widgets/risco_badge.dart';
import '../widgets/risco_card.dart';
import 'search_screen.dart';
import 'favoritos_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSearch;

  const HomeScreen({
    super.key,
    this.onNavigateToSearch,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final concelho = provider.concelhoPrincipal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIR - Incêndio Rural'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Mapa de Risco',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Pesquisar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favoritos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritosScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (provider.erro != null)
            MaterialBanner(
              content: Text(provider.erro!),
              backgroundColor:
                  Theme.of(context).colorScheme.errorContainer,
              leading: Icon(
                Icons.cloud_off,
                color: Theme.of(context).colorScheme.error,
              ),
              actions: [
                TextButton(
                  onPressed: () => provider.carregarDados(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),

          // Loading indicator
          if (provider.isLoading)
            const LinearProgressIndicator(),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.carregarDados(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      const AlertaGovernoCard(),
                  if (concelho == null) ...[
                    const SizedBox(height: 50),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logopirapp.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Selecione um concelho',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'para ver o perigo de incêndio rural',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: FilledButton.icon(
                        onPressed: () {
                          if (onNavigateToSearch != null) {
                            onNavigateToSearch!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Procurar Concelho'),
                      ),
                    ),
                  ] else ...[
                    // Concelho header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                concelho.nome,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                concelho.distrito,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            provider.isFavorito(concelho.dico)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: provider.isFavorito(concelho.dico)
                                ? Colors.red
                                : null,
                            size: 32,
                          ),
                          onPressed: () =>
                              provider.toggleFavorito(concelho.dico),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Cards Hoje & Amanhã (lado a lado se ecrã largo)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardHoje = provider.getRiscoHoje(concelho.dico) != null
                            ? RiscoCard(
                                titulo: 'Hoje',
                                rcm: provider.getRiscoHoje(concelho.dico)!.rcm,
                                data: provider.riscoHoje?.dataPrev ?? '',
                              )
                            : _buildNoDataCard(context, 'Hoje');

                        final cardAmanha = provider.getRiscoAmanha(concelho.dico) != null
                            ? RiscoCard(
                                titulo: 'Amanhã',
                                rcm: provider.getRiscoAmanha(concelho.dico)!.rcm,
                                data: provider.riscoAmanha?.dataPrev ?? '',
                                isCompact: constraints.maxWidth <= 640,
                              )
                            : _buildNoDataCard(context, 'Amanhã');

                        if (constraints.maxWidth > 640) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cardHoje),
                              const SizedBox(width: 16),
                              Expanded(child: cardAmanha),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            cardHoje,
                            const SizedBox(height: 16),
                            cardAmanha,
                          ],
                        );
                      },
                    ),

                    // Extended forecast (Dias 3 a 9)
                    Builder(
                      builder: (context) {
                        final diasPrevisao =
                            provider.getPrevisaoDias(concelho.dico);
                        final proximosDias = diasPrevisao.length > 2
                            ? diasPrevisao.sublist(2)
                            : <RiscoPrevisaoDia>[];

                        if (proximosDias.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 20,
                                  color: Color(0xFFFF6B35),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Previsão Estendida (${diasPrevisao.length} Dias)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 140,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: proximosDias.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final item = proximosDias[index];
                                  final cor = corDoRisco(item.risco.rcm);
                                  final corTexto =
                                      corDoRiscoTextoEmFundoClaro(item.risco.rcm);
                                  return Container(
                                    width: 112,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: cor.withValues(alpha: 0.7),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          item.rotuloDia,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        RiscoBadge(
                                          rcm: item.risco.rcm,
                                          size: 34,
                                        ),
                                        Text(
                                          textoDoRisco(item.risco.rcm),
                                          style: TextStyle(
                                            color: corTexto,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.risco.tMin != null &&
                                            item.risco.tMax != null)
                                          Text(
                                            '${item.risco.tMin!.round()}° / ${item.risco.tMax!.round()}°C',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Last update info
                    if (provider.ultimaAtualizacao != null)
                      Center(
                        child: Text(
                          'Última atualização: ${formatarDateTime(provider.ultimaAtualizacao!)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Source attribution
                    Center(
                      child: Text(
                        'Fonte: IPMA',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildNoDataCard(BuildContext context, String titulo) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Sem dados disponíveis',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
