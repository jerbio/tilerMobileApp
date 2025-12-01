import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Displays hour markers on the left side of the timeline (7 AM, 8 AM, etc.)
class TimelineHourMarker extends StatelessWidget {
  final DateTime time;
  final bool isCurrentHour;
  final bool showWeatherIcon;
  final IconData? weatherIcon;

  const TimelineHourMarker({
    Key? key,
    required this.time,
    this.isCurrentHour = false,
    this.showWeatherIcon = false,
    this.weatherIcon,
  }) : super(key: key);

  String _formatHour(BuildContext context) {
    final hour = time.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _formatHour(context),
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 12,
              fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w400,
              color: isCurrentHour
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (showWeatherIcon && weatherIcon != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                weatherIcon,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// A row that contains the hour marker and the tile content
class TimelineRow extends StatelessWidget {
  final DateTime startTime;
  final Widget child;
  final bool showHourMarker;
  final bool isCurrentHour;

  const TimelineRow({
    Key? key,
    required this.startTime,
    required this.child,
    this.showHourMarker = true,
    this.isCurrentHour = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHourMarker)
          TimelineHourMarker(
            time: startTime,
            isCurrentHour: isCurrentHour,
          ),
        Expanded(child: child),
      ],
    );
  }
}

/// Generates hour markers for a given time range
class TimelineHourList extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final Map<int, Widget> hourToWidget;

  const TimelineHourList({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.hourToWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hours = <Widget>[];
    var currentHour = DateTime(
        startTime.year, startTime.month, startTime.day, startTime.hour);
    final now = DateTime.now();

    while (currentHour.isBefore(endTime)) {
      final isCurrentHour = currentHour.hour == now.hour &&
          currentHour.day == now.day &&
          currentHour.month == now.month &&
          currentHour.year == now.year;

      final widget = hourToWidget[currentHour.hour];

      hours.add(
        TimelineRow(
          startTime: currentHour,
          isCurrentHour: isCurrentHour,
          child: widget ?? const SizedBox(height: 60),
        ),
      );

      currentHour = currentHour.add(const Duration(hours: 1));
    }

    return Column(children: hours);
  }
}
