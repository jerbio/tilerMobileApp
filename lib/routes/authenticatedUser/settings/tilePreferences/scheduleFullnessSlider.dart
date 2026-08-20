import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class ScheduleFullnessSlider extends StatelessWidget {
  static const double minimumIntensity = 15;
  static const double maximumIntensity = 95;
  static const double intensityStep = 5;
  static const double defaultIntensity = 50;

  /// The scale the dead zones are measured against.
  static const double fullIntensity = 100;

  static int get divisions =>
      ((maximumIntensity - minimumIntensity) / intensityStep).round();

  /// Portion of the track below [minimumIntensity].
  static int get leadingDeadZoneFlex => minimumIntensity.round();

  /// Portion of the track the slider can reach.
  static int get activeFlex => (maximumIntensity - minimumIntensity).round();

  /// Portion of the track above [maximumIntensity].
  static int get trailingDeadZoneFlex =>
      (fullIntensity - maximumIntensity).round();

  final num? intensityRate;
  final ValueChanged<double> onIntensityChanged;

  const ScheduleFullnessSlider({
    Key? key,
    required this.intensityRate,
    required this.onIntensityChanged,
  }) : super(key: key);

  /// The backend persists this as a fraction, so it is scaled for display.
  static double percentageFromRate(num? intensityRate) {
    final num? stored = intensityRate;
    return normalizeIntensity(
        stored == null ? null : stored.toDouble() * fullIntensity);
  }

  static double rateFromPercentage(double percentage) {
    return percentage / fullIntensity;
  }

  /// Stored values can predate the range, so they are pulled onto the
  /// increments the slider accepts before being rendered.
  static double normalizeIntensity(num? intensityPercentage) {
    final double stored = intensityPercentage?.toDouble() ?? defaultIntensity;
    final double bounded =
        stored.clamp(minimumIntensity, maximumIntensity).toDouble();
    return ((bounded - minimumIntensity) / intensityStep).round() *
            intensityStep +
        minimumIntensity;
  }

  Widget _deadZone(int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final secondaryColor =
        theme.extension<TileThemeExtension>()?.onSurfaceSecondary ??
            colorScheme.onSurfaceVariant;
    final deadZoneColor =
        colorScheme.surfaceContainerHighest.withAlpha((255 * 0.65).toInt());
    final scaleStyle = TextStyle(fontSize: 12, color: secondaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.scheduleFullness,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Text(
          localizations.scheduleFullnessDescription,
          style: TextStyle(fontSize: 14, color: secondaryColor),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            _deadZone(leadingDeadZoneFlex, deadZoneColor),
            Expanded(
              flex: activeFlex,
              child: Slider(
                value: percentageFromRate(intensityRate),
                min: minimumIntensity,
                max: maximumIntensity,
                divisions: divisions,
                onChanged: (value) =>
                    onIntensityChanged(rateFromPercentage(value)),
              ),
            ),
            _deadZone(trailingDeadZoneFlex, deadZoneColor),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.lighter, style: scaleStyle),
            Text(localizations.balanced, style: scaleStyle),
            Text(localizations.fuller, style: scaleStyle),
          ],
        ),
        SizedBox(height: 12),
        Text(
          localizations.scheduleFullnessLimits(
              minimumIntensity.round(), maximumIntensity.round()),
          style: scaleStyle,
        ),
      ],
    );
  }
}
