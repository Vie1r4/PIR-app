import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../providers/acessibilidade_provider.dart';
import '../providers/risco_provider.dart';
import 'definicoes_screen.dart';
import 'favoritos_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';

/// Ecrã principal adaptativo:
/// - Desktop (>= 720px): NavigationRail lateral com aba Definicoes pinada no fundo (trailing)
/// - Mobile (< 720px): NavigationBar inferior com 5 destinos
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> with WidgetsBindingObserver {
  int _indiceSelecionado = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Quando a aplicação volta ao primeiro plano ou ganha foco, verifica e atualiza silenciosamente se necessário
      if (mounted) {
        context.read<RiscoProvider>().verificarEAtualizarAutomatico();
      }
    }
  }

  void _mudarAba(int index) {
    if (_indiceSelecionado != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _indiceSelecionado = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiscoProvider>();
    final accProvider = context.watch<AcessibilidadeProvider>();
    final numFavoritos = provider.favoritos.length;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _mudarAba(1),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () => _mudarAba(1),
      const SingleActivator(LogicalKeyboardKey.keyR, control: true): () => provider.carregarDados(),
      const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () => provider.carregarDados(),
      const SingleActivator(LogicalKeyboardKey.f5): () => provider.carregarDados(),
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () => _mudarAba(0),
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () => _mudarAba(1),
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () => _mudarAba(2),
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () => _mudarAba(3),
      const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _mudarAba(0),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _mudarAba(1),
      const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => _mudarAba(2),
      const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => _mudarAba(3),
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (_indiceSelecionado != 0) _mudarAba(0);
      },
    };

    final List<Widget> paginas = [
      HomeScreen(
        onNavigateToTab: _mudarAba,
        onNavigateToSearch: () => _mudarAba(1),
      ),
      const MapScreen(showAppBar: false),
      FavoritosScreen(
        isEmbedded: true,
        onConcelhoSelected: (dico) => _mudarAba(0),
      ),
      const DefinicoesScreen(),
    ];

    final Widget layoutContent = isDesktop
        ? _buildDesktopLayout(paginas, accProvider)
        : _buildMobileLayout(paginas, numFavoritos, accProvider);

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(autofocus: true, child: layoutContent),
    );
  }

  Widget _buildDesktopLayout(List<Widget> paginas, AcessibilidadeProvider accProvider) {
    final largura = MediaQuery.of(context).size.width;
    final extended = largura >= 1050;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? kBrandDark : kBrand;
    final sidebarBg = isDark ? kDarkCard : kLightCard;
    final borderColor = isDark ? const Color(0x16FFFFFF) : const Color(0x12000000);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: extended ? 220 : 72,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                right: BorderSide(color: borderColor, width: 0.8),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _SidebarDestinationButton(
                  icon: CupertinoIcons.house,
                  selectedIcon: CupertinoIcons.house_fill,
                  label: 'Início',
                  isSelected: _indiceSelecionado == 0,
                  extended: extended,
                  activeColor: activeColor,
                  onTap: () => _mudarAba(0),
                ),
                _SidebarDestinationButton(
                  icon: CupertinoIcons.map,
                  selectedIcon: CupertinoIcons.map_fill,
                  label: 'Mapa & Pesquisa',
                  isSelected: _indiceSelecionado == 1,
                  extended: extended,
                  activeColor: activeColor,
                  onTap: () => _mudarAba(1),
                ),
                _SidebarDestinationButton(
                  icon: CupertinoIcons.heart,
                  selectedIcon: CupertinoIcons.heart_fill,
                  label: 'Favoritos',
                  isSelected: _indiceSelecionado == 2,
                  extended: extended,
                  activeColor: activeColor,
                  onTap: () => _mudarAba(2),
                ),
                const Spacer(),
                _SidebarDestinationButton(
                  icon: CupertinoIcons.gear_alt,
                  selectedIcon: CupertinoIcons.gear_alt_fill,
                  label: 'Definições',
                  isSelected: _indiceSelecionado == 3,
                  extended: extended,
                  activeColor: activeColor,
                  onTap: () => _mudarAba(3),
                ),
                if (extended) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Powered by ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.65),
                              letterSpacing: 0.1,
                            ),
                          ),
                          TextSpan(
                            text: 'Pirofafe',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: activeColor.withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          Expanded(
            child: accProvider.reduzirAnimacoes
                ? KeyedSubtree(
                    key: ValueKey<int>(_indiceSelecionado),
                    child: paginas[_indiceSelecionado],
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(curved),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.988, end: 1.0).animate(curved),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_indiceSelecionado),
                      child: paginas[_indiceSelecionado],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    List<Widget> paginas,
    int numFavoritos,
    AcessibilidadeProvider accProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? kBrandDark : kBrand;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: accProvider.reduzirAnimacoes
            ? KeyedSubtree(
                key: ValueKey<int>(_indiceSelecionado),
                child: paginas[_indiceSelecionado],
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(curved),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.988, end: 1.0).animate(curved),
                        child: child,
                      ),
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_indiceSelecionado),
                  child: paginas[_indiceSelecionado],
                ),
              ),
      ),
      bottomNavigationBar: _MobileBottomBar(
        selectedIndex: _indiceSelecionado.clamp(0, 3),
        onTabSelected: _mudarAba,
        numFavoritos: numFavoritos,
        isDark: isDark,
        activeColor: activeColor,
        isGrandes: accProvider.elementosGrandes,
      ),
    );
  }
}

