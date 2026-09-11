// DayGrid scroll host (P6 Step 16.3, C18).
//
// The grid's scroll view is a `center`-anchored `CustomScrollView`: the
// 24h grid Stack is the center sliver (anchored at `pixels == 0`), and an
// optional `header` sliver sits BEFORE it in negative scroll extent
// `[minScrollExtent, 0)`. Consequences this suite pins down:
//   * no header → `minScrollExtent == 0`, byte-identical to the old
//     SingleChildScrollView host;
//   * with a header → `minScrollExtent == -headerExtent`, and `pixels == 0`
//     still puts 12 AM at the top of the viewport (the header is above);
//   * the initial auto-scroll never reveals the header (lower clamp 0.0);
//   * a header height change moves `minScrollExtent`, NEVER the grid
//     (`pixels` and every tile `Rect` unchanged) — the no-snap core;
//   * a user pull-down reveals the header and `onHeaderRevealChanged`
//     reports 0 → 1;
//   * pull-to-refresh still fires -- from a pull that starts with the header
//     fully revealed (`RefreshIndicator` arms only at `extentBefore == 0`).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

class _RecordingScheduleBloc extends ScheduleBloc {
  final List<ScheduleEvent> events = <ScheduleEvent>[];

  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    events.add(event);
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
    throw StateError('bloc.close() stalled after $pumps drains');
  });
}

Widget _buildApp({
  required ScheduleBloc bloc,
  required DayGridController controller,
  required List<SubCalendarEvent> tiles,
  Widget? header,
  ValueChanged<double>? onHeaderRevealChanged,
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
          now: DateTime(2026, 5, 15, 14, 30),
          day: DateTime(2027, 1, 15),
          dayKey: 'd',
          controller: controller,
          header: header,
          onHeaderRevealChanged: onHeaderRevealChanged,
        ),
      ),
    ),
  );
}

Widget _header(double height) => SizedBox(
      key: const Key('test_header'),
      height: height,
      child: const ColoredBox(color: Colors.red),
    );

ScrollController _scrollControllerOf(WidgetTester tester) => tester
    .widget<CustomScrollView>(find.byType(CustomScrollView))
    .controller!;

