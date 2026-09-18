// Step 6.4 — the series sections on Tile Detail.
//
// Sessions (stepper), Repetition (row + detail + callout), Priority (cards
// + callout), Location (the Add Tile row: × / name / chevron), then under
// Additional Details: Colour, Preferred time (restriction profile), Notes
// (calendar scope). The widgets are the ones extracted from Edit Tile at
// 6.0 (`tileFormSections.dart`), keyed `detail*` here; the pickers are the
// shared Add Tile screens, scripted through seams.
//
// Every row obeys ONE locking rule (a finished or provider-owned series is
// read-only); a picker dismissed with Back changes nothing; a confirmed
// "none" (no repeat, automatic colour, anytime) is an answer.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/tileFormSections.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRepeatScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileTimeRestrictionScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';

import '../addTile/l10n_fixture.dart';
import 'tile_detail_draft_test.dart' as fx;
import 'tile_detail_shell_test.dart' as shell;

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

bool hasTap(WidgetTester tester, Finder f) =>
    tester.getSemantics(f).getSemanticsData().hasAction(SemanticsAction.tap);

/// A profile that is not one of the four simple day parts: 9–5 every day.
RestrictionProfile customProfile() =>
    RestrictionProfile(daySelection: <RestrictionDay?>[
      for (int i = 0; i < 7; i++)
        RestrictionDay(
          weekday: i,
          restrictionTimeLine: RestrictionTimeLine(
            start: const TimeOfDay(hour: 9, minute: 0),
            duration: const Duration(hours: 8),
            weekDay: i,
          ),
        ),
    ])
      ..id = 'rp-7'
      ..isEnabled = true;

