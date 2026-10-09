// Colour cues for a schedule change (Detailed mode only): free time that
// opened up turns green, the travel change that pushed tiles turns amber
// before they lift, and a moved tile pulses in the accent as it lands. Plus
// the empty-day state honouring the "Schedule updates" setting.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleMotion/schedule_motion_cubit.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/freeGapFlash.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridStepPlayer.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/services/changeFlash.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

final DateTime day = DateTime(2026, 5, 15);
final Timeline dayTimeline =
    Timeline.fromDateTime(day, day.add(const Duration(days: 1)));
int at(int h, int m) =>
    day.add(Duration(hours: h, minutes: m)).millisecondsSinceEpoch;

SubCalendarEvent tile(String id, int start, int minutes, {int travel = 0}) {
  final t = SubCalendarEvent(
      id: id, name: id, start: start, end: start + minutes * 60000);
  t.travelTimeBefore = travel * 60000.0;
  return t;
}

/// Sync, groceries, Vit.D, dinner, read.
List<SubCalendarEvent> thursday({int? vitd, int? groc, int grocTravel = 12}) =>
    [
      tile('sync', at(16, 0), 45),
      tile('groc', groc ?? at(17, 15), 40, travel: grocTravel),
      tile('vitd', vitd ?? at(18, 11), 30, travel: 7),
      tile('dinner', at(19, 0), 45),
      tile('read', at(20, 30), 30),
    ];

ScheduleDelta diff(List<SubCalendarEvent> a, List<SubCalendarEvent> b) =>
    ScheduleDelta.compute(before: a, after: b, day: dayTimeline);

ScheduleStatus status(String id) =>
    ScheduleStatus.fromJson({'analysisId': id, 'evaluationId': id});

