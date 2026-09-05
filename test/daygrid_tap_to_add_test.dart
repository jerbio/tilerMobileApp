// Tap-to-add.
//
// Tapping an empty region of the *daily* grid seeds a new tile at the tapped
// (snapped) time and opens the existing `AddTile` route with a `PreTile`.
//
// `DayGridWidget.computeTapSeed` is the pure inverse of the layout mapping
// `time(y) = y / pxPerHour`: snapped DOWN to the controller's `snapInterval`
// (shared with drag-and-drop), clamped to the visible day (a tap
// resolving into the past prefills with "now"), and a 1h default duration.
// The widget tests prove the daily grid actually pushes `AddTile` with the
// seeded preTile, and that a grid with no `day` (the forecast peek) stays
// read-only.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records `ScheduleBloc` events WITHOUT running the [GetScheduleEvent] handler
/// (no API calls in tests). The grid only touches the bloc on pull-to-refresh,
/// which these tests don't exercise — the provider just needs to exist.
class _RecordingScheduleBloc extends ScheduleBloc {
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    if (event is GetScheduleEvent) {
      return;
    }
    super.add(event);
  }
}

SubCalendarEvent _tile(String id, DateTime start, DateTime end) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  tile.isViable = true;
  return tile;
}

Widget _buildApp({
  required ScheduleBloc bloc,
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
        body: DayGridWidget(tiles: tiles, now: now, day: day),
      ),
    ),
  );
}
/// Closes [bloc] from the real async zone, draining the FakeAsync microtask
/// queue while the done-delivery cascade is in flight (same idiom as the
/// DayGrid refresh/now-line suite).
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

