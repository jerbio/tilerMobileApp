// daygrid_day_summary_entry_test.dart
//
// C17: grid mode gets the same day-summary entry point list mode surfaces —
// the (unmodified) [DaySummaryHeader]. `DayGridPage` mounts it ONLY for the
// day that is today; any other day's grid page shows no header. Tapping the
// header opens [TodayStatusScreen] carrying that day's start->end [Timeline]
// (the same TimelineSummary / ScheduleSummaryBloc pipeline list mode uses).
//
// The grid body (banner strip, pinned header, and the real [DayGridWidget]) is
// the production path; the page is hosted in a bounded viewport exactly like
// daygrid_pinned_header_test.dart, with ScheduleBloc + ScheduleSummaryBloc
// provided so the header's bloc reads resolve.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
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

/// Grid-mode page in a bounded viewport (the grid uses an `Expanded` region, so
/// the page needs a bounded-height parent). [dayIndex] is parameterised so a
/// test can render today (header present) or any other day (header absent).
Widget _buildApp({
  required DailyViewLayoutCubit cubit,
  required int dayIndex,
  required List<TilerEvent> tiles,
}) {
  // The providers sit ABOVE MaterialApp so the blocs are also visible to any
  // route pushed onto MaterialApp's navigator — the DaySummaryHeader opens
  // TodayStatusScreen via Navigator.push, and that route builds above `home`.
  return MultiBlocProvider(
    providers: [
      BlocProvider<DailyViewLayoutCubit>.value(value: cubit),
      BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
      BlocProvider(
          create: (_) =>
              ScheduleSummaryBloc(getContextCallBack: () => null)),
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
      home: Scaffold(
        body: DayGridPage(
          dayIndex: dayIndex,
          tiles: tiles,
          key: Key('day_$dayIndex'),
        ),
      ),
    ),
  );
}

/// One mid-day tile for the day under test, so the grid/banner/pinned strips
/// have a normal (non-empty) input, mirroring the pinned-header harness.
List<TilerEvent> _someTiles(DateTime day) {
  return <TilerEvent>[
    _tile('regular', 'RegularEvent',
        DateTime(day.year, day.month, day.day, 9),
        DateTime(day.year, day.month, day.day, 10)),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Force grid layout so DayGridPage takes its grid-mode Column branch.
    SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
  });

  group('DayGridPage grid-mode DaySummaryHeader (C17)', () {
    testWidgets('renders the summary header for today', (tester) async {
      final cubit = DailyViewLayoutCubit();
      addTearDown(cubit.close);
      final int todayIndex = Utility.currentTime().universalDayIndex;

      await tester.pumpWidget(_buildApp(
        cubit: cubit,
        dayIndex: todayIndex,
        tiles: _someTiles(Utility.currentTime()),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(DaySummaryHeader), findsOneWidget,
          reason: "today's grid page must surface the day-summary entry");
      expect(tester.takeException(), isNull);
    });

    testWidgets('does NOT render the summary header for a non-today day',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      addTearDown(cubit.close);
      final int todayIndex = Utility.currentTime().universalDayIndex;
      final DateTime fiveDaysAgo =
          Utility.getTimeFromIndex(todayIndex - 5);

      await tester.pumpWidget(_buildApp(
        cubit: cubit,
        dayIndex: todayIndex - 5,
        tiles: _someTiles(fiveDaysAgo),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(DaySummaryHeader), findsNothing,
          reason: 'only today carries the day-summary entry in grid mode');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'tapping the header opens TodayStatusScreen with the day start->end Timeline',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      addTearDown(cubit.close);
      final int todayIndex = Utility.currentTime().universalDayIndex;

      await tester.pumpWidget(_buildApp(
        cubit: cubit,
        dayIndex: todayIndex,
        tiles: _someTiles(Utility.currentTime()),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(DaySummaryHeader), findsOneWidget);

      await tester.tap(find.byType(DaySummaryHeader));
      await tester.pump(); // route push -> TodayStatusScreen (loading)
      await tester.pump(); // commit the pushed route's content into the tree

      expect(find.byType(TodayStatusScreen), findsOneWidget,
          reason: 'tapping the header must navigate to TodayStatusScreen');
      final TodayStatusScreen screen =
          tester.widget<TodayStatusScreen>(find.byType(TodayStatusScreen));

      // The header builds the Timeline from its dayIndex: start of day ->
      // end of day, matching DaySummaryHeader._navigateToSummary.
      final DateTime dayStart = Utility.getTimeFromIndex(todayIndex);
      final DateTime dayEnd = dayStart.endOfDay;
      expect(
        screen.timeline.start,
        dayStart.millisecondsSinceEpoch,
        reason: 'the pushed Timeline must start at the day start',
      );
      expect(
        screen.timeline.end,
        dayEnd.millisecondsSinceEpoch,
        reason: 'the pushed Timeline must end at the day end',
      );

      // Let the (auth-gated, no-network) summary load settle, then confirm the
      // navigation surfaced no build/layout exception.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}