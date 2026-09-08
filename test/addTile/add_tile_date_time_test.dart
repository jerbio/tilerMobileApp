// Step 4.3d — Date and time selection.
//
// The platform pickers are kept (D42), so what needs pinning is not the
// picker chrome but how a picked value is COMBINED with the one already in
// the draft. Every defect in this area has the same shape: choosing one thing
// silently moves another.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
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

Future<void> pumpShell(WidgetTester tester, Widget child) async {
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
    home: child,
  ));
}

void main() {
  group('Picking a date changes ONLY the day', () {
    test('the wall-clock time is carried onto the new day', () {
      final DateTime current = DateTime(2026, 9, 5, 14, 30);
      final DateTime picked = DateTime(2026, 12, 25);

      final DateTime next = applyPickedDate(current, picked);

      expect(next.year, 2026);
      expect(next.month, 12);
      expect(next.day, 25);
      expect(next.hour, 14, reason: 'picking a date must not move the time');
      expect(next.minute, 30);
    });

    test('the picked value\'s own time component is ignored', () {
      // `showDatePicker` returns midnight; taking it wholesale would silently
      // reset the block to 00:00.
      final DateTime current = DateTime(2026, 9, 5, 9, 15);
      final DateTime pickedAtMidnight = DateTime(2026, 9, 20, 0, 0);

      final DateTime next = applyPickedDate(current, pickedAtMidnight);

      expect(next.hour, 9);
      expect(next.minute, 15);
    });

    test('a late-evening time survives a date change', () {
      // 23:45 plus a duration is the rollover case; the date change itself
      // must not be what moves it.
      final DateTime current = DateTime(2026, 9, 5, 23, 45);
      final DateTime next = applyPickedDate(current, DateTime(2026, 9, 6));

      expect(next, DateTime(2026, 9, 6, 23, 45));
    });
  });

  group('Picking a time changes ONLY the time', () {
    test('the calendar day is preserved', () {
      final DateTime current = DateTime(2026, 9, 5, 14, 30);

      final DateTime next =
          applyPickedTime(current, const TimeOfDay(hour: 8, minute: 5));

      expect(next, DateTime(2026, 9, 5, 8, 5));
    });

    test('moving to a later time does not roll the day forward', () {
      final DateTime current = DateTime(2026, 9, 5, 1, 0);

      final DateTime next =
          applyPickedTime(current, const TimeOfDay(hour: 23, minute: 55));

      expect(next.day, 5);
      expect(next.hour, 23);
      expect(next.minute, 55);
    });

    test('midnight is expressible', () {
      final DateTime current = DateTime(2026, 9, 5, 14, 0);

      final DateTime next =
          applyPickedTime(current, const TimeOfDay(hour: 0, minute: 0));

      expect(next, DateTime(2026, 9, 5, 0, 0),
          reason: '00:00 must stay on the same day, not roll back a day');
    });
  });

  group('A deadline is the END of the chosen day', () {
    test('a picked day becomes 23:59 that day', () {
      // "Complete by Friday" means the end of Friday. Taking the picker's
      // midnight would give the user until the START of Friday — a whole day
      // less than they asked for.
      expect(deadlineForPickedDay(DateTime(2026, 9, 18)),
          DateTime(2026, 9, 18, 23, 59));
    });

    test('an already-timed value is normalized to the end of its day', () {
      expect(deadlineForPickedDay(DateTime(2026, 9, 18, 6, 30)),
          DateTime(2026, 9, 18, 23, 59));
    });
  });

  group('The selectable window matches the legacy +/-180 days', () {
    test('it is symmetric around the anchor', () {
      final DateTime anchor = DateTime(2026, 9, 5, 12, 0);
      final window = addTileDateWindow(anchor);

      expect(anchor.difference(window.first).inDays, 180);
      expect(window.last.difference(anchor).inDays, 180);
      expect(window.first.isBefore(anchor), isTrue);
      expect(window.last.isAfter(anchor), isTrue);
    });

    test('the anchor is always inside its own window', () {
      // A window that excluded the current value would make the picker refuse
      // to open on it.
      for (final DateTime anchor in <DateTime>[
        DateTime(2026, 1, 1),
        DateTime(2026, 6, 30, 23, 59),
        DateTime(2027, 12, 31, 0, 0),
      ]) {
        final window = addTileDateWindow(anchor);
        expect(window.first.isAfter(anchor), isFalse);
        expect(window.last.isBefore(anchor), isFalse);
      }
    });
  });

  group('Cancelling a picker changes nothing', () {
    testWidgets('dismissing the Fixed date picker leaves the start alone',
        (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      final DateTime before = draft.startTime;
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('fixedDateRow')));
      await tester.pumpAndSettle();
      // The platform dialog's own cancel, so the real dismissal path runs.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(draft.startTime, before);
    });

    testWidgets('dismissing the Fixed time picker leaves the start alone',
        (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      final DateTime before = draft.startTime;
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('fixedStartRow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(draft.startTime, before);
    });
  });

  group('The platform pickers are localized (D42)', () {
    testWidgets('the date picker renders with MaterialLocalizations',
        (tester) async {
      // The reason for keeping them: locale, calendar system, RTL, keyboard
      // entry and screen-reader support arrive for free and would all have to
      // be re-earned by a house-styled replacement.
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('fixedDateRow')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('the time picker renders with MaterialLocalizations',
        (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpShell(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('fixedStartRow')));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
    });
  });
}
