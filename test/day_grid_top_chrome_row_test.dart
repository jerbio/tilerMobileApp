// day_grid_top_chrome_row_test.dart
//
// P5 Step 15.2: DayGridTopChromeRow is the new grid-mode top chrome row
// (design §14.3 + §14.7/C16) — a leading, tappable day label
// (DateTimeHuman.humanDate) plus the shared HomeTopRightActionsRow trailing
// icon cluster, laid out in-flow (no Stack/Positioned). It is built and tested
// in ISOLATION: it is not yet referenced by AuthorizedRoute (Step 15.3) and it
// knows nothing about UiDateManagerBloc (Step 15.4). The day label opens a
// date picker through an injectable seam (pickDate) so these tests never need
// the real platform dialog.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(body: child),
  );
}

DayGridTopChromeRow _chrome({
  DateTime? currentDate,
  VoidCallback? onSearch,
  VoidCallback? onSettings,
  VoidCallback? onGoToToday,
  DailyViewLayout? dayGridLayout,
  VoidCallback? onDayGridLayoutToggle,
  ValueChanged<DateTime>? onDateSelected,
  DayGridDatePicker? pickDate,
}) {
  return DayGridTopChromeRow(
    currentDate: currentDate ?? Utility.currentTime().dayDate,
    onSearch: onSearch ?? () {},
    onSettings: onSettings ?? () {},
    onGoToToday: onGoToToday ?? () {},
    dayGridLayout: dayGridLayout,
    onDayGridLayoutToggle: onDayGridLayoutToggle,
    onDateSelected: onDateSelected,
    pickDate: pickDate,
  );
}

