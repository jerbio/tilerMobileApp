// Google-Calendar-style overlap columns.
//
// Two layers:
//   1. Pure unit tests for `OverlapColumns.assign` (the layout math).
//   2. Widget tests that pump `DayGridWidget` and assert per-tile
//      Positioned left/width + tap-to-raise z-order behaviour.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/overlapColumns.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Region matching a 400px viewport: gutter 35, +4 left / -8 total margins.
  const regionLeft = 39.0; // gutter(35) + 4
  const regionWidth = 357.0; // 400 - gutter(35) - 8
  const gap = OverlapColumns.defaultGap;

  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 5, 15, hour, minute);

  SubCalendarEvent tile(String id, DateTime start, DateTime end) =>
      SubCalendarEvent(
        id: id,
        name: id,
        start: start.millisecondsSinceEpoch,
        end: end.millisecondsSinceEpoch,
      );

  Map<String, TileColumnLayout> layout(List<SubCalendarEvent> tiles) =>
      OverlapColumns.assign<String, SubCalendarEvent>(
        tiles: tiles,
        keyOf: (t) => t.uniqueId,
        left: regionLeft,
        width: regionWidth,
      );

  group('OverlapColumns.assign', () {
    test('empty input -> empty map', () {
      expect(layout([]), isEmpty);
    });

    test('non-positive width -> empty map (caller falls back)', () {
      expect(
        OverlapColumns.assign<String, SubCalendarEvent>(
            tiles: [tile('a', at(8), at(9))],
            keyOf: (t) => t.uniqueId,
            left: regionLeft,
            width: 0),
        isEmpty);
    });

    test('singleton keeps the full region', () {
      final r = layout([tile('a', at(8), at(9))]);
      expect(r['a']!.left, regionLeft);
      expect(r['a']!.width, regionWidth);
    });

    test('non-overlapping tiles each keep the full region', () {
      final r =
          layout([tile('a', at(8), at(9)), tile('b', at(10), at(11))]);
      expect(r['a']!.left, regionLeft);
      expect(r['a']!.width, regionWidth);
      expect(r['b']!.left, regionLeft);
      expect(r['b']!.width, regionWidth);
    });

    test('two overlapping tiles share two columns', () {
      // A 8-10, B 9-11 -> one cluster, colCount 2.
      final r = layout([tile('a', at(8), at(10)), tile('b', at(9), at(11))]);
      final shared = (regionWidth - 1 * gap) / 2;
      expect(r['a']!.left, regionLeft);
      expect(r['a']!.width, shared);
      expect(r['b']!.left, regionLeft + (shared + gap));
      expect(r['b']!.width, shared);
      // A ends exactly where B begins (with the gap) — no x-overlap.
      expect(r['a']!.left + r['a']!.width + gap, r['b']!.left);
    });

    test('transitive cluster reuses a freed column (later-starting tile)', () {
      // A 8-10, B 9-11, C 10-12: A&B overlap, B&C overlap -> one cluster,
      // colCount 2. C starts exactly when A ends (10) so C reuses column 0.
      final r = layout([
        tile('a', at(8), at(10)),
        tile('b', at(9), at(11)),
        tile('c', at(10), at(12)),
      ]);
      final shared = (regionWidth - gap) / 2;
      expect(r['a']!.left, regionLeft); // col 0
      expect(r['b']!.left, regionLeft + (shared + gap)); // col 1
      expect(r['c']!.left, regionLeft); // col 0 (A ended at 10 == C start)
      expect(r['c']!.width, shared);
    });

    test('three fully-overlapping tiles use three columns', () {
      final r = layout([
        tile('a', at(9), at(12)),
        tile('b', at(9, 30), at(11)),
        tile('c', at(10), at(13)),
      ]);
      final shared = (regionWidth - 2 * gap) / 3;
      expect(r['a']!.left, regionLeft);
      expect(r['b']!.left, regionLeft + (shared + gap));
      expect(r['c']!.left, regionLeft + 2 * (shared + gap));
      expect(r['a']!.width, shared);
      expect(r['b']!.width, shared);
      expect(r['c']!.width, shared);
      // The rightmost column fills the region exactly (left + full span).
      // `moreOrLessEquals` because the 3-way split (353/3) isn't exact in fp.
      expect(r['c']!.left + r['c']!.width,
          moreOrLessEquals(regionLeft + regionWidth));
    });

    test('touching intervals do not share a cluster', () {
      // A 8-9, B 9-10 (B.start == A.end) -> strict isInterfering => separate.
      final r =
          layout([tile('a', at(8), at(9)), tile('b', at(9), at(10))]);
      expect(r['a']!.width, regionWidth);
      expect(r['b']!.width, regionWidth);
      expect(r['a']!.left, regionLeft);
      expect(r['b']!.left, regionLeft);
    });

    test('identical intervals get stable, distinct columns', () {
      // Input order b, a — ties resolve by key so a (col 0) precedes b (col 1).
      final r = layout([tile('b', at(8), at(9)), tile('a', at(8), at(9))]);
      final shared = (regionWidth - gap) / 2;
      expect(r['a']!.left, regionLeft);
      expect(r['b']!.left, regionLeft + (shared + gap));
      expect(r['a']!.width, shared);
      expect(r['b']!.width, shared);
    });
  });

  // ---- Widget integration ----

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

  /// Grid in a fixed 400x600 viewport (so scroll/column math is deterministic).
  /// A fixed [now] on a *different* date keeps the minute timer off
  /// (no pending Timer at teardown) and the now-line absent for a fully
  /// deterministic tree.
  Widget gridViewport(List<SubCalendarEvent> tiles) {
    return SizedBox(
      width: 400,
      height: 600,
      child: DayGridWidget(
        tiles: tiles,
        now: DateTime(2026, 5, 14, 12),
      ),
    );
  }

  /// The outermost [Positioned] a [TileGridWidget] builds (by stable key).
  Positioned tilePosition(WidgetTester tester, String id) {
    final tileFinder =
        find.byKey(ValueKey<String>('daygrid_tile_$id'));
    return tester.widget<Positioned>(find
        .descendant(of: tileFinder, matching: find.byType(Positioned))
        .first);
  }

  /// The laid-out size of a [TileGridWidget] (by its stable key).
  Size tileSize(WidgetTester tester, String id) =>
      tester.getSize(find.byKey(ValueKey<String>('daygrid_tile_$id')));

  /// The grid's own [Stack] (the nearest Stack ancestor of the tile — NOT the
  /// Scaffold's). Z-order among tiles is the order of its `TileGridWidget`
  /// children; the last one draws on top.
  Stack gridStack(WidgetTester tester, String tileId) {
    final finder = find
        .ancestor(
            of: find.byKey(ValueKey<String>('daygrid_tile_$tileId')),
            matching: find.byType(Stack))
        .first;
    return tester.widget<Stack>(finder);
  }

  /// Zero-based z-order rank among the grid's *tiles* only (the tap-to-add layer
  /// and the 24 gutter rows are skipped). Higher = drawn later = on top.
  int tileIndex(Stack stack, String id) {
    final key = 'daygrid_tile_$id';
    var tileRank = -1;
    for (final w in stack.children) {
      if (w is! TileGridWidget) {
        continue;
      }
      tileRank += 1;
      if ((w.key as ValueKey<String>?)?.value == key) {
        return tileRank;
      }
    }
    return -1;
  }

  group('DayGridWidget overlap columns', () {
    testWidgets('non-overlapping tiles each keep the full region',
        (tester) async {
      final tiles = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 9)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 11)),
        buildTile(
            id: 'c',
            name: 'Gamma',
            start: DateTime(2026, 5, 15, 12),
            end: DateTime(2026, 5, 15, 13)),
      ];
      await tester.pumpWidget(buildTestApp(child: gridViewport(tiles)));
      await tester.pump(const Duration(milliseconds: 100));
      for (final id in const ['a', 'b', 'c']) {
        expect(tilePosition(tester, id).left, regionLeft);
        expect(tileSize(tester, id).width, regionWidth);
      }
    });

    testWidgets('overlapping tiles split into shared-width columns',
        (tester) async {
      // A 8-10 and B 9-11 overlap -> one two-column cluster.
      final tiles = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 10)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 9),
            end: DateTime(2026, 5, 15, 11)),
      ];
      await tester.pumpWidget(buildTestApp(child: gridViewport(tiles)));
      await tester.pump(const Duration(milliseconds: 100));
      final shared = (regionWidth - gap) / 2;
      final aLeft = tilePosition(tester, 'a').left!;
      final aWidth = tileSize(tester, 'a').width;
      final bLeft = tilePosition(tester, 'b').left!;
      // A occupies column 0, B column 1.
      expect(aLeft, regionLeft);
      expect(aWidth, shared);
      expect(bLeft, regionLeft + (shared + gap));
      expect(tileSize(tester, 'b').width, shared);
      // A ends exactly where B begins (plus the gap) — no x-overlap.
      expect(aLeft + aWidth + gap, bLeft);
    });

    testWidgets('tapping a tile raises it above its neighbours (z-order)',
        (tester) async {
      // Non-overlapping so each tile stays independently tappable — this
      // isolates the pre-existing tap-to-raise behaviour.
      final tiles = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 9)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 11)),
      ];
      await tester.pumpWidget(buildTestApp(child: gridViewport(tiles)));
      await tester.pump(const Duration(milliseconds: 100));
      final stack = gridStack(tester, 'a');
      expect(tileIndex(stack, 'a'), 0);
      expect(tileIndex(stack, 'b'), 1);
      // Tap A: it becomes the selected (top) tile, moving above B.
      await tester.tap(find.byKey(ValueKey<String>('daygrid_tile_a')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final stackAfter = gridStack(tester, 'a');
      expect(tileIndex(stackAfter, 'a'), 1); // raised to the top
      expect(tileIndex(stackAfter, 'b'), 0);
    });

    testWidgets('tapping does not duplicate the tile', (tester) async {
      final tiles = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 9)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 11)),
      ];
      await tester.pumpWidget(buildTestApp(child: gridViewport(tiles)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TileGridWidget), findsNWidgets(2));
      await tester.tap(find.byKey(ValueKey<String>('daygrid_tile_a')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Selection re-orders the Stack; it never adds a second widget.
      expect(find.byType(TileGridWidget), findsNWidgets(2));
    });
  });
}