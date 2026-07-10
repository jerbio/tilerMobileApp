import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionHeader.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionList.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastCompositeSummary.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastHeaderSheet.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
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

VibePreviewAction _previewAction(ActionType type, {String? description}) =>
    VibePreviewAction(
      entityId: 'e_${type.name}',
      action: VibeAction(
        id: 'a_${type.name}',
        descriptions: description ?? type.name,
        type: type,
        entityId: 'e_${type.name}',
      ),
    );

// ---------------------------------------------------------------------------
// VibePreviewAction.isHighlightable — pure logic, no widget tree needed
// ---------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VibePreviewAction.isHighlightable', () {
    test('true for task-adding types', () {
      expect(_previewAction(ActionType.addNewTask).isHighlightable, isTrue);
      expect(_previewAction(ActionType.addNewAppointment).isHighlightable,
          isTrue);
      expect(_previewAction(ActionType.updateExistingTask).isHighlightable,
          isTrue);
      expect(_previewAction(ActionType.addNewProject).isHighlightable, isTrue);
    });

    test('true for what-if types that produce a new entity', () {
      expect(
          _previewAction(ActionType.whatIfAddedNewTask).isHighlightable, isTrue);
      expect(_previewAction(ActionType.whatIfAddANewAppointment).isHighlightable,
          isTrue);
      expect(
          _previewAction(ActionType.whatIfEditUpdateTask).isHighlightable, isTrue);
    });

    test('false for removal and mark-done types', () {
      expect(
          _previewAction(ActionType.removeExistingTask).isHighlightable, isFalse);
      expect(_previewAction(ActionType.markTaskAsDone).isHighlightable, isFalse);
      expect(_previewAction(ActionType.exitPrompting).isHighlightable, isFalse);
      expect(_previewAction(ActionType.whatIfRemovedTask).isHighlightable,
          isFalse);
      expect(_previewAction(ActionType.whatIfMarkedTaskAsDone).isHighlightable,
          isFalse);
      expect(
          _previewAction(ActionType.conversationalAndNotSupported).isHighlightable,
          isFalse);
      expect(_previewAction(ActionType.none).isHighlightable, isFalse);
    });

    test('false when action is null', () {
      final noAction = VibePreviewAction(entityId: 'e');
      expect(noAction.isHighlightable, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // TileCastCompositeSummary widget
  // -------------------------------------------------------------------------
  group('TileCastCompositeSummary', () {
    testWidgets('renders each action description', (t) async {
      final actions = [
        _previewAction(ActionType.removeExistingTask,
            description: 'Remove evening run'),
        _previewAction(ActionType.markTaskAsDone, description: 'Mark run done'),
        _previewAction(ActionType.exitPrompting, description: 'Exit chat'),
      ];
      await t.pumpWidget(_wrap(TileCastCompositeSummary(actions: actions)));
      await t.pump();

      expect(find.text('Remove evening run'), findsOneWidget);
      expect(find.text('Mark run done'), findsOneWidget);
      expect(find.text('Exit chat'), findsOneWidget);
    });

    testWidgets('renders nothing when list is empty', (t) async {
      await t.pumpWidget(
          _wrap(const TileCastCompositeSummary(actions: [])));
      await t.pump();
      expect(
          find.byKey(const ValueKey('tilecast_composite_summary')), findsNothing);
    });

    testWidgets('shows the "Also included" label', (t) async {
      await t.pumpWidget(_wrap(TileCastCompositeSummary(actions: [
        _previewAction(ActionType.removeExistingTask,
            description: 'Remove evening run'),
      ])));
      await t.pump();
      expect(find.text('Also included'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // TileCastCompositeSummary — truncation
  // -------------------------------------------------------------------------
  group('TileCastCompositeSummary truncation', () {
    List<VibePreviewAction> _manyActions(int n) => List.generate(
          n,
          (i) => _previewAction(ActionType.removeExistingTask,
              description: 'Action $i'),
        );

    testWidgets('shows all rows when count <= maxVisible', (t) async {
      await t.pumpWidget(
          _wrap(TileCastCompositeSummary(actions: _manyActions(3))));
      await t.pump();
      expect(find.text('Action 0'), findsOneWidget);
      expect(find.text('Action 1'), findsOneWidget);
      expect(find.text('Action 2'), findsOneWidget);
      expect(find.textContaining('more'), findsNothing);
    });

    testWidgets('truncates and shows "+ N more" when count > maxVisible',
        (t) async {
      await t.pumpWidget(
          _wrap(TileCastCompositeSummary(actions: _manyActions(5))));
      await t.pump();
      // Default maxVisible = 3: first 3 visible, overflow shows "+ 2 more"
      expect(find.text('Action 0'), findsOneWidget);
      expect(find.text('Action 1'), findsOneWidget);
      expect(find.text('Action 2'), findsOneWidget);
      expect(find.text('Action 3'), findsNothing);
      expect(find.text('Action 4'), findsNothing);
      expect(find.textContaining('+ 2 more'), findsOneWidget);
    });

    testWidgets('custom maxVisible respected', (t) async {
      await t.pumpWidget(_wrap(
          TileCastCompositeSummary(actions: _manyActions(6), maxVisible: 2)));
      await t.pump();
      expect(find.text('Action 0'), findsOneWidget);
      expect(find.text('Action 1'), findsOneWidget);
      expect(find.text('Action 2'), findsNothing);
      expect(find.textContaining('+ 4 more'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // TileCastActionList — composite group routing
  // -------------------------------------------------------------------------
  group('TileCastActionList composite group', () {
    List<VibePreviewAction> _twoActions() => [
          _previewAction(ActionType.addNewTask, description: 'Add Drinks'),
          _previewAction(ActionType.removeExistingTask,
              description: 'Remove Run'),
        ];

    testWidgets('composite-group item shows group icon', (t) async {
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: _twoActions(),
        selectedIndex: 0,
        compositeGroupIndices: const {1},
        onSelect: (_) {},
      )));
      await t.pump();
      expect(
          find.byKey(TileCastActionList.compositeGroupIconKey(1)), findsOneWidget);
      expect(
          find.byKey(TileCastActionList.compositeGroupIconKey(0)), findsNothing);
    });

    testWidgets('composite-group items are highlighted when composite page is active',
        (t) async {
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: _twoActions(),
        selectedIndex: -1,
        isCompositeSelected: true,
        compositeGroupIndices: const {1},
        onSelect: (_) {},
      )));
      await t.pump();
      final tile = t.widget<ListTile>(
          find.byKey(TileCastActionList.itemKey(1)));
      expect(tile.selected, isTrue);
    });

    testWidgets('non-composite item is not highlighted when composite page is active',
        (t) async {
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: _twoActions(),
        selectedIndex: -1,
        isCompositeSelected: true,
        compositeGroupIndices: const {1},
        onSelect: (_) {},
      )));
      await t.pump();
      final tile = t.widget<ListTile>(
          find.byKey(TileCastActionList.itemKey(0)));
      expect(tile.selected, isFalse);
    });

    testWidgets('tapping a composite-group item calls onSelect with its index',
        (t) async {
      int? tapped;
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: _twoActions(),
        selectedIndex: 0,
        compositeGroupIndices: const {1},
        onSelect: (i) => tapped = i,
      )));
      await t.pump();
      await t.tap(find.byKey(TileCastActionList.itemKey(1)));
      await t.pump();
      expect(tapped, 1);
    });
  });

  // -------------------------------------------------------------------------
  // TileCastHeaderSheet titleOverride for composite page
  // -------------------------------------------------------------------------
  group('TileCastHeaderSheet titleOverride', () {
    testWidgets('shows titleOverride text instead of action description',
        (t) async {
      await t.pumpWidget(_wrap(TileCastHeaderSheet(
        action: _previewAction(ActionType.addNewTask,
            description: 'Add gym session'),
        index: 2,
        total: 3,
        titleOverride: 'Also included (2)',
        autoHideDelay: const Duration(milliseconds: 50),
        slideDuration: const Duration(milliseconds: 20),
      )));
      await t.pump();

      expect(find.text('Also included (2)'), findsOneWidget);
      expect(find.text('Add gym session'), findsNothing);
      await t.pumpAndSettle();
    });

    testWidgets('position counter still reflects index + 1 / total', (t) async {
      await t.pumpWidget(_wrap(TileCastHeaderSheet(
        action: _previewAction(ActionType.addNewTask),
        index: 2,
        total: 3,
        titleOverride: 'Also included (1)',
        autoHideDelay: const Duration(milliseconds: 50),
        slideDuration: const Duration(milliseconds: 20),
      )));
      await t.pump();

      final position =
          t.widget<Text>(find.byKey(TileCastHeaderSheet.positionKey));
      expect(position.data, '3 / 3');
      await t.pumpAndSettle();
    });

    testWidgets('prev/next/list callbacks still fire on tap', (t) async {
      int prev = 0, next = 0, list = 0;
      await t.pumpWidget(_wrap(TileCastHeaderSheet(
        action: _previewAction(ActionType.addNewTask),
        index: 1,
        total: 3,
        titleOverride: 'Also included (1)',
        onPrev: () => prev++,
        onNext: () => next++,
        onOpenList: () => list++,
        autoHideDelay: const Duration(milliseconds: 50),
        slideDuration: const Duration(milliseconds: 20),
      )));

      await t.tap(find.byKey(TileCastHeaderSheet.prevKey));
      await t.tap(find.byKey(TileCastHeaderSheet.nextKey));
      await t.tap(find.byKey(TileCastHeaderSheet.listKey));
      await t.pump();

      expect(prev, 1);
      expect(next, 1);
      expect(list, 1);
      await t.pumpAndSettle();
    });
  });
}
