// Drag-and-drop reschedule — persistence, optimistic settle and rollback.
//
// A committed drop moves ONLY the sub-event's Start/End to the snapped
// slot: the parent calendar-event window (CalStart/CalEnd = the tile's
// original `calendarEventStart/End`, often multi-day) is preserved so
// the scheduler keeps the sub-event in its original slot and the tile's
// height is untouched by the commit. A tile without a usable parent
// window hard-pins the snapped slot into CalStart/CalEnd (the scheduler
// does not re-fit the move). The request rides
// `EvaluateSchedule(callBack:)` — the tile holds the dropped slot
// optimistically while it is in flight, and the position only becomes
// model-owned once the parent re-serves data with a changed time for the
// tile. A failed request rolls back: `ReloadLocalScheduleEvent` with the
// pre-drag subEvents restores the bloc state, the tile slides back to its
// pre-drag slot, and a second drop issued while a request is in flight is
// ignored (no double-write race).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records `ScheduleBloc` events WITHOUT running the network-bound
/// handlers (`GetScheduleEvent` / `EvaluateSchedule`) — the commit
/// request is exercised through the injected fake API. The pure
/// `ReloadLocalScheduleEvent` handler runs for real (it only emits a
/// state, no API calls).
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
      final err = error!;
      // Delivered on a later fake-async tick so the optimistic settle
      // (the dropped slot) is an observable frame before the rollback.
      return Future<SubCalendarEvent>.delayed(const Duration(milliseconds: 50),
          () {
        throw err;
      });
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
  double? calendarEventStart,
  double? calendarEventEnd,
}) {
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  t.isViable = true;
  t.thirdpartyType = TileSource.tiler;
  t.split = 1;
  if (calendarEventStart != null) {
    t.calendarEventStart = calendarEventStart.toDouble();
  }
  if (calendarEventEnd != null) {
    t.calendarEventEnd = calendarEventEnd.toDouble();
  }
  return t;
}

Widget _buildApp({
  required ScheduleBloc bloc,
  required SubCalendarEventApi api,
  required List<SubCalendarEvent> tiles,
  DateTime? now,
  DateTime? day,
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
          controller: DayGridController()..setPxPerHour(80),
          subCalendarEventApi: api,
        ),
      ),
    ),
  );
}

/// The tile's own position (content y, scroll-independent): the nearest
/// `AnimatedPositioned` ancestor of the tile's name caption.
double _tileTop(WidgetTester tester, String name) {
  final positioned = tester.widget<AnimatedPositioned>(
    find
        .ancestor(
            of: find.text(name), matching: find.byType(AnimatedPositioned))
        .first,
  );
  return positioned.top!;
}

