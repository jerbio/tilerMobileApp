import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/actionChip.dart';

/// Quick action chips row with "Show Route" and "Re-optimize" buttons
class QuickActionChipsRow extends StatelessWidget {
  final VoidCallback? onShowRoute;
  final VoidCallback? onReOptimize;

  const QuickActionChipsRow({
    Key? key,
    this.onShowRoute,
    this.onReOptimize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        children: [
          if (onShowRoute != null)
            TilerActionChip(
              icon: Icons.route,
              label: l10n.showRouteChip,
              onTap: onShowRoute!,
            ),
          if (onShowRoute != null && onReOptimize != null)
            const SizedBox(width: 8),
          if (onReOptimize != null)
            TilerActionChip(
              icon: Icons.refresh,
              label: l10n.reOptimizeChip,
              onTap: onReOptimize!,
            ),
        ],
      ),
    );
  }
}
