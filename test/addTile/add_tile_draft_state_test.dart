// Phase 1 / Step 1.1 — RED: AddTileDraft state-model contract.
//
// Behavior under test (docs/add-tile-redesign.md §6.1, §6.2, §6.4, §8.1):
//  * Explicit AddTileType.flexible/fixed replaces the isAppointment boolean.
//  * Defaults: flexible has NO guessed duration (visibly required); fixed
//    defaults to 30 minutes only when no prefill/suggestion supplies one.
//  * Validation by type: name non-empty + duration >= 1 minute (legacy
//    equivalence: legacy rejects inMinutes <= 0); fixed end is derived.
//  * Mode switch preserves shared values; mode-specific values go dormant,
//    are never discarded, and restore on switch back (§6.1 matrix).
//  * Dirty state (D2): dirty only when a USER-edited field differs from its
//    initial/prefilled value; suggestion-applied changes are not dirty.
//  * Stale suggestions (§6.4): rejected after a manual edit or disposal.
//  * D3: repeat is preserved across type switches (both modes carry
//    RepetitionData end-to-end, characterized in Step 0.1) — the confirm
//    path is exposed but not triggered in v1.
//  * A single immutable snapshot for request mapping (Step 1.2 input).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';

void main() {
  final now = DateTime(2026, 9, 4, 9, 30);
  final location = Location.fromDefault();

  group('1.1 AddTileDraft — defaults', () {
    test(
        'flexible defaults: empty name, zero duration (required, not guessed), Anytime, no restriction, auto-revisable, medium priority, split 1',
        () {
      final d = AddTileDraft.flexible(now: now);
      expect(d.type, AddTileType.flexible);
      expect(d.name, '');
      expect(d.duration, Duration.zero);
      expect(d.endTime, isNull, reason: 'null endTime == Complete by: Anytime');
      expect(d.restrictionProfile, isNull);
      expect(d.isAutoRevisable, isTrue);
      expect(d.priority, TilePriority.medium);
      expect(d.splitCount, 1);
      expect(d.repetitionData, isNull);
      expect(d.color, isNull);
      expect(d.startTime, now);
    });

    test(
        'fixed defaults: 30-minute duration only when no prefill, start = now, name empty',
        () {
      final d = AddTileDraft.fixed(now: now);
      expect(d.type, AddTileType.fixed);
      expect(d.duration, const Duration(minutes: 30));
      expect(d.startTime, now);
      expect(d.name, '');
    });

    test(
        'prefill overrides the 30-minute fixed default (name/duration/start/location)',
        () {
      final pre = SimpleAdditionTile(
        description: 'Call dentist',
        duration: const Duration(minutes: 90),
        location: location,
      )..startTime = DateTime(2026, 9, 5, 14, 0);
      final d = AddTileDraft.fixed(preTile: pre, now: now);
      expect(d.name, 'Call dentist');
      expect(d.duration, const Duration(minutes: 90));
      expect(d.startTime, DateTime(2026, 9, 5, 14, 0));
      expect(identical(d.location, location), isTrue);
    });

    test('flexible prefill does not invent a duration when preTile has none',
        () {
      final pre = SimpleAdditionTile(description: 'Think');
      final d = AddTileDraft.flexible(preTile: pre, now: now);
      expect(d.name, 'Think');
      expect(d.duration, Duration.zero,
          reason: '§5.2: do not silently submit a guessed duration');
    });
  });

  group('1.1 AddTileDraft — validation by type', () {
    test(
        'flexible: empty name and zero duration are invalid with stable reason codes',
        () {
      final d = AddTileDraft.flexible(now: now);
      final errors = d.validate();
      expect(errors['name'], 'name_empty');
      expect(errors['duration'], 'duration_invalid');
      expect(d.isValid, isFalse);
    });

    test(
        'flexible: one-minute duration is valid (legacy equivalence: legacy rejects inMinutes <= 0)',
        () {
      final d = AddTileDraft.flexible(now: now)..name = 'x';
      d.setUserDuration(const Duration(minutes: 1));
      expect(d.validate(), isEmpty);
      expect(d.isValid, isTrue);
    });

    test('flexible: no-deadline (Anytime) is valid per D1', () {
      final d = AddTileDraft.flexible(now: now)
        ..name = 'x'
        ..setUserDuration(const Duration(minutes: 30));
      expect(d.endTime, isNull);
      expect(d.isValid, isTrue,
          reason: 'D1 accepted: Complete by: Anytime is server-valid');
    });

    test('fixed: valid with name+duration; start always present', () {
      final d = AddTileDraft.fixed(now: now)..name = 'Standup';
      expect(d.isValid, isTrue);
      expect(d.startTime, now);
    });

    test('fixed: invalid duration (0 min) blocks even though end is derived',
        () {
      final d = (AddTileDraft.fixed(now: now)..name = 'Standup')
        ..setUserDuration(Duration.zero);
      expect(d.validate()['duration'], 'duration_invalid');
      expect(d.isValid, isFalse);
    });
  });

  group('1.1 AddTileDraft — calculated fixed end', () {
    test('end = start + duration, immediate and pure', () {
      final d = AddTileDraft.fixed(now: DateTime(2026, 9, 4, 9, 0))..name = 'x';
      expect(d.calculatedEnd, DateTime(2026, 9, 4, 9, 30));
      d.setUserDuration(const Duration(minutes: 45));
      expect(d.calculatedEnd, DateTime(2026, 9, 4, 9, 45));
      d.setUserStartTime(DateTime(2026, 9, 4, 9, 40));
      expect(d.calculatedEnd, DateTime(2026, 9, 4, 10, 25));
    });

    test('end crosses midnight/day rollover', () {
      final d = AddTileDraft.fixed(
          now: DateTime(2026, 9, 4, 23, 30)) // 30 min default
        ..name = 'x';
      expect(d.calculatedEnd, DateTime(2026, 9, 5, 0, 0));
    });
  });

  group('1.1 AddTileDraft — mode switch (§6.1 matrix)', () {
    test(
        'flexible -> fixed preserves name/duration/location/color/repeat; invalid duration becomes 30 min',
        () {
      final loc = Location.fromDefault();
      final rep = RepetitionData(
          frequency: RepetitionFrequency.weekly,
          repetitionStart: DateTime(2026, 9, 4),
          repetitionEnd: DateTime(2026, 10, 4),
          weeklyRepetition: {1},
          isEnabled: true);
      final d = AddTileDraft.flexible(
          now: now,
          name: 'Deep work',
          duration: Duration.zero,
          location: loc,
          color: const Color(0xFF123456),
          repetitionData: rep)
        ..setUserDuration(const Duration(minutes: 120));
      final locBefore = d.location;
      final repBefore = d.repetitionData;
      final endBefore = DateTime(2026, 9, 9);
      d.endTime = endBefore;

      d.switchToFixed();

      expect(d.type, AddTileType.fixed);
      expect(d.name, 'Deep work');
      expect(identical(d.location, locBefore), isTrue);
      expect(identical(d.repetitionData, repBefore), isTrue);
      expect(d.color, const Color(0xFF123456));
      expect(d.duration, const Duration(minutes: 120));
      // flexible-only values go dormant but are retained, not discarded:
      expect(d.endTime, endBefore);
    });

    test('flexible -> fixed with invalid (zero) duration adopts 30 minutes',
        () {
      final d = AddTileDraft.flexible(now: now, name: 'x');
      d.switchToFixed();
      expect(d.duration, const Duration(minutes: 30));
    });

    test(
        'fixed -> flexible restores dormant endTime/restriction/priority/split (never reset)',
        () {
      final prof = RestrictionProfile.noRestriction();
      final d = AddTileDraft.fixed(
        now: now,
        name: 'Review',
        endTime: DateTime(2026, 9, 10),
        restrictionProfile: prof,
        isAutoRevisable: false,
        priority: TilePriority.high,
        splitCount: 4,
      );
      d.switchToFlexible();
      expect(d.type, AddTileType.flexible);
      expect(d.name, 'Review');
      expect(d.endTime, DateTime(2026, 9, 10));
      expect(identical(d.restrictionProfile, prof), isTrue);
      expect(d.isAutoRevisable, isFalse);
      expect(d.priority, TilePriority.high);
      expect(d.splitCount, 4);
    });

    test(
        'D3: repeat with identical semantics in both modes => preserve (no confirmation required)',
        () {
      final d = AddTileDraft.flexible(
        now: now,
        repetitionData: RepetitionData(
          frequency: RepetitionFrequency.daily,
          repetitionStart: DateTime(2026, 9, 4),
          repetitionEnd: DateTime(2026, 10, 4),
        ),
      );
      expect(d.repeatSwitchDecision, RepeatSwitchDecision.preserve);
      d.switchToFixed();
      expect(d.repetitionData, isNotNull);
    });
  });

  group('1.1 AddTileDraft — dirty state (D2)', () {
    test('fresh draft is not dirty; needsCloseConfirmation is false', () {
      final d = AddTileDraft.flexible(now: now);
      expect(d.isDirty, isFalse);
      expect(d.needsCloseConfirmation, isFalse);
    });

    test('user edit makes the draft dirty', () {
      final d = AddTileDraft.flexible(now: now);
      d.setUserDuration(const Duration(minutes: 45));
      expect(d.isDirty, isTrue);
      expect(d.needsCloseConfirmation, isTrue);
    });

    test('user edit reverted to the initial value is not dirty', () {
      final d = AddTileDraft.fixed(now: now); // 30 min initial
      d.setUserDuration(const Duration(minutes: 60));
      expect(d.isDirty, isTrue);
      d.setUserDuration(const Duration(minutes: 30));
      expect(d.isDirty, isFalse);
    });

    test('suggestion-applied change is NOT a meaningful user edit (not dirty)',
        () {
      final d = AddTileDraft.flexible(now: now);
      expect(d.applySuggestedDuration(const Duration(minutes: 20)), isTrue);
      expect(d.duration, const Duration(minutes: 20));
      expect(d.isDirty, isFalse,
          reason: '§6.4/D2: app-driven suggestions are not meaningful edits');
    });
  });

  group('1.1 AddTileDraft — stale suggestion rejection (§6.4)', () {
    test('suggestions are rejected after the user manually edited the field',
        () {
      final d = AddTileDraft.flexible(now: now);
      d.setUserDuration(const Duration(minutes: 45));
      expect(d.applySuggestedDuration(const Duration(minutes: 90)), isFalse);
      expect(d.duration, const Duration(minutes: 45));
    });

    test('suggestions are rejected after disposal (stale async responses)', () {
      final d = AddTileDraft.flexible(now: now);
      d.dispose();
      expect(d.applySuggestedDuration(const Duration(minutes: 90)), isFalse);
    });

    test('canAcceptSuggestion reflects manual-edit + disposed state', () {
      final d = AddTileDraft.flexible(now: now);
      expect(d.canAcceptSuggestion(AddTileSuggestedField.duration), isTrue);
      d.setUserDuration(const Duration(minutes: 45));
      expect(d.canAcceptSuggestion(AddTileSuggestedField.duration), isFalse);
      expect(d.canAcceptSuggestion(AddTileSuggestedField.location), isTrue);
      d.dispose();
      expect(d.canAcceptSuggestion(AddTileSuggestedField.location), isFalse);
    });
  });

  group('1.1 AddTileDraft — snapshot (Step 1.2 input)', () {
    test('snapshot is a stable immutable view of the current draft', () {
      final d = AddTileDraft.fixed(now: now, name: 'Gym')
        ..setUserDuration(const Duration(minutes: 40));
      final s1 = d.snapshot;
      final s2 = d.snapshot;
      expect(s1, s2, reason: 'immutable snapshot is value-equal across calls');
      expect(s1.type, AddTileType.fixed);
      expect(s1.name, 'Gym');
      expect(s1.duration, const Duration(minutes: 40));
      expect(s1.startTime, now);
      expect(s1.calculatedEnd, DateTime(2026, 9, 4, 10, 10));
    });

    test(
        'snapshot captures flexible-only values even when dormant under fixed type',
        () {
      final d = AddTileDraft.flexible(
        now: now,
        name: 'Plan',
        duration: const Duration(minutes: 30),
        endTime: DateTime(2026, 9, 20),
        priority: TilePriority.low,
      );
      d.switchToFixed();
      final s = d.snapshot;
      expect(s.endTime, DateTime(2026, 9, 20));
      expect(s.priority, TilePriority.low);
      expect(s.splitCount, 1);
    });
  });
}