/// The rendered pixel height of the tile (by its stable grid key): the
/// `AnimatedPositioned` sizes to its body, so the laid-out size IS the
/// duration-derived height the [TileGridWidget] computes. (Same stable
/// key the layout-math tests measure.)
double _tileHeight(WidgetTester tester, String name) =>
    tester.getSize(find.byKey(ValueKey<String>('daygrid_tile_$name'))).height;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A future grid day: no past-time prefill, no now-line.
  final dayStart = DateTime(2027, 1, 15);
  final now = DateTime(2026, 5, 15, 14, 30);

  group('drag commit (hard pin)', () {
    testWidgets('drop persists the snapped slot — Start=CalStart pin',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      // Long-press + drag 120px (90min) → 10:30.
      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // This tile has NO parent calendar-event window: the request falls
      // back to the HARD PIN — CalStart/CalEnd are pinned to the dropped
      // slot so the scheduler cannot re-fit the move elsewhere.
      final edit = api.captured!;
      expect(edit.id, 'a');
      expect(edit.startTime, DateTime(2027, 1, 15, 10, 30));
      expect(edit.endTime, DateTime(2027, 1, 15, 11, 30));
      expect(edit.calStartTime, DateTime(2027, 1, 15, 10, 30));
      expect(edit.calEndTime, DateTime(2027, 1, 15, 11, 30));
      expect(edit.splitCount, isNotNull);
      expect(edit.thirdPartyType, 'tiler');

      // The request rides EvaluateSchedule(callBack:), and the pre-drag
      // subEvents are what the re-evaluation renders while in flight.
      final evaluate = bloc.events.whereType<EvaluateSchedule>().toList();
      expect(evaluate, hasLength(1));
      expect(evaluate.first.callBack, isNotNull);
      final rendered =
          evaluate.first.renderedSubEvents.where((t) => t.id == 'a').toList();
      expect(rendered, hasLength(1));
      expect(rendered.first.start,
          DateTime(2027, 1, 15, 9).millisecondsSinceEpoch);

      // Optimistic settle: the tile holds the dropped slot (content y
      // 840) even though the model still says 09:00 (720).
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));

      await tester.runAsync(() => bloc.close());
    });

    testWidgets(
        'drop preserves the parent CalStart/CalEnd window (only Start/End move)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      // The parent window spans days (the real data shape): the dragged
      // 1-hour slot must NOT replace it on commit.
      final parentStart = dayStart.subtract(const Duration(days: 2));
      final parentEnd = dayStart.add(const Duration(days: 3));
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10),
              calendarEventStart: parentStart.millisecondsSinceEpoch.toDouble(),
              calendarEventEnd: parentEnd.millisecondsSinceEpoch.toDouble())
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      // Long-press + drag 120px (90min) → 10:30.
      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final edit = api.captured!;
      // Only the sub-event slot moves...
      expect(edit.id, 'a');
      expect(edit.startTime, DateTime(2027, 1, 15, 10, 30));
      expect(edit.endTime, DateTime(2027, 1, 15, 11, 30));
      // ...and the parent window is preserved: the multi-day slot, NOT
      // the dragged 1-hour slot (the tile's height survives the save).
      // (The getter builds UTC DateTimes — compare the same shape.)
      expect(
          edit.calStartTime,
          DateTime.fromMillisecondsSinceEpoch(
              parentStart.millisecondsSinceEpoch,
              isUtc: true));
      expect(
          edit.calEndTime,
          DateTime.fromMillisecondsSinceEpoch(parentEnd.millisecondsSinceEpoch,
              isUtc: true));

      await tester.runAsync(() => bloc.close());
    });

    testWidgets('success → tile settles at the server-confirmed position',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120)); // → 10:30.
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5)); // optimistic hold.

      // The server confirms with a correction: the re-served schedule
      // places the tile at 11:00–12:00. The position becomes model-owned
      // and the tile settles there (the layout transition slides it).
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 11), DateTime(2027, 1, 15, 12))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: scroll resync.
      await tester.pump(const Duration(milliseconds: 300)); // settle.
      expect(_tileTop(tester, 'a'), closeTo(880, 0.5));

      await tester.runAsync(() => bloc.close());
    });

    testWidgets(
        '50-minute tile: duration survives lift → commit → hold → settle (height intact)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      // A 50-minute tile (not a round hour/half-hour): the persisted
      // duration and the rendered pixel height must both track
      // `end - start` through the whole commit cycle at 80 px/h.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 9, 50))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      // Steady state: 50 minutes at 80 px/h → 66.67 px tall.
      expect(_tileTop(tester, 'a'), closeTo(720, 0.5));
      expect(_tileHeight(tester, 'a'), closeTo(50.0 / 60 * 80, 0.5));

      // Long-press + drag 120px (90min) → drop at 10:30.
      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // The persisted request keeps the 50-minute span (10:30 → 11:20);
      // without a parent window the hard pin carries the same span.
      final edit = api.captured!;
      expect(edit.startTime, DateTime(2027, 1, 15, 10, 30));
      expect(edit.endTime, DateTime(2027, 1, 15, 11, 20));
      expect(edit.calStartTime, DateTime(2027, 1, 15, 10, 30));
      expect(edit.calEndTime, DateTime(2027, 1, 15, 11, 20));

      // Optimistic hold: the dropped slot renders at the SAME 50-minute
      // height (the start override shifts the end by the same delta —
      // it never rescales the tile).
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));
      expect(_tileHeight(tester, 'a'), closeTo(50.0 / 60 * 80, 0.5),
          reason: 'the optimistic hold must keep the 50-minute height');
      // The commit did not re-sync the initial scroll.
      final scrollController = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      expect(scrollController.position.pixels, closeTo(720, 1),
          reason: 'the commit must not snap the grid');

      // The server confirms the 50-minute span (10:30 → 11:20) — the
      // position becomes model-owned and the height is still 50 minutes.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile(
              'a', DateTime(2027, 1, 15, 10, 30), DateTime(2027, 1, 15, 11, 20))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: scroll resync (must be a no-op).
      await tester.pump(const Duration(milliseconds: 300)); // settle.
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));
      expect(_tileHeight(tester, 'a'), closeTo(50.0 / 60 * 80, 0.5),
          reason: 'the settled model must render the persisted 50 minutes');
      expect(scrollController.position.pixels, closeTo(720, 1),
          reason: 'the re-served 50-minute tile must not snap the scroll');

      await tester.runAsync(() => bloc.close());
    });
  });
  group('drag rollback + race', () {
    testWidgets(
        'API failure → rollback: pre-drag state dispatched, tile returns',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi()
        ..error = TilerError(Code: '422', Message: 'range violation');
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120)); // → 10:30.
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5)); // optimistic hold.

      // Deliver the delayed failure → the rollback path runs.
      await tester.pump(const Duration(milliseconds: 60));

      // The failure rolls the bloc back to the PRE-DRAG schedule state…
      final rollbacks =
          bloc.events.whereType<ReloadLocalScheduleEvent>().toList();
      expect(rollbacks, hasLength(1));
      final restored =
          rollbacks.first.subEvents.where((t) => t.id == 'a').toList();
      expect(restored, hasLength(1));
      expect(restored.first.start,
          DateTime(2027, 1, 15, 9).millisecondsSinceEpoch);

      // …and the tile slides back to its pre-drag slot (content y 720).
      await tester.pump(const Duration(milliseconds: 300));
      expect(_tileTop(tester, 'a'), closeTo(720, 0.5));
      expect(api.updateCount, 1);

      await tester.runAsync(() => bloc.close());
    });

    testWidgets('double drop while a request is in flight is ignored',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final inFlight = Completer<SubCalendarEvent>();
      api.pending = inFlight.future;
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10)),
          _tile('b', DateTime(2027, 1, 15, 11), DateTime(2027, 1, 15, 12)),
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      // Drop 'a' at 10:30 — the request stays in flight.
      final g1 = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await g1.moveBy(const Offset(0, 120));
      await tester.pump();
      await g1.up();
      await tester.pump();
      expect(api.updateCount, 1);

      // Drop 'b' (content top 880 → viewport y 160) while 'a' is in
      // flight: the gesture works, but the drop is ignored — no second
      // write.
      final g2 = await tester.startGesture(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 500));
      await g2.moveBy(const Offset(0, 80)); // → 12:00.
      await tester.pump();
      await g2.up();
      await tester.pump();
      expect(api.updateCount, 1, reason: 'the in-flight request wins');
      expect(bloc.events.whereType<EvaluateSchedule>(), hasLength(1));
      expect(_tileTop(tester, 'b'), closeTo(880, 0.5)); // 'b' never moved.

      // Let the first request settle — 'a' holds its confirmed slot.
      inFlight.complete(SubCalendarEvent(
        id: 'a',
        name: 'a',
        start: DateTime(2027, 1, 15, 10, 30).millisecondsSinceEpoch,
        end: DateTime(2027, 1, 15, 11, 30).millisecondsSinceEpoch,
      ));
      await tester.pump();
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));

      await tester.runAsync(() => bloc.close());
    });

    testWidgets(
        'save badge: spinner while in flight → saved badge on confirmation',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      final inFlight = Completer<SubCalendarEvent>();
      api.pending = inFlight.future;
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      // Drop 'a' at 10:30 — the request stays in flight.
      final g1 = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await g1.moveBy(const Offset(0, 120));
      await tester.pump();
      await g1.up();
      await tester.pump();

      // While the commit is in flight the tile shows the `saving`
      // spinner badge (a live CircularProgressIndicator).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);

      // Confirm the request — the spinner is replaced by the `saved`
      // badge (no timer; it lingers until the next drag interaction).
      inFlight.complete(SubCalendarEvent(
        id: 'a',
        name: 'a',
        start: DateTime(2027, 1, 15, 10, 30).millisecondsSinceEpoch,
        end: DateTime(2027, 1, 15, 11, 30).millisecondsSinceEpoch,
      ));
      // Flush the completion microtask (the `.then` that sets `saved`)
      // before the next frame is rendered.
      await tester.runAsync(() async {});
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await tester.runAsync(() => bloc.close());
    });

    testWidgets('save badge: a failed commit shows the error badge',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      api.error = TilerError(Code: '422', Message: 'boom');
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120)); // → 10:30.
      await tester.pump();
      await gesture.up();
      await tester.pump();
      // In flight: the spinner badge is up (no error badge yet).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      // Deliver the delayed failure — the rollback runs and the `error`
      // badge replaces the spinner.
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      // …and the tile is back at its pre-drag slot.
      expect(_tileTop(tester, 'a'), closeTo(720, 0.5));

      await tester.runAsync(() => bloc.close());
    });

    testWidgets('save badge (error) clears on the next drag lift (reset)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      api.error = TilerError(Code: '422', Message: 'boom');
      // The grid day is today (matches [now]) so both tiles sit at their
      // real content positions; after the initial scroll to 720 (9:00),
      // 'a' (9:00) is at viewport y 0 and 'b' (13:00) at viewport y 400.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2026, 5, 15, 9), DateTime(2026, 5, 15, 10)),
          _tile('b', DateTime(2026, 5, 15, 13), DateTime(2026, 5, 15, 14)),
        ],
        now: now,
        day: DateTime(2026, 5, 15),
      ));
      await tester.pump(); // initial scroll → 720.

      // A failed drop on 'a' leaves the `error` badge lingering.
      final g1 = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await g1.moveBy(const Offset(0, 120)); // → 10:30.
      await tester.pump();
      await g1.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60)); // deliver error.
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // A new long-press lift on a DIFFERENT tile ('b') resets the badge
      // back to idle. (A second long-press on the same spot isn't
      // guaranteed to be re-recognised by the gesture arena.) The lift
      // clears the badge before the drop could commit a new move.
      final bCenter = tester.getCenter(find.text('b'));
      final g2 = await tester.startGesture(bCenter);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      await g2.up();
      await tester.pump();

      await tester.runAsync(() => bloc.close());
    });
  });

  group('past day (all days, not only today/future)', () {
    // A grid day strictly BEFORE `now` (2026-05-15 14:30). The drag
    // approach must not special-case today: every time computation stays
    // relative to the grid day (midnight of the earliest tile), and
    // nothing may snap a past slot to "now".
    final pastDay = DateTime(2026, 5, 14);

    testWidgets('drop on a PAST day persists the past-day slot (not today/now)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2026, 5, 14, 9), DateTime(2026, 5, 14, 10))
        ],
        now: now,
        day: pastDay,
      ));
      await tester.pump(); // initial scroll → 720.

      // Long-press + drag 120px (90min) → 10:30.
      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // The persisted request stays on the PAST day — a today-specific
      // clamp (e.g. to `now`) would shift these into 2026-05-15.
      final edit = api.captured!;
      expect(edit.id, 'a');
      expect(edit.startTime, DateTime(2026, 5, 14, 10, 30));
      expect(edit.endTime, DateTime(2026, 5, 14, 11, 30));
      // No parent window → the hard pin carries the same past-day slot.
      expect(edit.calStartTime, DateTime(2026, 5, 14, 10, 30));
      expect(edit.calEndTime, DateTime(2026, 5, 14, 11, 30));

      // Same relative layout math as any day: the optimistic hold sits at
      // 10:30 → content y 840.
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));

      // The re-evaluation renders the pre-drag (past-day) schedule while
      // in flight — not a re-baseline against today.
      final evaluate = bloc.events.whereType<EvaluateSchedule>().toList();
      expect(evaluate, hasLength(1));
      final rendered =
          evaluate.first.renderedSubEvents.where((t) => t.id == 'a').toList();
      expect(rendered.first.start,
          DateTime(2026, 5, 14, 9).millisecondsSinceEpoch);

      await tester.runAsync(() => bloc.close());
    });

    testWidgets(
        're-served confirmation on a PAST day releases the optimistic hold',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2026, 5, 14, 9), DateTime(2026, 5, 14, 10))
        ],
        now: now,
        day: pastDay,
      ));
      await tester.pump(); // initial scroll → 720.

      // Drop 'a' at 10:30 — the optimistic hold renders at content y 840.
      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));

      // The parent re-serves with the confirmed PAST-DAY time — the
      // override clears and the position becomes model-owned at the same
      // slot (the layout math is relative to the grid day, not today).
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile(
              'a', DateTime(2026, 5, 14, 10, 30), DateTime(2026, 5, 14, 11, 30))
        ],
        now: now,
        day: pastDay,
      ));
      await tester.pump(); // post-frame: scroll resync (must be a no-op).
      await tester.pump(const Duration(milliseconds: 300)); // settle.
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));

      await tester.runAsync(() => bloc.close());
    });

    testWidgets('API failure on a PAST day rolls back to the pre-drag slot',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi()
        ..error = TilerError(Code: '422', Message: 'range violation');
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: [
          _tile('a', DateTime(2026, 5, 14, 9), DateTime(2026, 5, 14, 10))
        ],
        now: now,
        day: pastDay,
      ));
      await tester.pump(); // initial scroll → 720.

      final gesture = await tester.startGesture(const Offset(200, 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0, 120)); // → 10:30.
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5)); // optimistic hold.

      // Deliver the delayed failure → the rollback path runs.
      await tester.pump(const Duration(milliseconds: 60));

      // The failure restores the PRE-DRAG past-day schedule state…
      final rollbacks =
          bloc.events.whereType<ReloadLocalScheduleEvent>().toList();
      expect(rollbacks, hasLength(1));
      final restored =
          rollbacks.first.subEvents.where((t) => t.id == 'a').toList();
      expect(restored, hasLength(1));
      expect(restored.first.start,
          DateTime(2026, 5, 14, 9).millisecondsSinceEpoch);

      // …and the tile slides back to its pre-drag slot (content y 720).
      await tester.pump(const Duration(milliseconds: 300));
      expect(_tileTop(tester, 'a'), closeTo(720, 0.5));
      expect(api.updateCount, 1);

      await tester.runAsync(() => bloc.close());
    });
  });

  group('scroll preservation on tile refresh', () {
    testWidgets(
        'post-commit tile reload does NOT snap the grid back to the top',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      // A tile at 9am drives the initial scroll to 720px (9 * 80).
      final initialTiles = [
        _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10)),
      ];
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: initialTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // initial scroll → 720.

      final scrollController = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      expect(scrollController.position.pixels, closeTo(720, 1),
          reason: 'initial scroll lands at the first tile (9am)');

      // The user manually scrolls down to ~3pm (1200px = 15h * 80).
      scrollController.jumpTo(1200);
      await tester.pump();
      expect(scrollController.position.pixels, closeTo(1200, 1));

      // Simulate the re-evaluation after a drag commit: the parent re-serves
      // a NEW tiles list instance (same day, same tile, slightly moved). The
      // grid must NOT jump back to the first tile's hour — the user's scroll
      // position (1200px) is preserved.
      final reloadedTiles = [
        _tile('a', DateTime(2027, 1, 15, 10), DateTime(2027, 1, 15, 11)),
      ];
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: reloadedTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: would apply the old resync.
      await tester.pump(const Duration(milliseconds: 100));

      // The scroll position is still at 3pm — NOT snapped back to the first
      // tile (now 10am = 800px) or to the default 8am (640px).
      expect(scrollController.position.pixels, closeTo(1200, 1),
          reason: 'post-commit reload must NOT reset the user scroll position');

      await tester.runAsync(() => bloc.close());
    });

    testWidgets('initial empty → tiles arrival DOES scroll to the first tile',
        (tester) async {
      // Verifies the wasEmpty guard: when the grid starts with no tiles and
      // data arrives, the initial scroll IS applied (the "first load" case).
      final bloc = _RecordingScheduleBloc();
      final api = _FakeSubCalendarEventApi();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: <SubCalendarEvent>[],
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // empty day: initial scroll → default 8am (640).

      final scrollController = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      expect(scrollController.position.pixels, closeTo(640, 1),
          reason: 'empty day → defaultScrollHour (8am)');

      // Data arrives: first tile at 9am.
      final tiles = [
        _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10)),
      ];
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        api: api,
        tiles: tiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: scroll resync to 9am.

      expect(scrollController.position.pixels, closeTo(720, 1),
          reason: 'first tiles on empty grid → scroll to first tile hour');

      await tester.runAsync(() => bloc.close());
    });
  });
}
