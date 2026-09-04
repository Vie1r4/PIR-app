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
    return ListTile(
      leading: rcm != null
          ? RiscoBadge(rcm: rcm!, size: 36)
          : Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: Theme.of(context).colorScheme.outline,
                size: 20,
              ),
            ),
      title: Text(
        concelho.nome,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(concelho.distrito),
      trailing: onFavoriteToggle != null
          ? IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? Colors.red
                    : Theme.of(context).colorScheme.outline,
              ),
              onPressed: onFavoriteToggle,
            )
          : null,
      onTap: onTap,
    );
  }
}
