// Moved tiles fly in the daily list: the row is hidden while a copy flies
// from where it was to where it went, an outline stays at the old row, and
// tiles that leave the screen (or the day) get an edge chip instead.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleMotion/schedule_motion_cubit.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/listFlights.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoff.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoffChip.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

// A past day: no free-slot rows and no "now" auto-scroll.
final DateTime day = DateTime(2026, 5, 15);
final Timeline dayTimeline =
    Timeline.fromDateTime(day, day.add(const Duration(days: 1)));
final Timeline window = Timeline.fromDateTime(
    day.subtract(const Duration(days: 3)), day.add(const Duration(days: 4)));

SubCalendarEvent tile(String id, double startHour, {int dayOffset = 0}) {
  final start =
      day.add(Duration(days: dayOffset, minutes: (startHour * 60).round()));
  return SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
  );
}

ScheduleStatus status(String id) =>
    ScheduleStatus.fromJson({'analysisId': id, 'evaluationId': id});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListFlightPlayer', () {
    GridChoreography steps(List<String> ids) {
      final before = [
        for (var i = 0; i < ids.length; i++) tile(ids[i], 8.0 + i)
      ];
      final after = [
        for (var i = 0; i < ids.length; i++) tile(ids[i], 8.5 + i)
      ];
      return GridChoreography.plan(ScheduleDelta.compute(
          before: before, after: after, day: dayTimeline))!;
    }

    test('prepare hides the rows; launch drops tiles with nowhere to land', () {
      final player = ListFlightPlayer(apply: (change) => change());
      player.prepare({
        'a': (const Rect.fromLTWH(0, 0, 100, 50), 0),
        'b': (const Rect.fromLTWH(0, 60, 100, 50), 0),
      });
      expect(player.isHidden('a'), isTrue);
      expect(player.isHidden('b'), isTrue);

      player.launch(
          {'a': const Rect.fromLTWH(0, 200, 100, 50)}, steps(['a', 'b']));
      expect(player.isHidden('a'), isTrue);
      expect(player.isHidden('b'), isFalse);
      player.stop(notify: false);
    });

    testWidgets('lift, fly, land, then the row comes back', (tester) async {
      final player = ListFlightPlayer(apply: (change) => change());
      player.prepare({'a': (const Rect.fromLTWH(0, 0, 100, 50), 0)});
      player.launch({'a': const Rect.fromLTWH(0, 200, 100, 50)}, steps(['a']));
      final flight = player.flights.single;
      expect(flight.lifted, isFalse);

      await tester.pump(Duration.zero);
      expect(flight.lifted, isTrue);
      expect(player.ghosts, hasLength(1));
      await tester.pump(GridChoreography.lift);
      expect(flight.moving, isTrue);
      await tester.pump(GridChoreography.move);
      expect(player.isHidden('a'), isFalse);
      expect(player.ghosts.single.value.fading, isTrue);
      await tester.pump(GridChoreography.ghostLinger);
      expect(player.isActive, isFalse);
    });

    testWidgets('rows come back if the flight is never launched',
        (tester) async {
      final player = ListFlightPlayer(apply: (change) => change());
      player.prepare({'a': (const Rect.fromLTWH(0, 0, 100, 50), 0)});
      await tester.pump(ListFlightPlayer.launchTimeout);
      expect(player.isHidden('a'), isFalse);
    });
  });

  group('EnhancedTileBatch flights', () {
    late ScheduleBloc bloc;
    late List<SubCalendarEvent> dayTiles;

    Future<void> reload(WidgetTester tester, List<SubCalendarEvent> all,
        ScheduleStatus s) async {
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: all,
          timelines: const [],
          lookupTimeline: window,
          scheduleStatus: s));
      await tester.pump();
    }

    /// Twelve half-hour tiles, one per hour from 8am, in a 500 px list.
    Future<void Function()> mount(WidgetTester tester,
        {ScheduleMotionCubit? motion}) async {
      SharedPreferences.setMockInitialValues({});
      bloc = ScheduleBloc(getContextCallBack: () => null);
      dayTiles = [for (var i = 0; i < 12; i++) tile('T$i', 8.0 + i)];
      await reload(tester, dayTiles, status('r0'));
      late void Function() rebuild;
      Widget body = StatefulBuilder(builder: (context, setState) {
        rebuild = () => setState(() {});
        return SizedBox(
          height: 500,
          child: EnhancedTileBatch(
            dayIndex: day.universalDayIndex,
            tiles: dayTiles,
            showProactiveAlerts: false,
            showTimelineMarkers: false,
            showEnhancedCards: true,
            showConflictAlerts: false,
            showTravelConnectors: false,
            showFreeSlots: false,
          ),
        );
      });
      final providers = <BlocProvider>[
        BlocProvider<ScheduleBloc>.value(value: bloc),
        BlocProvider<ScheduleSummaryBloc>(
            create: (_) => ScheduleSummaryBloc(getContextCallBack: () => null)),
        if (motion != null)
          BlocProvider<ScheduleMotionCubit>.value(value: motion),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: MultiBlocProvider(providers: providers, child: body)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return rebuild;
    }

    /// Serves [all] as revision r1 with [onDay] as this day's tiles.
    Future<void> serve(WidgetTester tester, void Function() rebuild,
        List<SubCalendarEvent> all, List<SubCalendarEvent> onDay) async {
      dayTiles = onDay;
      await reload(tester, all, status('r1'));
      rebuild();
      await tester.pump();
    }

    List<SubCalendarEvent> withT1At(double hour, {int dayOffset = 0}) => [
          for (final t in [for (var i = 0; i < 12; i++) tile('T$i', 8.0 + i)])
            t.uniqueId == 'T1' ? tile('T1', hour, dayOffset: dayOffset) : t
        ];

    double rowOpacity(WidgetTester tester, String name) => tester
        .widget<Opacity>(
            find.byKey(ValueKey<String>('list_row_opacity_tile:$name')))
        .opacity;

    final flight = find.byKey(ListFlightOverlay.flightKey('T1'));
    final ghost = find.byKey(ListFlightOverlay.ghostKey('T1'));
    final later = find.byKey(GridHandoffChip.keyFor(HandoffDirection.later));
    final nextDay =
        find.byKey(GridHandoffChip.keyFor(HandoffDirection.nextDay));

    testWidgets('a re-optimize flies a tile that moves within view',
        (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = withT1At(11.5);
      await serve(tester, rebuild, moved, moved);

      // From the first frame the real row is hidden and a copy holds it.
      expect(flight, findsOneWidget);
      expect(rowOpacity(tester, 'T1'), 0);

      await tester.pump(); // laid out: the copy gets its destination
      await tester.pump(Duration.zero); // lift
      expect(ghost, findsOneWidget);
      expect(find.text('Moved to 11:30 AM'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      expect(flight, findsNothing);
      expect(rowOpacity(tester, 'T1'), 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(ghost, findsNothing);
      expect(later, findsNothing);
    });

    testWidgets('a tile that moves below the view gets a chip, no flight',
        (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = withT1At(20.5);
      await serve(tester, rebuild, moved, moved);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(flight, findsNothing);
      expect(later, findsOneWidget);
      expect(find.text('T1 moved to 8:30 PM'), findsOneWidget);

      await tester.tap(later);
      // Not pumpAndSettle: the day summary shimmers while it loads.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(later, findsNothing);
      expect(find.text('T1'), findsOneWidget);
    });

    testWidgets('a tile moved to another day gets a day chip', (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final all = withT1At(9, dayOffset: 1);
      await serve(
          tester, rebuild, all, all.where((t) => t.uniqueId != 'T1').toList());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(nextDay, findsOneWidget);
      expect(find.text('T1 moved to Sat, May 16'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a background refresh moves the row at once', (tester) async {
      final rebuild = await mount(tester);
      final moved = withT1At(11.5);
      await serve(tester, rebuild, moved, moved);
      expect(flight, findsNothing);
      expect(rowOpacity(tester, 'T1'), 1);
      await tester.pump(const Duration(seconds: 1));
      expect(later, findsNothing);
    });

    testWidgets('Minimal mode: no flight, but the chip still shows',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {ScheduleMotionPreferences.modeKey: 'minimal'});
      final motion = ScheduleMotionCubit();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      final rebuild = await mount(tester, motion: motion);

      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = withT1At(20.5);
      await serve(tester, rebuild, moved, moved);
      expect(flight, findsNothing);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(later, findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await motion.close();
    });
  });
}
