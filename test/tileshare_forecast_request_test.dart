// The what-if forecast request for a shared task (the old invitation screen's
// binoculars). The server reads the deadline from separate Day / Month / Year /
// Hour / Minute fields and fills a missing hour or minute with 0, so a request
// that sent only the date meant "midnight at the START of the deadline's day":
// for a task due later today that is already past, and the server answered
// "End time has to be later than start". The request must carry the deadline's
// time of day.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/services/tileShare/tileShareForecastRequest.dart';

void main() {
  const int hour = 3600000;
  final DateTime now = DateTime(2026, 10, 1, 12, 34);
  int ms(DateTime d) => d.millisecondsSinceEpoch;

  /// The end the server would build from the request's own fields.
  DateTime endOf(Map<String, Object> p) => DateTime(
      int.parse(p['EndYear'] as String),
      int.parse(p['EndMonth'] as String),
      int.parse(p['EndDay'] as String),
      int.parse(p['EndHour'] as String),
      int.parse(p['EndMinute'] as String));

  test('starts now and ends at the deadline, to the minute', () {
    final p = TileShareForecastRequest.forTask(
        durationMs: 2 * hour, endMs: ms(DateTime(2026, 10, 4, 18, 45)), now: now)!;
    expect(p['StartYear'], '2026');
    expect(p['StartMonth'], '10');
    expect(p['StartDay'], '1');
    expect(p['StartHour'], '12');
    expect(p['StartMinute'], '34');
    expect(endOf(p), DateTime(2026, 10, 4, 18, 45));
    expect(p['DurationHours'], '2');
    expect(p['DurationInMs'], '${2 * hour}');
  });

  test('a task due later today ends after it starts (the case that was '
      'rejected)', () {
    final p = TileShareForecastRequest.forTask(
        durationMs: hour, endMs: ms(DateTime(2026, 10, 1, 20, 0)), now: now)!;
    final start = DateTime(2026, 10, 1, 12, 34);
    expect(endOf(p).isAfter(start), isTrue);
    expect(endOf(p), DateTime(2026, 10, 1, 20, 0));
  });

  test('the hour and minute are sent even when they are zero', () {
    final p = TileShareForecastRequest.forTask(
        durationMs: hour, endMs: ms(DateTime(2026, 10, 5, 0, 0)), now: now)!;
    expect(p['EndHour'], '0');
    expect(p['EndMinute'], '0');
  });

  test('a duration that is not a whole number of hours keeps its exact '
      'milliseconds', () {
    final p = TileShareForecastRequest.forTask(
        durationMs: 90 * 60000,
        endMs: ms(DateTime(2026, 10, 4, 9, 0)),
        now: now)!;
    expect(p['DurationInMs'], '${90 * 60000}');
    expect(p['DurationHours'], '1');
  });

  test('there is no request for a deadline that has passed, or is now', () {
    expect(
        TileShareForecastRequest.forTask(
            durationMs: hour, endMs: ms(DateTime(2026, 10, 1, 12, 0)), now: now),
        isNull);
    expect(
        TileShareForecastRequest.forTask(
            durationMs: hour, endMs: ms(now), now: now),
        isNull);
  });

  test('there is none without a duration or a deadline', () {
    expect(
        TileShareForecastRequest.forTask(
            durationMs: null, endMs: ms(DateTime(2026, 10, 4)), now: now),
        isNull);
    expect(
        TileShareForecastRequest.forTask(
            durationMs: hour, endMs: null, now: now),
        isNull);
  });
}
