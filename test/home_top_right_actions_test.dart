// home_top_right_actions_test.dart
//
// P5 Step 15.1: extracts the icon Row out of the overlay-only
// HomeTopRightActions into a reusable, non-Positioned HomeTopRightActionsRow
// so the grid-mode DayGridTopChromeRow (Step 15.2) can reuse the same icon
// logic. These tests pin that the extracted row is standalone (no Stack or
// Positioned ancestor required) and behaves identically to what
// HomeTopRightActions rendered before the extraction; the legacy
// HomeTopRightActions wrapper is re-tested too (same icons, same tap
// callbacks, same Positioned placement).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
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

Widget _row({
  bool isViewingToday = true,
  VoidCallback? onSearch,
  VoidCallback? onSettings,
  VoidCallback? onGoToToday,
  DailyViewLayout? dayGridLayout,
  VoidCallback? onDayGridLayoutToggle,
}) {
  return _wrap(
    HomeTopRightActionsRow(
      isViewingToday: isViewingToday,
      onSearch: onSearch ?? () {},
      onSettings: onSettings ?? () {},
      onGoToToday: onGoToToday ?? () {},
      dayGridLayout: dayGridLayout,
      onDayGridLayoutToggle: onDayGridLayoutToggle,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeTopRightActionsRow (extracted, non-Positioned)', () {
    testWidgets('renders standalone with no Positioned ancestor of its own',
        (tester) async {
      await tester.pumpWidget(_row());
      await tester.pump();

      expect(find.byType(HomeTopRightActionsRow), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      // The row must not itself be wrapped in a Positioned — that's the
      // whole point of the extraction (Positioned lives on the legacy
      // HomeTopRightActions wrapper instead).
      expect(
        find.ancestor(
          of: find.byType(HomeTopRightActionsRow),
          matching: find.byType(Positioned),
        ),
        findsNothing,
      );
    });

    testWidgets('exposes the tutorial spotlight key', (tester) async {
      await tester.pumpWidget(_row());
      await tester.pump();

      expect(find.byKey(TutorialKeys.topRightActionsKey), findsOneWidget);
    });

    testWidgets('"Go to Today" is hidden when viewing today', (tester) async {
      await tester.pumpWidget(_row(isViewingToday: true));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('"Go to Today" is visible when not viewing today',
        (tester) async {
      await tester.pumpWidget(_row(isViewingToday: false));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('list/grid toggle is hidden when layout is not provided',
        (tester) async {
      await tester.pumpWidget(_row());
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsNothing);
      expect(find.byIcon(Icons.view_list), findsNothing);
    });

    testWidgets('shows the toggle icon for the target layout when provided',
        (tester) async {
      await tester.pumpWidget(_row(
        dayGridLayout: DailyViewLayout.list,
        onDayGridLayoutToggle: () {},
      ));
      await tester.pump();

      // The icon shows the layout the user would switch TO: currently in
      // list, so the grid icon is offered.
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsNothing);
    });

    testWidgets('tapping search calls onSearch', (tester) async {
      bool called = false;
      await tester.pumpWidget(_row(onSearch: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      expect(called, isTrue);
    });

    testWidgets('tapping settings calls onSettings', (tester) async {
      bool called = false;
      await tester.pumpWidget(_row(onSettings: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      expect(called, isTrue);
    });

    testWidgets('tapping "Go to Today" calls onGoToToday', (tester) async {
      bool called = false;
      await tester.pumpWidget(
          _row(isViewingToday: false, onGoToToday: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.calendar_today));
      expect(called, isTrue);
    });

    testWidgets('tapping the layout toggle calls onDayGridLayoutToggle',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(_row(
        dayGridLayout: DailyViewLayout.list,
        onDayGridLayoutToggle: () => called = true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.grid_view));
      expect(called, isTrue);
    });
  });

  group('HomeTopRightActions (legacy Positioned wrapper) still renders identically', () {
    Widget buildOverlay({
      bool isViewingToday = true,
      VoidCallback? onSearch,
      VoidCallback? onSettings,
      VoidCallback? onGoToToday,
    }) {
      return _wrap(
        Stack(
          children: [
            HomeTopRightActions(
              isViewingToday: isViewingToday,
              onSearch: onSearch ?? () {},
              onSettings: onSettings ?? () {},
              onGoToToday: onGoToToday ?? () {},
            ),
          ],
        ),
      );
    }

    testWidgets('still wraps the extracted row, not the raw icon Row',
        (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      expect(find.byType(HomeTopRightActionsRow), findsOneWidget);
    });

    testWidgets('keeps its top-0/right-8 Positioned placement', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      final positionedFinder = find.ancestor(
        of: find.byKey(TutorialKeys.topRightActionsKey),
        matching: find.byType(Positioned),
      );
      expect(positionedFinder, findsOneWidget);
      final positioned = tester.widget<Positioned>(positionedFinder.first);
      expect(positioned.top, 0);
      expect(positioned.right, 8);
    });

    testWidgets('still shows the search and settings icons', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('tapping search still calls onSearch', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildOverlay(onSearch: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      expect(called, isTrue);
    });

    testWidgets('tapping settings still calls onSettings', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildOverlay(onSettings: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      expect(called, isTrue);
    });
  });
}