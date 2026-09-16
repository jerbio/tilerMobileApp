// P7 Step 17.3 — the content filter applied to the day content (C34):
//   * grid page: `blocks` renders only rigid tiles, `tiles` only flexible
//     ones, `all` everything; the pinned all-day card follows the same rule;
//   * the conflict/RSVP rows keep the UNFILTERED day (chrome stays whole);
//   * list page (non-today): the same rule on EnhancedTileBatch's input;
//   * today's list page: the builder receives the filtered set.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridAlertRows.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/freeSlotRow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/travelBandWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

class _RecordingScheduleBloc extends ScheduleBloc {
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);
  @override
  void add(ScheduleEvent event) {
    if (event is GetScheduleEvent) return;
    super.add(event);
  }
}

final DateTime _day = DateTime(2027, 1, 15);
final int _dayIndex = _day.universalDayIndex;

SubCalendarEvent _tile(String id, int startH, int endH,
    {bool rigid = false, double? travelBefore}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: _day.add(Duration(hours: startH)).millisecondsSinceEpoch,
    end: _day.add(Duration(hours: endH)).millisecondsSinceEpoch,
  );
  tile.isViable = true;
  tile.isRigid = rigid;
  tile.travelTimeBefore = travelBefore;
  return tile;
}

/// 2 blocks (one conflicting with a tile, one all-day) + 3 tiles.
List<TilerEvent> _fixture() => [
      _tile('block1', 9, 10, rigid: true),
      _tile('allday', 0, 24, rigid: true),
      _tile('t1', 9, 11), // conflicts with block1
      _tile('t2', 13, 14, travelBefore: 30 * 60 * 1000), // travel band
      _tile('t3', 16, 17),
    ];

