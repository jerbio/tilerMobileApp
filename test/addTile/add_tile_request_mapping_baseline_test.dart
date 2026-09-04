// Phase 0 / Step 0.1 — Behavioral baseline (characterization).
//
// These tests pin the EXACT wire fields the legacy `AddTileState
// .onSubmitButtonTap()` produces for representative drafts. The mapping is
// extracted (behavior-preserving) into `NewTileRequestMapper` so it can be
// observed without a live widget, blocs, or API calls.
//
// The expected values below are derived from the original inline mapping
// (addTile.dart lines 1064-1159) BEFORE it is moved, so a faithful extraction
// passes and any divergence in wire semantics fails here.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

DateTime get _now => DateTime(2026, 9, 4, 14, 30);

void main() {
  group('0.1 request mapping baseline — Flexible Tile', () {
    test('basic flexible tile (name + duration only) maps to documented wire',
        () {
      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: false,
        name: 'Test Task',
        duration: Duration(minutes: 45),
        // Real widget default: _location = Location.fromDefault() (non-null).
        // Mirrors the as-is baseline, where a "ghost" location is always present.
        location: Location.fromDefault(),
        isAutoRevisable: true,
        priority: TilePriority.medium,
        splitCount: '1',
        now: _now,
      ));

      expect(tile.Name, 'Test Task');
      expect(tile.DurationMinute, '45');
      // Flexible: Rigid is never set.
      expect(tile.Rigid, isNull);
      // Flexible start = midnight of the submit day (Utility.currentTime).
      expect(tile.StartYear, '2026');
      expect(tile.StartMonth, '9');
      expect(tile.StartDay, '4');
      expect(tile.StartHour, '0');
      expect(tile.StartMinute, '0');
      // No deadline and no repetition => no End fields.
      expect(tile.EndYear, isNull);
      expect(tile.EndMonth, isNull);
      expect(tile.EndDay, isNull);
      expect(tile.EndHour, isNull);
      expect(tile.EndMinute, isNull);
      expect(tile.isEveryDay, 'false');
      expect(tile.isRestricted, 'false');
      expect(tile.isWorkWeek, 'false');
      expect(tile.AutoReviseDeadline, 'true');
      expect(tile.Priority, 'medium');
      expect(tile.Count, '1');
      expect(tile.ColorSelection, '-1');
      // BASELINE QUIRK (documented finding): the widget initializes _location to
      // Location.fromDefault(), which is NON-NULL. Location.fromDefault() sets
      // isDefault/latitude but NOT id/address/description/source/isVerified, so
      // the ghost location emits all-null location content and the STRING "null"
      // for LocationIsVerified. The current code therefore always sends
      // LocationIsVerified='null' even when the user never picks a location.
      expect(tile.LocationAddress, isNull);
      expect(tile.LocationTag, isNull);
      expect(tile.LocationSource, isNull);
      expect(tile.LocationId, isNull); // ghost location carries no id
      expect(tile.LocationIsVerified, 'null'); // string "null", always sent
      expect(tile.RestrictionProfileId, isNull);
    });

    test(
        'no-deadline flexible tile leaves End unset and stays auto-revisable (D1 baseline)',
        () {
      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: false,
        name: 'No Deadline',
        duration: Duration(minutes: 30),
        isAutoRevisable: true,
        priority: TilePriority.medium,
        splitCount: '1',
        now: _now,
      ));

      // "Complete by: Anytime" => _endTime is null => no End* sent.
      expect(tile.EndYear, isNull);
      expect(tile.EndMinute, isNull);
      expect(tile.AutoReviseDeadline, 'true');
    });

    test('fully configured flexible tile maps every wire field', () {
      final Location location = Location.fromDefault();
      location.id = 'loc-1';
      location.address = '123 Main St';
      location.description = 'Office';
      location.source = 'custom';
      location.isVerified = true;

      final RestrictionProfile profile =
          RestrictionProfile.everyDay(RestrictionTimeLine(
        start: TimeOfDay(hour: 9, minute: 0),
        duration: Duration(hours: 8),
      ));
      profile.id = 'profile-123';

      final RepetitionData repetition = RepetitionData(
        frequency: RepetitionFrequency.weekly,
        repetitionEnd: DateTime(2026, 10, 15, 23, 59),
        weeklyRepetition: {1, 3, 5},
        isEnabled: true,
      );

      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: false,
        name: 'Deep Work',
        duration: Duration(minutes: 90),
        // A deadline IS provided, but repetition overrides it for End*.
        endTime: DateTime(2026, 9, 5, 17, 0),
        isAutoRevisable: true,
        priority: TilePriority.high,
        color: const Color(0xFF336699),
        location: location,
        repetitionData: repetition,
        restrictionProfile: profile,
        splitCount: '3',
        now: _now,
      ));

      expect(tile.Name, 'Deep Work');
      expect(tile.DurationMinute, '90');
      expect(tile.Rigid, isNull);
      // Repetition end overrides the deadline for the End fields.
      expect(tile.EndYear, '2026');
      expect(tile.EndMonth, '10');
      expect(tile.EndDay, '15');
      expect(tile.EndHour, '23');
      expect(tile.EndMinute, '59');
      // Flexible start = midnight of the submit day.
      expect(tile.StartYear, '2026');
      expect(tile.StartHour, '0');
      expect(tile.StartMinute, '0');
      // Repetition present => auto-revisable forced false.
      expect(tile.AutoReviseDeadline, 'false');
      expect(tile.Priority, 'high');
      expect(tile.Count, '3');
      // Deterministic color round-trips to its byte values.
      expect(tile.RColor, '51');
      expect(tile.GColor, '102');
      expect(tile.BColor, '153');
      expect(tile.ColorSelection, '-1');
      // Location passthrough.
      expect(tile.LocationAddress, '123 Main St');
      expect(tile.LocationTag, 'Office');
      expect(tile.LocationId, 'loc-1');
      expect(tile.LocationSource, 'custom');
      expect(tile.LocationIsVerified, 'true');
      // Restriction profile passthrough.
      expect(tile.isRestricted, 'true');
      expect(tile.RestrictionProfileId, 'profile-123');
      expect(tile.RestrictiveWeek, isNotNull);
      // Repetition passthrough.
      expect(tile.RepeatFrequency, 'weekly');
      expect(tile.RepeatType, 'weekly');
      expect(tile.RepeatData, 'false');
      expect(tile.RepeatWeeklyData, '1,3,5');
      expect(tile.RepeatEndYear, '2026');
      expect(tile.RepeatEndMonth, '10');
      expect(tile.RepeatEndDay, '15');
    });

    test('random color fallback (no explicit color) emits in-range RGB', () {
      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: false,
        name: 'Random Color',
        duration: Duration(minutes: 30),
        isAutoRevisable: true,
        priority: TilePriority.medium,
        splitCount: '1',
        now: _now,
      ));

      expect(tile.RColor, byteRange());
      expect(tile.GColor, byteRange());
      expect(tile.BColor, byteRange());
      expect(tile.ColorSelection, '-1');
    });
  });

  group('0.1 request mapping baseline — Fixed Block', () {
    test('basic fixed block maps rigid interval with calculated end', () {
      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: true,
        name: 'Standup',
        duration: Duration(minutes: 30),
        startTime: DateTime(2026, 9, 4, 9, 30),
        isAutoRevisable: true,
        priority: TilePriority.medium,
        splitCount: '1',
        now: _now,
      ));

      expect(tile.Name, 'Standup');
      expect(tile.DurationMinute, '30');
      expect(tile.Rigid, 'true');
      expect(tile.StartYear, '2026');
      expect(tile.StartMonth, '9');
      expect(tile.StartDay, '4');
      expect(tile.StartHour, '9');
      expect(tile.StartMinute, '30');
      // End = start + duration (30 min) => 10:00.
      expect(tile.EndYear, '2026');
      expect(tile.EndMonth, '9');
      expect(tile.EndDay, '4');
      expect(tile.EndHour, '10');
      expect(tile.EndMinute, '0');
      expect(tile.AutoReviseDeadline, 'true');
      expect(tile.Count, '1');
    });

    test(
        'repeating fixed block: calculated end + repeat fields, auto-revisable forced off',
        () {
      final RepetitionData repetition = RepetitionData(
        frequency: RepetitionFrequency.weekly,
        repetitionEnd: DateTime(2026, 10, 15, 23, 59),
        weeklyRepetition: {1, 3, 5},
        isEnabled: true,
      );

      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: true,
        name: 'Weekly Review',
        duration: Duration(minutes: 60),
        startTime: DateTime(2026, 9, 4, 9, 0),
        isAutoRevisable: true,
        priority: TilePriority.medium,
        repetitionData: repetition,
        splitCount: '1',
        now: _now,
      ));

      expect(tile.Rigid, 'true');
      expect(tile.StartHour, '9');
      expect(tile.StartMinute, '0');
      // For a block, the calculated end = start + duration, NOT the repeat end.
      expect(tile.EndHour, '10');
      expect(tile.EndMinute, '0');
      expect(tile.EndDay, '4');
      // Repeat end is reported separately.
      expect(tile.RepeatEndYear, '2026');
      expect(tile.RepeatEndMonth, '10');
      expect(tile.RepeatEndDay, '15');
      expect(tile.RepeatFrequency, 'weekly');
      expect(tile.RepeatType, 'weekly');
      expect(tile.RepeatData, 'false');
      expect(tile.RepeatWeeklyData, '1,3,5');
      // Repetition present => auto-revisable forced false.
      expect(tile.AutoReviseDeadline, 'false');
    });
  });

  group('0.1 entry-point prefill characterization', () {
    test(
        'free-slot PreTile value-set (name+duration+startTime) for a flexible tile',
        () {
      // A free-slot PreTile populates description->name, duration, and startTime.
      // Baseline finding: for a FLEXIBLE tile the start prefill is ignored;
      // Start is always midnight of the submit day. It is honored only for
      // Fixed Blocks (see the Fixed Block group above).
      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: false,
        name: 'Free Slot Task',
        duration: Duration(minutes: 20),
        startTime: DateTime(2026, 9, 4, 11, 0),
        isAutoRevisable: true,
        priority: TilePriority.medium,
        splitCount: '1',
        now: _now,
      ));

      expect(tile.Name, 'Free Slot Task');
      expect(tile.DurationMinute, '20');
      expect(tile.Rigid, isNull);
      expect(tile.StartHour, '0');
      expect(tile.StartMinute, '0');
    });

    test(
        'empty-day default draft maps duration default to "0" (validation is UI-level)',
        () {
      // The widget initializes _duration to Duration.zero. The mapper is not a
      // validator; it emits whatever it is given. "0" minutes is blocked by
      // the UI's isSubmissionReady (>1 minute), not by the mapper.
      final NewTile tile = NewTileRequestMapper.build(AddTileDraft(
        isAppointment: false,
        name: '',
        duration: Duration.zero,
        isAutoRevisable: true,
        priority: TilePriority.medium,
        splitCount: '1',
        now: _now,
      ));

      expect(tile.Name, '');
      expect(tile.DurationMinute, '0');
    });
  });
}

// Matcher: a string that parses to an int in [0, 255].
Matcher byteRange() => _InRangeByte();

class _InRangeByte extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final int? value = int.tryParse(item as String? ?? '');
    return value != null && value >= 0 && value <= 255;
  }

  @override
  Description describe(Description description) =>
      description.add('an integer byte (0-255)');
}
