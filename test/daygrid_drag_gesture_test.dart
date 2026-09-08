// Drag-and-drop reschedule — gesture, snap and range constraints.
//
// A long-press on a Tiler-owned tile lifts it into a drag: the finger
// position inverts through the layout mapping `time(y) = y / pxPerHour`
// (the same inverse tap-to-add proves) into a snapped start time, shown
// as a live ghost (snap line + time chip + slot outline). Drops outside
// the tile's allowed window (`rangeStart/rangeEnd`, falling back to
// `calendarEventStart/End`) are blocked — the tile never moves. Plain
// vertical drags (on tiles or background) still scroll the grid, a plain
// tap still opens the tile detail, and third-party (non-Tiler) tiles do
// not lift at all.
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/travelBandWidget.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records `ScheduleBloc` events WITHOUT running the network-bound
/// handlers (`GetScheduleEvent` / `EvaluateSchedule`) — the grid only
/// touches the bloc on drag commit and pull-to-refresh, and the drag
/// commit is exercised through the injected fake API.
class _RecordingScheduleBloc extends ScheduleBloc {
  final List<ScheduleEvent> events = <ScheduleEvent>[];

  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    events.add(event);
    if (event is GetScheduleEvent || event is EvaluateSchedule) {
      return; // record only — no API calls in tests.
    }
    super.add(event);
  }
}

/// `SubCalendarEventApi` double — captures the `EditTilerEvent` of a drag
/// commit and resolves it without touching the network. [error] forces a
/// failed request; [pending] keeps the request in flight until the test
/// completes it.
class _FakeSubCalendarEventApi extends SubCalendarEventApi {
  _FakeSubCalendarEventApi() : super(getContextCallBack: () => null);

  EditTilerEvent? captured;
  int updateCount = 0;
  Object? error;
  Future<SubCalendarEvent>? pending;

  @override
  Future<SubCalendarEvent> updateSubEvent(EditTilerEvent subEvent) {
    captured = subEvent;
    updateCount += 1;
    if (error != null) {
      return Future<SubCalendarEvent>.error(error!);
    }
    if (pending != null) {
      return pending!;
    }
    final confirmed = SubCalendarEvent(
      id: subEvent.id,
      name: subEvent.name,
      start: subEvent.startTime!.millisecondsSinceEpoch,
      end: subEvent.endTime!.millisecondsSinceEpoch,
    );
    return Future<SubCalendarEvent>.value(confirmed);
  }
}

SubCalendarEvent _tile(
  String id,
  DateTime start,
  DateTime end, {
  double? rangeStart,
  double? rangeEnd,
  double? calendarEventStart,
  double? calendarEventEnd,
  double? travelTimeBefore,
  TileSource source = TileSource.tiler,
}) {
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  t.isViable = true;
  t.thirdpartyType = source;
  if (rangeStart != null) t.rangeStart = rangeStart.toDouble();
  if (rangeEnd != null) t.rangeEnd = rangeEnd.toDouble();
  if (calendarEventStart != null) {
    t.calendarEventStart = calendarEventStart.toDouble();
  }
  if (calendarEventEnd != null) {
    t.calendarEventEnd = calendarEventEnd.toDouble();
  }
  if (travelTimeBefore != null) t.travelTimeBefore = travelTimeBefore;
  return t;
}
Widget _buildApp({
  required ScheduleBloc bloc,
  required SubCalendarEventApi api,
  required List<SubCalendarEvent> tiles,
  DateTime? now,
  DateTime? day,
  DayGridController? controller,
  bool preview = false,
}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<ScheduleBloc>(
      create: (_) => bloc,
      child: Scaffold(
        body: DayGridWidget(
          tiles: tiles,
          now: now,
          day: day,
          controller: controller,
          preview: preview,
          subCalendarEventApi: api,
        ),
      ),
    ),
  );
}

