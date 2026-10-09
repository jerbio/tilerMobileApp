import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoff.dart';
import 'package:tiler_app/util.dart';

/// Edge chip for tiles that moved out of view or to another day, e.g.
/// "↓ Read 30 pages moved to 10:30 PM" or "→ 3 Tiles moved to Fri, Oct 9".
/// Tapping it takes the user there.
class GridHandoffChip extends StatelessWidget {
  final GridHandoff handoff;
  final VoidCallback onTap;

  const GridHandoffChip(
      {super.key, required this.handoff, required this.onTap});

  static Key keyFor(HandoffDirection direction) =>
      Key('daygrid_handoff_${direction.name}');

  static IconData iconFor(HandoffDirection direction) {
    switch (direction) {
      case HandoffDirection.earlier:
        return Icons.arrow_upward;
      case HandoffDirection.later:
        return Icons.arrow_downward;
      case HandoffDirection.previousDay:
        return Icons.arrow_back;
      case HandoffDirection.nextDay:
        return Icons.arrow_forward;
    }
  }

  static String text(BuildContext context, GridHandoff handoff) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final first = handoff.tiles.first;
    final start = Utility.localDateTimeFromMs(first.start!);
    final when = handoff.isOtherDay
        ? materialL10n.formatMediumDate(start)
        : materialL10n.formatTimeOfDay(TimeOfDay.fromDateTime(start),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    final count = handoff.tiles.length;
    if (count == 1) {
      final name = first.name?.trim();
      return l10n.scheduleChangeTileMovedTo(
          name == null || name.isEmpty ? l10n.untitledTile : name, when);
    }
    switch (handoff.direction) {
      case HandoffDirection.earlier:
        return l10n.scheduleChangeTilesMovedEarlier(count);
      case HandoffDirection.later:
        return l10n.scheduleChangeTilesMovedLater(count);
      case HandoffDirection.previousDay:
      case HandoffDirection.nextDay:
        return l10n.scheduleChangeTilesMovedTo(count, when);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      liveRegion: true,
      child: Material(
        key: keyFor(handoff.direction),
        color: colorScheme.surface,
        elevation: 4,
        shape: StadiumBorder(side: BorderSide(color: colorScheme.primary)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconFor(handoff.direction),
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text(context, handoff),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
