import 'package:flutter/material.dart';
import 'package:tiler_app/services/scheduleMotion.dart';

/// A duration label that counts to its new value when it changes ("7 min"
/// → "22 min"), so a travel time or free gap reads as having changed rather
/// than being swapped. Changes at once when schedule-update motion is off.
class CountingDuration extends StatelessWidget {
  final Duration value;
  final String Function(BuildContext context, Duration value) format;
  final TextStyle? style;

  const CountingDuration({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  static const Duration countFor = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.inMilliseconds.toDouble()),
      duration:
          ScheduleMotion.modeFor(context).animates ? countFor : Duration.zero,
      curve: Curves.easeOut,
      builder: (context, ms, _) => Text(
        // Whole minutes while counting, so the label never shows seconds.
        format(context,
            Duration(minutes: (ms / Duration.millisecondsPerMinute).round())),
        style: style,
      ),
    );
  }
}
