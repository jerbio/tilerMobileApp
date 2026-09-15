// Phase 4 — modes, RSVP, what-if, load states.
//
//   4.1 Read-only and Procrastinate modes: a banner that says why the form
//       is limited, rows locked by ONE rule rather than per-widget flags
//   4.2 Third-party mode: source banner, the RSVP bar, Delete only
//   4.3 What-if preview: debounced, single-flight, stale results discarded,
//       one line under Timing, a sheet listing EVERY day's tiles;
//       4.3b: a clean answer and a failed check are each SAID, not silent
//   4.4 Load states: the skeleton and Retry are pinned in the shell tests;
//       here only that a failed load still offers Close
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/thirdPartyDecisionBar.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';

import '../addTile/l10n_fixture.dart';
import 'edit_tile_phase2_test.dart' as p2;
import 'edit_tile_shell_test.dart' as shell;

Finder key(String k) => find.byKey(ValueKey(k));

/// Every what-if surface the Timing section can show (4.3b).
const List<String> whatIfKeys = <String>[
  'editWhatIfPending',
  'editWhatIfLine',
  'editWhatIfClean',
  'editWhatIfFailed',
];

SubCalendarEvent thirdParty({String rsvp = 'needsAction'}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': 'sub-1',
      'name': 'Team sync',
      'start': shell.start.millisecondsSinceEpoch,
      'end': shell.end.millisecondsSinceEpoch,
      'calendarEventStart': shell.start.millisecondsSinceEpoch,
      'calendarEventEnd': shell.end.millisecondsSinceEpoch,
      'splitCount': 1,
      'thirdPartyType': 'google',
      'thirdPartyId': 'gcal-evt-9',
      'thirdPartyUserId': 'gcal-user-3',
      'rsvpStatus': rsvp,
      'priority': 'medium',
    });

Future<void> reveal(WidgetTester tester, Finder f) => p2.reveal(tester, f);

bool isButton(WidgetTester tester, Finder f) =>
    tester.getSemantics(f).getSemanticsData().hasAction(SemanticsAction.tap);

SubCalendarEvent lateTile(String id) => SubCalendarEvent.fromJson(
    <String, dynamic>{'id': id, 'name': id, 'thirdPartyType': 'tiler'});