/// Closes [bloc] from the real async zone, draining the FakeAsync
/// microtask queue (same idiom as the DayGrid tap-to-add suite).
Future<void> _closeBloc(WidgetTester tester, ScheduleBloc bloc) async {
  await tester.runAsync(() async {
    final closeFuture = bloc.close();
    int pumps = 0;
    for (; pumps < 20; pumps++) {
      try {
        await closeFuture.timeout(const Duration(milliseconds: 50));
        return;
      } on TimeoutException {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    throw StateError(
      'bloc.close() stalled after $pumps fake-zone drains; '
      'isClosed=${bloc.isClosed}',
    );
  });
}

/// Long-presss the tile at [start], drags it by [delta] and lifts —
/// asserting the long press actually lifted the tile into a drag.
Future<void> _dragTile(WidgetTester tester, Offset start, Offset delta) async {
  final gesture = await tester.startGesture(start);
  await tester.pump(kLongPressTimeout);
  expect(find.byKey(const Key('daygrid_drag_ghost')), findsOneWidget,
      reason: 'the long press must lift the tile into a drag');
  await gesture.moveBy(delta);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}
/// The tile's own position (content y, scroll-independent): the nearest
/// `AnimatedPositioned` ancestor of the tile's name caption.
double _tileTop(WidgetTester tester, String name) {
  final positioned = tester.widget<AnimatedPositioned>(
    find
        .ancestor(of: find.text(name), matching: find.byType(AnimatedPositioned))
        .first,
  );
  return positioned.top!;
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A future grid day: no past-time prefill, no now-line.
  final dayStart = DateTime(2027, 1, 15);
  final now = DateTime(2026, 5, 15, 14, 30);

  // ---------------------------------------------------------------------
  // computeDragSeed — the y→time inversion for drops (shared snap rules).
  // ---------------------------------------------------------------------
  group('computeDragSeed (drop Y → snapped start, constraints)', () {
    SubCalendarEvent tile(
      int h1,
      int m1,
      int h2,
      int m2, {
      double? rangeStart,
      double? rangeEnd,
      double? calendarEventStart,
      double? calendarEventEnd,
    }) {
      DateTime at(int h, int m) =>
          dayStart.add(Duration(hours: h, minutes: m));
      return _tile(
        't',
        at(h1, m1),
        at(h2, m2),
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        calendarEventStart: calendarEventStart,
        calendarEventEnd: calendarEventEnd,
      );
    }

    test('drop Y → snapped start, duration preserved (zoom table)', () {
      // (pxPerHour, snapInterval) per the controller's zoom bands — with
      // the expected floored starts for raw drops at 9:07 and 10:13.
      const cases = <(double, Duration, int, int, int, int)>[
        // px, snap, drop1 start (h,m), drop2 start (h,m)
        (40, const Duration(minutes: 30), 9, 0, 10, 0),
        (80, const Duration(minutes: 15), 9, 0, 10, 0),
        (150, const Duration(minutes: 15), 9, 0, 10, 0),
        (240, const Duration(minutes: 5), 9, 5, 10, 10),
      ];
      for (final (px, snap, h1, m1, h2, m2) in cases) {
        final t = tile(9, 0, 10, 0); // 1h tile.
        // Drop at raw 9:07 → snaps DOWN to the band start.
        final seed = DayGridWidget.computeDragSeed(
          tile: t,
          dayStart: dayStart,
          dropTopPx: (9 + 7 / 60.0) * px,
          pxPerHour: px,
          snapInterval: snap,
        );
        expect(seed.start, DateTime(2027, 1, 15, h1, m1),
            reason: 'px/h $px, drop 9:07');
        expect(seed.end, DateTime(2027, 1, 15, h1, m1).add(const Duration(hours: 1)),
            reason: 'px/h $px (duration preserved)');
        expect(seed.withinRange, isTrue, reason: 'px/h $px');
        expect(seed.blockReason, isNull, reason: 'px/h $px');

        // Drop at raw 10:13 → snaps DOWN to the band start.
        final seed2 = DayGridWidget.computeDragSeed(
          tile: t,
          dayStart: dayStart,
          dropTopPx: (10 + 13 / 60.0) * px,
          pxPerHour: px,
          snapInterval: snap,
        );
        expect(seed2.start, DateTime(2027, 1, 15, h2, m2),
            reason: 'px/h $px, drop 10:13');
      }
    });

    test('snaps at the fine band (5 min)', () {
      final t = tile(9, 0, 10, 0);
      final seed = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (9 + 8 / 60.0) * 240, // raw 9:08.
        pxPerHour: 240,
        snapInterval: const Duration(minutes: 5),
      );
      expect(seed.start, DateTime(2027, 1, 15, 9, 5));
    });

    test('clamps the drop into the visible day', () {
      final t = tile(9, 0, 10, 0);
      // Beyond the day's bottom: the tile's TOP clamps so the whole tile
      // (1h) still fits before midnight.
      final past = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: 25 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(past.start, DateTime(2027, 1, 15, 23, 0));
      expect(past.end, DateTime(2027, 1, 16, 0, 0));

      // Beyond the day's top: clamps to midnight.
      final before = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: -2 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(before.start, DateTime(2027, 1, 15, 0, 0));
      expect(before.end, DateTime(2027, 1, 15, 1, 0));
    });
test('rangeStart/rangeEnd window is enforced (no silent clamp)', () {
      final day8 = dayStart.add(const Duration(hours: 8));
      final day11 = dayStart.add(const Duration(hours: 11));
      // A 1h tile with an 08:00–11:00 window.
      final t = tile(9, 0, 10, 0,
          rangeStart: day8.millisecondsSinceEpoch.toDouble(),
          rangeEnd: day11.millisecondsSinceEpoch.toDouble());

      // 10:50 → snaps to 10:45, end 11:45 > 11:00 → blocked.
      final blocked = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (10 + 50 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(blocked.withinRange, isFalse);
      expect(blocked.blockReason, 'out_of_range');

      // Exactly at the window's end edge: 10:00 + 1h = 11:00 → allowed.
      final edge = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: 10 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(edge.withinRange, isTrue);

      // Before the window: 07:50 → 07:45 < 08:00 → blocked.
      final early = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (7 + 50 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(early.withinRange, isFalse);
    });

    test('calendarEventStart/End window is used when the range fields are absent',
        () {
      final day8 = dayStart.add(const Duration(hours: 8));
      final day10 = dayStart.add(const Duration(hours: 10));
      final t = tile(9, 0, 10, 0,
          calendarEventStart: day8.millisecondsSinceEpoch.toDouble(),
          calendarEventEnd: day10.millisecondsSinceEpoch.toDouble());

      // 09:50 → 09:45 + 1h = 10:45 > 10:00 → blocked.
      final blocked = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (9 + 50 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(blocked.withinRange, isFalse);

      // 08:30 + 1h = 09:30 ≤ 10:00 → allowed.
      final ok = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (8 + 30 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(ok.withinRange, isTrue);
    });

    test('no window fields → unbounded', () {
      final t = tile(9, 0, 10, 0);
      final seed = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: 22 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(seed.withinRange, isTrue);
    });

    test('rangeStart == rangeEnd (single-instant anchor) falls back to the '
        'calendarEvent window (real-data shape)', () {
      final anchor = dayStart.add(const Duration(hours: 8));
      // Real data carries rangeStart == rangeEnd == the parent event's start
      // instant — a zero-length "window" — with a real multi-day parent-event
      // slot in calendarEventStart/End. A duration-bearing tile can never fit
      // the zero-length range, so the drop must not be permanently blocked.
      final t = tile(9, 0, 10, 0,
          rangeStart: anchor.millisecondsSinceEpoch.toDouble(),
          rangeEnd: anchor.millisecondsSinceEpoch.toDouble(),
          calendarEventStart: anchor.millisecondsSinceEpoch.toDouble(),
          calendarEventEnd:
              dayStart.add(const Duration(days: 3)).millisecondsSinceEpoch
                  .toDouble());

      // 10:45 → 10:45, end 11:45. Under the old zero-length range window this
      // was permanently blocked; under the parent-event fallback the whole
      // tile is inside the multi-day slot → allowed.
      final seed = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (10 + 45 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(seed.start, DateTime(2027, 1, 15, 10, 45));
      expect(seed.end, DateTime(2027, 1, 15, 11, 45));
      expect(seed.withinRange, isTrue);
      expect(seed.blockReason, isNull);
    });

    test('rangeStart == rangeEnd with no calendarEvent window → unbounded', () {
      final anchor = dayStart.add(const Duration(hours: 8));
      final t = tile(9, 0, 10, 0,
          rangeStart: anchor.millisecondsSinceEpoch.toDouble(),
          rangeEnd: anchor.millisecondsSinceEpoch.toDouble());
      final seed = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (10 + 45 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(seed.withinRange, isTrue);
    });

    test('a drop beyond the parent-event window is still blocked '
        '(no over-permission)', () {
      final anchor = dayStart.add(const Duration(hours: 8));
      final parentEnd = dayStart.add(const Duration(hours: 11));
      final t = tile(9, 0, 10, 0,
          rangeStart: anchor.millisecondsSinceEpoch.toDouble(),
          rangeEnd: anchor.millisecondsSinceEpoch.toDouble(),
          calendarEventStart: anchor.millisecondsSinceEpoch.toDouble(),
          calendarEventEnd:
              parentEnd.millisecondsSinceEpoch.toDouble());

      // 10:45 → end 11:45 > 11:00 → genuinely outside the parent slot → blocked.
      final blocked = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (10 + 45 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(blocked.withinRange, isFalse);
      expect(blocked.blockReason, 'out_of_range');

      // 08:30 + 1h = 09:30 ≤ 11:00 → allowed.
      final ok = DayGridWidget.computeDragSeed(
        tile: t,
        dayStart: dayStart,
        dropTopPx: (8 + 30 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
      );
      expect(ok.withinRange, isTrue);
    });

    test('bottomZoneStartY parks the bottom zone at the visible bottom',
        () {
      // No occlusion: the zone hugs the raw viewport bottom (600 - 48).
      expect(
        DayGridWidget.bottomZoneStartY(600, bottomOcclusion: 0),
        closeTo(552, 1e-9),
      );
      // A 56px bottom bar pulls the zone's top up by 56 (544 - 48).
      expect(
        DayGridWidget.bottomZoneStartY(600, bottomOcclusion: 56),
        closeTo(496, 1e-9),
      );
      // Bar + a 34px home-indicator inset (effective bottom 510 - 48).
      expect(
        DayGridWidget.bottomZoneStartY(600, bottomOcclusion: 56 + 34),
        closeTo(462, 1e-9),
      );
      // Occlusion larger than the viewport clamps to a full occlusion
      // (zone top at 0 — no reachable bottom zone).
      expect(
        DayGridWidget.bottomZoneStartY(600, bottomOcclusion: 10000),
        closeTo(0, 1e-9),
      );
      // A viewport shorter than the zone does not overflow.
      expect(
        DayGridWidget.bottomZoneStartY(40, bottomOcclusion: 0),
        closeTo(0, 1e-9),
      );
      // A zero-height viewport is a no-op.
      expect(DayGridWidget.bottomZoneStartY(0, bottomOcclusion: 0), 0);
    });
  });
// ---------------------------------------------------------------------
  // Grid-level drag behaviour.
  //
  // Grid math used below: default 80 px/h, tile 'a' at 09:00–10:00
  // (content top 720, initial scroll 720 → tile top at viewport y 0,
  // its name caption at y 10). A +120px drag = 90min → 10:30 →
  // content top 840.
  // ---------------------------------------------------------------------
  group('DayGridWidget drag gestures', () {
    testWidgets('plain tap does NOT start a drag', (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump(); // post-frame: initial scroll settles.

      await tester.tapAt(const Offset(200, 40));
      await tester.pump();

      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      expect(controller.mode, DayGridMode.idle);
      expect(api.updateCount, 0);
      expect(bloc.events, isEmpty);
      // The tile never moved — the ordinary tap just opened the
      // detail sheet (scoped OUT of the grid, so the caption
      // finder stays unambiguous).
      final caption = find.descendant(
          of: find.byType(DayGridWidget), matching: find.text('a'));
      expect(tester.getTopLeft(caption).dy, closeTo(10, 0.5));
      await _closeBloc(tester, bloc);
    });

    testWidgets('long-press begins a drag (ghost + dragging mode)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump();

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(kLongPressTimeout);

      expect(controller.mode, DayGridMode.dragging);
      // The ghost sits on the tile's current slot (no move yet).
      final ghost = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('daygrid_drag_ghost')));
      expect(ghost.top, closeTo(720, 0.5));
      // The snapped time chip shows the current start.
      expect(find.textContaining('9:00'), findsWidgets);

      await gesture.up();
      await tester.pump();
      expect(controller.mode, DayGridMode.idle);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      await _closeBloc(tester, bloc);
    });

    testWidgets('drag move snaps the ghost to the drop Y (10:30 at 80 px/h)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump();

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(kLongPressTimeout);
      await gesture.moveBy(const Offset(0, 120)); // 120px = 90min → 10:30.
      await tester.pump();

      final ghost = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('daygrid_drag_ghost')));
      expect(ghost.top, closeTo(840, 0.5));
      expect(find.textContaining('10:30'), findsWidgets);

      // In range: the drop commits the snapped slot.
      await gesture.up();
      await tester.pump();

      expect(api.updateCount, 1);
      expect(api.captured!.startTime, DateTime(2027, 1, 15, 10, 30));
      expect(api.captured!.endTime, DateTime(2027, 1, 15, 11, 30));
      // Optimistic settle: the tile holds the dropped slot (content y
      // 840) while the parent re-serves the server-confirmed data.
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      expect(controller.mode, DayGridMode.idle);
      await _closeBloc(tester, bloc);
    });
testWidgets('drop outside rangeStart/rangeEnd → blocked, tile returns',
        (tester) async {
      final day8 = dayStart.add(const Duration(hours: 8));
      final day11 = dayStart.add(const Duration(hours: 11));
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile(
            'a',
            DateTime(2027, 1, 15, 9),
            DateTime(2027, 1, 15, 10),
            rangeStart: day8.millisecondsSinceEpoch.toDouble(),
            rangeEnd: day11.millisecondsSinceEpoch.toDouble(),
          ),
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump();

      await _dragTile(tester, const Offset(200, 40), const Offset(0, 240));
      // +240px = 3h → 12:00, end 13:00 → past the 11:00 window.

      // Blocked: nothing persisted, no EvaluateSchedule dispatched.
      expect(api.updateCount, 0);
      expect(bloc.events.whereType<EvaluateSchedule>(), isEmpty);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      // The tile never moved.
      expect(tester.getTopLeft(find.text('a')).dy, closeTo(10, 0.5));
      await _closeBloc(tester, bloc);
    });

    testWidgets('read-only (non-Tiler) tile ignores long-press',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile(
            'g',
            DateTime(2027, 1, 15, 9),
            DateTime(2027, 1, 15, 10),
            source: TileSource.google,
          ),
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump();

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(kLongPressTimeout);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      expect(controller.mode, DayGridMode.idle);

      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(api.updateCount, 0);
      expect(bloc.events, isEmpty);
      expect(tester.getTopLeft(find.text('g')).dy, closeTo(10, 0.5));
      await _closeBloc(tester, bloc);
    });
testWidgets('preview grid ignores long-press', (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
        preview: true,
      ));
      await tester.pump();

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(kLongPressTimeout);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);

      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(api.updateCount, 0);
      await _closeBloc(tester, bloc);
    });

    testWidgets('plain vertical drag still scrolls (on background)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump(); // initial scroll → 720.

      // A quick vertical drag on the EMPTY background: the scroll view
      // owns it (no long press), so the grid scrolls instead of
      // dragging. The first move only crosses the gesture slop (the
      // drag acceptance consumes it); the second move's delta is
      // what the scroll position applies. No pump between the moves
      // and the lift — a frame boundary in between releases the
      // in-flight scroll drag in the test binding.
      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(0, 20)); // cross the slop.
      await gesture.moveBy(const Offset(0, 150)); // → scroll 570.
      await gesture.up();
      await tester.pump();

      // Tile 'a' (content top 720) now sits at viewport y 150 → caption 160.
      expect(tester.getTopLeft(find.text('a')).dy, closeTo(160, 1.0));
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      expect(api.updateCount, 0);
      await _closeBloc(tester, bloc);
    });

    testWidgets('plain vertical drag on a tile still scrolls',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump(); // initial scroll → 720.

      // A quick vertical drag ON the tile: the long press has not
      // elapsed, so the scroll view wins and nothing lifts. Two-move
      // sequence: the first move crosses the gesture slop (consumed
      // by the drag acceptance), the second's delta is what scrolls.
      // No pump between the moves and the lift — a frame boundary in
      // between releases the in-flight scroll drag in the test
      // binding.
      final gesture = await tester.startGesture(const Offset(200, 40));
      await gesture.moveBy(const Offset(0, 20)); // cross the slop.
      await gesture.moveBy(const Offset(0, 150)); // → scroll 570.
      await gesture.up();
      await tester.pump();

      // Tile 'a' (content top 720) now sits at viewport y 150 → caption 160.
      expect(tester.getTopLeft(find.text('a')).dy, closeTo(160, 1.0));
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsNothing);
      expect(controller.mode, DayGridMode.idle);
      expect(api.updateCount, 0);
      await _closeBloc(tester, bloc);
    });
