import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../providers/acessibilidade_provider.dart';
import '../providers/risco_provider.dart';
import '../providers/tema_provider.dart';
import '../utils/risco_helpers.dart';

class DefinicoesScreen extends StatelessWidget {
  const DefinicoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Definições'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: cs.onSurface,
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Aparência ────────────────────────────────────────────
                const _Secao(titulo: 'Aparência'),
                const _TemaSwitcher(),
                const SizedBox(height: 28),

                // ── Acessibilidade ────────────────────────────────────────
                const _Secao(titulo: 'Acessibilidade'),
                const _AcessibilidadeCard(),
                const SizedBox(height: 28),

                // ── Localização ──────────────────────────────────────────
                const _Secao(titulo: 'Localização & Concelho de Arranque'),
                const _LocalizacaoCard(),
                const SizedBox(height: 28),

                // ── Dados ─────────────────────────────────────────────
                const _Secao(titulo: 'Dados & Atualização'),
                const _DadosCard(),
                const SizedBox(height: 28),

                // ── Informação & Legal ────────────────────────────────
                const _Secao(titulo: 'Sobre & Legal'),
                const _EmergenciaLegalCard(),
                const SizedBox(height: 14),
                const _InfoCard(),
                const SizedBox(height: 40),

                // Assinatura em baixo
                Center(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.flame_fill,
                          size: 26,
                          color: isDark ? kBrandDark : kBrand),
                      const SizedBox(height: 8),
                      Text(
                        'PIR – Perigo de Incêndio Rural',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Versão 1.1.0 · Portugal Continental',
                        style: TextStyle(
                          color: cs.outline,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? kBrandDark : kBrand).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Powered by ',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.outline,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              'Pirofafe',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? kBrandDark : kBrand,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cabeçalho de secção ─────────────────────────────────────────────────────

class _Secao extends StatelessWidget {
  final String titulo;
  const _Secao({required this.titulo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10, top: 4),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: isDark ? Colors.white60 : Colors.black45,
        ),
      ),
    );
  }
}

// ── Switcher de tema ────────────────────────────────────────────────────────

class _TemaSwitcher extends StatelessWidget {
  const _TemaSwitcher();

