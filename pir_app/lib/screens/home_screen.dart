import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/risco_incendio.dart';
import '../providers/acessibilidade_provider.dart';
import '../providers/risco_provider.dart';
import '../utils/risco_helpers.dart';
import '../widgets/alerta_governo_card.dart';
import '../widgets/modal_niveis_risco.dart';
import '../widgets/modal_seletor_concelhos.dart';
import '../widgets/risco_badge.dart';
import '../widgets/risco_card.dart';
import '../widgets/status_conexao_badge.dart';
import 'favoritos_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onNavigateToSearch;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToSearch,
  });

  void _navegarPara(BuildContext context, int tabIndex) {
    if (onNavigateToTab != null) {
      onNavigateToTab!(tabIndex);
    } else if (tabIndex == 1 && onNavigateToSearch != null) {
      onNavigateToSearch!();
    } else {
      Widget screen;
      switch (tabIndex) {
        case 1:
          screen = const MapScreen();
          break;
        case 2:
          screen = const FavoritosScreen();
          break;
        default:
          return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final concelho = provider.concelhoPrincipal;

    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('PIR - Incêndio Rural'),
            ),
      body: Column(
        children: [
          // Error banner se houver erro crítico
          if (provider.erro != null)
            MaterialBanner(
              content: Text(provider.erro!),
              backgroundColor:
                  Theme.of(context).colorScheme.errorContainer,
              leading: Icon(
                CupertinoIcons.wifi_slash,
                color: Theme.of(context).colorScheme.error,
              ),
              actions: [
                TextButton(
                  onPressed: () => provider.carregarDados(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),

          // Loading indicator subtil no topo
          if (provider.isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: Theme.of(context).brightness == Brightness.dark
                  ? kBrandDark
                  : kBrand,
            ),

          // Conteúdo Principal
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.carregarDados(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 780;

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 28 : 16,
                          vertical: isDesktop ? 20 : 14,
                        ),
                        children: [
                          if (concelho == null) ...[
                            _buildZeroState(context, provider),
                          ] else if (isWide) ...[
                            // Layout em 2 colunas para ecrãs alargados / maximizados
                            _buildConcelhoHeader(context, provider, concelho),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coluna Esquerda: Cartão Hoje + Regras & Níveis + Aviso Alerta
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHeroHoje(context, provider, concelho),
                                      const SizedBox(height: 12),
                                      _buildBotaoExplicacaoRegras(context, provider, concelho),
                                      const SizedBox(height: 14),
                                      const AlertaGovernoCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Coluna Direita: Previsão Próximos Dias Integrada
                                Expanded(
                                  flex: 6,
                                  child: _buildPrevisaoIntegrada(context, provider, concelho),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            // Layout em 1 coluna vertical otimizado para janelas normais / compactas
                            _buildConcelhoHeader(context, provider, concelho),
                            const SizedBox(height: 14),
                            _buildHeroHoje(context, provider, concelho),
                            const SizedBox(height: 10),
                            _buildBotaoExplicacaoRegras(context, provider, concelho),
                            const SizedBox(height: 14),
                            _buildPrevisaoIntegrada(context, provider, concelho),
                            const SizedBox(height: 14),
                            const AlertaGovernoCard(),
                            const SizedBox(height: 20),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cabeçalho do Concelho estilo Apple Weather com botão de favoritos e estado de ligação
  Widget _buildConcelhoHeader(
    BuildContext context,
    RiscoProvider provider,
    dynamic concelho,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav = provider.isFavorito(concelho.dico);
    final acc = context.watch<AcessibilidadeProvider>();
    final favBtnSize = acc.elementosGrandes ? 52.0 : 44.0;
    final favIconSize = acc.elementosGrandes ? 26.0 : 22.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () {
              HapticFeedback.lightImpact();
              ModalSeletorConcelhos.exibir(
                context,
                onIrParaPesquisa: () => _navegarPara(context, 1),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          concelho.nome,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.chevron_up_chevron_down,
                        size: 20,
                        color: cs.outline.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        concelho.distrito,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          color: cs.outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusConexaoBadge(compact: true),
                    ],
                  ),
                  if (acc.dicasContextuais) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Selecionar outro concelho',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: cs.outline.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Botão de Localização Rápida
        Tooltip(
          message: 'Localizar concelho atual',
          child: Container(
            width: favBtnSize,
            height: favBtnSize,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: provider.isLocalizando
                  ? SizedBox(
                      width: favIconSize,
                      height: favIconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? kBrandDark : kBrand,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.location_fill,
                      size: favIconSize,
                      color: isDark ? kBrandDark : kBrand,
                    ),
              onPressed: provider.isLocalizando
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final concelhoDet =
                          await provider.detetarEDefinirLocalizacaoAtual();
                      if (concelhoDet != null) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                'Concelho atual: ${concelhoDet.nome} (${concelhoDet.distrito})'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.mensagemLocalizacao ??
                                'Não foi possível detetar a localização.'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
            ),
          ),
        ),
        // Botão de Favorito estilo cápsula circular
        Container(
          width: favBtnSize,
          height: favBtnSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: isFav ? 'Remover dos favoritos' : 'Guardar nos favoritos',
            icon: Icon(
              isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isFav
                  ? const Color(0xFFFF453A)
                  : cs.outline,
              size: favIconSize,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.toggleFavorito(concelho.dico);
            },
          ),
        ),
      ],
    );
  }

  /// Cartão Hero: Hoje em destaque principal
  Widget _buildHeroHoje(
    BuildContext context,
    RiscoProvider provider,
    dynamic concelho,
  ) {
    final riscoHoje = provider.getRiscoHoje(concelho.dico);
    if (riscoHoje == null) {
      return _buildNoDataCard(context, 'Hoje');
    }

    return RiscoCard(
      titulo: 'Hoje',
      rcm: riscoHoje.rcm,
      data: provider.riscoHoje?.dataPrev ?? '',
      tMin: riscoHoje.tMin,
      tMax: riscoHoje.tMax,
    );
  }

  /// Botão elegante estilo Apple para consultar a explicação de todos os níveis de risco e suas regras
  Widget _buildBotaoExplicacaoRegras(
    BuildContext context,
    RiscoProvider provider,
    dynamic concelho,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final riscoHoje = provider.getRiscoHoje(concelho.dico);
    final rcmHoje = riscoHoje?.rcm ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.35),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            ModalNiveisRisco.exibir(context, nivelInicial: rcmHoje);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? kBrandDark.withValues(alpha: 0.16) : kBrand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.shield,
                    size: 18,
                    color: isDark ? kBrandDark : kBrand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Níveis de Perigo & Legislação',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Classificação de risco e restrições legais de uso do fogo',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.outline,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Barra de horizonte de tendência diária compacta (estilo Apple Weather)
  Widget _buildTrendHorizon(BuildContext context, List<RiscoPrevisaoDia> dias) {
    if (dias.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.25),
          width: 0.6,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth / dias.length).clamp(46.0, 70.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dias.map((dia) {
                final cor = corDoRiscoContextual(dia.risco.rcm, Theme.of(context).brightness);
                final corTexto = isDark ? cor : corDoRiscoTextoEmFundoClaro(dia.risco.rcm);
                final isHoje = dia.diaIndex == 0;
                final diaLabel = isHoje
                    ? 'Hoje'
                    : (dia.diaIndex == 1
                        ? 'Amanhã'
                        : dia.rotuloDia.split(',').first.trim().split(' ').first);

                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        diaLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isHoje ? FontWeight.bold : FontWeight.w500,
                          color: isHoje
                              ? (isDark ? Colors.white : Colors.black)
                              : cs.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: isDark ? 0.25 : 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: cor.withValues(alpha: 0.7), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${dia.risco.rcm}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: corTexto,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (dia.risco.tMax != null)
                        Text(
                          '${dia.risco.tMax!.round()}°',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  /// Lista de previsão diária integrada (Amanhã + próximos dias num único bloco elegante)
  Widget _buildPrevisaoIntegrada(
    BuildContext context,
    RiscoProvider provider,
    dynamic concelho,
  ) {
    final todosDias = provider.getPrevisaoDias(concelho.dico);
    // Dias a partir de amanhã (diaIndex >= 1)
    final diasFuturos = todosDias.length > 1
        ? todosDias.sublist(1)
        : <RiscoPrevisaoDia>[];

    if (diasFuturos.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.35),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da secção
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 16,
                color: isDark ? kBrandDark : kBrand,
              ),
              const SizedBox(width: 8),
              Text(
                'TENDÊNCIA & PREVISÃO (${diasFuturos.length} DIAS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
          // Micro horizonte de tendência visual
          _buildTrendHorizon(context, todosDias),
          const SizedBox(height: 6),

          // Lista de dias com hairline dividers
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: diasFuturos.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.8,
              indent: 4,
              endIndent: 4,
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.20 : 0.25),
            ),
            itemBuilder: (context, index) {
              final item = diasFuturos[index];
              final cor = corDoRiscoContextual(
                item.risco.rcm,
                Theme.of(context).brightness,
              );
              final corTexto = isDark
                  ? cor
                  : corDoRiscoTextoEmFundoClaro(item.risco.rcm);
              final isAmanha = item.diaIndex == 1;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(
                  children: [
                    // Coluna do Dia
                    SizedBox(
                      width: 95,
                      child: Text(
                        item.rotuloDia,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isAmanha ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: 0.1,
                          color: isAmanha
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge com número de risco
                    RiscoBadge(
                      rcm: item.risco.rcm,
                      size: 30,
                    ),
                    const SizedBox(width: 12),

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
                          fontSize: 13,
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
                          fontSize: 13,
                          color: cs.outline.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Ecrã de Boas-Vindas quando não há concelho selecionado
  Widget _buildZeroState(BuildContext context, RiscoProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: ClipOval(
            child: Image.asset(
              'assets/logopirapp.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Perigo de Incêndio Rural',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Informação oficial do IPMA e Proteção Civil em direto',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Barra de pesquisa rápida em destaque estilo cápsula Apple
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _navegarPara(context, 1);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pesquisar concelho ou distrito...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pesquisar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Botão de Localização Automática em destaque
        Container(
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark
                    ? kBrandDark
                    : kBrand)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? kBrandDark
                      : kBrand)
                  .withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: provider.isLocalizando
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final concelhoDet =
                        await provider.detetarEDefinirLocalizacaoAtual();
                    if (concelhoDet != null) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Concelho detetado: ${concelhoDet.nome} (${concelhoDet.distrito})'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(provider.mensagemLocalizacao ??
                              'Não foi possível detetar a localização.'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isLocalizando) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? kBrandDark
                            : kBrand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'A detetar a tua localização...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? kBrandDark
                            : kBrand,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      CupertinoIcons.location_fill,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? kBrandDark
                          : kBrand,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Usar a minha localização atual',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? kBrandDark
                            : kBrand,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Seleção rápida por capitais
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'ACESSO RÁPIDO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChipConcelhoRapido(context, provider, 'Lisboa'),
            _buildChipConcelhoRapido(context, provider, 'Porto'),
            _buildChipConcelhoRapido(context, provider, 'Coimbra'),
            _buildChipConcelhoRapido(context, provider, 'Braga'),
            _buildChipConcelhoRapido(context, provider, 'Évora'),
            _buildChipConcelhoRapido(context, provider, 'Faro'),
            _buildChipConcelhoRapido(context, provider, 'Viseu'),
            _buildChipConcelhoRapido(context, provider, 'Guarda'),
            _buildChipConcelhoRapido(context, provider, 'Santarém'),
            _buildChipConcelhoRapido(context, provider, 'Leiria'),
          ],
        ),

        const SizedBox(height: 28),

        // Cartão de convite para explorar o mapa
        Card(
          elevation: 0,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _navegarPara(context, 1);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CupertinoIcons.map,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mapa de Portugal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Visualização cartográfica do perigo por concelho',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChipConcelhoRapido(
    BuildContext context,
    RiscoProvider provider,
    String nome,
  ) {
    return ActionChip(
      avatar: Icon(
        CupertinoIcons.placemark,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(nome),
      onPressed: () {
        HapticFeedback.lightImpact();
        final concelho = provider.concelhos
            .where((c) => c.nome.toLowerCase() == nome.toLowerCase())
            .firstOrNull;
        if (concelho != null) {
          provider.selecionarConcelho(concelho.dico);
        }
      },
    );
  }

  Widget _buildNoDataCard(BuildContext context, String titulo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0x18FFFFFF) : const Color(0x12000000),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            Text(
              titulo.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),
            Icon(
              CupertinoIcons.wifi_slash,
              size: 32,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              'Sem dados disponíveis',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