Finder _tileCard(String id) => find.byWidgetPredicate(
    (w) => w is TileGridWidget && w.tilerEvent.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final day = DateTime(2027, 1, 15);

  group('DayGrid initial scroll lands on the FIRST frame (no post-frame jump)',
      () {
    testWidgets(
        'the scroll controller is created at the first-tile-hour offset',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController(); // 80 px/h
      addTearDown(controller.dispose);
      // A carousel day page sliding into view mounts fresh: its first
      // painted frame must already be at 9 AM (720 px), not at 12 AM.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [
          _tile('nine', day.add(const Duration(hours: 9)),
              day.add(const Duration(hours: 10))),
        ],
        header: _header(240),
      ));

      final scrollController = _scrollControllerOf(tester);
      expect(scrollController.initialScrollOffset, 720.0,
          reason: 'the initial offset is baked into the controller, so the '
              'very first layout is at the target — no visible jump');
      expect(scrollController.position.pixels, 720.0);
      await _closeBloc(tester, bloc);
    });
  });

  group('DayGrid scroll host (center-anchored CustomScrollView)', () {
    testWidgets('no header → minScrollExtent is 0 (legacy behaviour)',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [_tile('a', day, day.add(const Duration(hours: 1)))],
      ));
      await tester.pump();

      final position = _scrollControllerOf(tester).position;
      expect(position.minScrollExtent, 0.0);
      expect(position.pixels, 0.0);
      await _closeBloc(tester, bloc);
    });

    testWidgets(
        'with a header → minScrollExtent is -headerExtent and the grid stays anchored at 0',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController(); // 80 px/h
      addTearDown(controller.dispose);
      // Tile at 00:00 → the initial auto-scroll targets hour 0 → 0 px.
      // With the header in negative extent the clamp must land on 0, not
      // on minScrollExtent (the header must NOT be auto-revealed).
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [_tile('a', day, day.add(const Duration(hours: 1)))],
        header: _header(240),
      ));
      await tester.pump();

      final position = _scrollControllerOf(tester).position;
      expect(position.minScrollExtent, -240.0);
      expect(position.pixels, 0.0,
          reason: 'initial auto-scroll must never reveal the header');
      // The 00:00 tile sits at the very top of the grid viewport — the
      // header is entirely above it (off-screen).
      final gridTop = tester.getTopLeft(find.byType(DayGridWidget)).dy;
      expect(tester.getTopLeft(_tileCard('a')).dy, closeTo(gridTop, 1.0));
      expect(find.byKey(const Key('test_header')), findsNothing);
      await _closeBloc(tester, bloc);
    });

    testWidgets(
        'a header height change moves minScrollExtent, never the grid (no-snap core)',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tiles = [
        _tile('ten', day.add(const Duration(hours: 10)),
            day.add(const Duration(hours: 11))),
      ];
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: tiles,
        header: _header(240),
      ));
      await tester.pump();

      final scrollController = _scrollControllerOf(tester);
      scrollController.jumpTo(600);
      await tester.pump();
      final before = tester.getRect(_tileCard('ten'));
      expect(scrollController.position.pixels, 600.0);

      // Same tiles instance, taller header.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: tiles,
        header: _header(300),
      ));
      await tester.pump();

      expect(scrollController.position.minScrollExtent, -300.0);
      expect(scrollController.position.pixels, 600.0,
          reason: 'the grid must not move when the header grows');
      expect(tester.getRect(_tileCard('ten')), before,
          reason: 'tile geometry must be pixel-identical');
      await _closeBloc(tester, bloc);
    });

    testWidgets(
        'a pull-down reveals the header and reports reveal progress 0 → 1',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final progress = <double>[];
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [_tile('a', day, day.add(const Duration(hours: 1)))],
        header: _header(240),
        onHeaderRevealChanged: progress.add,
      ));
      await tester.pump();
      expect(_scrollControllerOf(tester).position.pixels, 0.0);

      // Drag down past the header extent (+ touch slop); clamping physics
      // stop at minScrollExtent, so the header is fully revealed without a
      // refresh being armed (a refresh needs a drag that STARTS there).
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 280));
      await tester.pumpAndSettle();

      final position = _scrollControllerOf(tester).position;
      expect(position.pixels, closeTo(-240, 1.0));
      expect(find.byKey(const Key('test_header')), findsOneWidget);
      expect(progress, isNotEmpty);
      expect(progress.last, closeTo(1.0, 0.01));
      // Monotonic non-decreasing while pulling.
      for (int i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1] - 0.001));
      }
      // No refresh was triggered by a reveal that stops at the extent.
      expect(bloc.events.whereType<GetScheduleEvent>(), isEmpty);
      await _closeBloc(tester, bloc);
    });

    testWidgets('pull-to-refresh still fires after a full reveal',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [_tile('a', day, day.add(const Duration(hours: 1)))],
        header: _header(240),
      ));
      await tester.pump();

      // First pull: reveal the header (lands on minScrollExtent).
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 280));
      await tester.pumpAndSettle();
      expect(_scrollControllerOf(tester).position.pixels, closeTo(-240, 1.0));
      expect(bloc.events.whereType<GetScheduleEvent>(), isEmpty,
          reason: 'revealing the header must not refresh');

      // Second pull, starting AT minScrollExtent: overscroll → refresh.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final dispatches = bloc.events.whereType<GetScheduleEvent>().toList();
      expect(dispatches, isNotEmpty);
      expect(dispatches.first.forceRefresh, isTrue);
      await _closeBloc(tester, bloc);
    });
  });
}
