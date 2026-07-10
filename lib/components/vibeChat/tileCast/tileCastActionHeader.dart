import 'package:flutter/material.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Header for a single TileCast carousel page.
///
/// Shows the focused action's description, the carousel position, optional
/// stale / non-viable badges, and the previous/next/list navigation controls.
/// Kept free of bloc/schedule dependencies so it can be unit tested in
/// isolation.
class TileCastActionHeader extends StatelessWidget {
  static const prevKey = ValueKey('tilecast_prev');
  static const nextKey = ValueKey('tilecast_next');
  static const listKey = ValueKey('tilecast_list');
  static const titleKey = ValueKey('tilecast_title');
  static const positionKey = ValueKey('tilecast_position');
  static const staleBannerKey = ValueKey('tilecast_stale_banner');
  static const nonViableKey = ValueKey('tilecast_nonviable');

  final VibePreviewAction action;

  /// Zero-based index of this action within the carousel.
  final int index;

  /// Total number of actions in the carousel.
  final int total;

  final bool isStale;
  final bool isNonViable;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onOpenList;

  const TileCastActionHeader({
    Key? key,
    required this.action,
    required this.index,
    required this.total,
    this.isStale = false,
    this.isNonViable = false,
    this.onPrev,
    this.onNext,
    this.onOpenList,
  }) : super(key: key);

  String _resolveTitle(AppLocalizations localization) {
    final description = action.action?.descriptions;
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }
    return localization.reviewChanges;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;
    final bool canGoPrev = index > 0;
    final bool canGoNext = index < total - 1;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  key: prevKey,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: canGoPrev ? onPrev : null,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _resolveTitle(localization),
                        key: titleKey,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${index + 1} / $total',
                        key: positionKey,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: nextKey,
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: canGoNext ? onNext : null,
                  tooltip:
                      MaterialLocalizations.of(context).nextPageTooltip,
                ),
                IconButton(
                  key: listKey,
                  icon: const Icon(Icons.list_rounded),
                  onPressed: onOpenList,
                  tooltip: localization.reviewChanges,
                ),
              ],
            ),
            if (isNonViable || isStale)
              const SizedBox(height: 6),
            if (isNonViable)
              Align(
                alignment: Alignment.center,
                child: Container(
                  key: nonViableKey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 14, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 4),
                      Text(
                        localization.previewNonViableLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isStale) ...[
              if (isNonViable) const SizedBox(height: 6),
              Container(
                key: staleBannerKey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 14, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        localization.previewStaleBanner,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small helper exposing an action's display label for reuse in the list view.
extension TileCastActionLabel on VibePreviewAction {
  String displayLabel(AppLocalizations localization) {
    final description = action?.descriptions;
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }
    return localization.reviewChanges;
  }

  bool get isActionable {
    final type = action?.type;
    return type != ActionType.conversationalAndNotSupported &&
        type != ActionType.none;
  }

  /// Whether this action maps to a specific tile that can be highlighted in
  /// the TileCast carousel. Non-highlightable actions (removals, mark-done,
  /// shuffle, exit) are grouped into a single composite summary page instead
  /// of getting their own carousel page.
  bool get isHighlightable {
    const _nonHighlightable = {
      ActionType.removeExistingTask,
      ActionType.markTaskAsDone,
      ActionType.exitPrompting,
      ActionType.procrastinateAllTasks,
      ActionType.whatIfRemovedTask,
      ActionType.whatIfMarkedTaskAsDone,
      ActionType.whatIfProcrastinateAll,
      ActionType.whatIfProcrastinateTask,
      ActionType.conversationalAndNotSupported,
      ActionType.none,
    };
    final type = action?.type;
    if (type == null) return false;
    return !_nonHighlightable.contains(type);
  }
}