// ── Barra de Navegação Inferior Móvel/iOS Moderna e Ergonómica ───────────────

class _MobileBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final int numFavoritos;
  final bool isDark;
  final Color activeColor;
  final bool isGrandes;

  const _MobileBottomBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.numFavoritos,
    required this.isDark,
    required this.activeColor,
    required this.isGrandes,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = (isDark ? kDarkCard : kLightCard).withValues(alpha: 0.96);
    final borderColor = isDark ? const Color(0x20FFFFFF) : const Color(0x18000000);
    final inactiveColor = isDark ? const Color(0x99FFFFFF) : const Color(0x88000000);

    final items = [
      const _NavItemData(
        icon: CupertinoIcons.house,
        selectedIcon: CupertinoIcons.house_fill,
        label: 'Início',
      ),
      const _NavItemData(
        icon: CupertinoIcons.map,
        selectedIcon: CupertinoIcons.map_fill,
        label: 'Mapa',
      ),
      _NavItemData(
        icon: CupertinoIcons.heart,
        selectedIcon: CupertinoIcons.heart_fill,
        label: 'Favoritos',
        badgeCount: numFavoritos,
      ),
      const _NavItemData(
        icon: CupertinoIcons.gear_alt,
        selectedIcon: CupertinoIcons.gear_alt_fill,
        label: 'Definições',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: isGrandes ? 68 : 60,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: _MobileTabItem(
                  item: item,
                  isSelected: isSelected,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isGrandes: isGrandes,
                  onTap: () => onTabSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MobileTabItem extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final bool isGrandes;
  final VoidCallback onTap;

  const _MobileTabItem({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.isGrandes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isGrandes ? 25.0 : 23.0;
    final fontSize = isGrandes ? 12.5 : 11.5;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      splashColor: activeColor.withValues(alpha: 0.12),
      highlightColor: activeColor.withValues(alpha: 0.08),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: iconSize,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    right: -7,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? badgeCount;

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });
}

class _SidebarDestinationButton extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool extended;
  final Color activeColor;
  final VoidCallback onTap;

  const _SidebarDestinationButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.extended,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_SidebarDestinationButton> createState() =>
      _SidebarDestinationButtonState();
}

class _SidebarDestinationButtonState extends State<_SidebarDestinationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final bgColor = widget.isSelected
        ? widget.activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
        : (_isHovered
            ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
            : Colors.transparent);

    final borderColor = widget.isSelected
        ? widget.activeColor.withValues(alpha: isDark ? 0.35 : 0.22)
        : Colors.transparent;

    final contentColor = widget.isSelected
        ? widget.activeColor
        : (_isHovered ? cs.onSurface : cs.onSurfaceVariant);

    final acc = context.watch<AcessibilidadeProvider>();
    final isGrandes = acc.elementosGrandes;
    final btnHeight = isGrandes ? 52.0 : 46.0;
    final iconSize = isGrandes ? 24.0 : 21.0;

    final Widget iconWidget = Icon(
      widget.isSelected ? widget.selectedIcon : widget.icon,
      color: contentColor,
      size: iconSize,
    );

    final buttonContent = widget.extended
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: btnHeight,
            margin: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: isGrandes ? 5 : 3,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: widget.isSelected ? 3.5 : 0,
                  height: widget.isSelected ? (isGrandes ? 22 : 18) : 0,
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: widget.isSelected ? 8 : 4),
                iconWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: contentColor,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: isGrandes ? 14.5 : 13.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Tooltip(
            message: widget.label,
            waitDuration: const Duration(milliseconds: 400),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isGrandes ? 56 : 52,
              height: btnHeight,
              margin: EdgeInsets.symmetric(
                horizontal: isGrandes ? 8 : 10,
                vertical: isGrandes ? 5 : 3,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Center(child: iconWidget),
            ),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: buttonContent,
        ),
      ),
    );
  }
}