Widget app(Widget child) => MaterialApp(
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScheduleDelta.grownGaps', () {
    test('moving a tile out opens up the gap it sat in', () {
      final gaps = diff(thursday(), thursday(vitd: at(19, 55))).grownGaps;
      expect(gaps, hasLength(1));
      expect(gaps.single.beforeTileId, 'dinner');
      // Vit.D's 30 min plus the 7 min drive into it.
      expect(gaps.single.gained, const Duration(minutes: 37));
      expect(gaps.single.length, const Duration(minutes: 65));
    });

    test('a shorter drive frees the time before the tile', () {
      final gaps = diff(thursday(grocTravel: 30), thursday()).grownGaps;
      expect(gaps.single.beforeTileId, 'groc');
      expect(gaps.single.gained, const Duration(minutes: 18));
    });

    test('nothing changed, nothing grew', () {
      expect(diff(thursday(), thursday()).grownGaps, isEmpty);
    });
  });

  group('cause first', () {
    test('a batch pushed by a travel change waits for it', () {
      // The drive to groceries grows 12 -> 30 min, pushing groceries and
      // then Vit.D.
      final steps = GridChoreography.plan(diff(thursday(),
          thursday(groc: at(17, 33), vitd: at(18, 20), grocTravel: 30)))!;
      final batch = steps.batches.single;
      expect(batch.causeIds, ['groc']);
      expect(batch.causeAt, Duration.zero);
      expect(batch.liftAt, GridChoreography.causeLead);
    });

    test('without a travel change nothing waits', () {
      final steps =
          GridChoreography.plan(diff(thursday(), thursday(vitd: at(19, 55))))!;
      expect(steps.batches.single.causeIds, isEmpty);
      expect(steps.batches.single.liftAt, Duration.zero);
    });
  });

  group('GridStepPlayer flashes', () {
    testWidgets('travel first, then the landed tile, then the gained time',
        (tester) async {
      final before = thursday();
      final after =
          thursday(groc: at(17, 33), vitd: at(18, 20), grocTravel: 30);
      final delta = diff(before, after);
      final steps = GridChoreography.plan(delta)!;
      final player = GridStepPlayer(apply: (change) => change());
      player.start(
        steps,
        before: {for (final t in before) t.uniqueId: t},
        after: {for (final t in after) t.uniqueId: t},
        layoutOf: (_) => (0.0, 100.0),
        grownGaps: [
          FreeGap(
              startMs: at(18, 50),
              endMs: at(19, 0),
              gained: const Duration(minutes: 10),
              beforeTileId: 'dinner'),
        ],
      );
      final batch = steps.batches.single;

      await tester.pump(Duration.zero);
      expect(player.travelFlashing('groc'), isTrue);
      expect(player.flashFor('groc'), isNull);

      await tester.pump(batch.landAt);
      expect(player.flashFor('groc'), ChangeFlash.moved);
      expect(player.flashFor('vitd'), ChangeFlash.moved);
      expect(player.gapFlashes, hasLength(1));

      await tester.pump(ChangeFlashStyle.hold - batch.landAt);
      expect(player.travelFlashing('groc'), isFalse);

      await tester.pump(ChangeFlashStyle.hold + ChangeFlashStyle.fade);
      expect(player.flashFor('groc'), isNull);
      expect(player.gapFlashes, isEmpty);
    });
  });

  group('DayGridWidget flashes', () {
    testWidgets('the moved tile pulses and the opened gap turns green',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bloc = ScheduleBloc(getContextCallBack: () => null);
      List<SubCalendarEvent> tiles = [
        tile('a', at(8, 0), 60),
        tile('b', at(10, 0), 60),
        tile('c', at(12, 0), 60),
      ];
      Future<void> reload(ScheduleStatus s) async {
        bloc.add(ReloadLocalScheduleEvent(
            subEvents: tiles,
            timelines: const [],
            lookupTimeline: dayTimeline,
            scheduleStatus: s));
        await tester.pump();
      }

      await reload(status('r0'));
      late void Function() rebuild;
      await tester.pumpWidget(app(BlocProvider<ScheduleBloc>.value(
        value: bloc,
        child: StatefulBuilder(builder: (context, setState) {
          rebuild = () => setState(() {});
          return SizedBox(
            width: 400,
            height: 600,
            child: DayGridWidget(
                tiles: tiles, day: day, now: DateTime(2026, 5, 16, 9)),
          );
        }),
      )));
      await tester.pump();
      await tester.pump();

      // b leaves 10am for 2pm: the 9am-12pm stretch opens up.
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      tiles = [tiles[0], tile('b', at(14, 0), 60), tiles[2]];
      await reload(status('r1'));
      rebuild();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 350));

      TileGridWidget gridTile(String id) => tester.widget<TileGridWidget>(
          find.byKey(ValueKey<String>('daygrid_tile_$id')));
      expect(gridTile('b').flash, ChangeFlash.moved);
      expect(gridTile('a').flash, isNull);
      expect(find.byType(FreeGapFlashWidget), findsOneWidget);
      expect(find.text('+60 min free'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(gridTile('b').flash, isNull);
      expect(find.byType(FreeGapFlashWidget), findsNothing);
    });
  });

  group('EnhancedTileBatch row flash', () {
    testWidgets('a tile that flew in is ringed as it lands', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bloc = ScheduleBloc(getContextCallBack: () => null);
      List<SubCalendarEvent> tiles = [
        for (var i = 0; i < 8; i++) tile('T$i', at(8 + i, 0), 30),
      ];
      Future<void> reload(ScheduleStatus s) async {
        bloc.add(ReloadLocalScheduleEvent(
            subEvents: tiles,
            timelines: const [],
            lookupTimeline: dayTimeline,
            scheduleStatus: s));
        await tester.pump();
      }

      await reload(status('r0'));
      late void Function() rebuild;
      await tester.pumpWidget(app(MultiBlocProvider(
        providers: [
          BlocProvider<ScheduleBloc>.value(value: bloc),
          BlocProvider(
              create: (_) =>
                  ScheduleSummaryBloc(getContextCallBack: () => null)),
        ],
        child: StatefulBuilder(builder: (context, setState) {
          rebuild = () => setState(() {});
          return SizedBox(
            height: 600,
            child: EnhancedTileBatch(
              dayIndex: day.universalDayIndex,
              tiles: tiles,
              showProactiveAlerts: false,
              showTimelineMarkers: false,
              showEnhancedCards: true,
              showConflictAlerts: false,
              showTravelConnectors: false,
              showFreeSlots: false,
            ),
          );
        }),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      tiles = [
        for (final t in tiles)
          t.uniqueId == 'T1' ? tile('T1', at(11, 30), 30) : t
      ];
      await reload(status('r1'));
      rebuild();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      AnimatedContainer frameOf(String rowKey) =>
          tester.widget<AnimatedContainer>(find
              .ancestor(
                  of: find.byKey(ValueKey<String>('list_row_opacity_$rowKey')),
                  matching: find.byType(AnimatedContainer))
              .first);
      expect(frameOf('tile:T1').foregroundDecoration, isNotNull);
      expect(frameOf('tile:T0').foregroundDecoration, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(frameOf('tile:T1').foregroundDecoration, isNull);
    });
  });

  group('empty day honours Schedule updates', () {
    Future<double> firstFrameOpacity(WidgetTester tester,
        {ScheduleMotionCubit? motion}) async {
      final providers = <BlocProvider>[
        BlocProvider<ScheduleBloc>(
            create: (_) => ScheduleBloc(getContextCallBack: () => null)),
        BlocProvider<ScheduleSummaryBloc>(
            create: (_) => ScheduleSummaryBloc(getContextCallBack: () => null)),
        if (motion != null)
          BlocProvider<ScheduleMotionCubit>.value(value: motion),
      ];
      // The empty state sizes itself to the screen: use a tall one.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(app(MultiBlocProvider(
        providers: providers,
        child: SingleChildScrollView(
          child: EnhancedTileBatch(
            dayIndex: day.universalDayIndex,
            tiles: const <SubCalendarEvent>[],
            showProactiveAlerts: false,
          ),
        ),
      )));
      final opacity = tester
          .widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first)
          .opacity;
      await tester.pump(const Duration(seconds: 1));
      return opacity;
    }

    testWidgets('fades in by default', (tester) async {
      SharedPreferences.setMockInitialValues({});
      expect(await firstFrameOpacity(tester), 0);
    });

    testWidgets('shows at once when Off', (tester) async {
      SharedPreferences.setMockInitialValues(
          {ScheduleMotionPreferences.modeKey: 'off'});
      final motion = ScheduleMotionCubit();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(await firstFrameOpacity(tester, motion: motion), 1);
      await motion.close();
    });
  });
}
