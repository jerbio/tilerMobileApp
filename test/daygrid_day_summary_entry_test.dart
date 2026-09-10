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

  group('DayGridPage grid-mode summary-open tag (C17 follow-up, §15.4 Logging)', () {
    test('gridSummaryOpenTag builds the daygrid_summary_opened tag + dayIndex payload', () {
      final int todayIndex = Utility.currentTime().universalDayIndex;
      final String line = DayGridPage.gridSummaryOpenTag(todayIndex);

      expect(line, contains('daygrid_summary_opened'),
          reason: 'the tag name must follow the daygrid_<area>_<event> scheme');
      expect(line, contains('dayIndex: $todayIndex'),
          reason: 'the analytics payload must carry the tapped day index');
      expect(line, startsWith('DayGrid::'),
          reason: 'debug lines carry the DayGrid:: prefix for grep-ability (§12.0)');
    });

    testWidgets(
        'grid-mode header tap fires the daygrid_summary_opened tag AND navigates',
        (tester) async {
      // Proves the (grid-mode-only) tag actually FIRES on a REAL header tap —
      // not just that navigation still works. The grid mount site passes
      // onOpen to the shared [DaySummaryHeader], and the header calls it from
      // its own deepest tap recognizer immediately before navigating — so the
      // tag fires exactly once per real tap that also opens the summary (no
      // arena ambiguity, no stray pointer-up overcounting). The tag's debug
      // line flows through the non-interceptable built-in `print` and
      // AnalysticsSignal.send is a no-op here, so the test observes the fire
      // via [DayGridPage.summaryOpenTagFireCount] (reset first, then tapped).
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

      // The grid mount site must wire the tag into the header's onOpen seam.
      expect(
        tester.widget<DaySummaryHeader>(find.byType(DaySummaryHeader)).onOpen,
        isNotNull,
        reason:
            'the grid mount site must pass onOpen so the header tap fires the tag',
      );

      DayGridPage.summaryOpenTagFireCount = 0;
      await tester.tap(find.byType(DaySummaryHeader));
      await tester.pump(); // route push -> TodayStatusScreen (loading)
      await tester.pump(); // commit the pushed route into the tree

      expect(
        DayGridPage.summaryOpenTagFireCount,
        1,
        reason:
            'a single real header tap must fire the daygrid_summary_opened tag once',
      );

      expect(find.byType(TodayStatusScreen), findsOneWidget,
          reason:
              'the tag listener must not block the header navigation tap');
      expect(tester.takeException(), isNull);
    });
  });
}