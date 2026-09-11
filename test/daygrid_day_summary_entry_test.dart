// daygrid_day_summary_entry_test.dart
//
// C20 (supersedes C17): grid mode's day-summary entry point is the summary
// button in the fixed top bar ([DayGridTopChromeRow]), adjacent to the day
// pill — present for ANY shown day, not just today. Tapping it opens
// [TodayStatusScreen] carrying that day's start->end [Timeline] (the same
// TimelineSummary pipeline list mode's DaySummaryHeader uses), and fires the
// grid-mode-only `daygrid_summary_opened` tag with a `dayIndex` + `isToday`
// payload.
//
// The grid page itself no longer mounts DaySummaryHeader (the today-only
// C17 mount is retired); list mode's DaySummaryHeader is untouched.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/daySummaryHeader.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

SubCalendarEvent _tile(String id, String name, DateTime start, DateTime end) {
  final tile = SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  tile.isViable = true;
  return tile;
}

/// Providers sit ABOVE MaterialApp so the blocs are also visible to the
/// route pushed onto MaterialApp's navigator (TodayStatusScreen).
Widget _wrap(Widget body) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => DailyViewLayoutCubit()),
      BlocProvider(create: (_) => UiDateManagerBloc()),
      BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
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
      home: Scaffold(body: body),
    ),
  );
}

Widget _topBar(DateTime day) => DayGridTopChromeRow(
      currentDate: day,
      onSearch: () {},
      onSettings: () {},
      onGoToToday: () {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
  });

  group('Top-bar day summary entry (C20)', () {
    testWidgets('the summary button is present for today', (tester) async {
      await tester.pumpWidget(_wrap(_topBar(Utility.currentTime().dayDate)));
      await tester.pump();
      expect(find.byKey(DayGridTopChromeRow.summaryButtonKey), findsOneWidget);
    });

    testWidgets('the summary button is present for a non-today day',
        (tester) async {
      final DateTime fiveDaysAgo = Utility.getTimeFromIndex(
          Utility.currentTime().universalDayIndex - 5);
      await tester.pumpWidget(_wrap(_topBar(fiveDaysAgo)));
      await tester.pump();
      expect(find.byKey(DayGridTopChromeRow.summaryButtonKey), findsOneWidget);
    });

    testWidgets(
        'tapping it opens TodayStatusScreen with the SHOWN day start->end Timeline',
        (tester) async {
      final int dayIndex = Utility.currentTime().universalDayIndex - 5;
      final DateTime day = Utility.getTimeFromIndex(dayIndex);
      await tester.pumpWidget(_wrap(_topBar(day)));
      await tester.pump();

      DayGridTopChromeRow.summaryOpenTagFireCount = 0;
      await tester.tap(find.byKey(DayGridTopChromeRow.summaryButtonKey));
      await tester.pump(); // route push -> TodayStatusScreen (loading)
      await tester.pump(); // commit the pushed route's content into the tree

      expect(find.byType(TodayStatusScreen), findsOneWidget);
      final TodayStatusScreen screen =
          tester.widget<TodayStatusScreen>(find.byType(TodayStatusScreen));
      expect(screen.timeline.start, day.millisecondsSinceEpoch,
          reason: 'the pushed Timeline must start at the shown day start');
      expect(screen.timeline.end, day.endOfDay.millisecondsSinceEpoch,
          reason: 'the pushed Timeline must end at the shown day end');
      expect(DayGridTopChromeRow.summaryOpenTagFireCount, 1,
          reason: 'one real tap fires daygrid_summary_opened exactly once');

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('summaryOpenTag carries the dayIndex + isToday payload', () {
      final int todayIndex = Utility.currentTime().universalDayIndex;
      final String line =
          DayGridTopChromeRow.summaryOpenTag(todayIndex, isToday: true);
      expect(line, startsWith('DayGrid::'));
      expect(line, contains('daygrid_summary_opened'));
      expect(line, contains('dayIndex: $todayIndex'));
      expect(line, contains('isToday: true'));
    });
  });

  group('DayGridPage no longer mounts DaySummaryHeader (C17 retired)', () {
    testWidgets("today's grid page has no DaySummaryHeader", (tester) async {
      final int todayIndex = Utility.currentTime().universalDayIndex;
      final DateTime today = Utility.currentTime();
      await tester.pumpWidget(_wrap(DayGridPage(
        dayIndex: todayIndex,
        key: Key('day_$todayIndex'),
        tiles: <TilerEvent>[
          _tile('regular', 'RegularEvent',
              DateTime(today.year, today.month, today.day, 9),
              DateTime(today.year, today.month, today.day, 10)),
        ],
      )));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(DaySummaryHeader), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