void main() {
  // ------------------------------------------------------------------ 4.1
  group('4.1 Read-only mode', () {
    testWidgets('a completed tile: banner, locked rows, no Save, Delete only',
        (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile(isComplete: true));
      expect(key('editModeBanner'), findsOneWidget);
      expect(find.text(testL10n.editTileModeReadOnly), findsOneWidget);

      await reveal(tester, shell.durationRow);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(isButton(tester, shell.durationRow), isFalse,
          reason: 'a locked row is not a button');
      h.dispose();
      expect(shell.titleField, findsNothing,
          reason: 'the title is shown as a locked value, not a field');
      expect(find.byKey(const ValueKey('editTileSave'), skipOffstage: false),
          findsNothing);
      await reveal(tester, key('editActions'));
      expect(key('editAction_delete'), findsOneWidget);
      expect(key('editAction_complete'), findsNothing);
    });

    testWidgets('a disabled tile is read-only too', (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile(isEnabled: false));
      expect(find.text(testL10n.editTileModeReadOnly), findsOneWidget);
    });
  });

  group('4.1 Procrastinate mode', () {
    testWidgets('banner, fixed title, editable time, Save present',
        (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile(isProcrastinate: true));
      expect(find.text(testL10n.editTileModeProcrastinate), findsOneWidget);
      expect(shell.titleField, findsNothing);
      expect(find.text(testL10n.procrastinateBlockOut), findsWidgets);

      await reveal(tester, shell.durationRow);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(isButton(tester, shell.durationRow), isTrue);
      h.dispose();
      shell.pickedDurationAnswer = const Duration(hours: 2);
      await tester.tap(shell.durationRow);
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).canSave, isTrue);
      await reveal(tester, shell.save);
      expect(shell.save, findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ 4.2
  group('4.2 Third-party mode and RSVP', () {
    testWidgets('banner names the provider; rows locked; Delete only',
        (tester) async {
      await shell.pumpEdit(tester, tile: thirdParty());
      expect(
          find.text(
              testL10n.editTileModeThirdParty(testL10n.editTileProviderGoogle)),
          findsOneWidget);
      await reveal(tester, shell.durationRow);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(isButton(tester, shell.durationRow), isFalse);
      h.dispose();
      expect(shell.titleField, findsNothing);
      await reveal(tester, key('editActions'));
      expect(key('editAction_delete'), findsOneWidget);
      expect(key('editAction_startNow'), findsNothing);
    });

    testWidgets('the RSVP bar shows for an actionable status', (tester) async {
      await shell.pumpEdit(tester, tile: thirdParty());
      expect(find.byType(ThirdPartyDecisionBar), findsOneWidget);
      await shell.pumpEdit(tester, tile: thirdParty(rsvp: 'notApplicable'));
      expect(find.byType(ThirdPartyDecisionBar), findsNothing);
    });

    testWidgets('accepting sends the RSVP and reloads', (tester) async {
      await shell.pumpEdit(tester, tile: thirdParty());
      final ThirdPartyDecisionBar bar = tester
          .widget<ThirdPartyDecisionBar>(find.byType(ThirdPartyDecisionBar));
      bar.onAccept();
      await tester.pumpAndSettle();
      expect(shell.submission.actions, <String>['rsvp:gcal-evt-9:accepted']);
      expect(shell.loader.calls, 2, reason: 'the answer changes the tile');
      expect(shell.screen, findsOneWidget, reason: 'RSVP does not pop');
    });

    testWidgets('a failed RSVP shows its error on the bar', (tester) async {
      await shell.pumpEdit(tester, tile: thirdParty());
      shell.submission.actionAnswer =
          const EditTileSaveResult.failure(editTileFailureNetwork);
      tester
          .widget<ThirdPartyDecisionBar>(find.byType(ThirdPartyDecisionBar))
          .onDecline();
      await tester.pumpAndSettle();
      final ThirdPartyDecisionBar bar = tester
          .widget<ThirdPartyDecisionBar>(find.byType(ThirdPartyDecisionBar));
      expect(bar.errorText, testL10n.editTileRsvpFailed);
      expect(bar.isProcessing, isFalse);
    });
  });

  // ------------------------------------------------------------------ 4.3
  group('4.3 What-if preview', () {
    testWidgets('a time change previews once, after the debounce',
        (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewAnswer = WhatIfResult(
          tardy: <SubCalendarEvent>[lateTile('Gym')],
          overflow: const <SubCalendarEvent>[]);
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump();
      expect(shell.submission.previews, isEmpty, reason: 'not yet');
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      expect(shell.submission.previews, hasLength(1));
      await reveal(tester, key('editWhatIfLine'));
      expect(key('editWhatIfLine'), findsOneWidget);
      expect(find.text(testL10n.editTileWhatIfSummary(1, 0)), findsOneWidget);
    });

    testWidgets('a clean draft shows nothing at all', (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      for (final String k in whatIfKeys) {
        expect(key(k), findsNothing, reason: k);
      }
    });

    testWidgets('an empty result is a positive line, not silence (4.3b)',
        (tester) async {
      // The legacy screen cleared its button when nothing was affected,
      // which on device read as "the check vanished". A clean answer now
      // says so, and is not tappable: there is nothing to list.
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewAnswer = const WhatIfResult(
          tardy: <SubCalendarEvent>[], overflow: <SubCalendarEvent>[]);
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfClean'));
      expect(key('editWhatIfClean'), findsOneWidget);
      expect(find.text(testL10n.editTileWhatIfClean), findsOneWidget);
      expect(key('editWhatIfLine'), findsNothing);
      expect(key('editWhatIfFailed'), findsNothing);
      await tester.tap(key('editWhatIfClean'));
      await tester.pumpAndSettle();
      expect(key('editWhatIfSheet'), findsNothing);
    });

    testWidgets('the positive line gives way to the next check (4.3b)',
        (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewAnswer = const WhatIfResult(
          tardy: <SubCalendarEvent>[], overflow: <SubCalendarEvent>[]);
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfClean'));
      shell.submission.previewGates = <Completer<WhatIfResult?>>[
        Completer<WhatIfResult?>()
      ];
      shell.pickedDurationAnswer = const Duration(hours: 4);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pump();
      expect(key('editWhatIfClean'), findsNothing);
      expect(key('editWhatIfPending'), findsOneWidget);
    });

    testWidgets('a failed check says so and offers Retry (4.3b)',
        (tester) async {
      // Before 4.3b a failure and a clean answer were both silence.
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewAnswer = null; // the API seam's failure value
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfFailed'));
      expect(key('editWhatIfFailed'), findsOneWidget);
      expect(find.text(testL10n.editTileWhatIfFailed), findsOneWidget);
      expect(key('editWhatIfClean'), findsNothing);
      expect(key('editWhatIfLine'), findsNothing);
      expect(shell.submission.previews, hasLength(1));

      final Completer<WhatIfResult?> gate = Completer<WhatIfResult?>();
      shell.submission.previewGates = <Completer<WhatIfResult?>>[gate];
      await tester.tap(key('editWhatIfRetry'));
      await tester.pump();
      expect(shell.submission.previews, hasLength(2),
          reason: 'Retry runs at once, without the debounce');
      expect(key('editWhatIfPending'), findsOneWidget);
      gate.complete(WhatIfResult(
          tardy: <SubCalendarEvent>[lateTile('Gym')],
          overflow: const <SubCalendarEvent>[]));
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfLine'));
      expect(find.text(testL10n.editTileWhatIfSummary(1, 0)), findsOneWidget);
    });

    testWidgets('Retry is a button; the positive line is plain text (4.3b)',
        (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewAnswer = null;
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfRetry'));
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester.getSemantics(key('editWhatIfRetry')),
          matchesSemantics(
              isButton: true,
              hasTapAction: true,
              label: testL10n.editTileWhatIfRetry));
      h.dispose();
    });

    testWidgets('a name-only change does not preview', (tester) async {
      // The legacy screen previewed only time and split changes.
      await shell.pumpEdit(tester, tile: p2.tile());
      await tester.enterText(shell.titleField, 'Renamed');
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      expect(shell.submission.previews, isEmpty);
    });

    testWidgets('a stale result is discarded', (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      final Completer<WhatIfResult?> first = Completer<WhatIfResult?>();
      final Completer<WhatIfResult?> second = Completer<WhatIfResult?>();
      shell.submission.previewGates = <Completer<WhatIfResult?>>[first, second];

      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pump();
      shell.pickedDurationAnswer = const Duration(hours: 4);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pump();
      expect(shell.submission.previews, hasLength(2));

      // The NEWER answer lands first, then the older one arrives late.
      second.complete(WhatIfResult(
          tardy: <SubCalendarEvent>[lateTile('A'), lateTile('B')],
          overflow: const <SubCalendarEvent>[]));
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfLine'));
      expect(find.text(testL10n.editTileWhatIfSummary(2, 0)), findsOneWidget);
      first.complete(WhatIfResult(
          tardy: <SubCalendarEvent>[lateTile('Old')],
          overflow: const <SubCalendarEvent>[]));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.editTileWhatIfSummary(2, 0)), findsOneWidget,
          reason: 'the late, older answer must not overwrite the newer one');
    });

    testWidgets('the sheet lists every affected tile', (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewAnswer = WhatIfResult(
          tardy: <SubCalendarEvent>[lateTile('Gym'), lateTile('Laundry')],
          overflow: <SubCalendarEvent>[lateTile('Call mom')]);
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pumpAndSettle();
      await reveal(tester, key('editWhatIfLine'));
      await tester.tap(key('editWhatIfLine'));
      await tester.pumpAndSettle();
      expect(key('editWhatIfSheet'), findsOneWidget);
      // "Overflow", never "unscheduled" (D22).
      expect(find.text(testL10n.editTileWhatIfOverflow), findsOneWidget);
      expect(testL10n.editTileWhatIfSummary(2, 1).toLowerCase(),
          isNot(contains('unscheduled')));
      for (final String name in <String>['Gym', 'Laundry', 'Call mom']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('the preview never blocks Save', (tester) async {
      await shell.pumpEdit(tester, tile: p2.tile());
      shell.submission.previewGates = <Completer<WhatIfResult?>>[
        Completer<WhatIfResult?>()
      ];
      shell.pickedDurationAnswer = const Duration(hours: 3);
      await reveal(tester, shell.durationRow);
      await tester.tap(shell.durationRow);
      await tester.pump(editTileWhatIfDebounce);
      await tester.pump();
      await reveal(tester, shell.save);
      await tester.tap(shell.save);
      await tester.pump();
      expect(shell.submission.saved, hasLength(1));
    });
  });

  // ------------------------------------------------------------------ 4.4
  group('4.4 Load states', () {
    testWidgets('a failed load still offers Close', (tester) async {
      await shell.pumpEdit(tester,
          loadResult: const EditTileLoadResult.failure(editTileFailureNetwork));
      expect(key('editTileClose'), findsOneWidget);
      await tester.tap(key('editTileClose'));
      await tester.pumpAndSettle();
      expect(shell.screen, findsNothing);
    });
  });
}
