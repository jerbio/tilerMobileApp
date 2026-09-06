// Step 4.2 — the Repeat picker screen.
//
// Structure and interaction, against the Repeat mockup and the decisions it
// needed: Yearly kept (D22), Weekdays as a preset with no Custom row (D23),
// Sunday = 0 (D25), a range control the mockup does not draw (D26), and Back
// rather than Close (D12).
//
// The assertion that matters most is that the mockup's contradictory state —
// active weekday chips beside a selected "Does not repeat" — cannot be
// produced by any sequence of taps.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRepeatScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/repeatOptions.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

final DateTime now = DateTime(2026, 9, 6, 9, 0);

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

RepetitionData? _result;
bool _called = false;

Future<void> pumpRepeat(
  WidgetTester tester, {
  RepetitionData? initial,
  Size viewSize = AddTileTestMatrix.standard,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  _result = null;
  _called = false;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileRepeatScreen(
      now: now,
      initialRepetition: initial,
      onDone: (r) {
        _result = r;
        _called = true;
      },
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, RepeatOption option) async {
  await tester.tap(find.byKey(ValueKey('repeatOption_${option.name}')));
  await tester.pumpAndSettle();
}

/// Scrolls the range row into view. A ListView builds lazily, so with the Days
/// section present the row below it does not exist until reached.
Future<void> showRangeRow(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('repeatUntilRow')),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> done(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('repeatDone')));
  await tester.pumpAndSettle();
}

RepetitionData enabled(RepetitionFrequency f, {Set<int>? days}) =>
    RepetitionData(
      frequency: f,
      weeklyRepetition: days,
      repetitionEnd: DateTime(2026, 12, 31),
      isEnabled: true,
    );

