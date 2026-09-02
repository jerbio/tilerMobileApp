// plan_section_card_test.dart
//
// Phase 4 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// Covers the §5.3 / §5.4 card anatomy, the §7.3 expand/collapse contract, the
// §17 "show all" overflow rule, and the multi-select completion flow ported
// over from the existing summary page.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/todayStatus/planSectionCard.dart';
import 'package:tiler_app/components/todayStatus/planTaskRow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

List<PlanItemViewModel> _items(int count,
    {PlanItemStatus status = PlanItemStatus.placed}) {
  return List.generate(
    count,
    (i) => PlanItemViewModel(
      id: 'id$i',
      title: 'Tile $i',
      status: status,
      source: SubCalendarEvent(id: 'id$i', name: 'Tile $i'),
    ),
  );
}

Widget _harness({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(width: 390, child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('§5.3 card anatomy', () {
    testWidgets('renders the section title and tile count', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(4)),
      ));

      expect(find.text('Placed successfully'), findsOneWidget);
      expect(find.text('4 tiles'), findsOneWidget);
    });

    testWidgets('never labels the placed section "Complete" (§2.2)',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(2)),
      ));

      expect(find.text('Complete'), findsNothing);
    });

    testWidgets('renders one row per item', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));

      expect(find.byType(PlanTaskRow), findsNWidgets(3));
    });

    testWidgets('puts a divider between rows but not after the last',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('renders nothing when there are no items', (tester) async {
      await tester.pumpWidget(_harness(
        child: const PlanSectionCard(status: PlanItemStatus.placed, items: []),
      ));

      expect(find.byType(PlanTaskRow), findsNothing);
      expect(find.text('Placed successfully'), findsNothing);
    });

    testWidgets('shows the helper text on the attention card (§5.4)',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
        ),
      ));

      expect(find.text('Need attention'), findsOneWidget);
      expect(find.text("These could not fit into today's available time."),
          findsOneWidget);
    });
  });

  group('§7.3 expand / collapse', () {
    testWidgets('placed is expanded by default at six items or fewer',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(6)),
      ));

      expect(find.byType(PlanTaskRow), findsNWidgets(6));
    });

    testWidgets('placed is collapsed by default above six items',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(7)),
      ));

      expect(find.byType(PlanTaskRow), findsNothing);
      expect(find.text('7 tiles'), findsOneWidget,
          reason: 'a collapsed section must still report its count');
    });

    testWidgets('attention is expanded by default regardless of length',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(9, status: PlanItemStatus.needsAttention),
        ),
      ));

      expect(find.byType(PlanTaskRow), findsWidgets);
    });

    testWidgets('tapping the chevron toggles the section', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));

      await tester.tap(find.byKey(PlanSectionCard.chevronKey));
      await tester.pumpAndSettle();
      expect(find.byType(PlanTaskRow), findsNothing);

      await tester.tap(find.byKey(PlanSectionCard.chevronKey));
      await tester.pumpAndSettle();
      expect(find.byType(PlanTaskRow), findsNWidgets(3));
    });

    testWidgets('the chevron announces its state and section name',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));

      expect(find.bySemanticsLabel('Collapse Placed successfully'),
          findsOneWidget);

      await tester.tap(find.byKey(PlanSectionCard.chevronKey));
      await tester.pumpAndSettle();

      expect(
          find.bySemanticsLabel('Expand Placed successfully'), findsOneWidget);
    });

    testWidgets('the chevron meets the minimum touch target', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));

      final Size size = tester.getSize(find.byKey(PlanSectionCard.chevronKey));
      expect(
          size.width, greaterThanOrEqualTo(TodayStatusTokens.minTouchTarget));
      expect(
          size.height, greaterThanOrEqualTo(TodayStatusTokens.minTouchTarget));
    });

    testWidgets('expansion survives a parent rebuild (session persistence)',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));

      await tester.tap(find.byKey(PlanSectionCard.chevronKey));
      await tester.pumpAndSettle();
      expect(find.byType(PlanTaskRow), findsNothing);

      await tester.pumpWidget(_harness(
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(3)),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PlanTaskRow), findsNothing,
          reason: 'collapsing must not be undone by a data refresh');
    });
  });

  group('§17 overflow', () {
    testWidgets('caps the visible rows and offers "Show all"', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(12, status: PlanItemStatus.needsAttention),
        ),
      ));

      expect(find.byType(PlanTaskRow),
          findsNWidgets(PlanSectionCard.collapsedPreviewCount));
      expect(find.text('Show all'), findsOneWidget);

      await tester.tap(find.text('Show all'));
      await tester.pumpAndSettle();

      expect(find.byType(PlanTaskRow), findsNWidgets(12));
      expect(find.text('Show all'), findsNothing);
    });

    testWidgets('no "Show all" when everything already fits', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(3, status: PlanItemStatus.needsAttention),
        ),
      ));

      expect(find.text('Show all'), findsNothing);
    });
  });

  group('row interaction', () {
    testWidgets('forwards row taps with the tapped item', (tester) async {
      PlanItemViewModel? tapped;
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.placed,
          items: _items(3),
          onItemTap: (item) => tapped = item,
        ),
      ));

      await tester.tap(find.byType(PlanTaskRow).at(1));
      expect(tapped?.id, 'id1');
    });
  });

  group('multi-select completion flow (ported from the summary page)', () {
    testWidgets('shows checkboxes only in selection mode', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
        ),
      ));
      expect(find.byType(Checkbox), findsNothing);

      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
          selectionMode: true,
          onToggleSelected: (_) {},
        ),
      ));
      expect(find.byType(Checkbox), findsNWidgets(2));
    });

    testWidgets('toggling a checkbox reports the item id', (tester) async {
      final List<String> toggled = [];
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
          selectionMode: true,
          onToggleSelected: toggled.add,
        ),
      ));

      await tester.tap(find.byType(Checkbox).first);
      expect(toggled, ['id0']);
    });

    testWidgets('a row tap toggles selection while in selection mode',
        (tester) async {
      final List<String> toggled = [];
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
          selectionMode: true,
          onToggleSelected: toggled.add,
          onItemTap: (_) => fail('must not navigate while selecting'),
        ),
      ));

      await tester.tap(find.byType(PlanTaskRow).at(1));
      expect(toggled, ['id1']);
    });

    testWidgets('reflects the selected ids', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
          selectionMode: true,
          selectedIds: const {'id1'},
          onToggleSelected: (_) {},
        ),
      ));

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.first.value, isFalse);
      expect(checkboxes.last.value, isTrue);
    });

    testWidgets('header offers an exit affordance while selecting',
        (tester) async {
      int exits = 0;
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
          selectionMode: true,
          onToggleSelected: (_) {},
          onExitSelectionMode: () => exits++,
        ),
      ));

      await tester.tap(find.byKey(PlanSectionCard.exitSelectionKey));
      expect(exits, 1);
    });

    testWidgets('renders the selection footer beneath the rows',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanSectionCard(
          status: PlanItemStatus.needsAttention,
          items: _items(2, status: PlanItemStatus.needsAttention),
          selectionMode: true,
          selectedIds: const {'id0'},
          onToggleSelected: (_) {},
          selectionFooter: const Text('Complete Tiles'),
        ),
      ));

      expect(find.text('Complete Tiles'), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('card surface comes from the shared theme', (tester) async {
      await tester.pumpWidget(_harness(
        theme: TileThemeData.darkTheme,
        child: PlanSectionCard(status: PlanItemStatus.placed, items: _items(2)),
      ));

      final Container card =
          tester.widget<Container>(find.byKey(PlanSectionCard.cardKey));
      expect((card.decoration as BoxDecoration).color,
          TodayStatusTokens.from(TileThemeData.darkTheme).surface);
    });
  });
}
