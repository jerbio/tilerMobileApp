// The Duration picker renders the END a block lands on (D61).
//
// The legacy `EndTimeDurationDial` took a start time and showed the dial
// together with the resulting end: turning the dial moved the end, and
// editing the end recomputed the duration. The redesign's Fixed form derives
// "Ends" on the form, but its picker was start-blind — a user setting a
// block's length could not see where it would finish without backing out.
//
// The picker stays SHARED: the start is optional, the Flexible flow passes
// none, and without one the screen is exactly what it was.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

final DateTime start = DateTime(2026, 9, 5, 14, 0);

Duration? _picked;

/// What the injected time picker will answer; null = dismissed.
TimeOfDay? _pickerAnswer;

/// The initial time the picker was opened with, for asserting seeding.
TimeOfDay? _pickerOpenedWith;

Future<void> pumpEndAware(
  WidgetTester tester, {
  DateTime? startTime,
  Duration initial = const Duration(minutes: 30),
}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.narrow);
  addTearDown(tester.view.reset);
  _picked = null;
  _pickerAnswer = null;
  _pickerOpenedWith = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileDurationScreen(
      initialDuration: initial,
      startTime: startTime,
      onSelected: (d) => _picked = d,
      pickEndTime: (BuildContext _, TimeOfDay initialTime) async {
        _pickerOpenedWith = initialTime;
        return _pickerAnswer;
      },
    ),
  ));
  await tester.pumpAndSettle();
  // The list builds lazily and the Ends card is the last thing in it, so
  // at a phone height it is below the fold until scrolled to.
  if (startTime != null) {
    await tester.scrollUntilVisible(endRow, 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }
}

Finder get endRow => find.byKey(const ValueKey('durationEndRow'));

/// Turns the wheel to [d] the way the dial would report it.
Future<void> turnWheelTo(WidgetTester tester, Duration d) async {
  tester
      .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
      .onChanged(d);
  await tester.pumpAndSettle();
}

/// The text of the Ends row's value, whitespace-normalised: `DateFormat.jm`
/// may separate the meridiem with a narrow no-break space.
String endValue(WidgetTester tester) {
  final Iterable<Text> texts = tester.widgetList<Text>(
      find.descendant(of: endRow, matching: find.byType(Text)));
  return texts
      .map((t) => t.data ?? '')
      .join(' | ')
      .replaceAll(' ', ' ')
      .replaceAll(' ', ' ');
}

String clock(DateTime t) =>
    formatClockTime(t).replaceAll(' ', ' ').replaceAll(' ', ' ');

