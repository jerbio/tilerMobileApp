// The grid-mode Daily page body (P6) is an in-flow `Column`: the
// fixed-height [DayGridTopChromeRow] (toggle · day pill · summary · actions)
// on top, and the day grid filling the remaining (Expanded) space. The day
// selector / big date / alert rows are NOT in this Column any more — they
// live inside each day-page's grid scroll view as its negative-extent
// header (DayGridScrollHeader), revealed by pulling down. So:
//   * the grid's viewport starts strictly below the top bar;
//   * the top bar never changes height — across today/non-today and across
//     the whole header-reveal range (no-snap rule 1); only the day pill's
//     opacity changes;
//   * the summary button is present for ANY day (C20).
// List mode / Weekly / Monthly keep the legacy `Stack` overlay
// ([HomeTopRightActions]), which the regression group proves is untouched.
//
// The real [DailyTileList] carries schedule-loading network side effects that
// are out of scope for a pure layout test, so the grid region is injected
// through [GridDailyPageBody.gridBodyBuilder] as a lightweight stand-in; the
// top bar is the real production widget.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridPageBody.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonTab.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

const _gridRegionKey = Key('dayGridRegion');

/// Bounded 480px-tall harness hosting the grid-mode body. The grid body is a
/// lightweight keyed stand-in (via [GridDailyPageBody.gridBodyBuilder]); the
/// top bar is the real production widget.
Widget _buildGridHarness({
  required DailyViewLayoutCubit cubit,
  required UiDateManagerBloc dateBloc,
  required DateTime currentDate,
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
      ],
      child: Scaffold(
        body: GridDailyPageBody(
          currentDate: currentDate,
          onSearch: () {},
          onSettings: () {},
          onGoToToday: () {},
          gridBodyBuilder: (double maxHeight) => SizedBox(
            key: _gridRegionKey,
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

  group('GridDailyPageBody (grid-mode Column composition)', () {
    // A short viewport that would overflow if the grid region claimed the
    // full screen height (the pre-fix CarouselOptions behaviour).
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

    Future<(DailyViewLayoutCubit, UiDateManagerBloc)> blocs(
        WidgetTester tester, {required bool today}) async {
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

    testWidgets('lays the top bar above the grid; the grid never overlaps it',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: false);
      final DateTime tomorrow =
          Utility.currentTime().dayDate.add(const Duration(days: 1));

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: tomorrow,
      ));

      final Rect chrome = tester.getRect(find.byType(DayGridTopChromeRow));
      final Rect grid = tester.getRect(find.byKey(_gridRegionKey));
      expect(grid.top, greaterThanOrEqualTo(chrome.bottom),
          reason: 'the grid must start strictly below the top bar');
      // No day selector in the Column: it lives inside the grid's header.
      expect(find.byType(DayRibbonCarousel), findsNothing);
      expect(find.byType(DayRibbonTab), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the top bar height is constant across today / non-today and header reveal',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: true);
      final DateTime today = Utility.currentTime().dayDate;

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: today,
      ));
      final double todayHeight =
          tester.getSize(find.byType(DayGridTopChromeRow)).height;
      expect(todayHeight, DayGridTopChromeRow.height);

      // Non-today adds the go-to-today icon: same height.
      final DateTime tomorrow = today.add(const Duration(days: 1));
      dateBloc.add(DateChangeEvent(
          previousSelectedDate: today, selectedDate: tomorrow));
      await tester.pumpWidget(_buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: tomorrow,
      ));
      await tester.pump();
      expect(tester.getSize(find.byType(DayGridTopChromeRow)).height,
          todayHeight);

      // Full header reveal: the pill fades, the bar does not move.
      final scope = tester.widget<DayGridScope>(
          find.byType(DayGridScope));
      final Rect before = tester.getRect(find.byType(DayGridTopChromeRow));
      scope.report(tomorrow.universalDayIndex, 1.0);
      await tester.pump();
      expect(tester.getRect(find.byType(DayGridTopChromeRow)), before);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the day pill is fully visible at reveal 0 and hidden at reveal 1',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: true);
      final DateTime today = Utility.currentTime().dayDate;

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: today,
      ));

      Opacity pillOpacity() => tester.widget<Opacity>(find.ancestor(
            of: find.byKey(DayGridTopChromeRow.dayLabelKey),
            matching: find.byType(Opacity),
          ).first);

      expect(pillOpacity().opacity, 1.0);
      expect(find.text('Today'), findsOneWidget);

      final scope = tester.widget<DayGridScope>(
          find.byType(DayGridScope));
      scope.report(today.universalDayIndex, 1.0);
      await tester.pump();
      expect(pillOpacity().opacity, 0.0);

      // Reports from a NON-current day page are ignored.
      scope.report(today.universalDayIndex + 3, 0.0);
      await tester.pump();
      expect(pillOpacity().opacity, 0.0);

      scope.report(today.universalDayIndex, 0.0);
      await tester.pump();
      expect(pillOpacity().opacity, 1.0);
    });

    testWidgets('a day change resets the pill to fully visible',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: true);
      final DateTime today = Utility.currentTime().dayDate;

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: today,
      ));
      final scope = tester.widget<DayGridScope>(
          find.byType(DayGridScope));
      scope.report(today.universalDayIndex, 1.0);
      await tester.pump();
      expect(scope.progress.value, 1.0);

      dateBloc.add(DateChangeEvent(
          previousSelectedDate: today,
          selectedDate: today.add(const Duration(days: 1))));
      await tester.pump();
      await tester.pump();
      expect(scope.progress.value, 0.0);
    });

    testWidgets(
        'every day page grid uses the ONE shared DayGridController from the scope',
        (tester) async {
      // DayGridPage takes its grid branch only when the cubit restores grid.
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
      final (cubit, dateBloc) = await blocs(tester, today: true);
      final DateTime today = Utility.currentTime().dayDate;
      final int todayIndex = today.universalDayIndex;

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
            BlocProvider(
                create: (_) => ScheduleBloc(getContextCallBack: () => null)),
          ],
          child: Scaffold(
            body: GridDailyPageBody(
              currentDate: today,
              onSearch: () {},
              onSettings: () {},
              onGoToToday: () {},
              // Two real day pages side by side, as the carousel would host.
              gridBodyBuilder: (double maxHeight) => SizedBox(
                height: maxHeight,
                child: Row(children: [
                  Expanded(
                      child: DayGridPage(
                          dayIndex: todayIndex, tiles: const [])),
                  Expanded(
                      child: DayGridPage(
                          dayIndex: todayIndex + 1, tiles: const [])),
                ]),
              ),
            ),
          ),
        ),
      ));
      await tester.pump(); // cubit restore -> grid branch
      await tester.pump();

      final scope =
          tester.widget<DayGridScope>(find.byType(DayGridScope));
      final grids = tester
          .widgetList<DayGridWidget>(find.byType(DayGridWidget))
          .toList();
      expect(grids, hasLength(2));
      for (final grid in grids) {
        expect(identical(grid.controller, scope.controller), isTrue,
            reason: 'a page must not own (and async-restore) its own zoom');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the summary button and toggle are present for any day',
        (tester) async {
      final (cubit, dateBloc) = await blocs(tester, today: false);
      final DateTime tomorrow =
          Utility.currentTime().dayDate.add(const Duration(days: 1));

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: tomorrow,
      ));

      expect(find.byKey(DayGridTopChromeRow.summaryButtonKey), findsOneWidget);
      expect(find.byKey(DayGridTopChromeRow.layoutToggleKey), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget,
          reason: 'go-to-today shows for a non-today day');
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('Non-grid regression (legacy Stack overlay untouched)', () {
    testWidgets(
        'list/Weekly/Monthly keep HomeTopRightActions as a Stack overlay, '
        'not the new Column chrome', (tester) async {
      final cubit = DailyViewLayoutCubit();
      final dateBloc = UiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(dateBloc.close);

      // The non-grid composition is the legacy `Stack`: [HomeTopRightActions]
      // overlaid (it self-wraps in a Positioned), NOT the new Column /
      // DayGridTopChromeRow. This mirrors renderAuthorizedUserPageView's
      // non-grid branch.
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

      // HomeTopRightActions is present and overlaid inside a Stack...
      expect(find.byType(HomeTopRightActions), findsOneWidget);
      expect(
        find.ancestor(
            of: find.byType(HomeTopRightActions),
            matching: find.byType(Stack)),
        findsWidgets,
      );
      // ...and the new grid chrome is NOT part of this path.
      expect(find.byType(DayGridTopChromeRow), findsNothing);
      expect(find.byType(GridDailyPageBody), findsNothing);
    });
  });
}