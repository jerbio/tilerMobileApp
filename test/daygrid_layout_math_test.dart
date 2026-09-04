// DayGrid P1 step 1.4 — parametric rendering from DayGridController.pxPerHour,
// responsive tile width, cross-midnight clamping, and >=16h exclusion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  SubCalendarEvent buildTile({
    required String id,
    required String name,
    required DateTime start,
    required DateTime end,
  }) {
    return SubCalendarEvent(
      id: id,
      name: name,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
    );
  }

  /// The outermost [Positioned] a [TileGridWidget] builds (by stable key).
  Positioned tilePosition(WidgetTester tester, String id) {
    final tileFinder = find.byKey(ValueKey<String>('daygrid_tile_$id'));
    return tester.widget<Positioned>(find
        .descendant(of: tileFinder, matching: find.byType(Positioned))
        .first);
  }

  /// The laid-out size of a [TileGridWidget] (by its stable key).
  Size tileSize(WidgetTester tester, String id) =>
      tester.getSize(find.byKey(ValueKey<String>('daygrid_tile_$id')));

  group('DayGrid layout math (step 1.4)', () {
    testWidgets('tile top/height track pxPerHour at 40 / 80 / 240',
        (tester) async {
      final tile = buildTile(
          id: 'a',
          name: 'Alpha',
          start: DateTime(2026, 5, 15, 9, 30),
          end: DateTime(2026, 5, 15, 10, 30));

      const cases = <(double, double, double)>[
        (40, 380, 40), // 9.5h * 40, 1h * 40
        (80, 760, 80),
        (240, 2280, 240),
      ];
      for (final (px, expectedTop, expectedHeight) in cases) {
        final controller = DayGridController()..setPxPerHour(px);
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildTestApp(
            child: SizedBox(
                width: 400,
                height: 600,
                child: DayGridWidget(tiles: [tile], controller: controller))));
        await tester.pump(const Duration(milliseconds: 100));

        expect(tilePosition(tester, 'a').top, expectedTop,
            reason: 'top at pxPerHour $px');
        expect(tileSize(tester, 'a').height, expectedHeight,
            reason: 'height at pxPerHour $px');
        // Clean up the tree between cases.
        await tester.pumpWidget(
            buildTestApp(child: const SizedBox(width: 400, height: 600)));
        await tester.pump();
      }
    });
    testWidgets('pxPerHour change repositions without remount (key identity)',
        (tester) async {
      final tile = buildTile(
          id: 'a',
          name: 'Alpha',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 15, 9));
      final controller = DayGridController(); // 80 px/h default
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(
          child: SizedBox(
              width: 400,
              height: 600,
              child: DayGridWidget(tiles: [tile], controller: controller))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tilePosition(tester, 'a').top, 640); // 8h * 80

      final elementBefore =
          tester.element(find.byKey(const ValueKey<String>('daygrid_tile_a')));

      controller.setPxPerHour(240);
      await tester.pump(const Duration(milliseconds: 100));

      final elementAfter =
          tester.element(find.byKey(const ValueKey<String>('daygrid_tile_a')));
      expect(identical(elementBefore, elementAfter), isTrue,
          reason: 'tile element must be reused, not remounted');
      expect(tilePosition(tester, 'a').top, 1920); // 8h * 240
      expect(tileSize(tester, 'a').height, 240); // 1h * 240
    });

    testWidgets('cross-midnight tile clamps to the grid day bounds',
        (tester) async {
      // Grid day = 2026-05-15 (earliest tile starts on that day).
      final crosser = buildTile(
          id: 'c',
          name: 'Crosser',
          start: DateTime(2026, 5, 15, 22),
          end: DateTime(2026, 5, 16, 1)); // 22:00 -> 01:00
      final nextDay = buildTile(
          id: 'n',
          name: 'NextDay',
          start: DateTime(2026, 5, 16, 10),
          end: DateTime(2026, 5, 16, 11)); // fully outside the grid day
      final controller = DayGridController(); // 80 px/h
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(
          child: SizedBox(
              width: 400,
              height: 600,
              child: DayGridWidget(
                  tiles: [crosser, nextDay], controller: controller))));
      await tester.pump(const Duration(milliseconds: 100));

      // Clamped to the day: top = 22h * 80, height = 2h * 80 (not 3h).
      expect(tilePosition(tester, 'c').top, 1760);
      expect(tileSize(tester, 'c').height, 160);
      // A tile fully on the next day is not part of this day's timeline.
      expect(
          find.byKey(const ValueKey<String>('daygrid_tile_n')), findsNothing);
    });

    testWidgets('tile ending exactly at midnight clamps its bottom to 24h',
        (tester) async {
      final nightOwl = buildTile(
          id: 'n',
          name: 'NightOwl',
          start: DateTime(2026, 5, 15, 23),
          end: DateTime(2026, 5, 16, 0));
      final controller = DayGridController(); // 80 px/h
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(
          child: SizedBox(
              width: 400,
              height: 600,
              child:
                  DayGridWidget(tiles: [nightOwl], controller: controller))));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tilePosition(tester, 'n').top, 23 * 80);
      expect(tileSize(tester, 'n').height, 80);
      // top + height must not exceed the 24h content height.
      expect(tilePosition(tester, 'n').top! + tileSize(tester, 'n').height,
          lessThanOrEqualTo(24 * 80));
    });

    testWidgets('>= 16h tiles are excluded from the timeline', (tester) async {
      final longTile = buildTile(
          id: 'l',
          name: 'LongTile',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 16, 2)); // 18h
      final normal = buildTile(
          id: 'n',
          name: 'Normal',
          start: DateTime(2026, 5, 15, 14),
          end: DateTime(2026, 5, 15, 15));
      final controller = DayGridController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(
          child: SizedBox(
              width: 400,
              height: 600,
              child: DayGridWidget(
                  tiles: [longTile, normal], controller: controller))));
      await tester.pump(const Duration(milliseconds: 100));

      // The 18h tile belongs to the pinned header (step 1.7), not the grid.
      expect(
          find.byKey(const ValueKey<String>('daygrid_tile_l')), findsNothing);
      expect(find.text('LongTile'), findsNothing);
      expect(
          find.byKey(const ValueKey<String>('daygrid_tile_n')), findsOneWidget);
    });

    testWidgets(
        'tile width fills the viewport minus the gutter (narrow and wide)',
        (tester) async {
      final tile = buildTile(
          id: 'a',
          name: 'Alpha',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 15, 9));
      final gutter = TileDimensions.timeOfDayCellWidth;

      for (final viewportWidth in <double>[400, 800]) {
        await tester.pumpWidget(buildTestApp(
            child: SizedBox(
                width: viewportWidth,
                height: 600,
                child: DayGridWidget(tiles: [tile]))));
        await tester.pump(const Duration(milliseconds: 100));

        final position = tilePosition(tester, 'a');
        final size = tileSize(tester, 'a');
        expect(position.left, gutter + 4,
            reason: 'tile starts just after the $gutter gutter');
        expect(size.width, viewportWidth - gutter - 8,
            reason: 'tile fills the viewport minus gutter at $viewportWidth');
        await tester.pumpWidget(
            buildTestApp(child: const SizedBox(width: 400, height: 600)));
        await tester.pump();
      }
    });
  });
}
