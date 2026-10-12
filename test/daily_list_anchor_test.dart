// The daily list keeps the tile the user is looking at in place when a
// schedule change adds or removes rows above it; rows are keyed by what
// they show so they keep their identity; travel times and free gaps count
// to their new value.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/scheduleChangeScope.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/countingDuration.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/listAnchor.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileConnectorLayout.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

// A past day: no free-slot rows and no "now" auto-scroll.
final DateTime day = DateTime(2026, 5, 15);
final Timeline dayTimeline =
    Timeline.fromDateTime(day, day.add(const Duration(days: 1)));
final int dayIndex = day.universalDayIndex;

SubCalendarEvent tile(String id, double startHour,
    {double minutes = 30, int travelMinutes = 0}) {
  final start = day.add(Duration(minutes: (startHour * 60).round()));
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: start.add(Duration(minutes: minutes.round())).millisecondsSinceEpoch,
  );
  t.travelTimeBefore = travelMinutes * 60000.0;
  return t;
}

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

TileConnectorLayoutResult layout(List<TilerEvent> tiles) =>
    buildTileListWithConnectors(
      orderedTiles: tiles,
      showTravelConnectors: true,
      showConflictAlerts: true,
      excludeDeclinedFromConflicts: false,
      now: DateTime(2026, 10, 8),
      buildTile: (t,
              {required hour,
              required showHourMarker,
              required isCurrentHour}) =>
          Text(t.name ?? ''),
      buildConflictGroup: (g,
              {required hour,
              required showHourMarker,
              required isCurrentHour}) =>
          const Text('conflict'),
      wrapConnector: (c) => c,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('row keys', () {
    test('rows are keyed by what they show, not by position', () {
      final result = layout([
        tile('a', 8),
        tile('b', 10, travelMinutes: 15),
        tile('c', 12),
      ]);
      // The end-of-day return marker closes the day.
      expect(
          result.rowKeys, ['tile:a', 'travel:b', 'tile:b', 'tile:c', 'return']);
      expect(result.rowOfTile, {'a': 0, 'b': 2, 'c': 3});
      for (var i = 0; i < result.widgets.length; i++) {
        expect((result.keyedRows[i] as KeyedSubtree).key,
            ValueKey<String>(result.rowKeys[i]));
        expect(result.indexOfKey(ValueKey<String>(result.rowKeys[i])), i);
      }
      expect(result.indexOfKey(const ValueKey<String>('tile:zzz')), isNull);
    });

    test('a row keeps its key when rows are added before it', () {
      final before = layout([tile('b', 10), tile('c', 12)]);
      final after = layout([tile('x', 6), tile('y', 7), tile('b', 10)]);
      expect(before.rowKeys.first, 'tile:b');
      expect(after.rowKeys[after.rowOfTile['b']!], 'tile:b');
    });

    test('tiles in a conflict group map to the group row', () {
      final result = layout([tile('a', 8, minutes: 60), tile('b', 8.5)]);
      expect(result.rowKeys, ['conflict:a', 'return']);
      expect(result.rowOfTile, {'a': 0, 'b': 0});
    });
  });

  group('ListAnchorKeeper', () {
    // The schedule as the bloc would report it, one state per call.
    ScheduleChange? feed(ScheduleChangeFeed changes,
            List<SubCalendarEvent> tiles, ScheduleStatus s) =>
        changes.observe(
            ScheduleLoadedState(
                subEvents: tiles,
                timelines: const [],
                lookupTimeline: dayTimeline,
                previousLookupTimeline: dayTimeline,
                currentView: AuthorizedRouteTileListPage.Daily,
                scheduleStatus: s),
            attribute: (_) =>
                const ScheduleChangeAttribution(ScheduleChangeOrigin.userEdit));

    test('rows added above the anchor move it; it keeps its alignment', () {
      final changes = ScheduleChangeFeed();
      final keeper = ListAnchorKeeper();
      final before = [tile('a', 8), tile('b', 9), tile('c', 10)];

      keeper.capture(
          change: feed(changes, before, status('r0')),
          tiles: before,
          day: dayTimeline,
          visibleRows: [1, 2],
          alignmentOf: (_) => 0.0);
      expect(keeper.resolve(layout(before).rowOfTile), isNull);

      final after = [tile('x', 6), tile('y', 7), ...before];
      keeper.capture(
          change: feed(changes, after, status('r1')),
          tiles: after,
          day: dayTimeline,
          visibleRows: [1, 2],
          alignmentOf: (row) => row == 1 ? 0.25 : 0.6);
      final restore = keeper.resolve(layout(after).rowOfTile)!;
      // Nothing visible changed: the first unchanged tile in view.
      expect(restore.tileId, 'b');
      expect(restore.previousRow, 1);
      expect(restore.row, 3);
      expect(restore.moved, isTrue);
      expect(restore.alignment, 0.25);
    });

    test('the same revision again never moves the list', () {
      final changes = ScheduleChangeFeed();
      final keeper = ListAnchorKeeper();
      final tiles = [tile('a', 8), tile('b', 9)];
      keeper.capture(
          change: feed(changes, tiles, status('r0')),
          tiles: tiles,
          day: dayTimeline,
          visibleRows: [0],
          alignmentOf: (_) => 0.0);
      keeper.resolve(layout(tiles).rowOfTile);

      final more = [tile('x', 6), ...tiles];
      final again = feed(changes, more, status('r0'));
      expect(again, isNull);
      keeper.capture(
          change: again,
          tiles: more,
          day: dayTimeline,
          visibleRows: [0],
          alignmentOf: (_) => 0.0);
      expect(keeper.resolve(layout(more).rowOfTile), isNull);
    });

    test('without a change nothing is captured', () {
      final keeper = ListAnchorKeeper()..resolve({'a': 0});
      keeper.capture(
          change: null,
          tiles: [tile('x', 6), tile('a', 8)],
          day: dayTimeline,
          visibleRows: [0],
          alignmentOf: (_) => 0.0);
      expect(keeper.resolve({'x': 0, 'a': 1}), isNull);
    });
  });

  group('EnhancedTileBatch', () {
    testWidgets('tiles added above the view do not move what is on screen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bloc = ScheduleBloc(getContextCallBack: () => null);
      List<SubCalendarEvent> tiles = [
        for (var i = 0; i < 12; i++) tile('T$i', 8.0 + i),
      ];
      Future<void> reload(List<SubCalendarEvent> all, ScheduleStatus s) async {
        bloc.add(ReloadLocalScheduleEvent(
            subEvents: all,
            timelines: const [],
            lookupTimeline: dayTimeline,
            scheduleStatus: s));
        await tester.pump();
      }

      await reload(tiles, status('r0'));
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
          return ScheduleChangeScope(
              change: bloc.changeFeed.latest,
              child: SizedBox(
                height: 500,
                child: EnhancedTileBatch(
                  dayIndex: dayIndex,
                  tiles: tiles,
                  showProactiveAlerts: false,
                  showTimelineMarkers: false,
                  showEnhancedCards: true,
                  showConflictAlerts: false,
                  showTravelConnectors: false,
                  showFreeSlots: false,
                ),
              ));
        }),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll a few rows down so the view starts mid-day.
      await tester.drag(find.text('T0'), const Offset(0, -260));
      await tester.pump(const Duration(milliseconds: 300));
      final anchor = find.text('T4');
      expect(anchor, findsOneWidget);
      final yBefore = tester.getTopLeft(anchor).dy;

      // A new revision adds two tiles before everything.
      tiles = [tile('early1', 6), tile('early2', 7), ...tiles];
      await reload(tiles, status('r1'));
      rebuild();
      await tester.pump();

      expect(tester.getTopLeft(anchor).dy, closeTo(yBefore, 2));
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('CountingDuration', () {
    testWidgets('counts to the new value', (tester) async {
      Duration value = const Duration(minutes: 7);
      late void Function() rebuild;
      await tester.pumpWidget(app(StatefulBuilder(builder: (context, set) {
        rebuild = () => set(() {});
        return CountingDuration(
            value: value, format: (_, d) => '${d.inMinutes} min');
      })));
      expect(find.text('7 min'), findsOneWidget);

      value = const Duration(minutes: 22);
      rebuild();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('7 min'), findsNothing);
      expect(find.text('22 min'), findsNothing); // still counting
      await tester.pumpAndSettle();
      expect(find.text('22 min'), findsOneWidget);
    });
  });
}
