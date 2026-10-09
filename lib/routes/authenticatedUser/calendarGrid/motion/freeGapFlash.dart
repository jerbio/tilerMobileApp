import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/changeFlash.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

/// A brief green band over free time a schedule change opened up, labelled
/// with what was gained ("+45 min free").
class FreeGapFlashWidget extends StatelessWidget {
  final FreeGap gap;
  final double top;
  final double height;
  final double left;
  final double width;
  final bool fading;
  final bool animate;

  const FreeGapFlashWidget({
    super.key,
    required this.gap,
    required this.top,
    required this.height,
    required this.left,
    required this.width,
    required this.fading,
    required this.animate,
  });

  static Key keyFor(FreeGap gap) => Key('daygrid_free_gap_${gap.startMs}');

  @override
  Widget build(BuildContext context) {
    final color = ChangeFlash.freeGained.color(Theme.of(context).colorScheme);
    final fade = animate ? ChangeFlashStyle.fade : Duration.zero;
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
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: height < 18
                ? null
                : Text(
                    AppLocalizations.of(context)!
                        .scheduleChangeFreeGained(gap.gained.inMinutes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
