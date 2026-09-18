import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/concelho.dart';
import 'risco_badge.dart';

/// List tile widget for displaying a concelho with its risk level and favorite status
class ConcelhoTile extends StatelessWidget {
  final Concelho concelho;
  final int? rcm;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ConcelhoTile({
    super.key,
    required this.concelho,
    this.rcm,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.35),
            width: 0.8,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: rcm != null
              ? RiscoBadge(rcm: rcm!, size: 38)
              : Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.placemark,
                    color: cs.outline,
                    size: 20,
                  ),
                ),
          title: Text(
            concelho.nome,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(
            concelho.distrito,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.1,
              color: cs.outline,
            ),
          ),
          trailing: onFavoriteToggle != null
              ? IconButton(
                  tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                  icon: Icon(
                    isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: isFavorite
                        ? const Color(0xFFFF453A)
                        : cs.outline,
                    size: 22,
                  ),
                  onPressed: onFavoriteToggle,
                )
              : Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