/// Enlarges the test surface so the (tall) `AddTile` screen pushed by the
/// grid does not report a RenderFlex overflow during a pump.
void _setSurface(WidgetTester tester) {
  final originalPhysicalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(1080, 2160); // logical 540 x 1080.
  addTearDown(() {
    tester.view.devicePixelRatio = originalDpr;
    tester.view.physicalSize = originalPhysicalSize;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('computeTapSeed (y→time inversion, guards)', () {
    // A future grid day: no past-time prefill, so the raw snapped time is returned.
    final dayStart = DateTime(2027, 1, 15);
    final now = DateTime(2026, 5, 15, 14, 30);

    test('exact hour -> snapped start with 1h default duration', () {
      final seed = DayGridWidget.computeTapSeed(
        dayStart: dayStart,
        dy: 4 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
        now: now,
      );
      expect(seed.start, DateTime(2027, 1, 15, 4, 0));
      expect(seed.duration, const Duration(hours: 1));
      expect(seed.prefilledFromNow, isFalse);
    });

    test('snaps DOWN to snapInterval', () {
      // 4:07 at 80 px/h -> 4:00 (15-min snap, snap down).
      final seed = DayGridWidget.computeTapSeed(
        dayStart: dayStart,
        dy: (4 + 7 / 60.0) * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
        now: now,
      );
      expect(seed.start, DateTime(2027, 1, 15, 4, 0));
    });

    test('snap granularity follows the zoom band', () {
      const dy = 12.483 * 80; // raw hour ~12:29.
      expect(
        DayGridWidget.computeTapSeed(
          dayStart: dayStart,
          dy: dy,
          pxPerHour: 80,
          snapInterval: const Duration(minutes: 30),
          now: now,
        ).start,
        DateTime(2027, 1, 15, 12, 0),
      );
      expect(
        DayGridWidget.computeTapSeed(
          dayStart: dayStart,
          dy: dy,
          pxPerHour: 80,
          snapInterval: const Duration(minutes: 5),
          now: now,
        ).start,
        DateTime(2027, 1, 15, 12, 25),
      );
    });

    test('clamps below midnight to 00:00', () {
      final seed = DayGridWidget.computeTapSeed(
        dayStart: dayStart,
        dy: -100,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
        now: now,
      );
      expect(seed.start, DateTime(2027, 1, 15, 0, 0));
    });

    test('clamps at the day end to the last snap slot', () {
      final seed = DayGridWidget.computeTapSeed(
        dayStart: dayStart,
        dy: 24 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
        now: now,
      );
      expect(seed.start, DateTime(2027, 1, 15, 23, 45));
    });

    test('a past-time tap prefills with now', () {
      // Grid day is today; tapping 10:00 (before now 14:30) -> now.
      final today = DateTime(2026, 5, 15);
      final seed = DayGridWidget.computeTapSeed(
        dayStart: today,
        dy: 10 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
        now: now,
      );
      expect(seed.start, DateTime(2026, 5, 15, 14, 30));
      expect(seed.prefilledFromNow, isTrue);
    });

    test('a tap at/after now is not prefilled', () {
      final today = DateTime(2026, 5, 15);
      final seed = DayGridWidget.computeTapSeed(
        dayStart: today,
        dy: 16 * 80,
        pxPerHour: 80,
        snapInterval: const Duration(minutes: 15),
        now: now,
      );
      expect(seed.start, DateTime(2026, 5, 15, 16, 0));
      expect(seed.prefilledFromNow, isFalse);
    });
  });
group('DayGridWidget tap-to-add wiring (daily view)', () {
    // A future grid day (no past-time prefill) with a 0–1h tile that pins the
    // initial scroll offset to 0 (midnight at the viewport top).
    final dayStart = DateTime(2027, 1, 15);
    final now = DateTime(2026, 5, 15, 14, 30);
    final anchorTiles = <SubCalendarEvent>[
      _tile('t0', DateTime(2027, 1, 15, 0), DateTime(2027, 1, 15, 1)),
    ];

    testWidgets('empty-area tap pushes AddTile seeded at the tapped time',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: anchorTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: initial scroll settles at 0.

      // Default controller: 80 px/h. y = 320 -> 4:00.
      await tester.tapAt(const Offset(200, 320));
      await tester.pump();
      // Advance the fake clock past AddTile's 700ms auto-result Timer
      // (started in initState because preTile.location is null) so its
      // callback runs and is consumed. The callback is a no-op here
      // (preTile.description is null). AddTileState.dispose() would cancel
      // the now directly-cancellable Timer anyway, so this pump is just
      // belt-and-suspenders for the "A Timer is still pending" invariant.
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(AddTile), findsOneWidget);
      final addTile = tester.widget<AddTile>(find.byType(AddTile));
      expect(addTile.preTile!.startTime, DateTime(2027, 1, 15, 4, 0));
      expect(addTile.preTile!.duration, const Duration(hours: 1));
      await _closeBloc(tester, bloc);
    });

    testWidgets('empty-area tap snaps DOWN to the 15-min interval',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: anchorTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump();

      // y for 4:07 at 80 px/h -> snaps down to 4:00.
      await tester.tapAt(Offset(200, (4 + 7 / 60.0) * 80));
      await tester.pump();
      // Fire AddTile's 700ms auto-result Timer (see above) so no Timer is
      // pending when the widget tree is torn down.
      await tester.pump(const Duration(milliseconds: 750));

      final addTile = tester.widget<AddTile>(find.byType(AddTile));
      expect(addTile.preTile!.startTime, DateTime(2027, 1, 15, 4, 0));
      await _closeBloc(tester, bloc);
    });

    testWidgets('no day supplied -> tap-to-add is disabled (read-only)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      // No `day` (as in DayCast): an empty-area tap must NOT push AddTile.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: anchorTiles,
        now: now,
      ));
      await tester.pump();

      await tester.tapAt(const Offset(200, 320));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AddTile), findsNothing);
      await _closeBloc(tester, bloc);
    });

    testWidgets(
        'dismissing AddTile before the 700ms auto-result fires leaves no pending Timer',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: anchorTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: initial scroll settles.

      // Push AddTile; initState schedules the 700ms auto-result Timer because
      // the seeded preTile has location == null.
      await tester.tapAt(const Offset(200, 320));
      await tester.pump();
      // Settle the push so AddTile is built and its initState Timer is
      // scheduled. 100ms keeps the fake clock well under the 700ms
      // auto-result Timer.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AddTile), findsOneWidget);

      // Dismiss AddTile while the 700ms auto-result Timer is still pending:
      // pop the route so AddTileState.dispose() runs. dispose() cancels the
      // (now directly-cancellable) Timer, so no Timer is pending at test end.
      // (Fake clock here is ~400ms < 700ms, so the Timer is still live when
      // it is cancelled.) Under the previous
      // Future.delayed(...).asStream().listen(...) approach the underlying
      // one-shot Timer would survive dispose and trip the framework's
      // "A Timer is still pending" invariant.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump(); // start the (300ms) reverse transition.
      await tester.pump(const Duration(milliseconds: 300)); // transition done.
      await tester.pump(); // frame that detaches & disposes AddTile.

      expect(find.byType(AddTile), findsNothing);
      await _closeBloc(tester, bloc);
    });
  });
}