/// The what-if forecast request (`POST /api/WhatIf/NewTile`) for a shared task:
/// from now to its deadline, for its duration.
///
/// The server builds the end from separate Day / Month / Year / **Hour /
/// Minute** fields and fills a missing hour or minute with 0. A request with
/// only the date therefore ended at midnight at the *start* of the deadline's
/// day — already past for a task due later today, which the server rejected
/// ("End time has to be later than start"), and ignoring the deadline's time of
/// day for any other. So the deadline's hour and minute are always sent.
abstract final class TileShareForecastRequest {
  /// `null` when there is nothing to forecast: no duration, no deadline, or a
  /// deadline that is not after [now].
  static Map<String, Object>? forTask({
    required int? durationMs,
    required int? endMs,
    required DateTime now,
  }) {
    if (durationMs == null || endMs == null) return null;
    if (endMs <= now.millisecondsSinceEpoch) return null;
    final Duration duration = Duration(milliseconds: durationMs);
    final DateTime end = DateTime.fromMillisecondsSinceEpoch(endMs);
    return <String, Object>{
      'StartMinute': now.minute.toString(),
      'StartHour': now.hour.toString(),
      'StartDay': now.day.toString(),
      'StartMonth': now.month.toString(),
      'StartYear': now.year.toString(),
      'EndMinute': end.minute.toString(),
      'EndHour': end.hour.toString(),
      'EndDay': end.day.toString(),
      'EndMonth': end.month.toString(),
      'EndYear': end.year.toString(),
      'DurationHours': duration.inHours.toString(),
      'DurationInMs': duration.inMilliseconds.toString(),
    };
  }
}
