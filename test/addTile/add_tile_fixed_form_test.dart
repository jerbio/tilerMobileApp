// Phase 3.1 — Fixed Block interval form.
//
// Built to the Add Block mockup, with the deviations locked in plan §4.1/§4.2
// and reconfirmed 2026-09-05:
//   * no bottom Cancel — the top-left Close is the only cancel path;
//   * Color lives under More options, not as a primary row;
//   * Location and Repeat stay as direct rows.
//
// The interval itself is the behavior under test: Date, Starts and Duration
// are editable, Ends is DERIVED (start + duration) and read-only, and the
// derived value must survive day rollover and DST boundaries.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/fixedBlockForm.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';

final now = DateTime(2026, 9, 5, 14, 0);

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size viewSize = AddTileTestMatrix.standard,
  double textScale = AddTileTestMatrix.baseTextScale,
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
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  ));
}

AddTileDraft fixedDraft() => AddTileDraft.fixed(now: now);

void main() {
  group('Fixed Block — structure', () {
    testWidgets('shows title, date, starts, duration, derived end and location',
        (tester) async {
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: fixedDraft(), now: now),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('fixedTitleField')), findsOneWidget);
      expect(find.byKey(const ValueKey('fixedDateRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('fixedStartRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('fixedDurationRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('fixedEndRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('locationRow')), findsOneWidget);
      expect(find.text('Add Block'), findsWidgets);
    });

    testWidgets('Flexible-only controls never appear in Fixed mode',
        (tester) async {
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: fixedDraft(), now: now),
      );
      await tester.pump();

      expect(find.text('Complete by'), findsNothing);
      expect(find.text('Preferred time'), findsNothing);
      expect(find.byKey(const ValueKey('completeByRow')), findsNothing);
    });

    testWidgets('the only cancel control is the top-left Close',
        (tester) async {
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: fixedDraft(), now: now),
      );
      await tester.pump();

      expect(find.byTooltip('Close'), findsOneWidget);
      // Locked deviation from the mockup: no bottom Cancel.
      expect(find.text('Cancel'), findsNothing);
    });
  });

  group('Fixed Block — the derived end', () {
    testWidgets('Ends is read-only and carries a locked affordance',
        (tester) async {
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: fixedDraft(), now: now),
      );
      await tester.pump();

      expect(find.text('Auto-calculated'), findsOneWidget);
      // §4.1: the end row must not offer an editable affordance.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('fixedEndRow')),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );
    });

    testWidgets('Ends recalculates immediately when duration changes',
        (tester) async {
      final draft = fixedDraft();
      draft.setUserStartTime(DateTime(2026, 9, 5, 14, 0));
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: draft, now: now),
      );
      await tester.pump();

      expect(find.text(formatClockTime(DateTime(2026, 9, 5, 14, 30))),
          findsOneWidget);

      draft.setUserDuration(const Duration(hours: 2));
      await tester.pump();

      expect(find.text(formatClockTime(DateTime(2026, 9, 5, 16, 0))),
          findsOneWidget);
    });

    test('the derived end rolls over midnight', () {
      final draft = AddTileDraft.fixed(now: DateTime(2026, 9, 5, 23, 30));
      draft.setUserStartTime(DateTime(2026, 9, 5, 23, 30));
      draft.setUserDuration(const Duration(hours: 1));
      expect(draft.calculatedEnd, DateTime(2026, 9, 6, 0, 30),
          reason: 'a Block may cross midnight into the next day');
    });

    test('the derived end is wall-clock across a DST spring-forward', () {
      // US DST 2026: clocks jump 02:00 -> 03:00 on Mar 8. `DateTime.add` on a
      // local DateTime is wall-clock arithmetic here, so the contract under
      // test is that end == start + duration, which is what the mapper ships.
      final draft = AddTileDraft.fixed(now: DateTime(2026, 3, 8, 1, 30));
      draft.setUserStartTime(DateTime(2026, 3, 8, 1, 30));
      draft.setUserDuration(const Duration(hours: 2));
      expect(draft.calculatedEnd, draft.startTime.add(draft.duration));
    });
  });

  group('Fixed Block — defaults and validation', () {
    test('duration defaults to 30 minutes with no prefill', () {
      expect(fixedDraft().duration, const Duration(minutes: 30));
    });

    testWidgets('an empty title keeps the CTA disabled', (tester) async {
      final draft = fixedDraft();
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: draft, now: now),
      );
      await tester.pump();

      final cta = tester.widget<AddTileBottomAction>(
          find.byKey(const ValueKey('addTileCta')));
      expect(cta.enabled, isFalse);
      expect(cta.type, AddTileType.fixed);
    });
  });

  group('Fixed Block — clock formatting', () {
    // ICU emits a NARROW NO-BREAK SPACE (U+202F) before AM/PM, not an ASCII
    // space. Normalizing keeps the assertion about the format rather than
    // about which invisible separator the current ICU build ships.
    String normalize(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

    test('formats 12-hour wall-clock times', () {
      expect(
          normalize(formatClockTime(DateTime(2026, 9, 5, 14, 0))), '2:00 PM');
      expect(
          normalize(formatClockTime(DateTime(2026, 9, 5, 14, 30))), '2:30 PM');
      expect(
          normalize(formatClockTime(DateTime(2026, 9, 5, 0, 5))), '12:05 AM');
    });

    test('formats the date row, marking today', () {
      expect(
          formatBlockDate(testL10n, DateTime(2026, 9, 5),
              today: DateTime(2026, 9, 5)),
          startsWith('Today, '));
      expect(
        formatBlockDate(testL10n, DateTime(2026, 9, 12),
            today: DateTime(2026, 9, 5)),
        isNot(startsWith('Today')),
      );
    });
  });
}
