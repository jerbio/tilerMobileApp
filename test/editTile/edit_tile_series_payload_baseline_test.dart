// Step 0.2 — the field vocabulary, frozen.
//
// D15: the sub-event update accepts the same fields `CalendarEventApi
// .updateCalEvent` sends today — location, restriction, repetition, colour,
// duration, deadline automation — with the same names and value formats,
// plus `ApplicableOccurence` and `Priority`. `TileDetail` is the only
// producer of that map, so it is pinned here as the AUTHORITY the redesign's
// mapper reproduces for the new fields (Step 1.2), while `TileDetail` itself
// stays untouched (D1).
//
// Two kinds of pin: the scalar fields as literals, and the three structured
// fields (`RestrictiveWeek`, `RepetitionConfig`, `ColorConfig`) as
// "equals what the shared serialiser produces" — those serialisers are
// reused verbatim by the mapper, so the value that matters is that the map
// carries them under these keys, in these shapes, and nothing else.
//
// Quirks pinned deliberately (not endorsed):
//   * `Start`/`End` are epoch ms WITHOUT `.toUtc()` — unlike the sub-event
//     map. `millisecondsSinceEpoch` is zone-independent, so the wire value is
//     the same; the asymmetry is noted so nobody "harmonises" it blindly.
//   * absent optionals go out as the string "null" (`.toString()`), except
//     the nullable-aware ones (`?.toString()`) which go out as Dart `null`.
//   * `IsLocationCleared` is a bool, not a string, unlike every other flag.
//   * `Duration` appears only when `tileDuration` is set.
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/repetition.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tileColor.dart';
import 'package:tiler_app/data/uiConfig.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0); // 1789221600000
final DateTime end = DateTime.utc(2026, 9, 20, 23, 59); // 1789948740000

/// The series the way `TileDetail` seeds it from a loaded calendar event.
EditCalendarEvent series() => EditCalendarEvent()
  ..id = 'cal-1'
  ..name = 'Write report'
  ..splitCount = 3
  ..startTime = start
  ..endTime = end
  ..calStartTime = start
  ..calEndTime = end
  ..thirdPartyType = 'tiler'
  ..thirdPartyId = null
  ..thirdPartyUserId = null
  ..note = null
  ..isAutoDeadline = false
  ..isAutoReviseDeadline = true;

/// Built the way the Repeat picker builds one (via `RepetitionData`), so the
/// weekday spelling and the timeline come from the same code the redesign
/// will use.
Repetition weeklyMonWedFri() => Repetition.fromRepetitionData(RepetitionData(
      frequency: RepetitionFrequency.weekly,
      repetitionStart: start,
      repetitionEnd: end,
      weeklyRepetition: <int>{1, 3, 5},
      isEnabled: true,
    ));

void main() {
  group('updateCalEvent query map — frozen', () {
    test('a plain series, no location, no rule, no colour', () {
      expect(CalendarEventApi.updateCalEventParams(series()), {
        'EventID': 'cal-1',
        'EventName': 'Write report',
        'Start': '1789221600000',
        'End': '1789948740000',
        'Split': '3',
        'ThirdPartyEventID': 'null',
        'ThirdPartyUserID': 'null',
        'ThirdPartyType': 'tiler',
        'Notes': 'null',
        'IsAutoDeadline': 'false',
        'IsAutoReviseDeadline': 'true',
        // `?.toString()` → Dart null, not the string.
        'CalAddress': null,
        'CalAddressDescription': null,
        'IsCalAddressVerified': null,
        'IsLocationCleared': false,
        'RestrictionProfileId': null,
        'RestrictiveWeek': null,
        'RepetitionConfig': null,
        'ColorConfig': null,
      });
    });

    test('a location travels as CalAddress / CalAddressDescription / verified',
        () {
      final map = CalendarEventApi.updateCalEventParams(series()
        ..address = '482 sample ln #3, boulder, co 80301, usa'
        ..addressDescription = 'home'
        ..isAddressVerified = true);
      expect(map['CalAddress'], '482 sample ln #3, boulder, co 80301, usa');
      expect(map['CalAddressDescription'], 'home');
      expect(map['IsCalAddressVerified'], 'true');
      expect(map['IsLocationCleared'], false);
    });

    test('clearing the location is a separate boolean flag', () {
      final map =
          CalendarEventApi.updateCalEventParams(series(), clearLocation: true);
      expect(map['IsLocationCleared'], true,
          reason: 'a bool, not "true" — the one flag not stringified');
      expect(map['CalAddress'], isNull);
    });

    test('a repetition rule travels as RepetitionConfig in request form', () {
      final Repetition rule = weeklyMonWedFri();
      final map =
          CalendarEventApi.updateCalEventParams(series()..repetition = rule);
      expect(map['RepetitionConfig'], rule.toRequestJson());
      expect(map['RepetitionConfig'], {
        'IsEnabled': true,
        'IsForever': false,
        'RepetitionStart': 1789221600000,
        'RepetitionEnd': 1789948740000,
        'Frequency': 'weekly',
        'TileStart': null,
        'TileEnd': null,
        'DayOfWeekRepetitions': ['monday', 'wednesday', 'friday'],
      });
    });

    test('a colour travels as ColorConfig with an always-true IsEnabled', () {
      final map = CalendarEventApi.updateCalEventParams(series()
        ..uiConfig = (UIConfig.fromJson(<String, dynamic>{})
          ..tileColor = TileColor.fromColor(const Color(0xFFE91E63))));
      expect(map['ColorConfig'], {
        'IsEnabled': true,
        'Red': 233,
        'Green': 30,
        'Blue': 99,
        'Opacity': 1.0,
      });
    });

    test('a restriction profile travels twice: its id and its week config', () {
      final RestrictionProfile profile = RestrictionProfile.noRestriction()
        ..id = 'rp-7';
      final map = CalendarEventApi.updateCalEventParams(series()
        ..restrictionProfileId = 'rp-7'
        ..restrictionProfile = profile);
      expect(map['RestrictionProfileId'], 'rp-7');
      expect(
          map['RestrictiveWeek'], profile.toRestrictionWeekConfig()?.toJson());
      expect(map['RestrictiveWeek'], isNotNull);
    });

    test('Duration appears only when a tile duration is set', () {
      expect(
          CalendarEventApi.updateCalEventParams(series())
              .containsKey('Duration'),
          isFalse);
      final map = CalendarEventApi.updateCalEventParams(
          series()..tileDuration = const Duration(minutes: 90));
      expect(map['Duration'], '5400000');
    });

    test('no other keys exist — the vocabulary is closed', () {
      // The redesign copies THESE names; a key added here without a
      // decision would silently widen the contract.
      final map = CalendarEventApi.updateCalEventParams(
          series()..tileDuration = const Duration(minutes: 90));
      expect(map.keys.toSet(), <String>{
        'EventID',
        'EventName',
        'Start',
        'End',
        'Split',
        'ThirdPartyEventID',
        'ThirdPartyUserID',
        'ThirdPartyType',
        'Notes',
        'IsAutoDeadline',
        'IsAutoReviseDeadline',
        'CalAddress',
        'CalAddressDescription',
        'IsCalAddressVerified',
        'IsLocationCleared',
        'RestrictionProfileId',
        'RestrictiveWeek',
        'RepetitionConfig',
        'ColorConfig',
        'Duration',
      });
    });
  });
}
