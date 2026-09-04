// Phase 1 / Step 1.2 — RED: request-mapper parity (legacy vs new model).
//
// The legacy `AddTileState.onSubmitButtonTap()` mapping was extracted
// (behavior-preserving) into `NewTileRequestMapper.build(LegacyAddTileDraft)`
// in Step 0.1. Step 1.1 introduced the widget-independent draft model
// (`AddTileDraft` + `AddTileDraftSnapshot`). This step proves the NEW path —
// `NewTileRequestMapper.buildFromSnapshot(snapshot)` — produces the SAME
// `NewTile` wire payload as the legacy path for representative drafts.
//
// Each case builds the SAME logical draft two ways (a legacy snapshot and a
// new-model draft) and asserts deep equality of `toJson()`. This catches any
// field the snapshot/adapter drops or remaps. Per docs §8.2 the old mapping
// must not be removed until these parity tests pass; the legacy inline builder
// stays the reference.
//
// Colors are set explicitly in every parity case so `toJson()` is
// deterministic and comparable. The random-color fallback is covered separately
// in the 0.1 baseline (byteRange) and is intentionally excluded from the
// deep-equality set.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

DateTime get _now => DateTime(2026, 9, 4, 14, 30);
final _color = const Color(0xFF336699);

/// Builds the SAME logical draft as a legacy snapshot and as a new-model
/// draft, then asserts the two mappers emit identical wire payloads.
void _expectParity(
  String description,
  LegacyAddTileDraft legacy,
  AddTileDraft newDraft, {
  required DateTime now,
}) {
  // No randomizer needed: every parity case sets an explicit color on BOTH
  // sides, so the random-color fallback (the only nondeterministic path) is
  // never exercised and the two payloads are directly comparable.
  final NewTile legacyTile = NewTileRequestMapper.build(legacy);
  final NewTile newTile =
      NewTileRequestMapper.buildFromSnapshot(newDraft.snapshot, now: now);
  expect(
    newTile.toJson(),
    legacyTile.toJson(),
    reason:
        '$description — new mapper payload must equal legacy mapper payload',
  );
}

