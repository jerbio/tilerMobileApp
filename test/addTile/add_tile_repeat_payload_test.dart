// D27 — `RepeatType` is the NUMERIC frequency, sent alongside the name.
//
// A captured web request sends BOTH fields, in different forms:
//   "RepeatType":"1", "RepeatFrequency":"Weekly"
// Mobile sent `frequency.name` for both, so `RepeatType` went up as "weekly".
// Product direction (2026-09-06): send both, like the web.
//
// The numeric value is the enum's declaration index —
// `{daily, weekly, monthly, yearly, none}` puts weekly at 1, matching the
// captured payload. Only weekly is confirmed by real data; the rest follow
// from the ordering, which is why every value is pinned here. If the backend
// ever disagrees for another frequency, this table is the thing to correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

DateTime get _now => DateTime(2026, 9, 6, 9, 0);

NewTile mapWithRepeat(RepetitionFrequency frequency, {Set<int>? days}) =>
    NewTileRequestMapper.build(LegacyAddTileDraft(
      isAppointment: false,
      name: 'test repetition',
      duration: const Duration(minutes: 10),
      repetitionData: RepetitionData(
        frequency: frequency,
        repetitionEnd: DateTime(2026, 12, 31),
        weeklyRepetition: days,
        isEnabled: true,
      ),
      color: const Color(0xFF336699),
      now: _now,
    ));

void main() {
  group('RepeatType is numeric, RepeatFrequency is the name', () {
    test('weekly matches the captured web payload', () {
      final tile = mapWithRepeat(RepetitionFrequency.weekly);
      expect(tile.RepeatType, '1', reason: 'web sends "RepeatType":"1"');
      expect(tile.RepeatFrequency, 'weekly',
          reason: 'the name still ships; the backend is case-insensitive');
    });

    test('every frequency maps to its declaration index', () {
      expect(mapWithRepeat(RepetitionFrequency.daily).RepeatType, '0');
      expect(mapWithRepeat(RepetitionFrequency.weekly).RepeatType, '1');
      expect(mapWithRepeat(RepetitionFrequency.monthly).RepeatType, '2');
      expect(mapWithRepeat(RepetitionFrequency.yearly).RepeatType, '3');
      expect(mapWithRepeat(RepetitionFrequency.none).RepeatType, '4');
    });

    test('the name is unchanged for every frequency', () {
      for (final f in RepetitionFrequency.values) {
        expect(mapWithRepeat(f).RepeatFrequency, f.name);
      }
    });
  });

  group('The rest of the repeat payload is untouched', () {
    test('weekly day data still ships comma-joined', () {
      final tile =
          mapWithRepeat(RepetitionFrequency.weekly, days: <int>{1, 3, 5});
      expect(tile.RepeatWeeklyData, '1,3,5',
          reason: 'matches the captured web payload exactly');
    });

    test('an explicit end still ships as year/month/day', () {
      final tile = mapWithRepeat(RepetitionFrequency.weekly);
      expect(tile.RepeatEndYear, '2026');
      expect(tile.RepeatEndMonth, '12');
      expect(tile.RepeatEndDay, '31');
    });

    test('no repetition ships no repeat fields at all', () {
      final tile = NewTileRequestMapper.build(LegacyAddTileDraft(
        isAppointment: false,
        name: 'no repeat',
        duration: const Duration(minutes: 10),
        color: const Color(0xFF336699),
        now: _now,
      ));
      expect(tile.RepeatType, isNull);
      expect(tile.RepeatFrequency, isNull);
      expect(tile.RepeatWeeklyData, isNull);
    });
  });
}