/// The rendered day-label text (found via the widget's stable key so it is not
/// confused with any tooltip text in the trailing icon row).
String _labelText(WidgetTester tester) {
  final label =
      tester.widget<Text>(find.byKey(DayGridTopChromeRow.dayLabelKey));
  return label.data!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayGridTopChromeRow — day label (DateTimeHuman.humanDate)', () {
    testWidgets('renders "Today" when the shown day is today', (tester) async {
      final DateTime today = Utility.currentTime().dayDate;
      await tester.pumpWidget(_wrap(_chrome(currentDate: today)));
      await tester.pump();

      expect(_labelText(tester), 'Today');
    });

    testWidgets('renders "Tomorrow" for the day after today', (tester) async {
      final DateTime tomorrow =
          Utility.currentTime().dayDate.add(const Duration(days: 1));
      await tester.pumpWidget(_wrap(_chrome(currentDate: tomorrow)));
      await tester.pump();

      expect(_labelText(tester), 'Tomorrow');
    });

    testWidgets('renders a localized date for a non-relative date',
        (tester) async {
      // A date in a different year than "now" takes humanDate's
      // 'EEE, MMM d, yy' branch. Compute the expected string the same way the
      // widget does so the assertion is locale/format-robust.
      final DateTime past = DateTime(2001, 1, 1);
      await tester.pumpWidget(_wrap(_chrome(currentDate: past)));
      await tester.pump();

      final String expected = DateFormat('EEE, MMM d, yy').format(past);
      expect(_labelText(tester), expected);
    });
  });

  group(
      'DayGridTopChromeRow — trailing actions reuse HomeTopRightActionsRow', () {
    testWidgets(
        'mounts the shared HomeTopRightActionsRow (in-flow, not Positioned)',
        (tester) async {
      await tester.pumpWidget(_wrap(_chrome()));
      await tester.pump();

      expect(find.byType(HomeTopRightActionsRow), findsOneWidget);
      // The trailing row still carries the tutorial spotlight key.
      expect(find.byKey(TutorialKeys.topRightActionsKey), findsOneWidget);
    });

    testWidgets('shows search and settings icons', (tester) async {
      await tester.pumpWidget(_wrap(_chrome()));
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('tapping search calls onSearch', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(_chrome(onSearch: () => called = true)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      expect(called, isTrue);
    });

    testWidgets('tapping settings calls onSettings', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(_chrome(onSettings: () => called = true)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      expect(called, isTrue);
    });
  });

  group('DayGridTopChromeRow — go-to-today visibility mirrors isViewingToday',
      () {
    testWidgets('hides "Go to Today" when the shown day is today',
        (tester) async {
      final DateTime today = Utility.currentTime().dayDate;
      await tester.pumpWidget(_wrap(_chrome(currentDate: today)));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('shows "Go to Today" when the shown day is not today',
        (tester) async {
      final DateTime tomorrow =
          Utility.currentTime().dayDate.add(const Duration(days: 1));
      bool called = false;
      await tester.pumpWidget(_wrap(
        _chrome(currentDate: tomorrow, onGoToToday: () => called = true),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      await tester.tap(find.byIcon(Icons.calendar_today));
      expect(called, isTrue);
    });
  });

  group('DayGridTopChromeRow — list/grid toggle', () {
    testWidgets('hides the toggle when dayGridLayout is not provided',
        (tester) async {
      await tester.pumpWidget(_wrap(_chrome()));
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsNothing);
      expect(find.byIcon(Icons.view_list), findsNothing);
    });

    testWidgets('shows the toggle and taps it when provided', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(
        _chrome(
          dayGridLayout: DailyViewLayout.list,
          onDayGridLayoutToggle: () => called = true,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      await tester.tap(find.byIcon(Icons.grid_view));
      expect(called, isTrue);
    });
  });

  group('DayGridTopChromeRow — date-picker seam (C16)', () {
    testWidgets(
        'tapping the label opens the picker with the shown date as initialDate',
        (tester) async {
      final DateTime shown = DateTime(2026, 5, 15);
      final DateTime picked = DateTime(2026, 12, 25);
      DateTime? capturedInitial;
      DateTime? capturedFirst;
      DateTime? capturedLast;

      Future<DateTime?> mockPickDate(BuildContext context,
          {required DateTime initialDate,
          required DateTime firstDate,
          required DateTime lastDate}) async {
        capturedInitial = initialDate;
        capturedFirst = firstDate;
        capturedLast = lastDate;
        return picked;
      }

      DateTime? reported;
      await tester.pumpWidget(_wrap(_chrome(
        currentDate: shown,
        onDateSelected: (d) => reported = d,
        pickDate: mockPickDate,
      )));
      await tester.pump();

      await tester.tap(find.byKey(DayGridTopChromeRow.dayLabelKey));
      await tester.pump();

      expect(capturedInitial, shown,
          reason: 'the shown day must be the picker initialDate');
      // A non-null result must be reported to onDateSelected.
      expect(reported, picked);
      // Bounds must be a generous window that contains the initial date.
      expect(capturedFirst, isNotNull);
      expect(capturedLast, isNotNull);
      expect(capturedFirst!.isBefore(capturedLast!), isTrue);
      expect(
        !capturedFirst!.isAfter(capturedInitial!) &&
            !capturedLast!.isBefore(capturedInitial!),
        isTrue,
        reason: 'the initial date must lie within the picker bounds',
      );
    });

    testWidgets(
        'cancelling the picker (null result) does NOT invoke onDateSelected',
        (tester) async {
      final DateTime shown = DateTime(2026, 5, 15);
      int pickerCalls = 0;

      Future<DateTime?> mockPickDate(BuildContext context,
          {required DateTime initialDate,
          required DateTime firstDate,
          required DateTime lastDate}) async {
        pickerCalls += 1;
        return null; // user dismissed the dialog without choosing.
      }

      DateTime? reported;
      await tester.pumpWidget(_wrap(_chrome(
        currentDate: shown,
        onDateSelected: (d) => reported = d,
        pickDate: mockPickDate,
      )));
      await tester.pump();

      await tester.tap(find.byKey(DayGridTopChromeRow.dayLabelKey));
      await tester.pump();

      expect(pickerCalls, 1,
          reason: 'the seam must have been invoked once on tap');
      expect(reported, isNull,
          reason: 'a cancelled picker must not report a date');
    });

    testWidgets(
        'does not throw when no onDateSelected is wired (still opens the seam)',
        (tester) async {
      final DateTime shown = DateTime(2026, 5, 15);
      int pickerCalls = 0;

      Future<DateTime?> mockPickDate(BuildContext context,
          {required DateTime initialDate,
          required DateTime firstDate,
          required DateTime lastDate}) async {
        pickerCalls += 1;
        return DateTime(2026, 6, 1);
      }

      // onDateSelected intentionally left null: the row must still open the
      // picker and simply have nowhere to report the result (Step 15.4 wires
      // it up). This must not throw.
      await tester.pumpWidget(_wrap(_chrome(currentDate: shown, pickDate: mockPickDate)));
      await tester.pump();

      await tester.tap(find.byKey(DayGridTopChromeRow.dayLabelKey));
      await tester.pump();

      expect(pickerCalls, 1);
      expect(tester.takeException(), isNull);
    });
  });
}