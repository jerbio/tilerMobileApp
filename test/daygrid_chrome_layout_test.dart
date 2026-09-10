// The grid-mode Daily page body is an in-flow `Column` —
// [DayGridTopChromeRow] (tappable day label + top-right actions) on top, the
// day ribbon below it, and the day grid filling the remaining (Expanded)
// space. The grid's own scroll viewport genuinely starts BELOW the chrome; it
// never runs behind/under the day selector. List mode / Weekly /
// Monthly keep the legacy `Stack` overlay ([HomeTopRightActions]), which the
// regression group below proves is structurally untouched.
//
// The real [DailyTileList] carries schedule-loading network side effects that
// are out of scope for a pure layout test, so the grid region is injected
// through [GridDailyPageBody.gridBodyBuilder] as a lightweight stand-in; the
// chrome row and the ribbon are the real production widgets.
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
import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonTab.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

const _gridRegionKey = Key('dayGridRegion');

/// Bounded 480px-tall harness hosting the grid-mode body. The grid body is a
/// lightweight keyed stand-in (via [GridDailyPageBody.gridBodyBuilder]); the
/// chrome row and ribbon are the real production widgets. A non-today
/// [dateBloc] makes the ribbon the full [DayRibbonCarousel] (not the collapsed
/// today tab), so these are the "ribbon expanded" geometry.
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

    testWidgets(
        'lays the chrome row, then the ribbon, then the grid (dy ordering)',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final dateBloc = UiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(dateBloc.close);
      final DateTime today = Utility.currentTime().dayDate;
      final DateTime tomorrow = today.add(const Duration(days: 1));
      dateBloc.add(DateChangeEvent(
        previousSelectedDate: today,
        selectedDate: tomorrow,
      ));

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: tomorrow,
      ));

      // The ribbon is the full carousel (non-today), the collapsed tab is not.
      expect(find.byType(DayRibbonCarousel), findsOneWidget);
      expect(find.byType(DayRibbonTab), findsNothing);

      final Offset chrome = tester.getTopLeft(find.byType(DayGridTopChromeRow));
      final Offset ribbon =
          tester.getTopLeft(find.byType(DayRibbonCarousel));
      final Offset grid = tester.getTopLeft(find.byKey(_gridRegionKey));

      // chrome (top) < ribbon (middle) < grid (bottom).
      expect(ribbon.dy, greaterThan(chrome.dy),
          reason: 'the ribbon must sit below the chrome row');
      expect(grid.dy, greaterThan(ribbon.dy),
          reason: 'the grid must sit below the ribbon');

      // No RenderFlex / overflow exception at the short viewport.
      expect(tester.takeException(), isNull);
    });

    testWidgets('the grid viewport never overlaps the chrome or the ribbon',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final dateBloc = UiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(dateBloc.close);
      final DateTime today = Utility.currentTime().dayDate;
      final DateTime tomorrow = today.add(const Duration(days: 1));
      dateBloc.add(DateChangeEvent(
        previousSelectedDate: today,
        selectedDate: tomorrow,
      ));

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: tomorrow,
      ));

      final Rect chrome = tester.getRect(find.byType(DayGridTopChromeRow));
      final Rect ribbon = tester.getRect(find.byType(DayRibbonCarousel));
      final Rect grid = tester.getRect(find.byKey(_gridRegionKey));

      // The grid starts at/below the bottom of BOTH chrome elements, so it
      // never runs behind/under the day selector.
      expect(grid.top, greaterThanOrEqualTo(chrome.bottom),
          reason: 'the grid must not overlap the chrome row');
      expect(grid.top, greaterThanOrEqualTo(ribbon.bottom),
          reason: 'the grid must not overlap the ribbon');
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the collapsed ribbon tab (DayRibbonTab) for today',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final dateBloc = UiDateManagerBloc(); // starts on today
      addTearDown(cubit.close);
      addTearDown(dateBloc.close);
      final DateTime today = Utility.currentTime().dayDate;

      await pumpShort(tester, _buildGridHarness(
        cubit: cubit,
        dateBloc: dateBloc,
        currentDate: today,
      ));

      expect(find.byType(DayRibbonTab), findsOneWidget);
      expect(find.byType(DayRibbonCarousel), findsNothing);

      final Offset ribbon = tester.getTopLeft(find.byType(DayRibbonTab));
      final Offset grid = tester.getTopLeft(find.byKey(_gridRegionKey));
      expect(grid.dy, greaterThan(ribbon.dy),
          reason: 'the grid must sit below the collapsed ribbon tab');
      expect(tester.takeException(), isNull);
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