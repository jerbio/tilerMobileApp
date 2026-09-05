// Phase 2.3 — More options (in-flow disclosure, decision D4).
//
// Red tests for the advanced Flexible controls:
//   * More options is COLLAPSED by default — a first-time user finishes
//     without ever opening it;
//   * expanded, it exposes exactly the legacy advanced set (priority, color,
//     split into sessions, flexible completion date, advanced preferred-time
//     profile) so no legacy capability is lost;
//   * Fixed Block gets only the subset Section 5.4 allows;
//   * "Flexible completion date" disappears when Repeat owns the end date,
//     matching the mapper (a repetition end forces AutoReviseDeadline=false);
//   * every advanced value still maps to the legacy wire payload.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileMoreOptions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

final now = DateTime(2026, 9, 4, 14, 0);

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

/// Opens the More options disclosure, scrolling it into view first (it sits
/// below the primary decisions on a small viewport).
Future<void> expandMoreOptions(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(const ValueKey('moreOptionsHeader')));
}

/// Scrolls [finder] into view, then taps it. The expanded advanced controls
/// sit below the fold on the standard test viewport, so a bare `tap()` would
/// miss the hit test.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('More options — disclosure', () {
    testWidgets('is collapsed by default and hides every advanced control',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      expect(find.byKey(const ValueKey('moreOptionsHeader')), findsOneWidget);
      // Collapsed: none of the advanced controls are in the tree.
      expect(find.byKey(const ValueKey('priorityControl')), findsNothing);
      expect(find.byKey(const ValueKey('colorRow')), findsNothing);
      expect(find.byKey(const ValueKey('splitCountControl')), findsNothing);
      expect(
          find.byKey(const ValueKey('flexibleCompletionToggle')), findsNothing);
      expect(
          find.byKey(const ValueKey('advancedPreferredTimeRow')), findsNothing);
    });

    testWidgets('expanded, it exposes the full Flexible advanced set',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(find.byKey(const ValueKey('priorityControl')), findsOneWidget);
      expect(find.byKey(const ValueKey('colorRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('splitCountControl')), findsOneWidget);
      expect(find.byKey(const ValueKey('flexibleCompletionToggle')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('advancedPreferredTimeRow')),
          findsOneWidget);
    });

    testWidgets('uses the approved terminology, never the engine wording',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(find.text('Split into sessions'), findsOneWidget);
      expect(find.text('How many times'), findsNothing,
          reason: 'legacy engine wording must not appear');
      expect(find.text('Flexible completion date'), findsOneWidget);
      expect(find.text('Soft Deadline'), findsNothing);
      expect(find.text('Repetition'), findsNothing);
    });

    testWidgets('Fixed Block exposes only its allowed subset', (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      // Section 5.4: Fixed Block options are Color (+ recurrence extras).
      expect(find.byKey(const ValueKey('colorRow')), findsOneWidget);
      // Flexible-only controls must never appear for a Block.
      expect(find.byKey(const ValueKey('priorityControl')), findsNothing);
      expect(find.byKey(const ValueKey('splitCountControl')), findsNothing);
      expect(
          find.byKey(const ValueKey('flexibleCompletionToggle')), findsNothing);
      expect(
          find.byKey(const ValueKey('advancedPreferredTimeRow')), findsNothing);
    });
  });

  group('More options — priority', () {
    testWidgets('defaults to medium and records a selection', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      expect(draft.priority, TilePriority.medium, reason: 'legacy default');

      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      await tapVisible(tester, find.byKey(const ValueKey('priorityHigh')));
      await tester.pump();
      expect(draft.priority, TilePriority.high);
    });
  });

  group('More options — split into sessions', () {
    testWidgets('defaults to 1 and steps within bounds', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(draft.splitCount, 1, reason: 'legacy default');

      await tapVisible(
          tester, find.byKey(const ValueKey('splitCountIncrement')));
      await tester.pump();
      expect(draft.splitCount, 2);

      await tapVisible(
          tester, find.byKey(const ValueKey('splitCountDecrement')));
      await tester.pump();
      expect(draft.splitCount, 1);

      // Lower bound: 1 session is the legacy floor (empty input meant '1').
      await tapVisible(
          tester, find.byKey(const ValueKey('splitCountDecrement')));
      await tester.pump();
      expect(draft.splitCount, 1, reason: 'split count never drops below 1');
    });

    test('the draft clamps an out-of-range split count', () {
      final draft = AddTileDraft.flexible(now: now);
      draft.setSplitCount(0);
      expect(draft.splitCount, 1);
      draft.setSplitCount(-4);
      expect(draft.splitCount, 1);
    });
  });

  group('More options — flexible completion date', () {
    testWidgets('toggles isAutoRevisable and explains the consequence',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      expect(draft.isAutoRevisable, isTrue, reason: 'legacy default');

      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(find.text('Tiler may move this date slightly if needed.'),
          findsOneWidget);

      await tapVisible(
          tester, find.byKey(const ValueKey('flexibleCompletionToggle')));
      await tester.pump();
      expect(draft.isAutoRevisable, isFalse);
    });

    testWidgets('is hidden once Repeat owns the end date', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setRepetitionData(RepetitionData(
          frequency: RepetitionFrequency.daily, isEnabled: true));

      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      // The mapper forces AutoReviseDeadline=false when a repetition end
      // exists, so offering the toggle here would be a lie.
      expect(
          find.byKey(const ValueKey('flexibleCompletionToggle')), findsNothing);
      expect(find.byKey(const ValueKey('priorityControl')), findsOneWidget,
          reason: 'the rest of More options is unaffected');
    });
  });

  group('More options — payload parity', () {
    test('a fully configured advanced draft maps to the legacy payload', () {
      const color = Color(0xFF336699);
      final draft = AddTileDraft.flexible(now: now);
      draft.name = 'Deep work';
      draft.setUserDuration(const Duration(hours: 2));
      draft.endTime = DateTime(2026, 9, 12, 23, 59);
      draft.setPriority(TilePriority.high);
      draft.setColor(color);
      draft.setSplitCount(3);
      draft.setAutoRevisable(false);

      final legacy = LegacyAddTileDraft(
        isAppointment: false,
        name: 'Deep work',
        duration: const Duration(hours: 2),
        endTime: DateTime(2026, 9, 12, 23, 59),
        startTime: draft.startTime,
        // The legacy widget holds a ghost `Location.fromDefault()` when no
        // preTile supplies one, and the draft mirrors that exactly — it
        // changes the wire `LocationIsVerified` field, so parity needs it on
        // both sides.
        location: Location.fromDefault(),
        isAutoRevisable: false,
        priority: TilePriority.high,
        color: color,
        splitCount: '3',
        now: now,
      );

      final NewTile fromLegacy = NewTileRequestMapper.build(legacy);
      final NewTile fromDraft =
          NewTileRequestMapper.buildFromSnapshot(draft.snapshot, now: now);
      expect(fromDraft.toJson(), fromLegacy.toJson());
      // Spot-check the advanced fields specifically.
      expect(fromDraft.Priority, 'high');
      expect(fromDraft.Count, '3');
      expect(fromDraft.AutoReviseDeadline, 'false');
    });
  });

  group('More options — summaries', () {
    test('summaries describe the current advanced values', () {
      expect(priorityLabel(TilePriority.low), 'Low');
      expect(priorityLabel(TilePriority.medium), 'Medium');
      expect(priorityLabel(TilePriority.high), 'High');

      expect(splitCountSummary(1), '1 session');
      expect(splitCountSummary(3), '3 sessions');

      expect(colorSummary(null), 'Automatic');
      expect(colorSummary(const Color(0xFF336699)), 'Custom');
    });
  });
}