void main() {
  group('1.2 request mapper parity (legacy == new)', () {
    test('basic flexible tile (name + duration)', () {
      _expectParity(
        'basic flexible',
        LegacyAddTileDraft(
          isAppointment: false,
          name: 'Test Task',
          duration: Duration(minutes: 45),
          location: Location.fromDefault(),
          isAutoRevisable: true,
          priority: TilePriority.medium,
          color: _color,
          splitCount: '1',
          now: _now,
        ),
        AddTileDraft.flexible(
          now: _now,
          name: 'Test Task',
          duration: Duration(minutes: 45),
          location: Location.fromDefault(),
          color: _color,
        ),
        now: _now,
      );
    });

    test('no-deadline flexible tile (D1: Anytime, auto-revisable stays true)',
        () {
      _expectParity(
        'no-deadline flexible',
        LegacyAddTileDraft(
          isAppointment: false,
          name: 'No Deadline',
          duration: Duration(minutes: 30),
          // Real widget always holds the ghost location (addTile.dart:81);
          // the new model reproduces it via its no-preTile fallback.
          location: Location.fromDefault(),
          isAutoRevisable: true,
          priority: TilePriority.medium,
          color: _color,
          splitCount: '1',
          now: _now,
        ),
        AddTileDraft.flexible(
          now: _now,
          name: 'No Deadline',
          duration: Duration(minutes: 30),
          color: _color,
        ),
        now: _now,
      );
    });

    test(
        'fully configured flexible tile (deadline + repeat + location + restriction + priority + split)',
        () {
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

      _expectParity(
        'fully configured flexible',
        LegacyAddTileDraft(
          isAppointment: false,
          name: 'Deep Work',
          duration: Duration(minutes: 90),
          endTime: DateTime(2026, 9, 5, 17, 0),
          isAutoRevisable: true,
          priority: TilePriority.high,
          color: _color,
          location: location,
          repetitionData: repetition,
          restrictionProfile: profile,
          splitCount: '3',
          now: _now,
        ),
        AddTileDraft.flexible(
          now: _now,
          name: 'Deep Work',
          duration: Duration(minutes: 90),
          endTime: DateTime(2026, 9, 5, 17, 0),
          isAutoRevisable: true,
          priority: TilePriority.high,
          color: _color,
          location: location,
          repetitionData: repetition,
          restrictionProfile: profile,
          splitCount: 3,
        ),
        now: _now,
      );
    });

    test('basic fixed block (name + duration + start -> rigid, calculated end)',
        () {
      _expectParity(
        'basic fixed block',
        LegacyAddTileDraft(
          isAppointment: true,
          name: 'Standup',
          duration: Duration(minutes: 30),
          startTime: DateTime(2026, 9, 4, 9, 30),
          location: Location.fromDefault(),
          isAutoRevisable: true,
          priority: TilePriority.medium,
          color: _color,
          splitCount: '1',
          now: _now,
        ),
        AddTileDraft.fixed(
          now: _now,
          name: 'Standup',
          duration: Duration(minutes: 30),
          // New model has no explicit start setter param; set it user-style.
          color: _color,
        )..setUserStartTime(DateTime(2026, 9, 4, 9, 30)),
        now: _now,
      );
    });

    test(
        'repeating fixed block (start + duration + repeat; auto-revisable forced off)',
        () {
      final RepetitionData repetition = RepetitionData(
        frequency: RepetitionFrequency.weekly,
        repetitionEnd: DateTime(2026, 10, 15, 23, 59),
        weeklyRepetition: {1, 3, 5},
        isEnabled: true,
      );

      _expectParity(
        'repeating fixed block',
        LegacyAddTileDraft(
          isAppointment: true,
          name: 'Weekly Review',
          duration: Duration(minutes: 60),
          startTime: DateTime(2026, 9, 4, 9, 0),
          location: Location.fromDefault(),
          isAutoRevisable: true,
          priority: TilePriority.medium,
          color: _color,
          repetitionData: repetition,
          splitCount: '1',
          now: _now,
        ),
        AddTileDraft.fixed(
          now: _now,
          name: 'Weekly Review',
          duration: Duration(minutes: 60),
          isAutoRevisable: true,
          priority: TilePriority.medium,
          repetitionData: repetition,
          color: _color,
        )..setUserStartTime(DateTime(2026, 9, 4, 9, 0)),
        now: _now,
      );
    });

    test('flexible free-slot PreTile (start prefill ignored -> midnight start)',
        () {
      // `startTime` is a PreTile-mixin field (not a SimpleAdditionTile
      // constructor param), so it is set via a cascade.
      final pre = SimpleAdditionTile(
        description: 'Free Slot Task',
        duration: Duration(minutes: 20),
      )..startTime = DateTime(2026, 9, 4, 11, 0);

      _expectParity(
        'flexible PreTile start ignored',
        LegacyAddTileDraft(
          isAppointment: false,
          name: 'Free Slot Task',
          duration: Duration(minutes: 20),
          startTime: DateTime(2026, 9, 4, 11, 0),
          // PreTile carries no location => both sides hold null (parity with
          // the widget's `_location = preTile.location`).
          isAutoRevisable: true,
          priority: TilePriority.medium,
          color: _color,
          splitCount: '1',
          now: _now,
        ),
        AddTileDraft.flexible(now: _now, preTile: pre, color: _color),
        now: _now,
      );
    });

    test('fixed free-slot PreTile (start prefill honored)', () {
      final pre = SimpleAdditionTile(
        description: 'Prefilled Block',
        duration: Duration(minutes: 15),
      )..startTime = DateTime(2026, 9, 4, 13, 15);

      _expectParity(
        'fixed PreTile start honored',
        LegacyAddTileDraft(
          isAppointment: true,
          name: 'Prefilled Block',
          duration: Duration(minutes: 15),
          startTime: DateTime(2026, 9, 4, 13, 15),
          isAutoRevisable: true,
          priority: TilePriority.medium,
          color: _color,
          splitCount: '1',
          now: _now,
        ),
        AddTileDraft.fixed(now: _now, preTile: pre, color: _color),
        now: _now,
      );
    });
  });
}
