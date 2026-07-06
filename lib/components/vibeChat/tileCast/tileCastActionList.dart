import 'package:flutter/material.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionHeader.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Navigable list of TileCast actions, shown as a bottom sheet on top of the
/// carousel. Highlights the currently selected action and reports taps back via
/// [onSelect] so the carousel can jump to that page (no chat round-trip).
class TileCastActionList extends StatelessWidget {
  static ValueKey<String> itemKey(int index) => ValueKey('tilecast_item_$index');
  static ValueKey<String> nonViableBadgeKey(int index) =>
      ValueKey('tilecast_item_nonviable_$index');

  final List<VibePreviewAction> actions;
  final int selectedIndex;

  /// Entity ids of tiles that could not be scheduled, used to badge the
  /// matching actions.
  final Set<String> nonViableEntityIds;
  final ValueChanged<int> onSelect;

  const TileCastActionList({
    Key? key,
    required this.actions,
    required this.selectedIndex,
    required this.onSelect,
    this.nonViableEntityIds = const {},
  }) : super(key: key);

  bool _isNonViable(VibePreviewAction action) {
    final entityId = action.entityId;
    if (entityId == null) return false;
    return nonViableEntityIds.contains(entityId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localization.reviewChanges,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                final bool isSelected = index == selectedIndex;
                final bool isNonViable = _isNonViable(action);

                return ListTile(
                  key: TileCastActionList.itemKey(index),
                  selected: isSelected,
                  selectedTileColor:
                      colorScheme.primaryContainer.withValues(alpha: 0.4),
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  title: Text(
                    action.displayLabel(localization),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: isNonViable
                      ? Icon(
                          Icons.error_outline_rounded,
                          key: TileCastActionList.nonViableBadgeKey(index),
                          size: 18,
                          color: colorScheme.error,
                        )
                      : (isSelected
                          ? Icon(Icons.check_rounded,
                              size: 18, color: colorScheme.primary)
                          : null),
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
