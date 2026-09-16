// P9 Step 18.1 — the occupancy rail's pure segment math (C37–C39, C41):
//   * the rail marks every stretch of the day NOT claimed by a BLOCK — free
//     time and tile time alike (the complement of the blocks);
//   * blocks = renderable rigid tiles (non-viable / pending / declined
//     third-party ones do not subtract); tiles never subtract;
//   * travel never counts — a block claims only its own [start, end];
//   * overlapping / touching blocks merge; output is sorted, day-clamped;
//   * `split` cuts a segment at "now" into its past / future halves.
// Step 18.2 (C40–C43): the grid paints the segments as 2 px bars in a 6 px
// lane at the far right (right of the travel rail), in the Tiler accent,
// non-interactive, past half dimmer on today, positioned with the tiles' own animation gate.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/occupancyRail.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

final DateTime _day = DateTime(2027, 1, 15);
int _at(int h, [int m = 0]) =>
    _day.add(Duration(hours: h, minutes: m)).millisecondsSinceEpoch;

SubCalendarEvent _tile(String id, int startMs, int endMs,
    {bool rigid = false,
    bool viable = true,
    RsvpStatus? rsvp,
    TileSource? source,
    double? travelBefore,
    double? travelAfter}) {
  final tile = SubCalendarEvent(
      id: id, name: id, start: startMs, end: endMs, rsvp: rsvp);
  tile.isViable = viable;
  tile.isRigid = rigid;
  if (source != null) tile.thirdpartyType = source;
  tile.travelTimeBefore = travelBefore;
  tile.travelTimeAfter = travelAfter;
  return tile;
}

List<(int, int)> _ms(List<OccupancySegment> segs) =>
    segs.map((s) => (s.startMs, s.endMs)).toList();

