import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastHeaderSheet.dart';
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

TileCastHeaderSheet _sheet({
  String description = 'Add gym session',
  int index = 1,
  int total = 3,
  bool isStale = false,
  bool isNonViable = false,
  VoidCallback? onPrev,
  VoidCallback? onNext,
  VoidCallback? onOpenList,
}) {
  return TileCastHeaderSheet(
    action: _action(description: description, entityId: 'e$index'),
    index: index,
    total: total,
    isStale: isStale,
    isNonViable: isNonViable,
    onPrev: onPrev,
    onNext: onNext,
    onOpenList: onOpenList,
    autoHideDelay: const Duration(milliseconds: 100),
    slideDuration: const Duration(milliseconds: 40),
  );
}

double _sizeFactor(WidgetTester t) =>
    t.widget<SizeTransition>(find.byType(SizeTransition)).sizeFactor.value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TileCastHeaderSheet strip', () {
    testWidgets('renders 1-based position and the action title', (t) async {
      await t.pumpWidget(_wrap(_sheet()));
      await t.pump();

      final position =
          t.widget<Text>(find.byKey(TileCastHeaderSheet.positionKey));
      expect(position.data, '2 / 3');
      expect(find.text('Add gym session'), findsOneWidget);

      await t.pumpAndSettle();
    });

    testWidgets('prev disabled on first page, next disabled on last',
        (t) async {
      await t.pumpWidget(_wrap(
          _sheet(index: 0, total: 2, onPrev: () {}, onNext: () {})));
      final prev =
          t.widget<IconButton>(find.byKey(TileCastHeaderSheet.prevKey));
      final next =
          t.widget<IconButton>(find.byKey(TileCastHeaderSheet.nextKey));
      expect(prev.onPressed, isNull);
      expect(next.onPressed, isNotNull);
      await t.pumpAndSettle();

      await t.pumpWidget(_wrap(
          _sheet(index: 1, total: 2, onPrev: () {}, onNext: () {})));
      final prev2 =
          t.widget<IconButton>(find.byKey(TileCastHeaderSheet.prevKey));
      final next2 =
          t.widget<IconButton>(find.byKey(TileCastHeaderSheet.nextKey));
      expect(prev2.onPressed, isNotNull);
      expect(next2.onPressed, isNull);
      await t.pumpAndSettle();
    });

    testWidgets('prev/next/list callbacks fire on tap', (t) async {
      int prev = 0, next = 0, list = 0;
      await t.pumpWidget(_wrap(_sheet(
        onPrev: () => prev++,
        onNext: () => next++,
        onOpenList: () => list++,
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

    testWidgets('warning dot only shows for stale or non-viable', (t) async {
      await t.pumpWidget(_wrap(_sheet()));
      expect(find.byKey(TileCastHeaderSheet.warningDotKey), findsNothing);
      await t.pumpAndSettle();

      await t.pumpWidget(_wrap(_sheet(isNonViable: true)));
      expect(find.byKey(TileCastHeaderSheet.warningDotKey), findsOneWidget);
      await t.pumpAndSettle();
    });
  });

  group('TileCastHeaderSheet auto-hide', () {
    testWidgets('starts revealed then retracts after the delay', (t) async {
      await t.pumpWidget(_wrap(_sheet()));
      await t.pump();
      expect(_sizeFactor(t), greaterThan(0.9));

      // Wait past the auto-hide delay and let the slide finish.
      await t.pump(const Duration(milliseconds: 120));
      await t.pumpAndSettle();
      expect(_sizeFactor(t), lessThan(0.1));
    });

    testWidgets('re-reveals when the index changes', (t) async {
      await t.pumpWidget(_wrap(_sheet(index: 0)));
      await t.pump(const Duration(milliseconds: 120));
      await t.pumpAndSettle();
      expect(_sizeFactor(t), lessThan(0.1));

      // New action selected -> should peek open again.
      await t.pumpWidget(_wrap(_sheet(index: 1)));
      await t.pump(const Duration(milliseconds: 40));
      expect(_sizeFactor(t), greaterThan(0.5));
      await t.pumpAndSettle();
    });

    testWidgets('tapping the handle pins it open (no auto-hide)', (t) async {
      await t.pumpWidget(_wrap(_sheet()));
      // Let it auto-collapse first.
      await t.pump(const Duration(milliseconds: 120));
      await t.pumpAndSettle();
      expect(_sizeFactor(t), lessThan(0.1));

      // Tap handle to open + pin.
      await t.tap(find.byKey(TileCastHeaderSheet.handleKey));
      await t.pumpAndSettle();
      expect(_sizeFactor(t), greaterThan(0.9));

      // Stays open past the auto-hide delay because it is pinned.
      await t.pump(const Duration(milliseconds: 200));
      await t.pumpAndSettle();
      expect(_sizeFactor(t), greaterThan(0.9));
    });
  });
}
