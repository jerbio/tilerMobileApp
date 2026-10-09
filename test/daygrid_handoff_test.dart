// Gutter lines and edge chips in the day grid: while tiles step to new
// times a line in the gutter shows each jump, and tiles that were on screen
// and moved out of view (or to another day) get a chip at the edge instead
// of just vanishing. Tapping the chip takes the user there.
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
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoff.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoffChip.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';

final DateTime day = DateTime(2026, 5, 15);
final DateTime now = DateTime(2026, 5, 16, 9);
final Timeline dayTimeline =
    Timeline.fromDateTime(day, day.add(const Duration(days: 1)));
final Timeline window = Timeline.fromDateTime(
    day.subtract(const Duration(days: 3)), day.add(const Duration(days: 4)));

SubCalendarEvent tile(String id, String name, double startHour,
    {double hours = 1, int dayOffset = 0}) {
  final start =
      day.add(Duration(days: dayOffset, minutes: (startHour * 60).round()));
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

  group('GridHandoff.fromDelta', () {
    // Visible part of the day: 8am to 4pm.
    final visibleFrom =
        day.add(const Duration(hours: 8)).millisecondsSinceEpoch;
    final visibleTo = day.add(const Duration(hours: 16)).millisecondsSinceEpoch;
    int place(int s, int e) => e <= visibleFrom ? -1 : (s >= visibleTo ? 1 : 0);

    List<GridHandoff> handoffs(
            List<SubCalendarEvent> before, List<SubCalendarEvent> after,
            {String? skipId}) =>
        GridHandoff.fromDelta(
            ScheduleDelta.compute(
                before: before, after: after, day: dayTimeline),
            place: place,
            skipId: skipId);

    test('visible tiles that moved below or above the view', () {
      final result = handoffs(
        [tile('a', 'A', 9), tile('b', 'B', 10), tile('c', 'C', 11)],
        [tile('a', 'A', 20), tile('b', 'B', 21), tile('c', 'C', 6)],
      );
      expect(result.map((h) => h.direction),
          [HandoffDirection.earlier, HandoffDirection.later]);
      expect(result[1].tiles.map((t) => t.uniqueId), ['a', 'b']);
      expect(result[1].targetStartMs,
          day.add(const Duration(hours: 20)).millisecondsSinceEpoch);
    });

    test('a tile still in view, or never seen, gets no chip', () {
      expect(handoffs([tile('a', 'A', 9)], [tile('a', 'A', 12)]), isEmpty);
      expect(handoffs([tile('a', 'A', 18)], [tile('a', 'A', 21)]), isEmpty);
    });

    test('tiles moved to other days group by destination day', () {
      final result = handoffs(
        [tile('a', 'A', 9), tile('b', 'B', 10), tile('c', 'C', 11)],
        [
          tile('a', 'A', 9, dayOffset: 1),
          tile('b', 'B', 14, dayOffset: 1),
          tile('c', 'C', 9, dayOffset: -1),
        ],
      );
      expect(result.map((h) => h.direction),
          [HandoffDirection.previousDay, HandoffDirection.nextDay]);
      expect(result[1].tiles.map((t) => t.uniqueId), ['a', 'b']);
    });

    test('the tile the user moved never gets a chip', () {
      expect(handoffs([tile('a', 'A', 9)], [tile('a', 'A', 20)], skipId: 'a'),
          isEmpty);
    });
  });

  group('DayGridWidget rails and edge chips', () {
    late ScheduleBloc bloc;
    List<SubCalendarEvent> gridTiles = [];

    Future<void> reload(WidgetTester tester, List<SubCalendarEvent> all,
        ScheduleStatus s) async {
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: all,
          timelines: const [],
          lookupTimeline: window,
          scheduleStatus: s));
      await tester.pump();
    }

    /// Alpha at 8am and Beta at 10am, in a 600 px tall grid at 80 px/h
    /// (the grid opens scrolled to Alpha, so roughly 8am to 3pm shows).
    Future<void Function()> mount(WidgetTester tester,
        {ScheduleMotionCubit? motion}) async {
      SharedPreferences.setMockInitialValues({});
      bloc = ScheduleBloc(getContextCallBack: () => null);
      gridTiles = [tile('a', 'Alpha', 8), tile('b', 'Beta', 10)];
      await reload(tester, gridTiles, status('r0'));
      late void Function() rebuild;
      Widget body = StatefulBuilder(builder: (context, setState) {
        rebuild = () => setState(() {});
        return SizedBox(
          width: 400,
          height: 600,
          child: DayGridWidget(tiles: gridTiles, day: day, now: now),
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

    /// Serves [all] as revision r1, with [onDay] as this grid's tiles.
    Future<void> serve(WidgetTester tester, void Function() rebuild,
        List<SubCalendarEvent> all, List<SubCalendarEvent> onDay) async {
      gridTiles = onDay;
      await reload(tester, all, status('r1'));
      rebuild();
      await tester.pump();
    }

    final later = find.byKey(GridHandoffChip.keyFor(HandoffDirection.later));
    final nextDay =
        find.byKey(GridHandoffChip.keyFor(HandoffDirection.nextDay));
    final rail = find.byKey(const ValueKey<String>('daygrid_rail_b'));

    bool onScreen(WidgetTester tester, Finder finder) {
      final y = tester.getTopLeft(finder).dy;
      return y >= 0 && y < 600;
    }

    testWidgets('a move within view draws a gutter line, and no chip',
        (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = [tile('a', 'Alpha', 8), tile('b', 'Beta', 12)];
      await serve(tester, rebuild, moved, moved);

      await tester.pump(Duration.zero); // lift
      expect(rail, findsOneWidget);
      expect(find.textContaining('+'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(rail, findsNothing);
      expect(later, findsNothing);
    });

    testWidgets('a tile moved below the view hands off to a chip; tap scrolls',
        (tester) async {
      final rebuild = await mount(tester);
      expect(onScreen(tester, find.text('Beta')), isTrue);

      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = [tile('a', 'Alpha', 8), tile('b', 'Beta', 21)];
      await serve(tester, rebuild, moved, moved);
      // No chip until the tile has moved.
      await tester.pump(Duration.zero);
      expect(later, findsNothing);
      // Frame by frame, as on a device: release, slide, land.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      expect(later, findsOneWidget);
      expect(find.text('Beta moved to 9:00 PM'), findsOneWidget);
      expect(onScreen(tester, find.text('Beta')), isFalse);

      await tester.tap(later);
      await tester.pumpAndSettle();
      expect(later, findsNothing);
      expect(onScreen(tester, find.text('Beta')), isTrue);
    });

    testWidgets('the chip hides on its own', (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = [tile('a', 'Alpha', 8), tile('b', 'Beta', 21)];
      await serve(tester, rebuild, moved, moved);
      await tester.pump(const Duration(milliseconds: 600));
      expect(later, findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(later, findsNothing);
    });

    testWidgets('a tile moved to another day gets a day chip', (tester) async {
      final rebuild = await mount(tester);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      await serve(
        tester,
        rebuild,
        [tile('a', 'Alpha', 8), tile('b', 'Beta', 10, dayOffset: 1)],
        [tile('a', 'Alpha', 8)],
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(nextDay, findsOneWidget);
      expect(find.text('Beta moved to Sat, May 16'), findsOneWidget);
      // No day navigation in this host: the tap only dismisses.
      await tester.tap(nextDay);
      await tester.pump();
      expect(nextDay, findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a background refresh gets no chip', (tester) async {
      final rebuild = await mount(tester);
      final moved = [tile('a', 'Alpha', 8), tile('b', 'Beta', 21)];
      await serve(tester, rebuild, moved, moved);
      await tester.pump(const Duration(seconds: 1));
      expect(later, findsNothing);
    });

    testWidgets('with Schedule updates Off the chip shows at once, no line',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {ScheduleMotionPreferences.modeKey: 'off'});
      final motion = ScheduleMotionCubit();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      final rebuild = await mount(tester, motion: motion);
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      final moved = [tile('a', 'Alpha', 8), tile('b', 'Beta', 21)];
      await serve(tester, rebuild, moved, moved);
      expect(later, findsOneWidget);
      expect(rail, findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await motion.close();
    });
  });
}
