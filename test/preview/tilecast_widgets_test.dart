import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionHeader.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastActionList.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

VibePreviewAction _action({
  String? description,
  String? entityId,
  ActionType type = ActionType.addNewTask,
}) {
  return VibePreviewAction(
    entityId: entityId,
    action: VibeAction(
      id: entityId,
      descriptions: description,
      type: type,
      entityId: entityId,
    ),
  );
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TileCastActionHeader', () {
    testWidgets('renders description title and 1-based position', (t) async {
      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'Add gym session'),
        index: 1,
        total: 3,
      )));

      expect(find.text('Add gym session'), findsOneWidget);
      final position = t.widget<Text>(find.byKey(TileCastActionHeader.positionKey));
      expect(position.data, '2 / 3');
    });

    testWidgets('prev disabled on first page, next disabled on last', (t) async {
      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'first'),
        index: 0,
        total: 2,
        onPrev: () {},
        onNext: () {},
      )));
      final prev = t.widget<IconButton>(find.byKey(TileCastActionHeader.prevKey));
      final next = t.widget<IconButton>(find.byKey(TileCastActionHeader.nextKey));
      expect(prev.onPressed, isNull);
      expect(next.onPressed, isNotNull);

      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'last'),
        index: 1,
        total: 2,
        onPrev: () {},
        onNext: () {},
      )));
      final prev2 = t.widget<IconButton>(find.byKey(TileCastActionHeader.prevKey));
      final next2 = t.widget<IconButton>(find.byKey(TileCastActionHeader.nextKey));
      expect(prev2.onPressed, isNotNull);
      expect(next2.onPressed, isNull);
    });

    testWidgets('next/prev/list callbacks fire on tap', (t) async {
      int prev = 0, next = 0, list = 0;
      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'middle'),
        index: 1,
        total: 3,
        onPrev: () => prev++,
        onNext: () => next++,
        onOpenList: () => list++,
      )));

      await t.tap(find.byKey(TileCastActionHeader.prevKey));
      await t.tap(find.byKey(TileCastActionHeader.nextKey));
      await t.tap(find.byKey(TileCastActionHeader.listKey));
      await t.pump();

      expect(prev, 1);
      expect(next, 1);
      expect(list, 1);
    });

    testWidgets('shows stale banner only when stale', (t) async {
      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'x'),
        index: 0,
        total: 1,
        isStale: false,
      )));
      expect(find.byKey(TileCastActionHeader.staleBannerKey), findsNothing);

      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'x'),
        index: 0,
        total: 1,
        isStale: true,
      )));
      expect(find.byKey(TileCastActionHeader.staleBannerKey), findsOneWidget);
    });

    testWidgets('shows non-viable badge only when non-viable', (t) async {
      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'x'),
        index: 0,
        total: 1,
        isNonViable: false,
      )));
      expect(find.byKey(TileCastActionHeader.nonViableKey), findsNothing);

      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: 'x'),
        index: 0,
        total: 1,
        isNonViable: true,
      )));
      expect(find.byKey(TileCastActionHeader.nonViableKey), findsOneWidget);
    });

    testWidgets('falls back to reviewChanges label when description empty',
        (t) async {
      await t.pumpWidget(_wrap(TileCastActionHeader(
        action: _action(description: '   '),
        index: 0,
        total: 1,
      )));
      final title = t.widget<Text>(find.byKey(TileCastActionHeader.titleKey));
      expect(title.data, isNotEmpty);
    });
  });

  group('TileCastActionList', () {
    testWidgets('renders one row per action', (t) async {
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: [
          _action(description: 'a'),
          _action(description: 'b'),
          _action(description: 'c'),
        ],
        selectedIndex: 0,
        onSelect: (_) {},
      )));
      expect(find.byKey(TileCastActionList.itemKey(0)), findsOneWidget);
      expect(find.byKey(TileCastActionList.itemKey(1)), findsOneWidget);
      expect(find.byKey(TileCastActionList.itemKey(2)), findsOneWidget);
    });

    testWidgets('marks the selected row as selected', (t) async {
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: [_action(description: 'a'), _action(description: 'b')],
        selectedIndex: 1,
        onSelect: (_) {},
      )));
      final selected =
          t.widget<ListTile>(find.byKey(TileCastActionList.itemKey(1)));
      final unselected =
          t.widget<ListTile>(find.byKey(TileCastActionList.itemKey(0)));
      expect(selected.selected, isTrue);
      expect(unselected.selected, isFalse);
    });

    testWidgets('tapping a row reports its index', (t) async {
      int? tapped;
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: [_action(description: 'a'), _action(description: 'b')],
        selectedIndex: 0,
        onSelect: (i) => tapped = i,
      )));
      await t.tap(find.byKey(TileCastActionList.itemKey(1)));
      await t.pump();
      expect(tapped, 1);
    });

    testWidgets('badges actions whose entity is non-viable', (t) async {
      await t.pumpWidget(_wrap(TileCastActionList(
        actions: [
          _action(description: 'a', entityId: 'e1'),
          _action(description: 'b', entityId: 'e2'),
        ],
        selectedIndex: 0,
        nonViableEntityIds: const {'e2'},
        onSelect: (_) {},
      )));
      expect(find.byKey(TileCastActionList.nonViableBadgeKey(0)), findsNothing);
      expect(
          find.byKey(TileCastActionList.nonViableBadgeKey(1)), findsOneWidget);
    });
  });
}
