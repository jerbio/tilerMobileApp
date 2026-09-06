// Step 4.3a — the Priority picker.
//
// Built to the Priority mockup with the revisions §4.2 attached to it:
//   * reachable only from More options;
//   * unambiguous icons;
//   * IMMEDIATE SELECTION-AND-RETURN rather than the mockup's heavy
//     "Save priority" transaction — a three-way choice needs no confirm step,
//     and this matches the Location picker (D18);
//   * Back, not Close (D12).
//
// The helper claim "Priority helps Tiler decide what to protect first" is the
// mockup's approved copy but remains UNVERIFIED against the scheduler — see
// P2-7 / D5. It is rendered as designed; the open question is product's.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePriorityScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
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

TilePriority? _picked;

Future<void> pumpPriority(
  WidgetTester tester, {
  TilePriority initial = TilePriority.medium,
}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
  addTearDown(tester.view.reset);
  _picked = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTilePriorityScreen(
      initial: initial,
      onSelected: (p) => _picked = p,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> pumpForm(WidgetTester tester, AddTileDraft draft) async {
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
    home: AddTileRedesignScreen(draft: draft, now: now),
  ));
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('The three options', () {
    testWidgets('each has a name and a consequence', (tester) async {
      await pumpPriority(tester);

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Nice to have'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Important'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Must get done'), findsOneWidget);
    });

    testWidgets('the current value arrives selected', (tester) async {
      await pumpPriority(tester, initial: TilePriority.high);

      expect(
        tester
            .widget<PriorityOptionRow>(
                find.byKey(const ValueKey('priorityOption_high')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<PriorityOptionRow>(
                find.byKey(const ValueKey('priorityOption_low')))
            .selected,
        isFalse,
      );
    });

    testWidgets('exactly one option is ever selected', (tester) async {
      await pumpPriority(tester, initial: TilePriority.medium);
      final rows =
          tester.widgetList<PriorityOptionRow>(find.byType(PriorityOptionRow));
      expect(rows.where((r) => r.selected).length, 1);
    });
  });

  group('Selection returns immediately (§4.2 revision)', () {
    testWidgets('tapping an option returns it', (tester) async {
      await pumpPriority(tester);
      await tester.tap(find.byKey(const ValueKey('priorityOption_high')));
      await tester.pumpAndSettle();

      expect(_picked, TilePriority.high);
    });

    testWidgets('there is no Save transaction to complete', (tester) async {
      // The mockup's "Save priority" button is dropped: a three-way choice
      // needs no confirm step, matching the Location picker (D18).
      await pumpPriority(tester);
      expect(find.text('Save priority'), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('re-picking the current value still returns it',
        (tester) async {
      // Tapping the already-selected row must not be a no-op that traps the
      // user on the screen.
      await pumpPriority(tester, initial: TilePriority.medium);
      await tester.tap(find.byKey(const ValueKey('priorityOption_medium')));
      await tester.pumpAndSettle();

      expect(_picked, TilePriority.medium);
    });
  });

  group('Navigation (D12)', () {
    testWidgets('uses Back, never Close', (tester) async {
      await pumpPriority(tester);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('Reachable only from More options (§4.2)', () {
    testWidgets('the Priority row is inside More options, not the main form',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpForm(tester, draft);

      expect(find.byKey(const ValueKey('priorityRow')), findsNothing,
          reason: 'collapsed by default, so priority is not on the main form');

      await tapVisible(tester, find.byKey(const ValueKey('moreOptionsHeader')));
      expect(find.byKey(const ValueKey('priorityRow')), findsOneWidget);
    });

    testWidgets('the row shows the current value', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setPriority(TilePriority.high);
      await pumpForm(tester, draft);
      await tapVisible(tester, find.byKey(const ValueKey('moreOptionsHeader')));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('priorityRow')),
          matching: find.text('High'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('picking from the row updates the draft', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpForm(tester, draft);
      await tapVisible(tester, find.byKey(const ValueKey('moreOptionsHeader')));
      await tapVisible(tester, find.byKey(const ValueKey('priorityRow')));

      await tester.tap(find.byKey(const ValueKey('priorityOption_low')));
      await tester.pumpAndSettle();

      expect(draft.priority, TilePriority.low);
    });

    testWidgets('backing out leaves the draft alone', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setPriority(TilePriority.high);
      await pumpForm(tester, draft);
      await tapVisible(tester, find.byKey(const ValueKey('moreOptionsHeader')));
      await tapVisible(tester, find.byKey(const ValueKey('priorityRow')));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(draft.priority, TilePriority.high);
    });

    testWidgets('Fixed Blocks never see priority at all', (tester) async {
      final draft = AddTileDraft.fixed(now: now);
      await pumpForm(tester, draft);
      await tapVisible(tester, find.byKey(const ValueKey('moreOptionsHeader')));

      expect(find.byKey(const ValueKey('priorityRow')), findsNothing,
          reason: 'priority is Flexible-only (§5.4)');
    });
  });
}