void main() {
  group('OccupancyRail.segments (the day minus its blocks)', () {
    test('no blocks → the whole day, tiles never subtract (C37)', () {
      expect(_ms(OccupancyRail.segments(const [], dayStart: _day)),
          [(_at(0), _at(24))]);
      final segs = OccupancyRail.segments(
        [_tile('a', _at(9), _at(10)), _tile('b', _at(14), _at(15))],
        dayStart: _day,
      );
      expect(_ms(segs), [(_at(0), _at(24))]);
    });

    test('disjoint blocks → the gaps around them, sorted by start', () {
      final segs = OccupancyRail.segments(
        [
          _tile('b', _at(14), _at(15), rigid: true),
          _tile('a', _at(9), _at(10), rigid: true),
        ],
        dayStart: _day,
      );
      expect(_ms(segs),
          [(_at(0), _at(9)), (_at(10), _at(14)), (_at(15), _at(24))]);
    });

    test('overlapping and touching blocks merge into one gap-free span', () {
      final segs = OccupancyRail.segments(
        [
          _tile('a', _at(9), _at(10, 30), rigid: true),
          _tile('b', _at(10), _at(11), rigid: true), // overlaps a
          _tile('c', _at(11), _at(12), rigid: true), // touches b
          _tile('d', _at(13), _at(14), rigid: true), // separate
        ],
        dayStart: _day,
      );
      expect(_ms(segs),
          [(_at(0), _at(9)), (_at(12), _at(13)), (_at(14), _at(24))]);
    });

    test('third-party events are blocks too (C30)', () {
      final segs = OccupancyRail.segments(
        [_tile('google', _at(11), _at(12), rigid: true, source: TileSource.google)],
        dayStart: _day,
      );
      expect(_ms(segs), [(_at(0), _at(11)), (_at(12), _at(24))]);
    });

    test('a block\'s travel never counts (C38)', () {
      final segs = OccupancyRail.segments(
        [
          _tile('a', _at(9), _at(10),
              rigid: true,
              travelBefore: 30 * 60 * 1000.0,
              travelAfter: 30 * 60 * 1000.0),
        ],
        dayStart: _day,
      );
      expect(_ms(segs), [(_at(0), _at(9)), (_at(10), _at(24))]);
    });

    test('non-renderable blocks do not subtract (parity rule)', () {
      final segs = OccupancyRail.segments(
        [
          _tile('unscheduled', _at(9), _at(10), rigid: true, viable: false),
          _tile('pending', _at(11), _at(12),
              rigid: true, rsvp: RsvpStatus.needsAction, source: TileSource.google),
          _tile('declined', _at(12), _at(13),
              rigid: true, rsvp: RsvpStatus.declined, source: TileSource.google),
          _tile('ok', _at(15), _at(16), rigid: true),
        ],
        dayStart: _day,
      );
      expect(_ms(segs), [(_at(0), _at(15)), (_at(16), _at(24))]);
    });

    test('an all-day block blanks the rail', () {
      expect(
          OccupancyRail.segments([_tile('allday', _at(0), _at(24), rigid: true)],
              dayStart: _day),
          isEmpty);
    });

    test('cross-midnight blocks are clamped to the day', () {
      final segs = OccupancyRail.segments(
        [
          _tile('overnight', _at(-1), _at(1), rigid: true), // 11 PM → 1 AM
          _tile('late', _at(23), _at(25), rigid: true), // 11 PM → 1 AM +1
        ],
        dayStart: _day,
      );
      expect(_ms(segs), [(_at(1), _at(23))]);
    });

    test('a block on the day edge leaves no zero-length segment', () {
      final segs = OccupancyRail.segments(
        [_tile('early', _at(0), _at(2), rigid: true)],
        dayStart: _day,
      );
      expect(_ms(segs), [(_at(2), _at(24))]);
    });

    test('null bounds are ignored', () {
      final t = SubCalendarEvent(id: 'x', name: 'x')..isRigid = true;
      expect(_ms(OccupancyRail.segments([t], dayStart: _day)),
          [(_at(0), _at(24))]);
    });
  });

  group('OccupancyRail.split (past / future at now, C41)', () {
    final seg = OccupancySegment(_at(9), _at(11));

    test('entirely past', () {
      final (past, future) = OccupancyRail.split(seg, _at(12));
      expect(past, isNotNull);
      expect((past!.startMs, past.endMs), (_at(9), _at(11)));
      expect(future, isNull);
    });

    test('entirely future', () {
      final (past, future) = OccupancyRail.split(seg, _at(8));
      expect(past, isNull);
      expect((future!.startMs, future.endMs), (_at(9), _at(11)));
    });

    test('straddling now', () {
      final (past, future) = OccupancyRail.split(seg, _at(10));
      expect((past!.startMs, past.endMs), (_at(9), _at(10)));
      expect((future!.startMs, future.endMs), (_at(10), _at(11)));
    });

    test('no now (not today) → all future', () {
      final (past, future) = OccupancyRail.split(seg, null);
      expect(past, isNull);
      expect(future, same(seg));
    });
  });

  group('DayGridWidget occupancy rail (C40–C43)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const double viewport = 400;
    const double gutter = TileDimensions.timeOfDayCellWidth;

    Widget host(Widget child) => MaterialApp(
          theme: TileThemeData.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: SizedBox(width: viewport, height: 600, child: child)),
        );

    Future<DayGridController> pumpGrid(
      WidgetTester tester, {
      required List<SubCalendarEvent> tiles,
      List<TilerEvent>? railTiles,
      DateTime? now,
    }) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(DayGridWidget(
        tiles: tiles,
        railTiles: railTiles,
        controller: controller,
        day: _day,
        // Default clock: NOT the grid day, so segments are unsplit unless
        // a test asks for today.
        now: now ?? _day.add(const Duration(days: 3, hours: 7)),
      )));
      await tester.pump(const Duration(milliseconds: 400));
      return controller;
    }

    Finder rail() => find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('daygrid_rail_'));

    Finder railPart(String suffix) => find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('daygrid_rail_') &&
        (w.key as ValueKey<String>).value.endsWith(suffix));

    Rect railRect(WidgetTester tester, String suffix) =>
        tester.getRect(railPart(suffix));

    testWidgets('segments paint in a 6 px lane right of the travel rail',
        (tester) async {
      await pumpGrid(tester, tiles: [
        _tile('block', _at(9), _at(10), rigid: true),
        _tile('a', _at(13), _at(14, 30)),
      ]);
      // The day minus the block: 0–9 and 10–24 (the tile subtracts nothing).
      expect(rail(), findsNWidgets(2));

      final Rect first = railRect(tester, '${_at(0)}_future');
      expect(first.width, DayGridWidget.railSegmentWidth);
      // Lane = the last 6 px of the viewport; the bar is centred in it.
      expect(
          first.left,
          viewport -
              DayGridWidget.railLaneWidth +
              (DayGridWidget.railLaneWidth - DayGridWidget.railSegmentWidth) /
                  2);
      expect(first.height, closeTo(9 * 80, 0.5));
      final Rect block =
          tester.getRect(find.byKey(const ValueKey<String>('daygrid_tile_block')));
      expect(first.bottom, closeTo(block.top, 0.5));
      final Rect second = railRect(tester, '${_at(10)}_future');
      expect(second.top, closeTo(block.bottom, 0.5));
      expect(second.height, closeTo(14 * 80, 0.5));

      // The tile column gives the lane its 6 px; the travel rail keeps its
      // place right of the tiles.
      expect(block.left, gutter + 4);
      expect(
          block.width,
          viewport -
              gutter -
              8 -
              DayGridWidget.travelRailWidth -
              DayGridWidget.railLaneWidth);
    });

    testWidgets('tiles cut no gap; overlapping blocks cut one', (tester) async {
      await pumpGrid(tester, tiles: [
        _tile('tile', _at(9), _at(10)),
        _tile('a', _at(13), _at(14), rigid: true),
        _tile('b', _at(13, 30), _at(15), rigid: true),
      ]);
      expect(rail(), findsNWidgets(2));
      expect(railRect(tester, '${_at(0)}_future').height, closeTo(13 * 80, 0.5));
      expect(railRect(tester, '${_at(15)}_future').height, closeTo(9 * 80, 0.5));
    });

    testWidgets('the rail reflects railTiles, not the (filtered) tiles',
        (tester) async {
      // P7 `Tiles` filter: the grid hides the block, the rail still shows
      // the gap it claims (C37).
      await pumpGrid(
        tester,
        tiles: [_tile('tile', _at(9), _at(10))],
        railTiles: [
          _tile('tile', _at(9), _at(10)),
          _tile('hidden', _at(13), _at(14), rigid: true),
        ],
      );
      expect(find.byKey(const ValueKey<String>('daygrid_tile_hidden')),
          findsNothing);
      expect(rail(), findsNWidgets(2));
      expect(railRect(tester, '${_at(0)}_future').height, closeTo(13 * 80, 0.5));
      expect(railRect(tester, '${_at(14)}_future').height, closeTo(10 * 80, 0.5));
    });

    testWidgets('today: the past half is dimmer than the future half',
        (tester) async {
      await pumpGrid(
        tester,
        tiles: [_tile('block', _at(9), _at(10), rigid: true)],
        now: _day.add(const Duration(hours: 5)),
      );
      // 0–9 splits at 5 AM; 10–24 is all future.
      expect(rail(), findsNWidgets(3));
      final Rect past = railRect(tester, '${_at(0)}_past');
      final Rect future = railRect(tester, '${_at(0)}_future');
      expect(past.height, closeTo(5 * 80, 0.5));
      expect(future.height, closeTo(4 * 80, 0.5));
      expect(future.top, closeTo(past.bottom, 0.5));

      Color colorOf(String suffix) {
        final box = tester.widget<DecoratedBox>(find.descendant(
            of: railPart(suffix), matching: find.byType(DecoratedBox)));
        return (box.decoration as BoxDecoration).color!;
      }

      final Color pastColor = colorOf('${_at(0)}_past');
      final Color futureColor = colorOf('${_at(0)}_future');
      expect(pastColor.a, lessThan(futureColor.a));
      // The Tiler accent, not a theme-derived neutral.
      expect(futureColor.withValues(alpha: 1), TileColors.primary);
      expect(pastColor.withValues(alpha: 1), TileColors.primary);
    });

    testWidgets('not today: no past half', (tester) async {
      await pumpGrid(
        tester,
        tiles: [_tile('block', _at(9), _at(10), rigid: true)],
        now: _day.add(const Duration(days: 3, hours: 5)),
      );
      expect(rail(), findsNWidgets(2));
      expect(railPart('_past'), findsNothing);
    });

    testWidgets('segments are non-interactive (IgnorePointer)',
        (tester) async {
      await pumpGrid(tester,
          tiles: [_tile('block', _at(9), _at(10), rigid: true)]);
      expect(
          find.descendant(of: rail(), matching: find.byType(IgnorePointer)),
          findsNWidgets(2));
      // A hit test at the bar's centre never reaches the bar itself.
      final Rect first = railRect(tester, '${_at(0)}_future');
      final HitTestResult result = HitTestResult();
      tester.binding.hitTestInView(result, first.center, tester.view.viewId);
      expect(
          result.path.any((e) =>
              e.target is RenderBox &&
              (e.target as RenderBox).size.width ==
                  DayGridWidget.railSegmentWidth),
          isFalse,
          reason: 'the 2 px bar must not be hit');
    });

    testWidgets('a refresh that removes a block animates the gap closed',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      List<SubCalendarEvent> tiles = [
        _tile('a', _at(9), _at(10), rigid: true),
        _tile('b', _at(11), _at(12), rigid: true),
      ];
      late void Function() rebuild;
      await tester.pumpWidget(host(StatefulBuilder(builder: (context, set) {
        rebuild = () => set(() {});
        return DayGridWidget(
          tiles: tiles,
          controller: controller,
          day: _day,
          now: _day.add(const Duration(days: 3, hours: 7)),
        );
      })));
      await tester.pump(const Duration(milliseconds: 400));
      expect(rail(), findsNWidgets(3));
      final Rect before = railRect(tester, '${_at(10)}_future');
      expect(before.height, closeTo(80, 0.5));

      // b goes away → the 10–11 segment grows to 10–24 (same key).
      tiles = [_tile('a', _at(9), _at(10), rigid: true)];
      rebuild();
      await tester.pump(); // t = 0
      final Rect t0 = railRect(tester, '${_at(10)}_future');
      expect(t0.top, closeTo(before.top, 0.5));
      expect((t0.height - before.height).abs(), lessThan(4),
          reason: 'must animate, not jump, at t=0');
      await tester.pump(const Duration(milliseconds: 500));
      expect(rail(), findsNWidgets(2));
      expect(railRect(tester, '${_at(10)}_future').height,
          closeTo(14 * 80, 0.5));
      expect(tester.takeException(), isNull);
    });
  });
}