void main() {
  // ------------------------------------------------------------ Sessions
  group('Sessions', () {
    testWidgets('a stepper for a flexible series; none for a block',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailSessionsPlus'));
      expect(find.byType(TileSessionsRow), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await shell.pumpDetail(tester, event: fx.loaded(isRigid: true));
      expect(find.byType(TileSessionsRow, skipOffstage: false), findsNothing);
    });

    testWidgets('plus and minus move the count, never below one',
        (tester) async {
      await shell.pumpDetail(tester, event: fx.loaded(split: 2));
      await reveal(tester, key('detailSessionsPlus'));
      await tester.tap(key('detailSessionsPlus'));
      await tester.pump();
      expect(shell.draftOf(tester).split, 3);
      await tester.tap(key('detailSessionsMinus'));
      await tester.pump();
      await tester.tap(key('detailSessionsMinus'));
      await tester.pump();
      expect(shell.draftOf(tester).split, 1);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester.getSemantics(key('detailSessionsMinus')),
          matchesSemantics(
              isButton: true, hasEnabledState: true, isEnabled: false),
          reason: 'one is the floor');
      h.dispose();
    });
  });

  // ---------------------------------------------------------- Repetition
  group('Repetition', () {
    testWidgets('the row summarises the rule, with detail and callout',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(repetition: fx.weeklyJson()));
      await reveal(tester, key('detailRepeatRow'));
      expect(key('detailRepeatDetail'), findsOneWidget);
      expect(key('detailRepeatCallout'), findsOneWidget);
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailRepeatRow'));
      expect(
          find.descendant(
              of: key('detailRepeatRow'),
              matching: find.text(testL10n.addTileRepeatNever)),
          findsOneWidget);
      expect(key('detailRepeatDetail'), findsNothing);
      expect(key('detailRepeatCallout'), findsNothing);
    });

    testWidgets('tap opens the picker on the rule; the answer is the rule',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(repetition: fx.weeklyJson()));
      await reveal(tester, key('detailRepeatRow'));
      shell.repeatAnswer = RepeatPickerResult(fx.weekly(days: <int>{2}));
      await tester.tap(key('detailRepeatRow'));
      await tester.pumpAndSettle();
      expect(shell.repeatSeed?.weeklyRepetition, <int>{1, 3, 5});
      expect(shell.draftOf(tester).repetition?.weeklyRepetition, <int>{2});
      expect(shell.draftOf(tester).canSave, isTrue);
    });

    testWidgets('Back changes nothing; a confirmed "does not repeat" clears',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(repetition: fx.weeklyJson()));
      await reveal(tester, key('detailRepeatRow'));
      shell.repeatAnswer = null;
      await tester.tap(key('detailRepeatRow'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).isDirty, isFalse);
      shell.repeatAnswer = const RepeatPickerResult(null);
      await tester.tap(key('detailRepeatRow'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).repetition, isNull);
      expect(shell.draftOf(tester).dirtyFields,
          <TileDetailField>{TileDetailField.repetition});
    });
  });

  // ------------------------------------------------------------ Deadline
  group('Deadline (2026-09-17)', () {
    testWidgets(
        'a non-repeating series shows its deadline; a date pick keeps '
        'the end of that day', (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailDeadlineRow'));
      expect(
          find.descendant(
              of: key('detailDeadlineRow'),
              matching: find.textContaining('Sep 20')),
          findsOneWidget);
      shell.pickedDateAnswer = DateTime(2026, 9, 25);
      await tester.tap(key('detailDeadlineRow'));
      await tester.pumpAndSettle();
      expect(shell.pickedDateSeed?.day, 20, reason: 'seeded on the deadline');
      final DateTime picked = shell.draftOf(tester).deadline!;
      expect(DateTime(picked.year, picked.month, picked.day),
          DateTime(2026, 9, 25));
      expect(picked.hour, 23, reason: 'the END of the picked day');
      expect(shell.draftOf(tester).canSave, isTrue);
    });

    testWidgets('a repeating series has no deadline row: its rule ends it',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(repetition: fx.weeklyJson()));
      await reveal(tester, key('detailRepeatRow'));
      expect(
          find.byKey(const ValueKey('detailDeadlineRow'), skipOffstage: false),
          findsNothing);
    });

    testWidgets(
        'no deadline reads Anytime; a pick sets one; × returns to Anytime '
        '(2026-09-17)', (tester) async {
      await shell.pumpDetail(tester, event: fx.loaded(noDeadline: true));
      await reveal(tester, key('detailDeadlineRow'));
      expect(
          find.descendant(
              of: key('detailDeadlineRow'),
              matching: find.text(testL10n.anytime)),
          findsOneWidget);
      expect(key('detailDeadlineClear'), findsNothing);
      shell.pickedDateAnswer = DateTime(2026, 9, 25);
      await tester.tap(key('detailDeadlineRow'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).deadline?.day, 25);
      expect(key('detailDeadlineClear'), findsOneWidget);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester.getSemantics(key('detailDeadlineClear')),
          matchesSemantics(
              isButton: true,
              hasTapAction: true,
              label: testL10n.addTileDeadlineClear));
      h.dispose();
      await tester.tap(key('detailDeadlineClear'));
      await tester.pump();
      expect(shell.draftOf(tester).deadline, isNull);
      expect(
          find.descendant(
              of: key('detailDeadlineRow'),
              matching: find.text(testL10n.anytime)),
          findsOneWidget);
    });

    testWidgets('a disabled rule shows Does not repeat AND the deadline row',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(repetition: <String, dynamic>{
            ...fx.weeklyJson(),
            'isEnabled': false,
          }));
      await reveal(tester, key('detailDeadlineRow'));
      expect(key('detailDeadlineRow'), findsOneWidget);
      await reveal(tester, key('detailRepeatRow'));
      expect(
          find.descendant(
              of: key('detailRepeatRow'),
              matching: find.text(testL10n.addTileRepeatNever)),
          findsOneWidget);
    });

    testWidgets('clearing the rule brings the deadline row back',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(repetition: fx.weeklyJson()));
      await reveal(tester, key('detailRepeatRow'));
      shell.repeatAnswer = const RepeatPickerResult(null);
      await tester.tap(key('detailRepeatRow'));
      await tester.pumpAndSettle();
      // The row sits ABOVE Repetition: scroll back up to it.
      await tester.scrollUntilVisible(key('detailDeadlineRow'), -120,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(key('detailDeadlineRow'), findsOneWidget);
    });

    testWidgets('a deadline before the start disables Save with the reason',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailDeadlineRow'));
      shell.pickedDateAnswer = DateTime(2026, 9, 1);
      await tester.tap(key('detailDeadlineRow'));
      await tester.pumpAndSettle();
      await reveal(tester, shell.save);
      expect(
          find.text(testL10n.editTileReasonEndNotAfterStart), findsOneWidget);
    });
  });

  // ------------------------------------------------------------ Priority
  group('Priority', () {
    testWidgets('the loaded priority is selected; a tap moves it',
        (tester) async {
      await shell.pumpDetail(tester, event: fx.loaded(priority: 'high'));
      await reveal(tester, key('detailPriority_high'));
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester.getSemantics(key('detailPriority_high')),
          matchesSemantics(
              isButton: true,
              hasTapAction: true,
              hasSelectedState: true,
              isSelected: true));
      h.dispose();
      await tester.tap(key('detailPriority_low'));
      await tester.pump();
      expect(shell.draftOf(tester).priority, TilePriority.low);
      expect(key('detailPriorityCallout'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------ Location
  group('Location', () {
    testWidgets('Not set → the picker; the answer becomes the place',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailLocationRow'));
      expect(
          find.descendant(
              of: key('detailLocationRow'),
              matching: find.text(testL10n.addTileValueNotSet)),
          findsOneWidget);
      expect(key('detailLocationClear'), findsNothing);
      shell.locationAnswer = fx.place('Work', '456 Market St');
      await tester.tap(key('detailLocationRow'));
      await tester.pumpAndSettle();
      expect(shell.locationSeed, isNull);
      expect(shell.draftOf(tester).location?.description, 'Work');
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('× clears a loaded place (a change the wire flags)',
        (tester) async {
      await shell.pumpDetail(tester,
          location: fx.place('Work', '456 Market St'));
      await reveal(tester, key('detailLocationRow'));
      await tester.tap(key('detailLocationClear'));
      await tester.pump();
      expect(shell.draftOf(tester).location, isNull);
      expect(shell.draftOf(tester).locationCleared, isTrue);
    });

    testWidgets('the name button opens the place editor seeded on the place',
        (tester) async {
      await shell.pumpDetail(tester,
          location: fx.place('Work', '456 Market St'));
      await reveal(tester, key('detailLocationRow'));
      shell.placeAnswer = fx.place('HQ', '456 Market St');
      await tester.tap(find.byType(NameLocationButton));
      await tester.pumpAndSettle();
      expect(shell.placeSeed?.description, 'Work');
      expect(shell.draftOf(tester).location?.description, 'HQ');
    });
  });

  // -------------------------------------------------------------- Colour
  group('Colour', () {
    testWidgets('Automatic / Custom; the picker seeds and sets',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailColorRow'));
      expect(find.text(testL10n.addTileColorAutomatic), findsOneWidget);
      shell.colorAnswer = const ColorChoice.chosen(Color(0xFF2196F3));
      await tester.tap(key('detailColorRow'));
      await tester.pumpAndSettle();
      expect(shell.colorSeed, isNull);
      expect(shell.draftOf(tester).color, const Color(0xFF2196F3));
      expect(find.text(testL10n.addTileColorCustom), findsOneWidget);
    });

    testWidgets('Back is not an answer; Automatic is', (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(color: const Color(0xFF2196F3)));
      await reveal(tester, key('detailColorRow'));
      shell.colorAnswer = const ColorChoice.none();
      await tester.tap(key('detailColorRow'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).isDirty, isFalse);
      shell.colorAnswer = const ColorChoice.automatic();
      await tester.tap(key('detailColorRow'));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).color, isNull);
      expect(shell.draftOf(tester).dirtyFields,
          <TileDetailField>{TileDetailField.color});
    });
  });

  // ------------------------------------------------------- Preferred time
  group('Preferred time (restriction profile)', () {
    testWidgets('reads Anytime with no profile; the route seeds and writes',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailRestrictionRow'));
      expect(
          find.descendant(
              of: key('detailRestrictionRow'),
              matching: find.text(testL10n.anytime)),
          findsOneWidget);
      shell.restrictionAnswer =
          TimeRestrictionResult(TimeRestrictionChoice.custom, customProfile());
      await tester.tap(key('detailRestrictionRow'));
      await tester.pumpAndSettle();
      expect(shell.restrictionSeed, isNull);
      expect(shell.draftOf(tester).restrictionProfile?.id, 'rp-7');
      expect(shell.draftOf(tester).dirtyFields,
          <TileDetailField>{TileDetailField.restriction});
      expect(
          find.descendant(
              of: key('detailRestrictionRow'),
              matching: find.text(testL10n.addTilePreferredTimeCustom)),
          findsOneWidget);
    });

    testWidgets('a dismissed route changes nothing; a written null is Anytime',
        (tester) async {
      await shell.pumpDetail(tester);
      final TileDetailDraft d = shell.draftOf(tester);
      d.setRestrictionProfile(customProfile());
      await tester.pump();
      await reveal(tester, key('detailRestrictionRow'));
      shell.restrictionAnswer = null;
      await tester.tap(key('detailRestrictionRow'));
      await tester.pumpAndSettle();
      expect(d.restrictionProfile?.id, 'rp-7');
      shell.restrictionAnswer =
          const TimeRestrictionResult(TimeRestrictionChoice.anytime, null);
      await tester.tap(key('detailRestrictionRow'));
      await tester.pumpAndSettle();
      expect(d.restrictionProfile, isNull);
    });
  });

  // --------------------------------------------------------------- Notes
  group('Notes (calendar scope)', () {
    testWidgets('a capped preview; tap opens the notes page for the series',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(note: 'bring the charts'));
      await reveal(tester, key('detailNotesRow'));
      expect(find.text('bring the charts'), findsWidgets);
      await tester.tap(key('detailNotesRow'));
      await tester.pumpAndSettle();
      expect(shell.openedNotes, <String>['cal-1:calendar:false']);
    });

    testWidgets('a persisted note is mirrored, and is never a change (D13)',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailNotesRow'));
      shell.notesPersistAnswer = 'new note';
      await tester.tap(key('detailNotesRow'));
      await tester.pumpAndSettle();
      expect(find.text('new note'), findsWidgets);
      expect(shell.draftOf(tester).isDirty, isFalse);
    });

    testWidgets('a finished series opens its notes read-only', (tester) async {
      await shell.pumpDetail(tester, event: fx.loaded(isComplete: true));
      await reveal(tester, key('detailNotesRow'));
      await tester.tap(key('detailNotesRow'));
      await tester.pumpAndSettle();
      expect(shell.openedNotes, <String>['cal-1:calendar:true']);
    });
  });

  // --------------------------------------------------------------- Locked
  group('One locking rule', () {
    testWidgets('a finished series: no row is tappable, the cards are inert',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(
              isComplete: true,
              repetition: fx.weeklyJson(),
              color: const Color(0xFF2196F3)),
          location: fx.place('Work', '456 Market St'));
      final SemanticsHandle h = tester.ensureSemantics();
      for (final String k in <String>[
        'detailRepeatRow',
        'detailLocationRow',
        'detailColorRow',
        'detailRestrictionRow',
        'detailPriority_low',
      ]) {
        await reveal(tester, key(k));
        expect(hasTap(tester, key(k)), isFalse, reason: k);
      }
      h.dispose();
      expect(key('detailLocationClear'), findsNothing);
      expect(find.byType(TileSessionsRow, skipOffstage: false), findsNothing);
    });

    testWidgets(
        'a finished non-repeating series: the deadline row is not tappable',
        (tester) async {
      await shell.pumpDetail(tester, event: fx.loaded(isComplete: true));
      await reveal(tester, key('detailDeadlineRow'));
      final SemanticsHandle h = tester.ensureSemantics();
      expect(hasTap(tester, key('detailDeadlineRow')), isFalse);
      h.dispose();
    });
  });

  // ------------------------------------------------------------- Save
  group('Save carries the sections', () {
    testWidgets('a rule, a priority and a place reach the submission',
        (tester) async {
      await shell.pumpDetail(tester);
      await reveal(tester, key('detailRepeatRow'));
      shell.repeatAnswer = RepeatPickerResult(fx.weekly());
      await tester.tap(key('detailRepeatRow'));
      await tester.pumpAndSettle();
      await reveal(tester, key('detailPriority_high'));
      await tester.tap(key('detailPriority_high'));
      await tester.pump();
      await reveal(tester, key('detailLocationRow'));
      shell.locationAnswer = fx.place('Work', '456 Market St');
      await tester.tap(key('detailLocationRow'));
      await tester.pumpAndSettle();
      await reveal(tester, shell.save);
      await tester.tap(shell.save);
      await tester.pumpAndSettle();
      expect(shell.submission.saved.single.dirtyFields, <TileDetailField>{
        TileDetailField.repetition,
        TileDetailField.priority,
        TileDetailField.location,
      });
    });
  });
}
