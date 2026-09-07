// Step 3.2 — Fixed Block secondary controls.
//
// The gap this closes: a Fixed Block could not be made to REPEAT at all.
// `FixedBlockForm` declared an `onRepeatTap` and its own header comment said
// "Location and Repeat remain direct rows", but no Repeat row was ever built,
// so a recurring Block was unreachable in the redesign while the legacy flow
// supported one.
//
// The interesting part is the interaction with the derived interval. A Block's
// end is `start + duration`, and an enabled repetition otherwise overrides
// `endTime` with the recurrence end. The mapper resolves that ordering — the
// rigid branch runs last and restores the Block's own end — and these tests
// pin it, because a repeating Block whose end silently became "180 days from
// now" would be a data-corrupting bug that no screen would reveal.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRepeatScreen.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

final now = DateTime(2026, 9, 5, 14, 0);

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

Future<void> pumpShell(
  WidgetTester tester,
  Widget child, {
  Size viewSize = AddTileTestMatrix.standard,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ));
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

Future<void> expandMoreOptions(WidgetTester tester) async {
  final Finder header = find.byKey(const ValueKey('moreOptionsHeader'));
  await scrollTo(tester, header);
  await tester.tap(header);
  await tester.pumpAndSettle();
}

RepetitionData weekly() => RepetitionData(
      frequency: RepetitionFrequency.weekly,
      weeklyRepetition: <int>{1, 3, 5},
      repetitionEnd: DateTime(2027, 3, 5),
      isEnabled: true,
    );

