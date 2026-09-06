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
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileMoreOptions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';

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
      expect(find.byKey(const ValueKey('priorityRow')), findsNothing);
      expect(find.byKey(const ValueKey('colorRow')), findsNothing);
      expect(find.byKey(const ValueKey('splitCountControl')), findsNothing);
      expect(
          find.byKey(const ValueKey('flexibleCompletionToggle')), findsNothing);
    });

    testWidgets('expanded, it exposes the full Flexible advanced set',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(find.byKey(const ValueKey('priorityRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('colorRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('splitCountControl')), findsOneWidget);
      expect(find.byKey(const ValueKey('flexibleCompletionToggle')),
          findsOneWidget);

      // Advanced preferred time is deliberately NOT here (D34) — the
      // Preferred time control's Custom chip is the single entry point to
      // that editor.
      expect(
          find.byKey(const ValueKey('advancedPreferredTimeRow')), findsNothing);
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
      expect(find.byKey(const ValueKey('priorityRow')), findsNothing);
      expect(find.byKey(const ValueKey('splitCountControl')), findsNothing);
      expect(
          find.byKey(const ValueKey('flexibleCompletionToggle')), findsNothing);
    });
  });

  group('More options — visual language (D32)', () {
    // More options was written before addTileFormKit existed and drew its own
    // bare label-over-row layout on a transparent background, so opening it
    // dropped the user out of the card-and-icon-chip language the rest of the
    // screen speaks. These assert the SHARED components are what render it,
    // which is the only way the two can be kept from drifting again.
    testWidgets('advanced controls live in a grouped card, like the form above',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      final int before = tester.widgetList(find.byType(AddTileSection)).length;
      await expandMoreOptions(tester);

      expect(tester.widgetList(find.byType(AddTileSection)).length,
          greaterThan(before),
          reason: 'expanding must add a grouped card, not bare rows');
    });

    testWidgets('every advanced row icon carries the same tint',
        (tester) async {
      // Split into sessions and Flexible completion date used the `muted`
      // chip, which made two of five peer rows read as switched off.
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      for (final String key in <String>[
        'priorityRow',
        'colorRow',
        'splitCountControl',
        'flexibleCompletionToggle',
      ]) {
        await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 120,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        final AddTileIconChip chip = tester.widget<AddTileIconChip>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(AddTileIconChip),
          ),
        );
        expect(chip.muted, isFalse,
            reason: '$key is a peer of the other advanced rows, so its icon '
                'must carry the same tint');
      }
    });

    testWidgets('every advanced row leads with an icon chip', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      for (final String key in <String>[
        'priorityRow',
        'colorRow',
        'splitCountControl',
        'flexibleCompletionToggle',
      ]) {
        await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 120,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(AddTileIconChip),
          ),
          findsOneWidget,
          reason: '$key renders without the icon chip every other row has',
        );
      }
    });
  });

  group('More options — colour', () {
    testWidgets('the row shows the actual colour, not just the word Custom',
        (tester) async {
      // "Custom" alone never answered "what colour is this tile?".
      final draft = AddTileDraft.flexible(now: now);
      draft.setColor(addTileColorPresets[4]);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('colorRow')), 120,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final ColorDot dot = tester.widget<ColorDot>(find.descendant(
        of: find.byKey(const ValueKey('colorRow')),
        matching: find.byType(ColorDot),
      ));
      expect(dot.color, addTileColorPresets[4]);
    });

    testWidgets('Automatic shows no swatch', (tester) async {
      // There is no colour to show yet — a swatch would have to invent one,
      // and the one the tile eventually gets is rolled at submit (D7).
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('colorRow')), 120,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('colorRow')),
          matching: find.byType(ColorDot),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('colorRow')),
          matching: find.text('Automatic'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the row opens the redesigned picker', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);
      await tapVisible(tester, find.byKey(const ValueKey('colorRow')));

      expect(find.byType(AddTileColorScreen), findsOneWidget);
    });

    testWidgets('choosing Automatic clears a colour already set',
        (tester) async {
      // End to end through the real navigation, because the round trip is
      // where a `Color?` result would have lost the difference between
      // "chose Automatic" and "backed out".
      final draft = AddTileDraft.flexible(now: now);
      draft.setColor(addTileColorPresets[2]);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);
      await tapVisible(tester, find.byKey(const ValueKey('colorRow')));

      await tester.tap(find.byKey(const ValueKey('colorAutomatic')));
      await tester.pumpAndSettle();

      expect(draft.color, isNull);
    });

    testWidgets('backing out of the picker leaves the colour alone',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setColor(addTileColorPresets[2]);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);
      await tapVisible(tester, find.byKey(const ValueKey('colorRow')));

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(draft.color, addTileColorPresets[2]);
    });
  });

  group('More options — priority', () {
    testWidgets('defaults to medium and shows it on the row', (tester) async {
      // Step 4.3a moved priority from inline chips to a row that opens the
      // Priority picker, per §4.2's "reachable only from More options".
      // Selection itself is covered in add_tile_priority_screen_test.dart.
      final draft = AddTileDraft.flexible(now: now);
      expect(draft.priority, TilePriority.medium, reason: 'legacy default');

      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      await expandMoreOptions(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('priorityRow')),
          matching: find.text('Medium'),
        ),
        findsOneWidget,
      );
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
      expect(find.byKey(const ValueKey('priorityRow')), findsOneWidget,
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
      expect(priorityLabel(testL10n, TilePriority.low), 'Low');
      expect(priorityLabel(testL10n, TilePriority.medium), 'Medium');
      expect(priorityLabel(testL10n, TilePriority.high), 'High');

      expect(splitCountSummary(testL10n, 1), '1 session');
      expect(splitCountSummary(testL10n, 3), '3 sessions');

      expect(colorSummary(testL10n, null), 'Automatic');
      expect(colorSummary(testL10n, const Color(0xFF336699)), 'Custom');
    });
  });
}
