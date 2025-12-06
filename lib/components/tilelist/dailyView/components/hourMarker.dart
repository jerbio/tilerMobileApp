import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Hour marker widget displayed alongside tiles
class HourMarker extends StatelessWidget {
  final int hour;
  final bool isCurrentHour;

  const HourMarker({
    Key? key,
    required this.hour,
    this.isCurrentHour = false,
  }) : super(key: key);

  String _formatHour(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    if (hour >= 12) {
      return l10n.hourPm(displayHour);
    }
    return l10n.hourAm(displayHour);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatHour(context),
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 12,
            fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w500,
            color: isCurrentHour
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        if (isCurrentHour)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

/// A tile row with hour marker on the left side
class TileRowWithHourMarker extends StatelessWidget {
  final Widget child;
  final int hour;
  final bool showHourMarker;
  final bool isCurrentHour;
  final double hourMarkerWidth;

  const TileRowWithHourMarker({
    Key? key,
    required this.child,
    required this.hour,
    this.showHourMarker = true,
    this.isCurrentHour = false,
    this.hourMarkerWidth = 55,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour marker column
        Container(
          width: hourMarkerWidth,
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: showHourMarker
              ? HourMarker(
                  hour: hour,
                  isCurrentHour: isCurrentHour,
                )
              : const SizedBox.shrink(),
        ),
        // Tile content
        Expanded(child: child),
      ],
    );
  }
}

/// A connector row with spacing for hour marker
class ConnectorRowWithHourMarker extends StatelessWidget {
  final Widget connector;
  final double hourMarkerWidth;

  const ConnectorRowWithHourMarker({
    Key? key,
    required this.connector,
    this.hourMarkerWidth = 55,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: hourMarkerWidth),
        Expanded(child: connector),
      ],
    );
  }
}
