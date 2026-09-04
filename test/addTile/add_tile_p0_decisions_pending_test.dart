// Phase 0 / Step 0.2 — Product & API decision gates.
//
// Decisions resolved at the Phase 1 checkpoint (owner PROD, 2026-09-04, see
// docs/add-tile-decision-log.md) are now EXECUTABLE assertions against the
// Step 1.1 draft model (`AddTileDraft`) and the existing `RepetitionData`
// default. Tests that cannot yet be exercised against production code (D10
// location-picker interaction contract -> Phase 4.1; O1 analytics send()
// no-op -> still a blocking finding) remain `skip`-ped with the decision id.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/util.dart';

void main() {
  final now = DateTime(2026, 9, 4, 9, 30);

  group('0.2 decision gates (resolved -> executable)', () {
    test('D1: no-deadline Flexible Tile is a valid draft (End* unset)', () {
      final d = AddTileDraft.flexible(now: now)
        ..name = 'Think about things'
        ..setUserDuration(const Duration(minutes: 30));
      expect(d.endTime, isNull,
          reason: 'Complete by: Anytime leaves the deadline unset');
      expect(d.isValid, isTrue,
          reason: 'D1 accepted: no-deadline is valid; the mapper leaves End* '
              'unset + AutoReviseDeadline=true (characterized in Step 0.1)');
    });

    test('D2: dirty draft needs a close confirmation; pristine does not', () {
      final pristine = AddTileDraft.flexible(now: now);
      expect(pristine.needsCloseConfirmation, isFalse);

      final edited = AddTileDraft.flexible(now: now)
        ..setUserDuration(const Duration(minutes: 45));
      expect(edited.needsCloseConfirmation, isTrue,
          reason: 'D2 accepted: meaningful user edit -> confirm before close');
    });

    test('D3: Repeat is preserved across a type switch (identical semantics)',
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
      expect(d.repetitionData, isNotNull,
          reason: 'D3 accepted: identical recurrence semantics -> preserve, '
              'no destructive clear');
    });

    test('D9: choosing a recurrence keeps the current end default', () {
      // The `RepetitionData` constructor is the single source of the
      // recurrence-end default, measured from the clock at construction;
      // D9 says we preserve it (180 days; 3650 for yearly) rather than
      // introduce a new control in v1.
      final weekly = RepetitionData(frequency: RepetitionFrequency.weekly);
      expect(weekly.repetitionEnd, isNotNull);
      expect(weekly.isForever, isTrue);
      final weeklyDays =
          weekly.repetitionEnd!.difference(Utility.currentTime()).inDays;
      expect(weeklyDays, inInclusiveRange(179, 180),
          reason: 'D9 accepted: default recurrence end ~180 days out');

      final yearly = RepetitionData(frequency: RepetitionFrequency.yearly);
      final yearlyDays =
          yearly.repetitionEnd!.difference(Utility.currentTime()).inDays;
      expect(yearlyDays, inInclusiveRange(3649, 3650),
          reason: 'D9 accepted: yearly default ~3650 days out');
    });
  });

  group('0.2 decision gates (resolved, executable test lands later)', () {
    test(
      'D10: Location row tap selects; CTA returns; favorite independent',
      () {
        // Product contract accepted 2026-09-04 (owner PROD). The executable
        // assertion is a widget test of the Location picker and ships in
        // Phase 4.1 — the draft model does not carry selection/favorite state.
        expect(true, isTrue,
            reason: 'D10 resolved; executable picker test deferred to 4.1.');
      },
      skip:
          'P1 D10 accepted — executable Location-picker test lands in Phase 4.1.',
    );

    test('O1: analytics baseline is actually emitted (send() is not a no-op)',
        () {
      // Still an OPEN, blocking finding: AnalysticsSignal.send() returns
      // "no-tag-set" before logging, so no Add Tile funnel event reaches
      // Firebase today. This test is the gate for re-enabling the signal path
      // (or a structured equivalent) with the allow-listed schema in
      // docs/add-tile-analytics-schema.md.
      expect(true, isTrue,
          reason:
              'Placeholder until O1 resolved: assert the Add Tile funnel event '
              'is delivered with structured, allow-listed properties.');
    },
        skip:
            'P0 O1 open — analytics send() is a no-op; baseline not queryable.');
  });
}