  @override
  Widget build(BuildContext context) {
    final temaProvider = context.watch<TemaProvider>();
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.paintbrush, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  'Tema da Aplicação',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<ThemeMode>(
              style: SegmentedButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurfaceVariant,
                selectedBackgroundColor: cs.primary,
                selectedForegroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(CupertinoIcons.sun_max, size: 18),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(CupertinoIcons.circle_righthalf_fill, size: 18),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(CupertinoIcons.moon, size: 18),
                  label: Text('Escuro'),
                ),
              ],
              selected: {temaProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> selecionado) {
                temaProvider.setTema(selecionado.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card de Acessibilidade ──────────────────────────────────────────────────

class _AcessibilidadeCard extends StatefulWidget {
  const _AcessibilidadeCard();

  @override
  State<_AcessibilidadeCard> createState() => _AcessibilidadeCardState();
}

class _AcessibilidadeCardState extends State<_AcessibilidadeCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AcessibilidadeProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resumoConfig = <String>[];
    if (acc.escalaTexto != EscalaTextoApp.normal) {
      resumoConfig.add('Texto ${acc.escalaTexto.rotulo}');
    }
    if (acc.altoContraste) resumoConfig.add('Alto contraste');
    if (acc.elementosGrandes) resumoConfig.add('Elementos grandes');
    if (acc.reduzirAnimacoes) resumoConfig.add('Sem animações');

    final textoSubtitulo = resumoConfig.isEmpty
        ? 'Predefinições de visualização e leitura'
        : resumoConfig.join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: acc.altoContraste
              ? (isDark ? Colors.white70 : Colors.black)
              : cs.outlineVariant.withValues(alpha: 0.4),
          width: acc.altoContraste ? 1.5 : 0.8,
        ),
      ),
      child: Column(
        children: [
          // Cabeçalho clicável para abrir/fechar as definições de acessibilidade
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _expandido = !_expandido);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.person_crop_circle,
                        size: 22,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opções de Acessibilidade',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            textoSubtitulo,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expandido
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      color: cs.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo detalhado expansível
          if (_expandido) ...[
            Divider(
              height: 1,
              thickness: 0.8,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Visão e Leitura: Tamanho do Texto
                  Row(
                    children: [
                      Icon(CupertinoIcons.textformat_size, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'TAMANHO DO TEXTO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<EscalaTextoApp>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurfaceVariant,
                      selectedBackgroundColor: cs.primary,
                      selectedForegroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: EscalaTextoApp.pequeno,
                        label: Text('Pequeno'),
                      ),
                      ButtonSegment(
                        value: EscalaTextoApp.normal,
                        label: Text('Normal'),
                      ),
                      ButtonSegment(
                        value: EscalaTextoApp.grande,
                        label: Text('Grande'),
                      ),
                      ButtonSegment(
                        value: EscalaTextoApp.gigante,
                        label: Text('Gigante'),
                      ),
                    ],
                    selected: {acc.escalaTexto},
                    onSelectionChanged: (Set<EscalaTextoApp> sel) {
                      acc.setEscalaTexto(sel.first);
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. Alto Contraste
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(CupertinoIcons.circle_lefthalf_fill, color: cs.primary),
                    title: const Text(
                      'Alto Contraste',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Reforça contornos, textos escuros e saturação de cores',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: acc.altoContraste,
                    onChanged: (val) => acc.setAltoContraste(val),
                  ),

                  // 3. Elementos Grandes
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(CupertinoIcons.arrow_up_left_arrow_down_right, color: cs.primary),
                    title: const Text(
                      'Elementos e Toques Ampliados',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Aumenta a área de toque dos botões e espaçamento de listas',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: acc.elementosGrandes,
                    onChanged: (val) => acc.setElementosGrandes(val),
                  ),

                  // 4. Reduzir Animações
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(CupertinoIcons.play_circle, color: cs.primary),
                    title: const Text(
                      'Reduzir Animações',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Transições instantâneas entre abas, sem movimentos complexos',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: acc.reduzirAnimacoes,
                    onChanged: (val) => acc.setReduzirAnimacoes(val),
                  ),

                  // 5. Dicas Contextuais e Ajuda
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(CupertinoIcons.question_circle, color: cs.primary),
                    title: const Text(
                      'Dicas & Ajuda Contextual',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Exibe legendas claras e orientações de navegação nos ecrãs',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: acc.dicasContextuais,
                    onChanged: (val) => acc.setDicasContextuais(val),
                  ),

                  const SizedBox(height: 12),
                  // Botão para repor predefinições
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => acc.reporPredefinicoes(),
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 16),
                      label: const Text(
                        'Repor Predefinições',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Card de Localização ──────────────────────────────────────────────────────

class _LocalizacaoCard extends StatelessWidget {
  const _LocalizacaoCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final concelhoAtual = provider.concelhoPrincipal;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // 1. Switch de Deteção Automática ao Iniciar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                CupertinoIcons.location,
                color: isDark ? kBrandDark : kBrand,
              ),
              title: const Text(
                'Detetar Concelho ao Iniciar',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Usa GPS ou rede para selecionar automaticamente o concelho onde te encontras',
                style: TextStyle(fontSize: 12),
              ),
              value: provider.autoLocalizacao,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                provider.alternarAutoLocalizacao(val);
              },
            ),
          ),
          Divider(
            height: 1,
            indent: 52,
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),

          // 2. Concelho Atual Atribuído
          _ItemLinha(
            icone: CupertinoIcons.placemark,
            titulo: 'Concelho Selecionado',
            valor: concelhoAtual != null
                ? '${concelhoAtual.nome} (${concelhoAtual.distrito})'
                : 'Nenhum concelho ativo',
            corValor: concelhoAtual != null
                ? (isDark ? kBrandDark : kBrand)
                : cs.outline,
          ),
          Divider(
            height: 1,
            indent: 52,
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),

          // 3. Botão de Ação Imediata: Obter Localização Agora
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localização Atual',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.mensagemLocalizacao ??
                            'Resolução espacial offline por GPS ou rede',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: provider.isLocalizando
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          final concelho =
                              await provider.detetarEDefinirLocalizacaoAtual();
                          if (concelho != null) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Concelho detetado: ${concelho.nome} (${concelho.distrito})'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            final servicoAtivo = await Geolocator.isLocationServiceEnabled();
                            final permissao = await Geolocator.checkPermission();
                            final precisaDefinicoes = !servicoAtivo || permissao == LocationPermission.deniedForever;

                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(provider.mensagemLocalizacao ??
                                    'Não foi possível detetar a localização.'),
                                duration: const Duration(seconds: 4),
                                action: precisaDefinicoes
                                    ? SnackBarAction(
                                        label: 'Definições',
                                        onPressed: () {
                                          if (!servicoAtivo) {
                                            Geolocator.openLocationSettings();
                                          } else {
                                            Geolocator.openAppSettings();
                                          }
                                        },
                                      )
                                    : null,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? kBrandDark : kBrand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: provider.isLocalizando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(CupertinoIcons.location_fill, size: 16),
                  label: Text(
                    provider.isLocalizando ? 'A detetar...' : 'Localizar Já',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
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

// ── Card de dados ────────────────────────────────────────────────────────────

class _DadosCard extends StatelessWidget {
  const _DadosCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final cs = Theme.of(context).colorScheme;
    final ultimaAtualizacao = provider.ultimaAtualizacao;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Column(
        children: [
          _ItemLinha(
            icone: CupertinoIcons.clock,
            titulo: 'Último Registo',
            valor: ultimaAtualizacao != null
                ? formatarDateTime(ultimaAtualizacao)
                : '—',
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinha(
            icone: provider.isOnline
                ? CupertinoIcons.wifi
                : CupertinoIcons.wifi_slash,
            titulo: 'Estado da Ligação',
            valor: provider.isOnline ? 'Online' : 'Offline',
            corValor: provider.isOnline
                ? const Color(0xFF34C759)
                : const Color(0xFFFF9500),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          const _ItemLinha(
            icone: CupertinoIcons.arrow_2_circlepath,
            titulo: 'Política de Cache & TTL',
            valor: '2 horas (Eco-Sync IPMA)',
            corValor: Color(0xFF34C759),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.carregarDados(forcar: true),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                label: Text(
                    provider.isLoading ? 'A sincronizar…' : 'Sincronizar Agora (Forçar)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de Emergência & Isenção de Responsabilidade ───────────────────────

class _EmergenciaLegalCard extends StatelessWidget {
  const _EmergenciaLegalCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF453A).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF453A).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.phone_fill,
                  color: Color(0xFFFF453A),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Em Caso de Incêndio: Ligue 112',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF453A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Esta aplicação é uma ferramenta de consulta informativa baseada em dados abertos públicos (Lei n.º 68/2021). Em caso de emergência ou avistamento de fumo/fogo, contacte de imediato o 112 e siga sempre as orientações oficiais da ANEPC (Proteção Civil) e do ICNF.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de informação ───────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Column(
        children: [
          _ItemLinhaClicavel(
            icone: CupertinoIcons.cloud,
            titulo: 'Fonte dos Dados',
            subtitulo: 'IPMA – Instituto Português do Mar e da Atmosfera',
            onTap: () => _abrirUrl('https://www.ipma.pt/pt/riscoincendio/rcm.pt/'),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinhaClicavel(
            icone: CupertinoIcons.calendar,
            titulo: 'Previsão Alargada',
            subtitulo: 'Modelo RCM até 9 dias (IPMA & Proteção Civil)',
            onTap: () => _abrirUrl('https://www.ipma.pt/pt/ambiente/risco.incendio/'),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinhaClicavel(
            icone: CupertinoIcons.doc_text_search,
            titulo: 'Enquadramento Legal & Dados Abertos',
            subtitulo: 'Lei n.º 68/2021 · Diretiva (UE) 2019/1024',
            onTap: () => _mostrarDialogoAvisoLegal(context),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinhaClicavel(
            icone: CupertinoIcons.shield,
            titulo: 'Proteção Civil & ICNF',
            subtitulo: 'Legislação Decreto-Lei n.º 82/2021',
            onTap: () => _abrirUrl('https://fogos.icnf.pt/'),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinhaClicavel(
            icone: CupertinoIcons.lock_shield,
            titulo: 'Política de Privacidade',
            subtitulo: 'Não guardamos dados pessoais · Processamento local',
            onTap: () => _mostrarDialogoPrivacidade(context),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          const _ItemLinha(
            icone: CupertinoIcons.info_circle,
            titulo: 'Natureza da App',
            valor: 'Iniciativa cívica independente',
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAvisoLegal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(CupertinoIcons.doc_text_search, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aviso Legal & Dados Abertos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enquadramento Legal da Informação:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '1. Princípio de Dados Abertos (Open Data):\n'
                'Esta aplicação reutiliza dados públicos meteorológicos e de perigo de incêndio rural disponibilizados pelo Instituto Português do Mar e da Atmosfera (IPMA, I.P.), ao abrigo da Lei n.º 68/2021, de 24 de agosto, que transpõe a Diretiva (UE) 2019/1024 relativa a dados abertos e à reutilização de informação do setor público.\n\n'
                '2. Isenção de Responsabilidade Operacional:\n'
                'O PIR-App é uma plataforma de agregação e visualização cívica independente. A informação aqui apresentada não substitui, em circunstância alguma, as comunicações, avisos à população ou ordens operacionais emanadas pela Autoridade Nacional de Emergência e Proteção Civil (ANEPC), pelo Instituto da Conservação da Natureza e das Florestas (ICNF) ou pelas Forças de Segurança.\n\n'
                '3. Atribuição de Fontes:\n'
                '• Perigo de Incêndio Rural (RCM): IPMA, I.P.\n'
                '• Limites Administrativos (CAOP): Direção-Geral do Território (DGT)\n\n'
                '4. Contactos de Emergência:\n'
                '• Número Europeu de Emergência: 112\n'
                '• Linha SOS Ambiente e Território (GNR): 808 200 520\n'
                '• Informações ICNF: 808 200 500',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compreendi'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPrivacidade(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(CupertinoIcons.lock_shield, size: 22),
            SizedBox(width: 8),
            Text('Política de Privacidade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A sua privacidade é uma prioridade.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                '• Geolocalização: Utilizada única e exclusivamente no dispositivo para determinar o concelho atual. Nenhuma coordenada GPS ou endereço IP é transmitido para servidores de terceiros ou armazenado externamente.\n\n'
                '• Dados e Favoritos: As preferências de tema, favoritos e concelho são guardadas exclusivamente na memória local do dispositivo (Hive Cache).\n\n'
                '• Sem Registo ou Rastreio: Não existem contas de utilizador, cookies de rastreio ou plataformas de publicidade.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compreendi'),
          ),
        ],
      ),
    );
  }
}

// ── Linha clicável com chevron ──────────────────────────────────────────────

class _ItemLinhaClicavel extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _ItemLinhaClicavel({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icone, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, size: 16, color: cs.outline.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Linha genérica ───────────────────────────────────────────────────────────

class _ItemLinha extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Color? corValor;

  const _ItemLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icone, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                )),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              color: corValor ?? cs.onSurfaceVariant,
              fontWeight: corValor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
