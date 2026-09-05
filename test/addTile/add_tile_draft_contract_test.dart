// Behavioral contract tests for the Add Tile draft model and its request
// mapping. These assert observable behavior only (deadline handling, close
// confirmation, recurrence preservation and default end, live acceptance).
// No planning or decision-tracking artifacts are referenced here; the mapping
// between these behaviors and product decisions lives in the design docs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

void main() {
  final now = DateTime(2026, 9, 4, 9, 30);

  group('deadline handling', () {
    test('a Flexible Tile with no deadline is valid and leaves it unset', () {
      final d = AddTileDraft.flexible(now: now)
        ..name = 'Think about things'
        ..setUserDuration(const Duration(minutes: 30));
      expect(d.endTime, isNull,
          reason: 'a no-deadline (anytime) draft leaves the deadline unset');
      expect(d.isValid, isTrue,
          reason: 'no-deadline is a valid draft; the mapper leaves the end '
              'unset and keeps the deadline revisable');
    });
  });

  group('close confirmation', () {
    test(
        'a draft with meaningful edits asks for confirmation; pristine does not',
        () {
      final pristine = AddTileDraft.flexible(now: now);
      expect(pristine.needsCloseConfirmation, isFalse);

      final edited = AddTileDraft.flexible(now: now)
        ..setUserDuration(const Duration(minutes: 45));
      expect(edited.needsCloseConfirmation, isTrue,
          reason: 'a meaningful user edit should confirm before close');
    });
  });

  group('recurrence across type switches', () {
    test('recurrence is preserved across a type switch when semantics match',
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
          reason: 'identical recurrence semantics should be preserved, '
              'not cleared');
    });
  });

  group('recurrence end default', () {
    test('choosing a recurrence keeps the default recurrence end', () {
      // The RepetitionData constructor is the single source of the
      // recurrence-end default, measured from the clock at construction.
      final weekly = RepetitionData(frequency: RepetitionFrequency.weekly);
      expect(weekly.repetitionEnd, isNotNull);
      expect(weekly.isForever, isTrue);
      final weeklyDays =
          weekly.repetitionEnd!.difference(Utility.currentTime()).inDays;
      expect(weeklyDays, inInclusiveRange(179, 180),
          reason: 'the weekly recurrence end defaults to ~180 days out');

      final yearly = RepetitionData(frequency: RepetitionFrequency.yearly);
      final yearlyDays =
          yearly.repetitionEnd!.difference(Utility.currentTime()).inDays;
      expect(yearlyDays, inInclusiveRange(3649, 3650),
          reason: 'the yearly recurrence end defaults to ~3650 days out');
    });
  });

  group('live server acceptance (not run in CI)', () {
    // Proves the server accepts a no-deadline Flexible Tile. The offline wire
    // contract (a no-deadline Flexible Tile maps to a well-formed end-unset
    // payload) is covered by add_tile_no_deadline_wire_contract_test.dart;
    // this test proves the SERVER accepts it. It needs a valid auth session
    // and network, so it is excluded from CI by default.
    //
    // To run it once with valid credentials:
    //   $env:ADD_TILE_LIVE_ACCEPTANCE = '1';
    //   flutter test test/addTile/add_tile_draft_contract_test.dart --plain-name 'server accepts'
    // On a pass, record the outcome and date in the decision log and remove
    // the skip. On a rejection, treat it as a blocking finding for the
    // no-deadline default.
    test(
      'server accepts a no-deadline Flexible Tile',
      () async {
        final now = Utility.currentTime();
        final AddTileDraft draft = AddTileDraft.flexible(
          now: now,
          name: 'Live acceptance probe',
          duration: const Duration(minutes: 30),
          // Explicit color: deterministic, avoids the random-color fallback.
          color: const Color(0xFF336699),
        );
        final NewTile tile =
            NewTileRequestMapper.buildFromSnapshot(draft.snapshot, now: now);

        final ScheduleApi api = ScheduleApi(getContextCallBack: () {});
        final result = await api.addNewTile(tile);

        expect(result.item2, isNull,
            reason: 'the server must accept a no-deadline Flexible Tile '
                '(end unset, deadline revisable).');
        expect(result.item1, isNotNull,
            reason: 'a successful addNewTile returns the created event.');
      },
      skip: Platform.environment['ADD_TILE_LIVE_ACCEPTANCE'] == '1'
          ? null
          : 'live acceptance needs valid credentials + network; run with '
              'ADD_TILE_LIVE_ACCEPTANCE=1 (see test comment).',
    );
  });

  group('pending behaviors (dedicated tests land later)', () {
    test(
      'location picker: row tap selects, CTA returns, favorite independent',
      () {
        // The executable assertion is a widget test of the location picker; the
        // draft model does not carry selection/favorite state, so this
        // placeholder is skipped until that picker ships.
        expect(true, isTrue);
      },
      skip: 'location-picker selection contract is exercised by a dedicated '
          'widget test once the picker is implemented.',
    );

    test(
        'analytics: the add-item funnel event is emitted (send is not a no-op)',
        () {
      // Placeholder until the analytics signal path is re-enabled with the
      // allow-listed schema; the gate is to assert the funnel event is
      // delivered with structured, allow-listed properties.
      expect(true, isTrue);
    },
        skip:
            'analytics send() is currently a no-op; re-enable before asserting.');
  });
}
