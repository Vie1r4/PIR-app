import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

                // ── Dados ─────────────────────────────────────────────
                const _Secao(titulo: 'Dados & Atualização'),
                const _DadosCard(),
                const SizedBox(height: 28),

                // ── Informação ────────────────────────────────────────
                const _Secao(titulo: 'Sobre a Aplicação'),
                const _InfoCard(),
                const SizedBox(height: 40),

                // Assinatura em baixo
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
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
                        'Versão 1.0.0 · Portugal Continental',
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, size: 20, color: cs.primary),
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
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
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
        borderRadius: BorderRadius.circular(22),
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
              borderRadius: BorderRadius.circular(22),
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
                        Icons.accessibility_new_rounded,
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
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
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
                      Icon(Icons.format_size_rounded, size: 18, color: cs.primary),
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
                    secondary: Icon(Icons.contrast_rounded, color: cs.primary),
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
                    secondary: Icon(Icons.zoom_out_map_rounded, color: cs.primary),
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
                    secondary: Icon(Icons.motion_photos_off_rounded, color: cs.primary),
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
                    secondary: Icon(Icons.help_outline_rounded, color: cs.primary),
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
                      icon: const Icon(Icons.restore_rounded, size: 16),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Column(
        children: [
          _ItemLinha(
            icone: Icons.history_toggle_off_outlined,
            titulo: 'Último Registo',
            valor: ultimaAtualizacao != null
                ? formatarDateTime(ultimaAtualizacao)
                : '—',
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinha(
            icone: provider.isOnline
                ? Icons.wifi_rounded
                : Icons.wifi_off_rounded,
            titulo: 'Estado da Ligação',
            valor: provider.isOnline ? 'Online' : 'Offline',
            corValor: provider.isOnline
                ? const Color(0xFF34C759)
                : const Color(0xFFFF9500),
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          const _ItemLinha(
            icone: Icons.sync_rounded,
            titulo: 'Sincronização Automática',
            valor: 'Ativa (a cada 30m / ao abrir)',
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
                    : () => provider.carregarDados(),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                    provider.isLoading ? 'A sincronizar…' : 'Sincronizar Agora'),
              ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Column(
        children: [
          _ItemLinha(
            icone: Icons.cloud_outlined,
            titulo: 'Fonte de Dados',
            valor: 'IPMA (api.ipma.pt)',
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinha(
            icone: Icons.gavel_outlined,
            titulo: 'Legislação',
            valor: 'DL n.º 82/2021 · ICNF',
          ),
          Divider(height: 1, indent: 52, color: cs.outlineVariant.withValues(alpha: 0.4)),
          _ItemLinha(
            icone: Icons.info_outline_rounded,
            titulo: 'Sobre',
            valor: 'App não oficial. Dados © IPMA.',
          ),
        ],
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
