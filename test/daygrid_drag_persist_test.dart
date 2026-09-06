// Drag-and-drop reschedule — persistence, optimistic settle and rollback.
//
// A committed drop hard-pins the tile to the dropped slot: `updateSubEvent`
// carries the snapped Start/End AND the same CalStart/CalEnd (the
// scheduler does not re-fit the move). The request rides
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
      return Future<SubCalendarEvent>.delayed(
          const Duration(milliseconds: 50), () {
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

SubCalendarEvent _tile(String id, DateTime start, DateTime end) {
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  t.isViable = true;
  t.thirdpartyType = TileSource.tiler;
  t.split = 1;
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

      // The request is a HARD PIN: the calendar-event slot (CalStart/
      // CalEnd) is pinned to the dropped slot as well, so the scheduler
      // cannot re-fit the move elsewhere.
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
      final rendered = evaluate.first.renderedSubEvents
          .where((t) => t.id == 'a')
          .toList();
      expect(rendered, hasLength(1));
      expect(rendered.first.start,
          DateTime(2027, 1, 15, 9).millisecondsSinceEpoch);

      // Optimistic settle: the tile holds the dropped slot (content y
      // 840) even though the model still says 09:00 (720).
      expect(_tileTop(tester, 'a'), closeTo(840, 0.5));

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
      expect(
          bloc.events.whereType<EvaluateSchedule>(),
          hasLength(1));
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
  });
}