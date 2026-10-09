import 'package:flutter/material.dart';

/// Picks a day, starting from [seed]. Injected in tests.
typedef DeadlinePickDate = Future<DateTime?> Function(
    BuildContext context, DateTime seed);

/// Picks a time of day, starting from [seed]. Injected in tests.
typedef DeadlinePickTime = Future<TimeOfDay?> Function(
    BuildContext context, TimeOfDay seed);

Future<DateTime?> platformPickDate(BuildContext context, DateTime seed) =>
    showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: seed.subtract(const Duration(days: 365)),
      lastDate: seed.add(const Duration(days: 365 * 2)),
    );

Future<TimeOfDay?> platformPickTime(BuildContext context, TimeOfDay seed) =>
    showTimePicker(context: context, initialTime: seed);

/// A deadline with a date and a time (T27): a day, then a time of day. A
/// cancelled day keeps [current] (`null`); a cancelled time keeps its time
/// of day.
Future<DateTime?> pickDeadline(
  BuildContext context,
  DateTime current, {
  DeadlinePickDate pickDate = platformPickDate,
  DeadlinePickTime pickTime = platformPickTime,
}) async {
  final DateTime? day = await pickDate(context, current);
  if (day == null || !context.mounted) return null;
  final TimeOfDay? time =
      await pickTime(context, TimeOfDay.fromDateTime(current));
  final TimeOfDay at = time ?? TimeOfDay.fromDateTime(current);
  return DateTime(day.year, day.month, day.day, at.hour, at.minute);
}
