import 'package:flutter/material.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionHeader.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Floating bottom card shown on the composite TileCast page.
///
/// Lists every non-highlightable action (removals, mark-done, shuffles, etc.)
/// that is part of the current TileCast batch but cannot be given its own
/// carousel page because it doesn't map to a specific highlighted tile.
///
/// Renders nothing when [actions] is empty.
class TileCastCompositeSummary extends StatelessWidget {
  final List<VibePreviewAction> actions;

  /// Maximum number of action rows shown before the "+ N more" overflow line.
  final int maxVisible;

  const TileCastCompositeSummary(
      {Key? key, required this.actions, this.maxVisible = 3})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;

    return Container(
      key: const ValueKey('tilecast_composite_summary'),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  localization.tileCastAlsoIncluded,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...actions.take(maxVisible).map(
                (a) => _buildRow(context, a, localization)),
            if (actions.length > maxVisible)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${actions.length - maxVisible} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, VibePreviewAction action,
      AppLocalizations localization) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              action.displayLabel(localization),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
