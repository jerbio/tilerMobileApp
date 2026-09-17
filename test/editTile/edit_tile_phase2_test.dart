// Phase 2 — primary form parity with mockup 1.
//
//   2.1 Fixed-type rows and the Deadline row
//   2.2 The Actions card (Complete · Start now · Defer · Delete), with the
//       legacy option set per mode and the D2 rule for a dirty draft
//   2.3 (moved to Tile Detail, D19)
//   2.4 Notes, Suggestions and Progress re-hosted in kit cards
//
// The harness is the Step 1.4 one; fixtures here carry the extra flags
// (`isRecurring`, `calendarEvent`, lifecycle) that decide which rows show.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileActions.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';

import '../addTile/add_tile_widget_harness.dart';
import '../addTile/l10n_fixture.dart';
import 'edit_tile_shell_test.dart' as shell;

final DateTime start = shell.start;
final DateTime end = shell.end;
final DateTime calEnd = DateTime(2026, 9, 20, 23, 59);

SubCalendarEvent tile({
  bool isRigid = false,
  bool isRecurring = false,
  bool isProcrastinate = false,
  bool isComplete = false,
  bool isEnabled = true,
  String thirdPartyType = 'tiler',
  int split = 1,
  Map<String, dynamic>? calendarEvent,
  String? note,
  Map<String, dynamic>? repetition,
  Location? location,
  Map<String, dynamic>? uiConfig,
}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': 'sub-1',
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'calendarEventStart': start.millisecondsSinceEpoch,
      'calendarEventEnd': calEnd.millisecondsSinceEpoch,
      'splitCount': split,
      'thirdPartyType': thirdPartyType,
      'thirdPartyId': thirdPartyType == 'tiler' ? null : 'ext-9',
      'isRigid': isRigid,
      'isRecurring': isRecurring,
      'isProcrastinateEvent': isProcrastinate,
      'isComplete': isComplete,
      'isEnabled': isEnabled,
      'priority': 'medium',
      if (calendarEvent != null) 'calendarEvent': calendarEvent,
      if (note != null) 'blob': <String, dynamic>{'note': note},
      if (repetition != null) 'repetition': repetition,
      if (location != null)
        'location': <String, dynamic>{
          'description': location.description,
          'address': location.address,
          'isNull': false,
          'isDefault': false,
        },
      if (uiConfig != null) 'uiConfig': uiConfig,
    });

Map<String, dynamic> series(
        {int split = 22, int complete = 19, int deleted = 0}) =>
    <String, dynamic>{
      'id': 'cal-1',
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': calEnd.millisecondsSinceEpoch,
      'splitCount': split,
      'completeCount': complete,
      'deleteCount': deleted,
      'thirdPartyType': 'tiler',
    };

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> open(WidgetTester tester, SubCalendarEvent t) =>
    shell.pumpEdit(tester, tile: t);

