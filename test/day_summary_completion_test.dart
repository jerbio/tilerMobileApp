// day_summary_completion_test.dart
//
// Regression: the daily view dispatches its day-summary requests with a
// non-null requestId (TileListState.refreshScheduleSummary uses
// incrementalTilerScrollId). DaySummary used to ignore ScheduleDaySummaryLoaded
// states whose requestId != null, so the completed/tardy counts never rendered
// on initial load / far-date jump — they only appeared after a swipe emitted a
// transient loading state. This test locks in that a Loaded state carrying a
// non-null requestId still surfaces the completed count.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

/// Fake API that returns a summary for each day in the requested window, with a
/// configurable number of completed tiles per day index.
class _FakeScheduleApi extends ScheduleApi {
  _FakeScheduleApi(this.completeCountByDay)
      : super(getContextCallBack: () => null);

  final Map<int, int> completeCountByDay;

  @override
  Future<Map<int, TimelineSummary>> getDaySummary(Timeline timeline) async {
    final Map<int, TimelineSummary> result = {};
    final int startIndex = timeline.startTime.universalDayIndex;
    final int endIndex = timeline.endTime.universalDayIndex;
    for (int dayIndex = startIndex; dayIndex <= endIndex; dayIndex++) {
      final summary = TimelineSummary();
      summary.dayIndex = dayIndex;
      final int count = completeCountByDay[dayIndex] ?? 0;
      summary.complete =
          List.generate(count, (i) => SubCalendarEvent(id: 'c-$dayIndex-$i'));
      result[dayIndex] = summary;
    }
    return result;
  }
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'DaySummary renders the completed count from a Loaded state that carries '
      'a non-null requestId', (tester) async {
    final DateTime today = Utility.currentTime().dayDate;
    final DateTime farDay = today.subtract(const Duration(days: 20));
    final int farIndex = farDay.universalDayIndex;

    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    bloc.scheduleApi = _FakeScheduleApi({farIndex: 3});
    addTearDown(bloc.close);

    // Mirror the daily view: dispatch with a non-null requestId and let it load.
    bloc.add(GetScheduleDaySummaryEvent(
      timeline: Timeline.fromDateTime(
        farDay.subtract(const Duration(days: 4)),
        farDay.add(const Duration(days: 4)),
      ),
      requestId: 'incremental-get-schedule',
    ));
    await bloc.stream.firstWhere((s) => s is ScheduleDaySummaryLoaded);

    // The batch hands DaySummary a fresh, empty summary (completion only ever
    // comes from the web request, surfaced via the bloc state).
    final summary = TimelineSummary()..dayIndex = farIndex;

    await tester.pumpWidget(
      _buildTestApp(
        child: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            body: DaySummary(dayTimelineSummary: summary),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('3'),
      findsOneWidget,
      reason: 'The completed count must render even though the summary was '
          'loaded via a request that carried a non-null requestId.',
    );
  });

  testWidgets(
      'DaySummary picks up the completed count when a requestId-tagged summary '
      'arrives AFTER the widget is mounted', (tester) async {
    final DateTime today = Utility.currentTime().dayDate;
    final int todayIndex = today.universalDayIndex;

    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    bloc.scheduleApi = _FakeScheduleApi({todayIndex: 2});
    addTearDown(bloc.close);

    // Mount first, while the bloc is still in its initial (no data) state.
    final summary = TimelineSummary()..dayIndex = todayIndex;
    await tester.pumpWidget(
      _buildTestApp(
        child: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            body: DaySummary(dayTimelineSummary: summary),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2'), findsNothing,
        reason: 'No completion should show before any summary is loaded.');

    // Now the daily view triggers a (requestId-tagged) refresh; the mounted
    // widget must apply it via its BlocListener.
    bloc.add(GetScheduleDaySummaryEvent(
      timeline: Timeline.fromDateTime(
        today.subtract(const Duration(days: 4)),
        today.add(const Duration(days: 4)),
      ),
      requestId: 'incremental-get-schedule',
    ));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget,
        reason: 'A summary that arrives after mount must be applied through the '
            'BlocListener, regardless of its requestId.');
  });
}
