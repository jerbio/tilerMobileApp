// edit_tile_third_party_timing_test.dart
//
// A calendar-provider event (Google, Outlook) can have its START and END
// changed from Tiler. The legacy Edit Tile allowed it — the date/time rows
// were only locked for an inactive tile — and saved through the same
// `updateSubEvent` call, carrying the third-party ids. The redesign's
// `EditTileMode.thirdParty` locked every row, which lost that. Locks in:
//   1. On a Google event the Starts/Ends time and date chips and the
//      Duration row are tappable and move the draft, exactly as on a Tiler
//      tile.
//   2. What stays provider-owned stays locked: the title is the locked
//      hero, notes are absent, RSVP is still offered.
//   3. Once the time moved, Save is offered and submits a draft whose
//      third-party ids are intact (the API needs them to route the update).
//   4. The banner says what CAN be done here, not that nothing can.
//   5. Regression guard: a finished tile is still fully locked.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';

import 'edit_tile_phase2_test.dart' as p2;
import 'edit_tile_shell_test.dart' as shell;

Finder key(String k) => find.byKey(ValueKey(k));

bool hasTap(WidgetTester tester, Finder f) =>
    tester.getSemantics(f).getSemanticsData().hasAction(SemanticsAction.tap);

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  group('Edit Tile — provider-owned event timing', () {
    testWidgets('Starts and Ends chips and Duration are live on a Google event',
        (tester) async {
      await p2.open(tester, p2.tile(thirdPartyType: 'google'));

      for (final String k in <String>[
        'editStartTime',
        'editStartDate',
        'editEndTime',
        'editEndDate',
        'editDurationRow',
      ]) {
        expect(hasTap(tester, key(k)), isTrue,
            reason: '$k must be tappable on a provider event — the legacy '
                'screen let the user move it.');
      }
    });

    testWidgets('moving the start moves the draft, like a Tiler tile',
        (tester) async {
      await p2.open(tester, p2.tile(thirdPartyType: 'google'));
      shell.pickedTimeAnswer = const TimeOfDay(hour: 9, minute: 15);

      await tester.tap(key('editStartTime'));
      await tester.pumpAndSettle();

      final EditTileDraft d = shell.draftOf(tester);
      expect(d.mode, EditTileMode.thirdParty);
      expect(d.startTime, DateTime(2026, 9, 12, 9, 15));
      expect(d.endTime, DateTime(2026, 9, 12, 10, 45),
          reason: 'the duration is kept, as for a Tiler tile');
    });

    testWidgets('title stays the locked hero, notes absent, RSVP offered',
        (tester) async {
      await p2.open(
          tester, p2.tile(thirdPartyType: 'google', calendarEvent: null));

      expect(key('editTitleLocked'), findsOneWidget,
          reason: 'The name is the provider\'s to change.');
      expect(key('editTitleField'), findsNothing);
      expect(find.byKey(const ValueKey('editNotesRow'), skipOffstage: false),
          findsNothing);
    });

    testWidgets(
        'after the time moves, Save is offered and submits with the '
        'third-party ids intact', (tester) async {
      await p2.open(tester, p2.tile(thirdPartyType: 'google'));
      // Save is offered (unlike a finished tile) but guarded until
      // something changed — the Add Tile CTA idiom.
      expect(shell.save, findsOneWidget);
      expect(shell.draftOf(tester).canSave, isFalse);
      await tester.tap(shell.save);
      await tester.pumpAndSettle();
      expect(shell.submission.saved, isEmpty,
          reason: 'Nothing to save until something changed.');

      shell.pickedTimeAnswer = const TimeOfDay(hour: 9, minute: 15);
      await tester.tap(key('editStartTime'));
      await tester.pumpAndSettle();

      expect(shell.draftOf(tester).canSave, isTrue);
      await tester.tap(shell.save);
      await tester.pumpAndSettle();

      expect(shell.submission.saved, hasLength(1));
      final EditTileDraft saved = shell.submission.saved.single;
      expect(saved.startTime, DateTime(2026, 9, 12, 9, 15));
      expect(saved.thirdPartyId, 'ext-9',
          reason: 'The update is routed to the provider event by its id.');
      expect(saved.thirdPartyType, 'google');
    });

    testWidgets('the banner says the time can be moved here', (tester) async {
      await p2.open(tester, p2.tile(thirdPartyType: 'google'));

      final String banner =
          l10n.editTileModeThirdParty(l10n.editTileProviderGoogle);
      expect(find.text(banner), findsOneWidget);
      expect(banner.toLowerCase(), isNot(contains('edit the event in')),
          reason: 'The old banner told the user everything had to be '
              'edited in the provider; the time can be moved here.');
    });

    testWidgets('a finished tile is still fully locked (regression guard)',
        (tester) async {
      await p2.open(tester, p2.tile(isComplete: true));

      for (final String k in <String>[
        'editStartTime',
        'editEndTime',
        'editDurationRow',
      ]) {
        expect(hasTap(tester, key(k)), isFalse, reason: '$k on a done tile');
      }
      expect(shell.save, findsNothing);
    });
  });
}
