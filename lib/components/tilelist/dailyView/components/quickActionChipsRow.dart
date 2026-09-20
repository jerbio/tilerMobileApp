import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/actionChip.dart';

/// Quick action chips row with "Show Route" and "Re-optimize" buttons
class QuickActionChipsRow extends StatelessWidget {
  final VoidCallback? onShowRoute;
  final VoidCallback? onReOptimize;
  final bool preview;

  /// Optional test/spotlight keys for the two chips.
  final Key? showRouteKey;
  final Key? reOptimizeKey;

  /// Optional right-aligned widget (the Daily content filter). The chips
  /// keep their left alignment and scroll if space runs out.
  final Widget? trailing;

  /// The row's RESTING height: 8 + 8 vertical padding around a ~32px chip.
  /// A minimum, not a fixed size — with a larger font scale the chips grow
  /// and the row grows with them. When it was fixed, a taller chip was
  /// clamped to 32 and its label painted below the box, which read on
  /// device as the chips riding the bottom of the row (2026-09-19).
  static const double height = 48;

  const QuickActionChipsRow({
    Key? key,
    this.onShowRoute,
    this.onReOptimize,
    this.preview = false,
    this.showRouteKey,
    this.reOptimizeKey,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        // Every child — the scrolling chips and the filter pill — sits on
        // the row's vertical centre, whatever its own height.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Never overflow at narrow widths / long locales: the chips scroll
          // horizontally instead (no visual change when they fit).
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (onShowRoute != null)
                    TilerActionChip(
                      key: showRouteKey,
                      preview: preview,
                      icon: Icons.route,
                      label: l10n.showRouteChip,
                      onTap: onShowRoute!,
                    ),
                  if (onShowRoute != null && onReOptimize != null)
                    const SizedBox(width: 8),
                  if (onReOptimize != null)
                    TilerActionChip(
                      key: reOptimizeKey,
                      preview: preview,
                      icon: Icons.refresh,
                      label: l10n.reOptimizeChip,
                      onTap: onReOptimize!,
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Center(child: trailing!),
          ],
        ],
      ),
    );
  }
}
