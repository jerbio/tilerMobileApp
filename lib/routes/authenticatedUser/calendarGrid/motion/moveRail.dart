import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/util.dart';

/// A line in the time gutter from where a tile was to where it went.
class MoveRail {
  final int fromStartMs;
  final int toStartMs;

  /// Only one rail per batch carries the "+1h 44m" label (the longest
  /// move), so labels never stack in the gutter.
  final bool labelled;

  /// Set once the tile has landed; the rail then fades away.
  bool fading = false;

  MoveRail(this.fromStartMs, this.toStartMs, {required this.labelled});

  Duration get shift => Duration(milliseconds: toStartMs - fromStartMs);
}

/// Draws a [MoveRail]: it grows from the old time toward the new one while
/// the tile slides, with a dot at each end and the shift as a label.
class MoveRailWidget extends StatelessWidget {
  final MoveRail rail;

  /// Content-space y of the old and new start.
  final double fromY;
  final double toY;

  /// Left edge of the rail lane in the gutter.
  final double left;
  final bool animate;

  const MoveRailWidget({
    super.key,
    required this.rail,
    required this.fromY,
    required this.toY,
    required this.left,
    required this.animate,
  });

  static const double _dot = 6;

  /// "+1h 44m" / "−20m".
  static String label(BuildContext context, Duration shift) {
    final sign = shift.isNegative ? '−' : '+';
    return '$sign${shift.abs().toHumanLocalized(context)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final top = fromY < toY ? fromY : toY;
    final height = (toY - fromY).abs();
    final downward = toY >= fromY;
    return Positioned(
      top: top - _dot / 2,
      left: left,
      width: 72,
      height: height + _dot,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: rail.fading ? 0.0 : 1.0,
          duration: animate ? GridChoreography.ghostLinger : Duration.zero,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: animate ? 0.0 : 1.0, end: 1.0),
            duration: animate ? GridChoreography.move : Duration.zero,
            curve: Curves.easeInOutCubic,
            builder: (context, grown, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                // The line grows from the old time toward the new one.
                Positioned(
                  left: (_dot - 2) / 2,
                  width: 2,
                  top: downward ? _dot / 2 : _dot / 2 + height * (1 - grown),
                  height: height * grown,
                  child: ColoredBox(color: color),
                ),
                Positioned(
                  left: 0,
                  top: downward ? 0 : height,
                  child: _dotAt(color),
                ),
                if (grown >= 1)
                  Positioned(
                    left: 0,
                    top: downward ? height : 0,
                    child: _dotAt(color),
                  ),
                if (rail.labelled && height > 18)
                  Positioned(
                    left: _dot + 2,
                    top: height / 2 - 7,
                    child: Opacity(
                      opacity: grown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label(context, rail.shift),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 10,
                                  height: 1.1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dotAt(Color color) => Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
