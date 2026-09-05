// DayGrid adaptive rendering — the two remaining adaptive rows:
// "Adaptive lines/labels" and "Tile content reflow".
//
// Covers:
//   * `DayGridWidget.gutterLineStride` — hour guide-line density thins out
//     at low zoom (every 2nd hour below the thin threshold).
//   * `DayGridWidget.gutterTickIntervalMinutes` — sub-hour tick hairlines
//     appear at high zoom (30 min; 15 min at/above the fine-snap
//     threshold of 160 px/h) and disappear at low zoom.
//   * `TileGridWidgetState.tileContentCollapsed` — tiles shorter than the
//     caption threshold collapse to a plain color bar (no name Text).
//   * Widget level: line/label/tick counts follow `pxPerHour`; a short tile
//     renders its caption only once it is tall enough at the current zoom.
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
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records `ScheduleBloc` events WITHOUT running the [GetScheduleEvent]
/// handler (no API calls in tests). Same idiom as the pinch-zoom suite.
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

/// Enlarges the test surface to a tall phone so the grid viewport is
/// realistic for the layout assertions (same idiom as the pinch-zoom suite).
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

/// Closes [bloc] from the real async zone (same idiom as the DayGrid
/// refresh / now-line suite).
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

/// The sub-hour tick hairlines in the gutter (keyed `daygrid_tick_h*m*`).
final _tickFinder = find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key as ValueKey<String>).value.startsWith('daygrid_tick_h'),
);

Widget _buildApp({
  required ScheduleBloc bloc,
  required DayGridController controller,
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
          controller: controller,
        ),
      ),
    ),
  );
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final dayStart = DateTime(2027, 1, 15);
  final now = DateTime(2026, 5, 15, 14, 30);

  group('DayGridWidget.gutterLineStride (adaptive lines)', () {
    test('renders an hour guide line every hour at/above the threshold', () {
      expect(
          DayGridWidget.gutterLineStride(
              DayGridWidget.gutterThinLabelThreshold),
          1);
      expect(DayGridWidget.gutterLineStride(80), 1);
      expect(DayGridWidget.gutterLineStride(240), 1);
    });

    test('thins to every 2nd hour below the threshold', () {
      expect(DayGridWidget.gutterLineStride(40), 2);
      expect(
          DayGridWidget.gutterLineStride(
              DayGridWidget.gutterThinLabelThreshold - 0.1),
          2);
    });
  });

  group('DayGridWidget.gutterTickIntervalMinutes (sub-hour ticks)', () {
    test('no sub-hour ticks below the thin threshold', () {
      expect(DayGridWidget.gutterTickIntervalMinutes(40), isNull);
      expect(
          DayGridWidget.gutterTickIntervalMinutes(
              DayGridWidget.gutterThinLabelThreshold - 0.1),
          isNull);
    });

    test('30-minute ticks between the thin and the C4 fine-snap thresholds',
        () {
      expect(DayGridWidget.gutterTickIntervalMinutes(64), 30);
      expect(DayGridWidget.gutterTickIntervalMinutes(80), 30);
      expect(DayGridWidget.gutterTickIntervalMinutes(159.9), 30);
    });

    test('15-minute ticks at/above the C4 fine-snap threshold (160)', () {
      expect(DayGridWidget.gutterTickIntervalMinutes(160), 15);
      expect(DayGridWidget.gutterTickIntervalMinutes(240), 15);
    });
  });

  group('TileGridWidgetState.tileContentCollapsed (content reflow)', () {
    test('collapses below the caption threshold', () {
      expect(
          TileGridWidgetState.tileContentCollapsed(
              TileGridWidgetState.collapsedTileHeight - 0.1),
          isTrue);
      // The 20-min minimum height at the C8 floor zoom (40 px/h = 13.33px).
      expect(TileGridWidgetState.tileContentCollapsed(13.33), isTrue);
    });

    test('keeps the caption at/above the threshold', () {
      expect(
          TileGridWidgetState.tileContentCollapsed(
              TileGridWidgetState.collapsedTileHeight),
          isFalse);
      expect(TileGridWidgetState.tileContentCollapsed(80), isFalse);
    });
  });

group('DayGridWidget adaptive gutter (widget)', () {
    testWidgets('hour lines thin out at low zoom, dense at high zoom',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      controller.setPxPerHour(80);

      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [
          _tile('anchor', DateTime(2027, 1, 15, 0),
              DateTime(2027, 1, 15, 1))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump();

      // 80 px/h: an hour guide line every hour (24) + all 24 labels.
      expect(find.byType(TileTimeCellWidget), findsNWidgets(24));
      expect(find.byType(TimeOfDayTimeCellWidget), findsNWidgets(24));

      // Zoom out below the thin threshold: major lines every 2nd hour (12)
      // and the sub-hour ticks drop away.
      controller.setPxPerHour(40);
      await tester.pump();
      expect(find.byType(TileTimeCellWidget), findsNWidgets(12));
      expect(_tickFinder, findsNothing);

      await _closeBloc(tester, bloc);
      controller.dispose();
    });

    testWidgets('sub-hour ticks appear at high zoom (30 min, then 15 min)',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      controller.setPxPerHour(80);

      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [
          _tile('anchor', DateTime(2027, 1, 15, 0),
              DateTime(2027, 1, 15, 1))
        ],
        now: now,
        day: dayStart,
      ));
      await tester.pump();

      // 80 px/h -> 30-min ticks: one per hour row (24).
      expect(_tickFinder, findsNWidgets(24));

      // 240 px/h -> 15-min ticks: three per hour row (72).
      controller.setPxPerHour(240);
      await tester.pump();
      expect(_tickFinder, findsNWidgets(72));

      // Back below the thin threshold -> no ticks at all.
      controller.setPxPerHour(40);
      await tester.pump();
      expect(_tickFinder, findsNothing);

      await _closeBloc(tester, bloc);
      controller.dispose();
    });
  });

  group('Tile content reflow (widget)', () {
    testWidgets('a short tile collapses to a plain bar; tall shows the name',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      controller.setPxPerHour(40);

      // 30 min at 40 px/h = 20px — above the 13.33px min but below the
      // 32px caption threshold.
      final shortTile = _tile('short_tile', DateTime(2027, 1, 15, 9),
          DateTime(2027, 1, 15, 9, 30));
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [shortTile],
        now: now,
        day: dayStart,
      ));
      await tester.pump();

      expect(find.byType(TileGridWidget), findsOneWidget);
      // Collapsed: no name caption anywhere.
      expect(find.text('short_tile'), findsNothing);

      // Zoom in: the same 30-min tile is 120px tall -> caption returns on
      // the same element (no remount).
      controller.setPxPerHour(240);
      await tester.pump();
      expect(find.text('short_tile'), findsOneWidget);

      await _closeBloc(tester, bloc);
      controller.dispose();
    });
  });
}