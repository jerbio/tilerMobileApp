// plan_section_grouping_test.dart
//
// Phase 7 follow-up: sub-events that share a parent calendar event collapse
// into one expandable group, and a row tap opens the tile (spec §9) rather
// than being consumed by the multi-select flow.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/todayStatus/planSectionCard.dart';
import 'package:tiler_app/components/todayStatus/planTaskRow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

PlanItemViewModel _item({
  required String id,
  required String title,
  String? parentId,
  PlanItemStatus status = PlanItemStatus.placed,
  int hour = 9,
}) {
  final source = SubCalendarEvent.fromJson({
    'id': id,
    'name': title,
    'start': DateTime(2026, 9, 1, hour).millisecondsSinceEpoch,
    'end': DateTime(2026, 9, 1, hour + 1).millisecondsSinceEpoch,
  });
  return PlanItemViewModel(
    id: id,
    title: title,
    status: status,
    source: source,
    parentId: parentId,
    scheduledStart: DateTime(2026, 9, 1, hour),
  );
}

Widget _harness(Widget child) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 390, child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('grouping by parent calendar event', () {
    testWidgets('collapses sibling sub-events into a single group row',
        (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 's1', title: 'Gym session', parentId: 'gym', hour: 7),
          _item(id: 's2', title: 'Gym session', parentId: 'gym', hour: 12),
          _item(id: 's3', title: 'Gym session', parentId: 'gym', hour: 18),
          _item(id: 'solo', title: 'Standup', hour: 9),
        ],
      )));

      // One group row + one ungrouped row; children stay hidden until expanded.
      expect(find.byType(PlanTaskRow), findsNWidgets(2));
      expect(find.text('Gym session'), findsOneWidget);
      expect(find.text('Standup'), findsOneWidget);
      expect(find.byKey(PlanSectionCard.groupToggleKey('gym')), findsOneWidget);
    });

    testWidgets('the group reports how many sessions it holds', (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 's1', title: 'Gym session', parentId: 'gym', hour: 7),
          _item(id: 's2', title: 'Gym session', parentId: 'gym', hour: 12),
          _item(id: 's3', title: 'Gym session', parentId: 'gym', hour: 18),
        ],
      )));

      expect(find.text('3 sessions'), findsOneWidget);
    });

    testWidgets('expanding a group reveals its sub-events', (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 's1', title: 'Gym session', parentId: 'gym', hour: 7),
          _item(id: 's2', title: 'Gym session', parentId: 'gym', hour: 12),
        ],
      )));

      await tester.tap(find.byKey(PlanSectionCard.groupToggleKey('gym')));
      await tester.pumpAndSettle();

      expect(find.byType(PlanTaskRow), findsNWidgets(3),
          reason: 'the group header row plus its two children');
    });

    testWidgets('a lone sub-event is not turned into a group', (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 's1', title: 'Gym session', parentId: 'gym'),
          _item(id: 'solo', title: 'Standup'),
        ],
      )));

      expect(find.byKey(PlanSectionCard.groupToggleKey('gym')), findsNothing);
      expect(find.byType(PlanTaskRow), findsNWidgets(2));
    });

    testWidgets('items without a parent id never group together',
        (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 'a', title: 'One'),
          _item(id: 'b', title: 'Two'),
        ],
      )));

      expect(find.byType(PlanTaskRow), findsNWidgets(2));
      expect(find.textContaining('sessions'), findsNothing);
    });

    testWidgets('the section header still counts every sub-event',
        (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 's1', title: 'Gym session', parentId: 'gym', hour: 7),
          _item(id: 's2', title: 'Gym session', parentId: 'gym', hour: 12),
          _item(id: 'solo', title: 'Standup', hour: 9),
        ],
      )));

      expect(find.text('3 tiles'), findsOneWidget);
    });
  });

  group('row tap opens the tile (spec §9)', () {
    testWidgets('attention rows open the tile instead of selecting',
        (tester) async {
      PlanItemViewModel? opened;
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.needsAttention,
        items: [
          _item(
              id: 'a1',
              title: 'Draft budget',
              status: PlanItemStatus.needsAttention),
        ],
        onItemTap: (item) => opened = item,
        onEnterSelectionMode: () {},
        onToggleSelected: (_) {},
      )));

      await tester.tap(find.byType(PlanTaskRow));
      expect(opened?.id, 'a1');
    });

    testWidgets('a group child row opens its own tile', (tester) async {
      PlanItemViewModel? opened;
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(id: 's1', title: 'Gym session', parentId: 'gym', hour: 7),
          _item(id: 's2', title: 'Gym session', parentId: 'gym', hour: 12),
        ],
        onItemTap: (item) => opened = item,
      )));

      await tester.tap(find.byKey(PlanSectionCard.groupToggleKey('gym')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PlanTaskRow).last);

      expect(opened?.id, 's2');
    });
  });

  group('entering selection mode', () {
    testWidgets('an explicit header control starts multi-select',
        (tester) async {
      int entered = 0;
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.needsAttention,
        items: [
          _item(
              id: 'a1',
              title: 'Draft budget',
              status: PlanItemStatus.needsAttention),
        ],
        onEnterSelectionMode: () => entered++,
        onToggleSelected: (_) {},
      )));

      await tester.tap(find.byKey(PlanSectionCard.enterSelectionKey));
      expect(entered, 1);
    });

    testWidgets('no select control when the section cannot be selected',
        (tester) async {
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [_item(id: 'p1', title: 'Standup')],
      )));

      expect(find.byKey(PlanSectionCard.enterSelectionKey), findsNothing);
    });

    testWidgets('while selecting, a row tap toggles instead of opening',
        (tester) async {
      final List<String> toggled = [];
      await tester.pumpWidget(_harness(PlanSectionCard(
        status: PlanItemStatus.needsAttention,
        items: [
          _item(
              id: 'a1',
              title: 'Draft budget',
              status: PlanItemStatus.needsAttention),
        ],
        selectionMode: true,
        onToggleSelected: toggled.add,
        onItemTap: (_) => fail('must not navigate while selecting'),
      )));

      await tester.tap(find.byType(PlanTaskRow));
      expect(toggled, ['a1']);
    });
  });
}
