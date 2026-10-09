import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/changeFlash.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/util.dart';

/// A brief green highlight on the time a schedule change freed, labelled
/// with what was gained ("+45 min free").
///
/// Only the freed slices of the gap are tinted (where tiles used to be),
/// not the whole gap: most of a long gap may already have been free, and
/// tinting all of it would make a small gain look like hours.
class FreeGapFlashWidget extends StatelessWidget {
  final FreeGap gap;

  /// The gap's content-space top and height; the slices are drawn inside.
  final double top;
  final double height;
  final double left;
  final double width;

  /// Content-space y of a time (ms), for placing the freed slices.
  final double Function(int ms) yOf;
  final bool fading;
  final bool animate;

  const FreeGapFlashWidget({
    super.key,
    required this.gap,
    required this.top,
    required this.height,
    required this.left,
    required this.width,
    required this.yOf,
    required this.fading,
    required this.animate,
  });

  static Key keyFor(FreeGap gap) => Key('daygrid_free_gap_${gap.startMs}');
  static Key sliceKey(int startMs) => Key('daygrid_free_slice_$startMs');

  /// Below this a slice is too short to hold its label, which then sits on
  /// it as a pill instead.
  static const double _labelFits = 22;

  @override
  Widget build(BuildContext context) {
    final color = ChangeFlash.freeGained.color(Theme.of(context).colorScheme);
    final fade = animate ? ChangeFlashStyle.fade : Duration.zero;
    final slices = gap.freed.isEmpty ? [(gap.startMs, gap.endMs)] : gap.freed;
    // The label goes on the largest slice.
    var labelled = slices.first;
    for (final slice in slices) {
      if (slice.$2 - slice.$1 > labelled.$2 - labelled.$1) labelled = slice;
    }
    final label = AppLocalizations.of(context)!
        .scheduleChangeFreeGained(gap.gained.toHumanLocalized(context));
    final labelStyle = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: color, fontWeight: FontWeight.w600);

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          // Fades in when it appears, out when [fading] turns on.
          tween: Tween<double>(begin: animate ? 0 : 1, end: fading ? 0 : 1),
          duration: fade,
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final slice in slices)
                Positioned(
                  key: sliceKey(slice.$1),
                  top: yOf(slice.$1) - top,
                  height: (yOf(slice.$2) - yOf(slice.$1)).clamp(2.0, height),
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.6)),
                    ),
                    child: slice == labelled &&
                            yOf(slice.$2) - yOf(slice.$1) >= _labelFits
                        ? Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle)
                        : null,
                  ),
                ),
              // A slice too short for its label: the label rides on it as a
              // pill, centred on the slice.
              if (yOf(labelled.$2) - yOf(labelled.$1) < _labelFits)
                Positioned(
                  top: (yOf(labelled.$1) + yOf(labelled.$2)) / 2 - top - 11,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color),
                      ),
                      child: Text(label, maxLines: 1, style: labelStyle),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