void main() {
  group('The rows', () {
    testWidgets('shows six options, Yearly present and Custom absent',
        (tester) async {
      await pumpRepeat(tester);

      for (final option in RepeatOption.values) {
        expect(find.byKey(ValueKey('repeatOption_${option.name}')),
            findsOneWidget);
      }
      expect(find.text('Yearly'), findsOneWidget, reason: 'D22 keeps Yearly');
      expect(find.text('Custom'), findsNothing,
          reason: 'D23 drops Custom — Weekly already selects days');
    });

    testWidgets('defaults to Does not repeat when nothing is set',
        (tester) async {
      await pumpRepeat(tester);
      await done(tester);
      expect(_called, isTrue);
      expect(_result, isNull);
    });
  });

  group('Day chips appear only where they mean something', () {
    testWidgets('hidden for Does not repeat, Daily, Monthly and Yearly',
        (tester) async {
      await pumpRepeat(tester);
      for (final option in [
        RepeatOption.doesNotRepeat,
        RepeatOption.daily,
        RepeatOption.monthly,
        RepeatOption.yearly,
      ]) {
        await choose(tester, option);
        expect(find.byKey(const ValueKey('repeatDaysSection')), findsNothing,
            reason: '$option has no day dimension');
      }
    });

    testWidgets('the mockup contradiction is unreachable', (tester) async {
      // Pick days under Weekly, then switch to Does not repeat: the chips must
      // vanish, not linger alongside it as the mockup draws.
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekly);
      expect(find.byKey(const ValueKey('repeatDaysSection')), findsOneWidget);

      await choose(tester, RepeatOption.doesNotRepeat);
      expect(find.byKey(const ValueKey('repeatDaysSection')), findsNothing);

      await done(tester);
      expect(_result, isNull,
          reason: 'no stale day selection may survive into the result');
    });

    testWidgets('Weekdays shows the preset', (tester) async {
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekdays);

      expect(find.byKey(const ValueKey('repeatDaysSection')), findsOneWidget);
      await done(tester);
      expect(_result!.weeklyRepetition, <int>{1, 2, 3, 4, 5});
    });

    testWidgets(
        'editing a Weekdays chip drops to Weekly rather than doing '
        'nothing (device report 2026-09-06)', (tester) async {
      // The chips were inert on Weekdays, with nothing to say so — reported
      // as "cannot unselect the week days". A preset must be a shortcut, not
      // a dead end: touching it customises the selection, which BY
      // DEFINITION is no longer "weekdays".
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekdays);

      await tester.tap(find.byKey(const ValueKey('repeatDay_1')));
      await tester.pumpAndSettle();
      await done(tester);

      expect(_result!.frequency, RepetitionFrequency.weekly);
      expect(_result!.weeklyRepetition, <int>{2, 3, 4, 5},
          reason: 'Monday came off and the row became Weekly');
    });

    testWidgets('adding a weekend day to Weekdays also drops to Weekly',
        (tester) async {
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekdays);

      await tester.tap(find.byKey(const ValueKey('repeatDay_6')));
      await tester.pumpAndSettle();
      await done(tester);

      expect(_result!.weeklyRepetition, <int>{1, 2, 3, 4, 5, 6});
    });

    testWidgets('re-selecting exactly Mon-Fri reads back as Weekdays',
        (tester) async {
      // Round trip: leave the preset by editing, then return to it.
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekdays);
      await tester.tap(find.byKey(const ValueKey('repeatDay_6')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repeatDay_6')));
      await tester.pumpAndSettle();
      await done(tester);

      expect(_result!.weeklyRepetition, <int>{1, 2, 3, 4, 5});
      expect(repeatOptionOf(_result), RepeatOption.weekdays,
          reason: 'the set is the preset again, so it reads as Weekdays');
    });

    testWidgets('shown and editable for Weekly', (tester) async {
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekly);

      // Seeded from the preset; drop Tue and Thu to leave Mon/Wed/Fri.
      await tester.tap(find.byKey(const ValueKey('repeatDay_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repeatDay_4')));
      await tester.pumpAndSettle();
      await done(tester);

      expect(_result!.frequency, RepetitionFrequency.weekly);
      expect(_result!.weeklyRepetition, <int>{1, 3, 5},
          reason: 'Sunday = 0, so this is Mon/Wed/Fri — the captured payload');
    });

    testWidgets('the seven day chips sit on ONE row', (tester) async {
      // A week reads as a week only when it is a single row. An earlier
      // `Wrap` pushed Saturday onto a second line at phone widths, which read
      // on device as a broken control rather than as reflowed content.
      //
      // Pinned at the NARROWEST supported width: the default 800px test
      // viewport is wide enough that even the old Wrap fit on one line, so
      // this assertion only means something at a phone width.
      await pumpRepeat(tester, viewSize: AddTileTestMatrix.narrow);
      await choose(tester, RepeatOption.weekly);

      final List<Offset> centres = <Offset>[
        for (int i = 0; i < 7; i++)
          tester.getCenter(find.byKey(ValueKey('repeatDay_$i'))),
      ];

      for (int i = 1; i < 7; i++) {
        expect(centres[i].dy, closeTo(centres[0].dy, 0.5),
            reason: 'day $i wrapped onto another line');
        expect(centres[i].dx, greaterThan(centres[i - 1].dx),
            reason: 'day $i must sit to the right of day ${i - 1}');
      }
      expect(tester.takeException(), isNull,
          reason: 'the row must fit, not overflow');
    });

    testWidgets('Weekly cannot be emptied to a repetition that never occurs',
        (tester) async {
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekly);
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.byKey(ValueKey('repeatDay_$i')));
        await tester.pumpAndSettle();
      }
      await done(tester);

      expect(_result!.weeklyRepetition, isNotEmpty);
    });
  });

  group('Existing values are preserved', () {
    testWidgets('weekly + Mon-Fri reopens as Weekdays', (tester) async {
      await pumpRepeat(tester,
          initial: enabled(RepetitionFrequency.weekly, days: {1, 2, 3, 4, 5}));
      expect(find.byKey(const ValueKey('repeatDaysSection')), findsOneWidget);
      await done(tester);
      expect(_result!.weeklyRepetition, <int>{1, 2, 3, 4, 5});
    });

    testWidgets('weekly + an arbitrary set reopens as Weekly with those days',
        (tester) async {
      await pumpRepeat(tester,
          initial: enabled(RepetitionFrequency.weekly, days: {0, 6}));
      await done(tester);
      expect(_result!.weeklyRepetition, <int>{0, 6},
          reason: 'a weekend selection must survive a round trip');
    });

    testWidgets('an existing range is kept, not reset to the default',
        (tester) async {
      await pumpRepeat(tester, initial: enabled(RepetitionFrequency.daily));
      expect(find.text(DateFormat.yMMMd().format(DateTime(2026, 12, 31))),
          findsOneWidget);
      await done(tester);
      expect(_result!.repetitionEnd, DateTime(2026, 12, 31));
    });
  });

  group('Range control (D26)', () {
    testWidgets('is hidden for Does not repeat', (tester) async {
      await pumpRepeat(tester);
      expect(find.byKey(const ValueKey('repeatUntilRow')), findsNothing);
    });

    testWidgets('defaults to 180 days out for a weekly repeat', (tester) async {
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.weekly);
      // The Days section pushes the range row below the fold, and a ListView
      // does not build what it has not reached.
      await showRangeRow(tester);
      expect(
        find.text(
            DateFormat.yMMMd().format(now.add(const Duration(days: 180)))),
        findsOneWidget,
      );
    });

    testWidgets('shows yearly its own much longer default', (tester) async {
      // RepetitionData gives yearly 3650 days, not 180 — the control has to
      // reflect what will actually be sent.
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.yearly);
      await showRangeRow(tester);
      expect(
        find.text(
            DateFormat.yMMMd().format(now.add(const Duration(days: 3650)))),
        findsOneWidget,
      );
    });
  });

  group('Navigation (D12)', () {
    testWidgets('uses Back, never Close', (tester) async {
      await pumpRepeat(tester);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Done confirms rather than committing on first tap',
        (tester) async {
      await pumpRepeat(tester);
      await choose(tester, RepeatOption.daily);
      expect(_called, isFalse,
          reason: 'unlike Location, Repeat needs several taps before it is '
              'meaningful, so selection alone must not commit');

      await done(tester);
      expect(_called, isTrue);
      expect(_result!.frequency, RepetitionFrequency.daily);
    });
  });
}