Future<void> reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  // ------------------------------------------------------------------ 2.1
  group('2.1 Fixed rows and Deadline', () {
    testWidgets(
        'every tile has Starts and Ends, each with a time and a date control '
        '(D24)', (tester) async {
      // The web edit form: Starts [time ▾][date], Ends [time ▾][date].
      // No separate Date row, no two-step Start tap.
      for (final bool rigid in <bool>[true, false]) {
        await open(tester, tile(isRigid: rigid));
        for (final String k in <String>[
          'editStartTime',
          'editStartDate',
          'editEndTime',
          'editEndDate'
        ]) {
          expect(key(k), findsOneWidget, reason: 'rigid=$rigid: $k');
        }
        expect(key('editDateRow'), findsNothing);
        expect(key('editStartsRow'), findsNothing);
      }
    });

    testWidgets('Starts date moves the day and keeps the clock and duration',
        (tester) async {
      for (final bool rigid in <bool>[true, false]) {
        await open(tester, tile(isRigid: rigid));
        shell.pickedDateAnswer = DateTime(2026, 9, 14);
        await tester.tap(key('editStartDate'));
        await tester.pumpAndSettle();
        final EditTileDraft d = shell.draftOf(tester);
        expect(d.startTime, DateTime(2026, 9, 14, 14, 0), reason: '$rigid');
        expect(d.endTime, DateTime(2026, 9, 14, 15, 30), reason: '$rigid');
        expect(shell.pickedTimeSeed, isNull, reason: 'the day alone');
      }
    });

    testWidgets('Starts time moves the clock and keeps the day and duration',
        (tester) async {
      for (final bool rigid in <bool>[true, false]) {
        await open(tester, tile(isRigid: rigid));
        shell.pickedTimeAnswer = const TimeOfDay(hour: 9, minute: 15);
        await tester.tap(key('editStartTime'));
        await tester.pumpAndSettle();
        final EditTileDraft d = shell.draftOf(tester);
        expect(d.startTime, DateTime(2026, 9, 12, 9, 15), reason: '$rigid');
        expect(d.endTime, DateTime(2026, 9, 12, 10, 45), reason: '$rigid');
        expect(shell.pickedDateSeed, isNull, reason: 'the clock alone');
      }
    });

    testWidgets('Ends date moves the end alone; the start stays',
        (tester) async {
      await open(tester, tile());
      shell.pickedDateAnswer = DateTime(2026, 9, 13);
      await tester.tap(key('editEndDate'));
      await tester.pumpAndSettle();
      final EditTileDraft d = shell.draftOf(tester);
      expect(d.startTime, DateTime(2026, 9, 12, 14, 0));
      expect(d.endTime, DateTime(2026, 9, 13, 15, 30));
      expect(shell.pickedDateSeed, DateTime(2026, 9, 12, 15, 30),
          reason: 'seeded on the end');
    });

    testWidgets(
        'an end date before the start is held and reported, not '
        'silently fixed', (tester) async {
      await open(tester, tile());
      shell.pickedDateAnswer = DateTime(2026, 9, 11);
      await tester.tap(key('editEndDate'));
      await tester.pumpAndSettle();
      final EditTileDraft d = shell.draftOf(tester);
      expect(d.endTime, DateTime(2026, 9, 11, 15, 30));
      expect(d.invalidReason, EditTileInvalidReason.endNotAfterStart);
      expect(d.canSave, isFalse);
    });

    testWidgets(
        'Ends time keeps the end\'s own day; on the start\'s day an earlier '
        'clock rolls to the next day (D61)', (tester) async {
      await open(tester, tile());
      shell.pickedTimeAnswer = const TimeOfDay(hour: 1, minute: 0);
      await tester.tap(key('editEndTime'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).endTime, DateTime(2026, 9, 13, 1, 0));

      shell.pickedDateAnswer = DateTime(2026, 9, 15);
      await tester.tap(key('editEndDate'));
      await tester.pumpAndSettle();
      shell.pickedTimeAnswer = const TimeOfDay(hour: 9, minute: 0);
      await tester.tap(key('editEndTime'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).endTime, DateTime(2026, 9, 15, 9, 0),
          reason: 'a later day is kept as picked');
    });
    testWidgets('the Deadline row shows only for a recurring tile',
        (tester) async {
      await open(tester, tile());
      expect(key('editDeadlineRow'), findsNothing);
      await open(tester, tile(isRecurring: true));
      await reveal(tester, key('editDeadlineRow'));
      expect(key('editDeadlineRow'), findsOneWidget);
    });

    testWidgets('a picked deadline is the END of that day', (tester) async {
      // "Complete by Friday" means the end of Friday (Add Tile D-rule).
      await open(tester, tile(isRecurring: true));
      await reveal(tester, key('editDeadlineRow'));
      shell.pickedDateAnswer = DateTime(2026, 9, 25);
      await tester.tap(key('editDeadlineRow'));
      await tester.pumpAndSettle();
      expect(shell.pickedDateSeed, calEnd);
      expect(shell.draftOf(tester).deadline,
          deadlineForPickedDay(DateTime(2026, 9, 25)));
    });
  });

  // ------------------------------------------------------------------ 2.2
  group('2.2 Actions', () {
    test('the option set reproduces the legacy playbackOptions logic', () {
      EditTileDraft d(SubCalendarEvent t) => EditTileDraft.fromLoaded(t);
      expect(editTileActionsFor(d(tile())), <EditTileAction>[
        EditTileAction.complete,
        EditTileAction.startNow,
        EditTileAction.defer,
        EditTileAction.delete,
      ]);
      expect(editTileActionsFor(d(tile(isProcrastinate: true))),
          <EditTileAction>[EditTileAction.complete, EditTileAction.delete],
          reason:
              'legacy removed Procrastinate and Now for a blocked-out tile');
      expect(editTileActionsFor(d(tile(thirdPartyType: 'google'))),
          <EditTileAction>[EditTileAction.delete],
          reason: 'legacy: a provider tile can only be deleted');
      expect(editTileActionsFor(d(tile(isComplete: true))),
          <EditTileAction>[EditTileAction.delete],
          reason: 'D9: a completed tile may still be deleted (legacy hid all)');
      expect(editTileActionsFor(d(tile(isEnabled: false))),
          <EditTileAction>[EditTileAction.delete]);
    });

    testWidgets('renders the four tiles for a live tile', (tester) async {
      await open(tester, tile());
      await reveal(tester, key('editActions'));
      for (final EditTileAction a in EditTileAction.values) {
        expect(key('editAction_${a.name}'), findsOneWidget);
      }
    });

    testWidgets('Complete confirms, then calls the endpoint and pops',
        (tester) async {
      await open(tester, tile());
      await reveal(tester, key('editActions'));
      await tester.tap(key('editAction_complete'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Write report'), findsWidgets,
          reason: 'the confirmation names the tile');

      await tester.tap(key('editActionConfirm'));
      await tester.pumpAndSettle();
      expect(shell.submission.actions, <String>['complete:sub-1']);
      expect(shell.screen, findsNothing);
    });

    testWidgets('cancelling the confirmation does nothing', (tester) async {
      await open(tester, tile());
      await reveal(tester, key('editActions'));
      await tester.tap(key('editAction_delete'));
      await tester.pumpAndSettle();
      await tester.tap(key('editActionCancel'));
      await tester.pumpAndSettle();
      expect(shell.submission.actions, isEmpty);
      expect(shell.screen, findsOneWidget);
    });

    testWidgets('a dirty draft is named as discarded (D2) and NOT saved',
        (tester) async {
      await open(tester, tile());
      await tester.enterText(shell.titleField, 'Edited');
      await tester.pump();
      await reveal(tester, key('editActions'));
      await tester.tap(key('editAction_startNow'));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.editTileActionDiscardsEdits), findsOneWidget);

      await tester.tap(key('editActionConfirm'));
      await tester.pumpAndSettle();
      expect(shell.submission.actions, <String>['startNow:sub-1']);
      expect(shell.submission.saved, isEmpty,
          reason: 'as today: an action never issues a save');
    });

    testWidgets('Defer asks for a duration after confirming', (tester) async {
      await open(tester, tile());
      await reveal(tester, key('editActions'));
      shell.pickedDurationAnswer = const Duration(hours: 2);
      await tester.tap(key('editAction_defer'));
      await tester.pumpAndSettle();
      await tester.tap(key('editActionConfirm'));
      await tester.pumpAndSettle();
      expect(shell.pickedDurationStart, isNull,
          reason: 'a deferral is a length, not an end time');
      expect(shell.submission.actions, <String>['defer:sub-1:120']);
      expect(shell.screen, findsNothing);
    });

    testWidgets('a failed action keeps the screen and says so', (tester) async {
      await open(tester, tile());
      await reveal(tester, key('editActions'));
      shell.submission.actionAnswer =
          const EditTileSaveResult.failure(editTileFailureNetwork);
      await tester.tap(key('editAction_complete'));
      await tester.pumpAndSettle();
      await tester.tap(key('editActionConfirm'));
      await tester.pumpAndSettle();
      expect(shell.screen, findsOneWidget);
      expect(find.text(testL10n.editTileActionFailed), findsOneWidget);
    });

    testWidgets('each action tile is an activatable button (D62)',
        (tester) async {
      await open(tester, tile());
      await reveal(tester, key('editActions'));
      final SemanticsHandle h = tester.ensureSemantics();
      for (final EditTileAction a in EditTileAction.values) {
        expect(tester.getSemantics(key('editAction_${a.name}')),
            matchesSemantics(isButton: true, hasTapAction: true),
            reason: a.name);
      }
      h.dispose();
    });
  });

  // ------------------------------------------------------------------ 2.4
  group('2.4 Notes, Suggestions, Progress', () {
    testWidgets('Notes are hosted for a Tiler tile, hidden for a provider tile',
        (tester) async {
      await open(tester, tile(note: 'bring the charts'));
      await reveal(tester, key('editNotesRow'));
      expect(key('editNotesRow'), findsOneWidget);
      await open(tester, tile(thirdPartyType: 'google'));
      expect(find.byKey(const ValueKey('editNotesRow'), skipOffstage: false),
          findsNothing);
    });

    testWidgets(
        'Suggestions render as rows and hand off to the REDESIGNED '
        'Add Tile with a prefill', (tester) async {
      shell.loader = shell.FakeLoader(EditTileLoadResult.success(
        tile(),
        <NextTileSuggestion>[
          NextTileSuggestion.fromJson(<String, dynamic>{'name': 'Review draft'})
        ],
      ));
      await shell.pumpEdit(tester, loadResult: shell.loader.result);
      await reveal(tester, key('editSuggestions'));
      expect(find.text('Review draft'), findsOneWidget);

      await tester.tap(find.text('Review draft'));
      await tester.pumpAndSettle();
      final RouteSettings pushed = shell.pushedRoutes.single;
      expect(pushed.name, '/AddTile');
      expect((pushed.arguments as Map)['preTile'], isNotNull);
      expect(
          ((pushed.arguments as Map)['preTile']).description, 'Review draft');
    });

    testWidgets('no suggestions → no section', (tester) async {
      await open(tester, tile());
      expect(key('editSuggestions'), findsNothing);
    });

    testWidgets('Progress shows the series counts for a flexible Tiler tile',
        (tester) async {
      await open(tester, tile(calendarEvent: series()));
      await reveal(tester, key('editProgress'));
      expect(
          find.text(testL10n.editTileProgressComplete(19, 22)), findsOneWidget);
      expect(
          find.text(testL10n.editTileProgressRemaining(3, 0)), findsOneWidget);
    });

    testWidgets('Progress is hidden for a block and when no series is loaded',
        (tester) async {
      await open(tester, tile(isRigid: true, calendarEvent: series()));
      expect(key('editProgress'), findsNothing);
      await open(tester, tile());
      expect(key('editProgress'), findsNothing);
    });
  });

  group('Narrow width', () {
    testWidgets('the full frame does not overflow at 320pt', (tester) async {
      await shell.pumpEdit(tester,
          tile: tile(isRecurring: true, calendarEvent: series(), note: 'n'),
          viewSize: AddTileTestMatrix.narrow);
      await reveal(tester, shell.save);
      expect(tester.takeException(), isNull);
    });
  });
}