void main() {
  group('Fixed Block — Repeat is reachable', () {
    testWidgets('the Fixed form renders a Repeat row', (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final Finder row = find.byKey(const ValueKey('repeatRow'));
      await scrollTo(tester, row);
      expect(row, findsOneWidget,
          reason: 'a Block that cannot recur is a missing capability, not a '
              'styling gap');
    });

    testWidgets('the row summarizes the current recurrence', (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final Finder row = find.byKey(const ValueKey('repeatRow'));
      await scrollTo(tester, row);
      expect(
        find.descendant(of: row, matching: find.text('Does not repeat')),
        findsOneWidget,
      );

      draft.setRepetitionData(weekly());
      await tester.pumpAndSettle();
      await scrollTo(tester, row);
      expect(
        find.descendant(of: row, matching: find.text('Weekly')),
        findsOneWidget,
      );
    });

    testWidgets('tapping it opens the shared Repeat picker', (tester) async {
      // The same screen the Flexible flow uses — one picker, two entry
      // points, so the two modes cannot drift apart.
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final Finder row = find.byKey(const ValueKey('repeatRow'));
      await scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byType(AddTileRepeatScreen), findsOneWidget);
    });

    testWidgets('a chosen recurrence reaches the draft', (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final Finder row = find.byKey(const ValueKey('repeatRow'));
      await scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('repeatOption_daily')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repeatDone')));
      await tester.pumpAndSettle();

      expect(draft.repetitionData, isNotNull);
      expect(draft.repetitionData!.frequency, RepetitionFrequency.daily);
    });
  });

  group('Fixed Block — route results', () {
    testWidgets('backing out of Repeat leaves the recurrence untouched',
        (tester) async {
      // Back is not an answer. `RepeatPickerResult` exists precisely so a
      // dismissal is distinguishable from a confirmed "Does not repeat",
      // which is itself a real choice.
      final draft = AddTileDraft.fixed(now: now);
      draft.setRepetitionData(weekly());
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final Finder row = find.byKey(const ValueKey('repeatRow'));
      await scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(draft.repetitionData?.frequency, RepetitionFrequency.weekly);
      expect(draft.repetitionData!.weeklyRepetition, <int>{1, 3, 5});
    });

    testWidgets('a confirmed "Does not repeat" DOES clear it', (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      draft.setRepetitionData(weekly());
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final Finder row = find.byKey(const ValueKey('repeatRow'));
      await scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('repeatOption_doesNotRepeat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repeatDone')));
      await tester.pumpAndSettle();

      expect(draft.repetitionData, isNull);
    });

    testWidgets('Color round-trips from a Block', (tester) async {
      // Color is the one advanced control both modes share, so its route must
      // work identically from either.
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      final Finder row = find.byKey(const ValueKey('colorRow'));
      await scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('colorPreset_2')));
      await tester.pumpAndSettle();

      expect(draft.color, isNotNull);
    });
  });

  group('Fixed Block — type isolation', () {
    testWidgets('Flexible-only advanced controls never render for a Block',
        (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(find.byKey(const ValueKey('colorRow')), findsOneWidget,
          reason: 'Color is the one advanced control both types share');
      for (final String key in <String>[
        'priorityRow',
        'splitCountControl',
        'flexibleCompletionToggle',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing,
            reason: '$key is Flexible-only and must not render for a Block');
      }
    });

    testWidgets('Flexible-only primary controls never render for a Block',
        (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      expect(find.byKey(const ValueKey('preferredTimeAnytime')), findsNothing,
          reason: 'a Block happens at a fixed time, so a day-part preference '
              'has nothing to act on');
      expect(find.byKey(const ValueKey('completeByRow')), findsNothing);
    });

    testWidgets('a recurrence survives a round trip through Flexible',
        (tester) async {
      // `repeatSemanticsIdenticalAcrossModes` is what makes preserving it
      // correct rather than merely convenient — the mapper ships the same
      // repetition fields either way.
      final draft = AddTileDraft.fixed(now: now);
      draft.setRepetitionData(weekly());
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.text('Flexible Tile'));
      await tester.pumpAndSettle();
      expect(draft.repetitionData?.frequency, RepetitionFrequency.weekly);

      await tester.tap(find.text('Fixed Block'));
      await tester.pumpAndSettle();
      expect(draft.repetitionData?.frequency, RepetitionFrequency.weekly);
      expect(draft.repetitionData!.weeklyRepetition, <int>{1, 3, 5});
    });
  });

  group('Fixed Block — a repeating Block keeps its own interval', () {
    NewTile mapFixed({RepetitionData? repetition}) {
      final draft = AddTileDraft.fixed(now: now);
      draft.name = 'Standup';
      draft.setUserStartTime(DateTime(2026, 9, 5, 9, 0));
      draft.setUserDuration(const Duration(minutes: 30));
      if (repetition != null) draft.setRepetitionData(repetition);
      return NewTileRequestMapper.buildFromSnapshot(draft.snapshot, now: now);
    }

    test('End stays start + duration, NOT the recurrence end', () {
      // An enabled repetition overrides `endTime` with the recurrence end for
      // a flexible tile. For a Block that would silently move the Block's own
      // end months into the future — no screen would show it, and the tile
      // would be wrong on the server.
      final NewTile tile = mapFixed(repetition: weekly());

      expect(tile.Rigid, 'true');
      expect(tile.EndYear, '2026');
      expect(tile.EndMonth, '9');
      expect(tile.EndDay, '5');
      expect(tile.EndHour, '9');
      expect(tile.EndMinute, '30');
    });

    test('the recurrence window is still sent', () {
      final NewTile tile = mapFixed(repetition: weekly());

      expect(tile.RepeatFrequency, 'weekly');
      expect(tile.RepeatEndYear, '2027');
      expect(tile.RepeatEndMonth, '3');
      expect(tile.RepeatEndDay, '5');
      expect(tile.RepeatWeeklyData, '1,3,5');
    });

    test('a non-repeating Block is unchanged by this step', () {
      final NewTile tile = mapFixed();

      expect(tile.Rigid, 'true');
      expect(tile.RepeatFrequency, isNull);
      expect(tile.EndHour, '9');
      expect(tile.EndMinute, '30');
    });
  });
}