Widget _host({
  required DailyViewLayoutCubit cubit,
  required DayContentFilterCubit filter,
  required Widget child,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: cubit),
      BlocProvider.value(value: filter),
      BlocProvider(create: (_) => UiDateManagerBloc()),
      BlocProvider<ScheduleBloc>(create: (_) => _RecordingScheduleBloc()),
      BlocProvider(
          create: (_) => ScheduleSummaryBloc(getContextCallBack: () => null)),
    ],
    child: MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A cubit change lands via a microtask: one frame to rebuild, then time
  /// for the exit ghosts (220ms) / enter cascade to finish, then a frame.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Set<String> gridIds(WidgetTester tester) => tester
      .widgetList<TileGridWidget>(find.byType(TileGridWidget))
      .map((w) => w.tilerEvent.id!)
      .toSet();

  group('grid page', () {
    Future<DayContentFilterCubit> pumpGrid(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final cubit = DailyViewLayoutCubit()..toggle();
      final filter = DayContentFilterCubit();
      addTearDown(cubit.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_host(
        cubit: cubit,
        filter: filter,
        child: DayGridPage(
          key: Key('day_$_dayIndex'),
          dayIndex: _dayIndex,
          tiles: _fixture(),
        ),
      ));
      await settle(tester);
      return filter;
    }

    testWidgets('all → every timeline tile + the pinned all-day block',
        (tester) async {
      await pumpGrid(tester);
      expect(gridIds(tester), {'block1', 't1', 't2', 't3'});
      expect(find.byKey(const Key('daygrid_pinned_card')), findsOneWidget);
      expect(find.byKey(DayGridAlertRows.conflictRowKey), findsOneWidget);
    });

    testWidgets('blocks → rigid tiles only; pinned block stays',
        (tester) async {
      final filter = await pumpGrid(tester);
      filter.set(DayContentFilter.blocks);
      await settle(tester);
      expect(gridIds(tester), {'block1'});
      expect(find.byKey(const Key('daygrid_pinned_card')), findsOneWidget);
    });

    testWidgets(
        'tiles → flexible tiles only; pinned block hidden; conflict row STILL shown (C34)',
        (tester) async {
      final filter = await pumpGrid(tester);
      filter.set(DayContentFilter.tiles);
      await settle(tester);
      expect(gridIds(tester), {'t1', 't2', 't3'});
      expect(find.byKey(const Key('daygrid_pinned_card')), findsNothing);
      expect(find.byKey(DayGridAlertRows.conflictRowKey), findsOneWidget,
          reason: 'the chrome always reflects the whole day');
    });

    testWidgets('travel bands render under all, none under any filter',
        (tester) async {
      final filter = await pumpGrid(tester);
      expect(find.byType(TravelBandWidget), findsOneWidget);
      filter.set(DayContentFilter.tiles);
      await settle(tester);
      expect(gridIds(tester), contains('t2'),
          reason: 't2 is still shown, but its travel is not');
      expect(find.byType(TravelBandWidget), findsNothing);
      filter.set(DayContentFilter.all);
      await settle(tester);
      expect(find.byType(TravelBandWidget), findsOneWidget);
    });

    testWidgets('switching filters transitions in place (no remount)',
        (tester) async {
      final filter = await pumpGrid(tester);
      final Element before = find.byType(DayGridPage).evaluate().single;
      filter.set(DayContentFilter.tiles);
      await settle(tester);
      filter.set(DayContentFilter.all);
      await settle(tester);
      expect(identical(find.byType(DayGridPage).evaluate().single, before),
          isTrue);
      expect(gridIds(tester), {'block1', 't1', 't2', 't3'});
    });
  });

  group('list page', () {
    testWidgets('non-today page filters EnhancedTileBatch input',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cubit = DailyViewLayoutCubit(); // list
      final filter = DayContentFilterCubit()..set(DayContentFilter.blocks);
      addTearDown(cubit.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_host(
        cubit: cubit,
        filter: filter,
        child: SingleChildScrollView(
          child: DayGridPage(
            key: Key('day_$_dayIndex'),
            dayIndex: _dayIndex,
            tiles: _fixture(),
          ),
        ),
      ));
      await settle(tester);
      final batch =
          tester.widget<EnhancedTileBatch>(find.byType(EnhancedTileBatch));
      expect(batch.tiles!.map((t) => t.id).toSet(), {'block1', 'allday'});
      expect(batch.showTravelConnectors, isFalse,
          reason: 'no travel widgets while filtered');
      expect(batch.showFreeSlots, isFalse,
          reason: 'no free-time gaps while filtered (they would be wrong)');
      expect(find.byType(FreeSlotRow), findsNothing);
    });

    testWidgets('non-today page under ALL keeps free-time gaps', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cubit = DailyViewLayoutCubit(); // list
      final filter = DayContentFilterCubit(); // all
      addTearDown(cubit.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_host(
        cubit: cubit,
        filter: filter,
        child: SingleChildScrollView(
          child: DayGridPage(
            key: Key('day_$_dayIndex'),
            dayIndex: _dayIndex,
            tiles: _fixture(),
          ),
        ),
      ));
      await settle(tester);
      final batch =
          tester.widget<EnhancedTileBatch>(find.byType(EnhancedTileBatch));
      expect(batch.showFreeSlots, isTrue);
      expect(batch.showTravelConnectors, isTrue);
    });

    testWidgets("today's page builder receives the filtered set",
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cubit = DailyViewLayoutCubit();
      final filter = DayContentFilterCubit()..set(DayContentFilter.tiles);
      addTearDown(cubit.close);
      addTearDown(filter.close);
      List<TilerEvent>? received;
      bool? receivedTravel;
      await tester.pumpWidget(_host(
        cubit: cubit,
        filter: filter,
        child: DayGridPage(
          key: Key('day_$_dayIndex'),
          dayIndex: _dayIndex,
          tiles: _fixture(),
          listViewBuilder: (tiles, showConnectors) {
            received = tiles;
            receivedTravel = showConnectors;
            return const SizedBox(key: Key('todayList'));
          },
        ),
      ));
      await settle(tester);
      expect(find.byKey(const Key('todayList')), findsOneWidget);
      expect(received!.map((t) => t.id).toSet(), {'t1', 't2', 't3'});
      expect(receivedTravel, isFalse);
    });
  });
}