testWidgets('travel bands dim while a drag is active', (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile(
            'a',
            DateTime(2027, 1, 15, 9),
            DateTime(2027, 1, 15, 10),
            travelTimeBefore: 30 * 60 * 1000, // 30min pre-travel band.
          ),
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump();

      expect(tester.widget<TravelBandWidget>(find.byType(TravelBandWidget))
              .dimmed,
          isFalse);

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(kLongPressTimeout);
      expect(tester.widget<TravelBandWidget>(find.byType(TravelBandWidget))
              .dimmed,
          isTrue);

      await gesture.up();
      await tester.pump();
      expect(tester.widget<TravelBandWidget>(find.byType(TravelBandWidget))
              .dimmed,
          isFalse);
      await _closeBloc(tester, bloc);
    });

    testWidgets('drag into the top edge zone auto-scrolls the grid up',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump(); // initial scroll → 720.

      // Lift the 9:00 tile (content top 720; the finger at viewport y 40
      // is content y 760).
      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(kLongPressTimeout);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsOneWidget);

      // The finger 20px into the top edge zone (viewport y 20 < 48):
      // the drop slot snaps to 8:45 (content top 700) and the edge
      // auto-scroll arms.
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      final ghostBefore = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('daygrid_drag_ghost'))).top!;
      expect(ghostBefore, closeTo(700, 0.5));

      // Let the auto-scroll run: each tick moves the grid toward the
      // finger until the top of the content is reached.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // The grid scrolled UP: the source tile (content top 720) slid
      // DOWN the viewport (its caption was at dy 10 at scroll 720).
      expect(tester.getTopLeft(find.text('a')).dy, greaterThan(100));
      // The ghost tracks the finger's (unchanged) viewport point: its
      // drop slot rolled earlier as the grid scrolled.
      final ghostAfter = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('daygrid_drag_ghost'))).top!;
      expect(ghostAfter, lessThan(ghostBefore));
      expect(controller.mode, DayGridMode.dragging); // still mid-drag.

      // Dropping now commits the scrolled-into slot (00:00 at the top
      // of the content).
      await gesture.up();
      await tester.pump();
      expect(controller.mode, DayGridMode.idle);
      expect(api.captured!.startTime, DateTime(2027, 1, 15, 0));

      await _closeBloc(tester, bloc);
    });

    testWidgets('drag into the bottom edge zone auto-scrolls the grid down',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('b', DateTime(2027, 1, 15, 14), DateTime(2027, 1, 15, 15))
        ],
        now: now,
        day: dayStart,
        controller: controller,
      ));
      await tester.pump(); // initial scroll → 1120 (the first tile's start).

      // Lift the 14:00 tile (content top 1120; at scroll 1120 the tile
      // fills viewport 0–80 and the finger at viewport y 60 — inside the
      // tile, outside both edge zones — is content y 1180).
      final gesture = await tester.startGesture(const Offset(200, 60));
      await tester.pump(kLongPressTimeout);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsOneWidget);

      // The finger 500px down → viewport y 560, inside the bottom edge
      // zone (560 > 600 - 48): the auto-scroll arms.
      await gesture.moveBy(const Offset(0, 500));
      await tester.pump();
      final ghostBefore = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('daygrid_drag_ghost'))).top!;
      // 20:15 raw → already on a 15-min snap (content top 1620).
      expect(ghostBefore, closeTo(1620, 0.5));

      // Let the auto-scroll run toward the bottom of the content.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // The grid scrolled DOWN: the source tile (content top 1120) slid
      // UP the viewport (its caption was at dy 10 at scroll 1120).
      expect(tester.getTopLeft(find.text('b')).dy, lessThan(10));
      // The ghost tracks the finger's viewport point: its drop slot
      // rolled later as the grid scrolled (22:45 at the content bottom).
      final ghostAfter = tester.widget<AnimatedPositioned>(
          find.byKey(const Key('daygrid_drag_ghost'))).top!;
      expect(ghostAfter, greaterThan(ghostBefore));
      expect(controller.mode, DayGridMode.dragging); // still mid-drag.

      // Dropping now commits the scrolled-into slot (22:45 near the
      // bottom of the content).
      await gesture.up();
      await tester.pump();
      expect(controller.mode, DayGridMode.idle);
      expect(api.captured!.startTime, DateTime(2027, 1, 15, 22, 45));

      await _closeBloc(tester, bloc);
    });

    testWidgets(
        'bottom auto-scroll reaches the visible edge behind a bottom nav',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final controller = DayGridController()..setPxPerHour(80);
      // Simulates the real calendar host: `Scaffold(extendBody: true)` with a
      // ~56px bottom bar, so the grid's scroll viewport extends BEHIND the
      // bar. The default test surface is 800x600, so the viewport is 600 tall
      // and the bar occludes the bottom 56px (visible bottom = 544). The
      // bottom auto-scroll zone must therefore sit at (544 - 48) = 496..544 —
      // a finger at viewport y 510 is reachable (above the bar) and inside
      // the zone, yet it was in the dead zone before the fix (510 < 552).
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ScheduleBloc>(
          create: (_) => bloc,
          child: Scaffold(
            extendBody: true,
            body: DayGridWidget(
              tiles: [
                _tile(
                    'b',
                    DateTime(2027, 1, 15, 14),
                    DateTime(2027, 1, 15, 15))
              ],
              now: now,
              day: dayStart,
              controller: controller,
              subCalendarEventApi: api,
            ),
            bottomNavigationBar: const SizedBox(height: 56),
          ),
        ),
      ));
      await tester.pump(); // initial scroll -> 1120 (the first tile's start).

      // Lift the 14:00 tile (content top 1120; at scroll 1120 the tile fills
      // viewport 0-80, the finger at viewport y 60 is inside the tile).
      final gesture = await tester.startGesture(const Offset(200, 60));
      await tester.pump(kLongPressTimeout);
      expect(find.byKey(const Key('daygrid_drag_ghost')), findsOneWidget);

      // Move the finger 450px down -> viewport y 510: inside the bottom zone
      // (510 > 496) and reachable (510 < 544, above the bar). Before the fix
      // this y was below the old threshold (552) and the grid would NOT
      // auto-scroll.
      await gesture.moveBy(const Offset(0, 450));
      await tester.pump();

      final captionBefore = tester.getTopLeft(find.text('b')).dy;
      // Let the auto-scroll run toward the bottom of the content.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // The grid scrolled DOWN: the source tile (content top 1120) slid UP
      // the viewport (its caption was at dy 10 at scroll 1120).
      final captionAfter = tester.getTopLeft(find.text('b')).dy;
      expect(captionAfter, lessThan(captionBefore));
      expect(controller.mode, DayGridMode.dragging); // still mid-drag.

      // Dropping commits a later slot (the finger scrolled the day down).
      await gesture.up();
      await tester.pump();
      expect(controller.mode, DayGridMode.idle);
      expect(
        api.captured!.startTime!.isAfter(DateTime(2027, 1, 15, 14)),
        isTrue,
      );

      await _closeBloc(tester, bloc);
    });
  });
}