void main() {
  group('The end a chosen clock time implies', () {
    test('a clock time after the start is that same day', () {
      expect(
        durationForPickedEnd(start, const TimeOfDay(hour: 16, minute: 0)),
        const Duration(hours: 2),
      );
    });

    test('a clock time at or before the start is the FOLLOWING day', () {
      // A block from 2 PM cannot end at 1 PM the same day, and the legacy
      // dial simply ignored such a pick. On a clock face, an earlier time
      // means tomorrow — which also lets a late block run past midnight.
      expect(
        durationForPickedEnd(start, const TimeOfDay(hour: 13, minute: 0)),
        const Duration(hours: 23),
      );
      expect(
        durationForPickedEnd(start, const TimeOfDay(hour: 14, minute: 0)),
        const Duration(hours: 24),
        reason: 'the same clock time is a full day, the picker ceiling',
      );
    });

    test('the implied duration lands on the five-minute grid', () {
      // 2:03 PM is 63 minutes: snapped to 65, not carried as-is, so the
      // Ends readout and the duration sent agree.
      expect(
        durationForPickedEnd(start, const TimeOfDay(hour: 15, minute: 3)),
        const Duration(minutes: 65),
      );
    });
  });

  group('Without a start the screen is unchanged', () {
    testWidgets('no Ends row is rendered', (tester) async {
      await pumpEndAware(tester);
      expect(endRow, findsNothing,
          reason: 'the Flexible flow has no start to derive an end from');
    });
  });

  group('With a start the screen shows where the block ends', () {
    testWidgets('the Ends row opens on start + duration', (tester) async {
      await pumpEndAware(tester, startTime: start);
      expect(endRow, findsOneWidget);
      expect(endValue(tester), contains(clock(DateTime(2026, 9, 5, 14, 30))));
    });

    testWidgets('turning the wheel moves the end', (tester) async {
      await pumpEndAware(tester, startTime: start);
      await turnWheelTo(tester, const Duration(hours: 2));
      expect(endValue(tester), contains(clock(DateTime(2026, 9, 5, 16, 0))));
    });

    testWidgets('an end past midnight says so', (tester) async {
      // 2 PM + 12 h is 2 AM — the same clock reading as "two in the
      // morning today", which would be BEFORE the start. The row has to
      // say which day it means.
      await pumpEndAware(tester, startTime: start);
      await turnWheelTo(tester, const Duration(hours: 12));
      expect(
        endValue(tester),
        contains(testL10n
            .addTileDurationEndsNextDay(clock(DateTime(2026, 9, 6, 2, 0)))),
      );
    });

    testWidgets('the row says which start it is measured from', (tester) async {
      await pumpEndAware(tester, startTime: start);
      final Finder heading = find
          .text(testL10n.addTileDurationEndsFromStart(formatClockTime(start)));
      expect(heading, findsOneWidget,
          reason: 'an end time with no visible anchor is just a number');
    });
  });

  group('Editing the end edits the duration', () {
    testWidgets('the time picker opens on the CURRENT end', (tester) async {
      await pumpEndAware(tester, startTime: start);
      await turnWheelTo(tester, const Duration(hours: 2));

      await tester.tap(endRow);
      await tester.pumpAndSettle();

      expect(_pickerOpenedWith, const TimeOfDay(hour: 16, minute: 0),
          reason: 'seeding from the start instead of the end would make '
              'every edit begin from scratch');
    });

    testWidgets('a picked end becomes the pending duration', (tester) async {
      await pumpEndAware(tester, startTime: start);
      _pickerAnswer = const TimeOfDay(hour: 17, minute: 30);

      await tester.tap(endRow);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
            .value,
        const Duration(hours: 3, minutes: 30),
        reason: 'the wheel must follow the edited end, as the legacy dial did',
      );
      expect(endValue(tester), contains(clock(DateTime(2026, 9, 5, 17, 30))));

      await tester.tap(find.byKey(const ValueKey('durationDone')));
      await tester.pumpAndSettle();
      expect(_picked, const Duration(hours: 3, minutes: 30));
    });

    testWidgets('dismissing the picker changes nothing', (tester) async {
      await pumpEndAware(tester, startTime: start);
      _pickerAnswer = null;

      await tester.tap(endRow);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DurationWheel>(find.byKey(const ValueKey('durationWheel')))
            .value,
        const Duration(minutes: 30),
      );
    });

    testWidgets('the row is announced with both ends of the interval',
        (tester) async {
      await pumpEndAware(tester, startTime: start);
      final SemanticsHandle handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(endRow),
        matchesSemantics(
          label: testL10n.addTileDurationEndsSemantics(
              formatClockTime(DateTime(2026, 9, 5, 14, 30)),
              formatClockTime(start)),
          hasTapAction: true,
          isButton: true,
        ),
      );
      handle.dispose();
    });
  });

  group('The shell hands the start to the picker', () {
    Future<void> pumpShell(WidgetTester tester, AddTileDraft draft) async {
      tester.view.physicalSize =
          AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localeResolutionCallback: _resolve,
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddTileRedesignScreen(draft: draft, now: start),
      ));
      await tester.pump();
    }

    Future<AddTileDurationScreen> openDuration(
        WidgetTester tester, String rowKey) async {
      final Finder row = find.byKey(ValueKey(rowKey));
      await tester.scrollUntilVisible(row, 120,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      return tester
          .widget<AddTileDurationScreen>(find.byType(AddTileDurationScreen));
    }

    testWidgets('a Fixed block opens the picker with its start',
        (tester) async {
      final draft = AddTileDraft.fixed(now: start);
      draft.setUserStartTime(DateTime(2026, 9, 5, 9, 15));
      await pumpShell(tester, draft);

      final AddTileDurationScreen screen =
          await openDuration(tester, 'fixedDurationRow');
      expect(screen.startTime, DateTime(2026, 9, 5, 9, 15));
    });

    testWidgets('a Flexible tile opens it with none', (tester) async {
      // Flexible has no fixed start; an end derived from `draft.startTime`
      // there would be the creation time, which means nothing to the user.
      await pumpShell(tester, AddTileDraft.flexible(now: start));

      final AddTileDurationScreen screen =
          await openDuration(tester, 'durationRow');
      expect(screen.startTime, isNull);
    });
  });
}
