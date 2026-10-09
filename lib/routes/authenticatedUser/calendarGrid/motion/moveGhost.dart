import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

/// The outline left at a moving tile's old spot.
class MoveGhost {
  final SubCalendarEvent from;
  final int toStartMs;
  final double left;
  final double width;

  /// Set once the tile has landed; the outline then fades away.
  bool fading = false;

  MoveGhost(this.from, this.toStartMs, this.left, this.width);
}

/// Faint outline of a tile at the time it is moving away from, captioned
/// with where it is going.
class MoveGhostWidget extends StatelessWidget {
  final MoveGhost ghost;
  final double top;
  final double height;
  final bool animate;

  const MoveGhostWidget({
    super.key,
    required this.ghost,
    required this.top,
    required this.height,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(Utility.localDateTimeFromMs(ghost.toStartMs)),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    final caption = AppLocalizations.of(context)!.scheduleChangeMovedTo(time);
    return Positioned(
      top: top,
      left: ghost.left,
      width: ghost.width,
      height: height,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: ghost.fading ? 0.0 : 1.0,
          duration: animate ? GridChoreography.ghostLinger : Duration.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
              border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.55),
                  width: 1.5),
            ),
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
