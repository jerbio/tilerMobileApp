import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/freeSlot.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const int _minute = 60 * 1000;
const int _hour = 60 * _minute;

SubCalendarEvent _tile({
  required String id,
  required DateTime start,
  required DateTime end,
  double? travelTimeBefore,
}) {
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  t.travelTimeBefore = travelTimeBefore;
  return t;
}

// Base day used across tests; "now" is set explicitly per test.
DateTime _at(int hour, [int minute = 0]) =>
    DateTime(2026, 6, 28, hour, minute);

int _nowAt(int hour, [int minute = 0]) => _at(hour, minute).millisecondsSinceEpoch;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FreeSlot.detect — basic gap detection', () {
    test('no tiles yields no slots', () {
      expect(
        FreeSlot.detect(orderedTiles: const [], nowMs: _nowAt(8)),
        isEmpty,
      );
    });

    test('single tile yields no slots', () {
      final tiles = [_tile(id: 'a', start: _at(9), end: _at(10))];
      expect(
        FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(8)),
        isEmpty,
      );
    });

    test('two tiles with a qualifying gap yields one slot', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(10)),
        _tile(id: 'b', start: _at(12), end: _at(13)),
      ];

      final slots = FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(8));

      expect(slots, hasLength(1));
      expect(slots.first.startMs, _at(10).millisecondsSinceEpoch);
      expect(slots.first.endMs, _at(12).millisecondsSinceEpoch);
      expect(slots.first.duration, const Duration(hours: 2));
      expect(slots.first.isLive, isFalse);
    });

    test('gap shorter than the minimum is ignored', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(10)),
        // Only 20 min gap, below the 30 min default.
        _tile(id: 'b', start: _at(10, 20), end: _at(11)),
      ];

      expect(
        FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(8)),
        isEmpty,
      );
    });

    test('minDurationMs override is respected', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(10)),
        _tile(id: 'b', start: _at(10, 20), end: _at(11)),
      ];

      final slots = FreeSlot.detect(
        orderedTiles: tiles,
        nowMs: _nowAt(8),
        minDurationMs: 15 * _minute,
      );

      expect(slots, hasLength(1));
      expect(slots.first.duration, const Duration(minutes: 20));
    });
  });

  group('FreeSlot.detect — now clamping', () {
    test('gap entirely in the future is unclamped', () {
      final tiles = [
        _tile(id: 'a', start: _at(14), end: _at(15)),
        _tile(id: 'b', start: _at(17), end: _at(18)),
      ];

      final slots = FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(9));

      expect(slots, hasLength(1));
      expect(slots.first.startMs, _at(15).millisecondsSinceEpoch);
      expect(slots.first.isLive, isFalse);
    });

    test('gap straddling now is clamped to now and marked live', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(10)),
        _tile(id: 'b', start: _at(13), end: _at(14)),
      ];

      // now is inside the 10:00–13:00 gap.
      final slots = FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(11));

      expect(slots, hasLength(1));
      expect(slots.first.startMs, _nowAt(11));
      expect(slots.first.endMs, _at(13).millisecondsSinceEpoch);
      expect(slots.first.isLive, isTrue);
    });

    test('gap entirely in the past yields no slot', () {
      final tiles = [
        _tile(id: 'a', start: _at(6), end: _at(7)),
        _tile(id: 'b', start: _at(9), end: _at(10)),
      ];

      // now is after the whole gap.
      expect(
        FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(15)),
        isEmpty,
      );
    });

    test('clamped remainder shorter than minimum is dropped', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(10)),
        _tile(id: 'b', start: _at(11), end: _at(12)),
      ];

      // now leaves only 20 min until the next tile.
      expect(
        FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(10, 40)),
        isEmpty,
      );
    });
  });

  group('FreeSlot.detect — travel and overlaps', () {
    test('travel time before the next tile is subtracted from the window', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(10)),
        _tile(
          id: 'b',
          start: _at(12),
          end: _at(13),
          travelTimeBefore: (30 * _minute).toDouble(),
        ),
      ];

      final slots = FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(8));

      expect(slots, hasLength(1));
      expect(slots.first.startMs, _at(10).millisecondsSinceEpoch);
      // 12:00 minus 30 min travel.
      expect(slots.first.endMs, _at(11, 30).millisecondsSinceEpoch);
      expect(slots.first.duration, const Duration(hours: 1, minutes: 30));
    });

    test('overlapping tiles use the running end so no phantom gap appears', () {
      final tiles = [
        _tile(id: 'a', start: _at(9), end: _at(13)),
        // Starts during a, ends before a — fully contained.
        _tile(id: 'b', start: _at(10), end: _at(11)),
        _tile(id: 'c', start: _at(14), end: _at(15)),
      ];

      final slots = FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(8));

      // Only the 13:00–14:00 window after the running end of a.
      expect(slots, hasLength(1));
      expect(slots.first.startMs, _at(13).millisecondsSinceEpoch);
      expect(slots.first.endMs, _at(14).millisecondsSinceEpoch);
    });

    test('tiles at or beyond 16h are excluded from gap detection', () {
      final tiles = [
        // 16h all-day style tile — excluded.
        _tile(id: 'allday', start: _at(0), end: _at(16)),
        _tile(id: 'a', start: _at(9), end: _at(10)),
        _tile(id: 'b', start: _at(12), end: _at(13)),
      ];

      final slots = FreeSlot.detect(orderedTiles: tiles, nowMs: _nowAt(8));

      // The all-day tile is ignored, leaving the 10:00–12:00 gap between a and b.
      expect(slots, hasLength(1));
      expect(slots.first.startMs, _at(10).millisecondsSinceEpoch);
      expect(slots.first.endMs, _at(12).millisecondsSinceEpoch);
    });
  });
}
