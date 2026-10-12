// Step-by-step schedule changes in the day grid: moved tiles wait at their
// old time, then lift, slide and land in batches of up to 3, leaving an
// outline where they were. Only Detailed mode, and only for a new revision
// caused by a re-optimize (or a change that pushed other tiles).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleMotion/schedule_motion_cubit.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';

final DateTime day = DateTime(2026, 5, 15);
// A clock on another day: no now-line, no minute timer.
final DateTime now = DateTime(2026, 5, 16, 9);
final Timeline dayTimeline =
    Timeline.fromDateTime(day, day.add(const Duration(days: 1)));

SubCalendarEvent tile(String id, String name, double startHour,
    {double hours = 1}) {
  final start = day.add(Duration(minutes: (startHour * 60).round()));
  return SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: start
        .add(Duration(minutes: (hours * 60).round()))
        .millisecondsSinceEpoch,
  );
}

ScheduleStatus status(String id) =>
    ScheduleStatus.fromJson({'analysisId': id, 'evaluationId': id});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GridChoreography.plan', () {
    List<SubCalendarEvent> row(int count, {double shift = 0}) => [
          for (var i = 0; i < count; i++)
            tile('t$i', 'T$i', 6.0 + i * 1.5 + shift, hours: 0.5)
        ];

    ScheduleDelta delta(List<SubCalendarEvent> a, List<SubCalendarEvent> b) =>
        ScheduleDelta.compute(before: a, after: b, day: dayTimeline);

    test('one moved tile is one batch', () {
      final steps = GridChoreography.plan(delta(row(3), [
        ...row(3).take(2),
        tile('t2', 'T2', 15, hours: 0.5),
      ]))!;
      expect(steps.batches.single.ids, ['t2']);
      expect(steps.batches.single.liftAt, Duration.zero);
      expect(steps.batches.single.moveAt, GridChoreography.lift);
      expect(steps.batches.single.landAt,
          GridChoreography.lift + GridChoreography.move);
    });

    test('seven moved tiles play as 3 + 3 + 1, each lifting as the last lands',
        () {
      final steps = GridChoreography.plan(delta(row(7), row(7, shift: 0.25)))!;
      expect(steps.batches.map((b) => b.ids.length), [3, 3, 1]);
      expect(steps.batches[1].liftAt, steps.batches[0].landAt);
      expect(steps.batches[2].liftAt, steps.batches[1].landAt);
      expect(steps.end, steps.batches[2].landAt + GridChoreography.ghostLinger);
      expect(steps.end, lessThan(const Duration(seconds: 2)));
    });

    test('the tile the user moved settles at once', () {
      final steps = GridChoreography.plan(delta(row(3), row(3, shift: 0.25)),
          subjectId: 't0')!;
      expect(steps.ids, {'t1', 't2'});
    });

    test('only the subject moved: nothing to step through', () {
      final after = [tile('t0', 'T0', 12, hours: 0.5), ...row(3).skip(1)];
      expect(
          GridChoreography.plan(delta(row(3), after), subjectId: 't0'), isNull);
    });

    test('too many moves, or an emptied day, use the plain transition', () {
      expect(
          GridChoreography.plan(delta(row(10), row(10, shift: 0.25))), isNull);
      // Every tile moved to tomorrow.
      expect(GridChoreography.plan(delta(row(3), row(3, shift: 24))), isNull);
    });
  });

  group('DayGridWidget step-by-step changes', () {
    late ScheduleBloc bloc;
    List<SubCalendarEvent> tiles = [];

    /// Alpha fixed at 8am; Beta at [betaHour]. At 80 px/h Beta sits
    /// (betaHour - 8) * 80 px below Alpha.
    List<SubCalendarEvent> withBetaAt(double betaHour) =>
        [tile('a', 'Alpha', 8), tile('b', 'Beta', betaHour)];

    double dyBetween(WidgetTester tester) =>
        tester.getTopLeft(find.text('Beta')).dy -
        tester.getTopLeft(find.text('Alpha')).dy;

    final ghost = find.byKey(const ValueKey<String>('daygrid_tile_from_b'));

    Future<void> reload(WidgetTester tester, List<SubCalendarEvent> next,
        ScheduleStatus s) async {
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: next,
          timelines: const [],
          lookupTimeline: dayTimeline,
          scheduleStatus: s));
      await tester.pump();
    }

    /// Mounts the grid on [bloc] (and [motion], when given). Returns a
    /// rebuild callback that re-serves the current [tiles].
    Future<void Function()> mount(WidgetTester tester,
        {ScheduleMotionCubit? motion}) async {
      SharedPreferences.setMockInitialValues({});
      // Created inside the test so its events run in the fake-async zone.
      bloc = ScheduleBloc(getContextCallBack: () => null);
      tiles = withBetaAt(10);
      await reload(tester, tiles, status('r0'));
      late void Function() rebuild;
      Widget body = StatefulBuilder(builder: (context, setState) {
        rebuild = () => setState(() {});
        return SizedBox(
          width: 400,
          height: 600,
          child: DayGridWidget(tiles: tiles, day: day, now: now),
        );
      });
      body = BlocProvider<ScheduleBloc>.value(value: bloc, child: body);
      if (motion != null) {
        body =
            BlocProvider<ScheduleMotionCubit>.value(value: motion, child: body);
      }
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      ));
      await tester.pump();
      await tester.pump();
      return rebuild;
    }

    /// Serves Beta at 2pm as revision r1, as the bloc would after a change.
    Future<void> serveMove(WidgetTester tester, void Function() rebuild) async {
      tiles = withBetaAt(14);
      await reload(tester, tiles, status('r1'));
      rebuild();
      await tester.pump();
    }

    testWidgets('a re-optimize holds, lifts, slides and lands the tile',
        (tester) async {
      final rebuild = await mount(tester);
      expect(dyBetween(tester), closeTo(160, 1));

      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      await serveMove(tester, rebuild);

      // Held at the old time on the first frame.
      expect(dyBetween(tester), closeTo(160, 1));

      // Lift: the outline appears at the old spot with where it's going.
      await tester.pump(Duration.zero);
      expect(ghost, findsOneWidget);
      expect(find.text('Moved to 2:00 PM'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(dyBetween(tester), closeTo(160, 1));

      // Released after the lift: it slides and lands.
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 400));
      expect(dyBetween(tester), closeTo(480, 1));

      // The outline fades and is gone once the sequence ends.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(ghost, findsNothing);
    });

    testWidgets('a background refresh slides straight away, no outline',
        (tester) async {
      final rebuild = await mount(tester);
      await serveMove(tester, rebuild);
      await tester.pump(Duration.zero);
      expect(ghost, findsNothing);
      await tester.pumpAndSettle();
      expect(dyBetween(tester), closeTo(480, 1));
    });

    testWidgets('Minimal mode skips the steps', (tester) async {
      SharedPreferences.setMockInitialValues(
          {ScheduleMotionPreferences.modeKey: 'minimal'});
      final motion = ScheduleMotionCubit();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(motion.state, ScheduleUpdateMode.minimal);

      final rebuild = await mount(tester, motion: motion);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      await serveMove(tester, rebuild);
      await tester.pump(Duration.zero);
      expect(ghost, findsNothing);
      await tester.pumpAndSettle();
      expect(dyBetween(tester), closeTo(480, 1));
      await motion.close();
    });

    testWidgets('the same revision served again does not replay',
        (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      await serveMove(tester, rebuild);
      await tester.pumpAndSettle();
      expect(ghost, findsNothing);

      // A new list instance for the same revision (e.g. a rebuild).
      tiles = withBetaAt(14);
      rebuild();
      await tester.pump();
      await tester.pump(Duration.zero);
      expect(ghost, findsNothing);
      expect(dyBetween(tester), closeTo(480, 1));
    });
  });
}
