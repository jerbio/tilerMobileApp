// The Daily page body (both layouts) is ONE in-flow `Column`:
//   1. the fixed [DayGridTopChromeRow] (toggle · day pill · summary · actions),
//   2. the compact, swipeable day strip — always visible, never an overlay,
//      a single instance shared by list and grid,
//   3. the quick actions (show route · re-optimize + loading bar),
//   4. the day carousel filling the remaining (Expanded) space.
// So the chrome is identical in list and grid mode, nothing above the content
// changes height, and the content can never be covered by the selector.
// Weekly / Monthly keep the legacy `Stack` overlay ([HomeTopRightActions]),
// which the regression group below proves is structurally untouched.
//
// The real [DailyTileList] carries schedule-loading network side effects that
// are out of scope for a pure layout test, so the day region is injected
// through [GridDailyPageBody.gridBodyBuilder] as a lightweight stand-in; the
// bar and the strip are the real production widgets.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridPageBody.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/dayQuickActionsRow.dart';
import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayButton.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

const _dayRegionKey = Key('dayRegion');
const _stripKey = Key('dailyDayStrip');

Widget _buildHarness({
  required DailyViewLayoutCubit cubit,
  required UiDateManagerBloc dateBloc,
  required DateTime currentDate,
  Widget Function(double maxHeight)? gridBodyBuilder,
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
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: dateBloc),
        BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
        BlocProvider(create: (_) => DayContentFilterCubit()),
      ],
      child: Scaffold(
        body: GridDailyPageBody(
          currentDate: currentDate,
          onSearch: () {},
          onSettings: () {},
          onGoToToday: () {},
          gridBodyBuilder: gridBodyBuilder ??
              (double maxHeight) => SizedBox(
                    key: _dayRegionKey,
                    width: double.infinity,
                    height: maxHeight,
                  ),
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

  Future<void> pumpShort(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(390, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(app);
    await tester.pump();
  }

  Future<(DailyViewLayoutCubit, UiDateManagerBloc)> blocs(WidgetTester tester,
      {required bool today}) async {
    final cubit = DailyViewLayoutCubit();
    final dateBloc = UiDateManagerBloc();
    addTearDown(cubit.close);
    addTearDown(dateBloc.close);
    if (!today) {
      final DateTime now = Utility.currentTime().dayDate;
      dateBloc.add(DateChangeEvent(
        previousSelectedDate: now,
        selectedDate: now.add(const Duration(days: 1)),
      ));
    }
    return (cubit, dateBloc);
  }

  group('GridDailyPageBody — ONE composition for list and grid', () {
    for (final layout in DailyViewLayout.values) {
      testWidgets(
          '[$layout] bar, then the day strip, then the content — in-flow, no overlap',
          (tester) async {
        SharedPreferences.setMockInitialValues({'dayGridLayout': layout.name});
        final (cubit, dateBloc) = await blocs(tester, today: true);
        final DateTime today = Utility.currentTime().dayDate;
        await pumpShort(tester,
            _buildHarness(cubit: cubit, dateBloc: dateBloc, currentDate: today));
        await tester.pump();

        final Rect bar = tester.getRect(find.byType(DayGridTopChromeRow));
        final Rect strip = tester.getRect(find.byKey(_stripKey));
        final Rect content = tester.getRect(find.byKey(_dayRegionKey));

        final Rect actions = tester.getRect(find.byType(DayQuickActionsRow));

        expect(bar.height, DayGridTopChromeRow.height);
        expect(strip.top, greaterThanOrEqualTo(bar.bottom));
        expect(strip.height, GridDailyPageBody.dayStripHeight);
        // Show route / Re-optimize sit under the strip in BOTH layouts.
        expect(actions.top, greaterThanOrEqualTo(strip.bottom));
        expect(find.byKey(DayQuickActionsRow.showRouteKey), findsOneWidget);
        expect(find.byKey(DayQuickActionsRow.reOptimizeKey), findsOneWidget);
        expect(content.top, greaterThanOrEqualTo(actions.bottom),
            reason: 'the chrome is in-flow, never an overlay');
        // The strip is the compact carousel, always visible (no tab).
        final ribbon =
            tester.widget<DayRibbonCarousel>(find.byType(DayRibbonCarousel));
        expect(ribbon.compact, isTrue);
        expect(ribbon.topMargin, 0);
        expect(find.byType(DayButton), findsAtLeastNWidgets(5));
        expect(find.byType(HomeTopRightActions), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the bar is identical across today / non-today (same order)',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: false);
      final DateTime tomorrow =
          Utility.currentTime().dayDate.add(const Duration(days: 1));
      await pumpShort(
          tester,
          _buildHarness(
              cubit: cubit, dateBloc: dateBloc, currentDate: tomorrow));

      final double toggleX =
          tester.getCenter(find.byKey(DayGridTopChromeRow.layoutToggleKey)).dx;
      final double pillX =
          tester.getCenter(find.byKey(DayGridTopChromeRow.dayLabelKey)).dx;
      final double summaryX = tester
          .getCenter(find.byKey(DayGridTopChromeRow.summaryButtonKey))
          .dx;
      final double todayX =
          tester.getCenter(find.byIcon(Icons.calendar_today)).dx;
      final double searchX = tester.getCenter(find.byIcon(Icons.search)).dx;
      final double settingsX =
          tester.getCenter(find.byIcon(Icons.settings)).dx;
      expect(toggleX, lessThan(pillX));
      expect(pillX, lessThan(summaryX));
      expect(summaryX, lessThan(todayX));
      expect(todayX, lessThan(searchX));
      expect(searchX, lessThan(settingsX));
      expect(tester.getSize(find.byType(DayGridTopChromeRow)).height,
          DayGridTopChromeRow.height);
      // The pill is plain: no reveal-driven opacity anywhere above it.
      expect(
          find.ancestor(
              of: find.byKey(DayGridTopChromeRow.dayLabelKey),
              matching: find.byType(Opacity)),
          findsNothing);
    });

    testWidgets('tapping a day in the strip dispatches DateChangeEvent',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: true);
      final DateTime today = Utility.currentTime().dayDate;
      final DateTime tomorrow = today.add(const Duration(days: 1));
      await pumpShort(tester,
          _buildHarness(cubit: cubit, dateBloc: dateBloc, currentDate: today));

      await tester.tap(find.text('${tomorrow.day}').first);
      await tester.pump();
      final state = dateBloc.state;
      expect(state, isA<UiDateManagerUpdated>());
      expect((state as UiDateManagerUpdated).currentDate.universalDayIndex,
          tomorrow.universalDayIndex);
    });

    testWidgets(
        'every day page grid uses the ONE shared DayGridController from the scope',
        (tester) async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
      final (cubit, dateBloc) = await blocs(tester, today: true);
      final DateTime today = Utility.currentTime().dayDate;
      final int todayIndex = today.universalDayIndex;

      await tester.pumpWidget(_buildHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: today,
        // Two real day pages side by side, as the carousel would host.
        gridBodyBuilder: (double maxHeight) => SizedBox(
          height: maxHeight,
          child: Row(children: [
            Expanded(child: DayGridPage(dayIndex: todayIndex, tiles: const [])),
            Expanded(
                child: DayGridPage(dayIndex: todayIndex + 1, tiles: const [])),
          ]),
        ),
      ));
      await tester.pump(); // cubit restore -> grid branch
      await tester.pump();

      final scope = tester.widget<DayGridScope>(find.byType(DayGridScope));
      final grids =
          tester.widgetList<DayGridWidget>(find.byType(DayGridWidget)).toList();
      expect(grids, hasLength(2));
      for (final grid in grids) {
        expect(identical(grid.controller, scope.controller), isTrue,
            reason: 'a page must not own (and async-restore) its own zoom');
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Non-Daily regression (legacy Stack overlay untouched)', () {
    testWidgets(
        'Weekly/Monthly keep HomeTopRightActions as a Stack overlay, '
        'not the Daily bar', (tester) async {
      final cubit = DailyViewLayoutCubit();
      final dateBloc = UiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(dateBloc.close);

      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: dateBloc),
          ],
          child: Scaffold(
            body: Stack(children: [
              const SizedBox.expand(),
              HomeTopRightActions(
                isViewingToday: true,
                onSearch: () {},
                onSettings: () {},
                onGoToToday: () {},
              ),
            ]),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(HomeTopRightActions), findsOneWidget);
      expect(
        find.ancestor(
            of: find.byType(HomeTopRightActions),
            matching: find.byType(Stack)),
        findsWidgets,
      );
      expect(find.byType(DayGridTopChromeRow), findsNothing);
      expect(find.byType(GridDailyPageBody), findsNothing);
      // No Daily-only toggle in the legacy overlay.
      expect(find.byIcon(Icons.grid_view), findsNothing);
      expect(find.byIcon(Icons.view_list), findsNothing);
    });
  });
}
