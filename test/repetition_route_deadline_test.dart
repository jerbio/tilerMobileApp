// Tests for the deadline date picker on RepetitionRoute.
//
// These lock in two fixes in `onDeadlineDateTap`:
//   1. A picked date is always written back to `repetitionData.repetitionEnd`
//      (previously it was silently dropped unless `weeklyRepetition != null`).
//   2. The picker opens on a sane, in-range date within [today, today + 10y].
//      A broken/out-of-range default (e.g. a deadline in the past) is clamped
//      into range instead of opening on a broken date (and, with the tightened
//      lower bound, would otherwise assert because initialDate < firstDate).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/repetitionRoute.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

DateTime _todayDate() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _deadlineText(DateTime date) => DateFormat.yMMMd().format(date);

Map<dynamic, dynamic> _params(RepetitionData repetitionData) {
  final DateTime today = _todayDate();
  return {
    'repetitionData': repetitionData,
    // A tile timeline is optional for the picker; provide one so the route is
    // exercised realistically.
    'tileTimeline': Timeline.fromDateTime(
      today,
      today.add(const Duration(days: 1)),
    ),
  };
}

/// Pumps a RepetitionRoute with [repetitionData] and returns once it is visible.
Future<void> _openRepetitionRoute(
  WidgetTester tester,
  RepetitionData repetitionData,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  settings: RouteSettings(arguments: _params(repetitionData)),
                  builder: (_) => RepetitionRoute(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('RepetitionRoute deadline picker', () {
    testWidgets('writes the selected date back to the deadline',
        (WidgetTester tester) async {
      // A deadline 40 days out guarantees the picker opens on a strictly future
      // month, so every visible day (including the 15th) is selectable.
      final DateTime initialDeadline =
          _todayDate().add(const Duration(days: 40));
      final RepetitionData repetitionData = RepetitionData(
        frequency: RepetitionFrequency.weekly,
        isEnabled: true,
        repetitionEnd: initialDeadline,
      );

      await _openRepetitionRoute(tester, repetitionData);

      // The current deadline is shown.
      expect(find.text(_deadlineText(initialDeadline)), findsOneWidget);

      // Open the picker and choose a different day in the same (opened) month.
      await tester.tap(find.text(_deadlineText(initialDeadline)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final DateTime expected =
          DateTime(initialDeadline.year, initialDeadline.month, 15);
      expect(find.text(_deadlineText(expected)), findsOneWidget);
      expect(repetitionData.repetitionEnd!.year, expected.year);
      expect(repetitionData.repetitionEnd!.month, expected.month);
      expect(repetitionData.repetitionEnd!.day, 15);
    });

    testWidgets('clamps a broken past deadline into range when opening',
        (WidgetTester tester) async {
      // A deadline in the past is out of the new [today, today + 10y] range.
      // Without clamping this would open on a broken date (and assert, since
      // initialDate would be before firstDate).
      final DateTime brokenDeadline =
          _todayDate().subtract(const Duration(days: 3650));
      final RepetitionData repetitionData = RepetitionData(
        frequency: RepetitionFrequency.weekly,
        isEnabled: true,
        repetitionEnd: brokenDeadline,
      );

      await _openRepetitionRoute(tester, repetitionData);

      // Opening the picker must not throw despite the out-of-range default.
      await tester.tap(find.text(_deadlineText(brokenDeadline)));
      await tester.pumpAndSettle();

      // Accepting the clamped initial date yields today, not the broken date.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final DateTime today = _todayDate();
      expect(find.text(_deadlineText(today)), findsOneWidget);
      expect(find.text(_deadlineText(brokenDeadline)), findsNothing);
      expect(repetitionData.repetitionEnd!.year, today.year);
      expect(repetitionData.repetitionEnd!.month, today.month);
      expect(repetitionData.repetitionEnd!.day, today.day);
    });
  });
}
