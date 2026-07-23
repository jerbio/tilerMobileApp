// schedule_summary_bloc_test.dart
//
// TDD — day summary loading when jumping outside the loaded sliding window.
//
// Repro for the bug: the daily view loads a small window (~7-8 days). Jumping
// to a date far outside that window (e.g. 20 days back via the day ribbon)
// leaves the completion metrics blank, and only a one-day swipe makes them
// appear.
//
// Root cause captured here: _onGetDayData used to UNION the requested timeline
// with the previously loaded summary timeline, producing an ever-growing span
// (old window -> far target). The backend only returns a bounded window, so the
// far target day never comes back in that giant range. A subsequent one-day
// swipe issues a small, bounded query that does include the day.
//
// Contract:
//   * A far jump must query a bounded window around the SELECTED date, not an
//     unbounded union stretching back to the previous window.
//   * Days loaded earlier are still retained (kept in the cache) after the jump.

import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

/// Fake schedule API that records every requested timeline and returns a
/// summary for each day *within* the requested window — mimicking a backend
/// that only ever answers for the bounded range it was asked about. The number
/// of completed tiles per day is configurable (and mutable between fetches) so
/// tests can simulate completions changing on the server.
class _FakeScheduleApi extends ScheduleApi {
  _FakeScheduleApi({Map<int, int>? completeCountByDay})
      : completeCountByDay = completeCountByDay ?? {},
        super(getContextCallBack: () => null);

  final List<Timeline> requestedTimelines = [];
  final Map<int, int> completeCountByDay;

  @override
  Future<Map<int, TimelineSummary>> getDaySummary(Timeline timeline) async {
    requestedTimelines.add(timeline);
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

Timeline _windowAround(DateTime day) => Timeline.fromDateTime(
      day.subtract(const Duration(days: 4)),
      day.add(const Duration(days: 4)),
    );

Future<ScheduleDaySummaryLoaded> _loadWindow(
    ScheduleSummaryBloc bloc, DateTime day,
    {String? requestId}) async {
  final loaded = bloc.stream
      .firstWhere((s) => s is ScheduleDaySummaryLoaded)
      .then((s) => s as ScheduleDaySummaryLoaded);
  bloc.add(
      GetScheduleDaySummaryEvent(timeline: _windowAround(day), requestId: requestId));
  return loaded;
}

int _completeCountFor(ScheduleDaySummaryLoaded loaded, int dayIndex) {
  final summary =
      loaded.dayData!.firstWhere((s) => s.dayIndex == dayIndex);
  return summary.complete?.length ?? 0;
}

void main() {
  test(
      'jumping to a far date queries a bounded window around the target '
      '(not an ever-growing union)', () async {
    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    final fake = _FakeScheduleApi();
    bloc.scheduleApi = fake;

    final DateTime today = Utility.currentTime().dayDate;
    final DateTime farDay = today.subtract(const Duration(days: 20));

    // Initial small window around today.
    await _loadWindow(bloc, today);

    // Jump ~20 days back (outside the loaded window).
    final loaded = await _loadWindow(bloc, farDay);

    final Timeline lastRequested = fake.requestedTimelines.last;
    final int requestedSpanDays =
        lastRequested.endTime.difference(lastRequested.startTime).inDays;

    expect(requestedSpanDays, lessThanOrEqualTo(10),
        reason: 'A far jump must request a bounded window around the selected '
            'date, not a union spanning back to the previous window.');

    // The selected far day must be present in the loaded summaries so its
    // completion metrics can render immediately.
    final int farDayIndex = farDay.universalDayIndex;
    expect(loaded.dayData!.any((s) => s.dayIndex == farDayIndex), isTrue,
        reason: 'The selected far day summary should be retrievable after the '
            'jump.');

    await bloc.close();
  });

  test('previously loaded days are retained after jumping to a far date',
      () async {
    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    final fake = _FakeScheduleApi();
    bloc.scheduleApi = fake;

    final DateTime today = Utility.currentTime().dayDate;
    final DateTime farDay = today.subtract(const Duration(days: 20));

    await _loadWindow(bloc, today);
    final loaded = await _loadWindow(bloc, farDay);

    // Today's summary (loaded first) should still be present even though the
    // far-jump fetch didn't include it.
    final int todayIndex = today.universalDayIndex;
    expect(loaded.dayData!.any((s) => s.dayIndex == todayIndex), isTrue,
        reason: 'Days loaded before the jump must be retained in the cache.');

    await bloc.close();
  });

  test(
      'retention preserves the completion COUNT for a day a later fetch omits',
      () async {
    final DateTime today = Utility.currentTime().dayDate;
    final int todayIndex = today.universalDayIndex;
    final DateTime farDay = today.subtract(const Duration(days: 20));
    final int farIndex = farDay.universalDayIndex;

    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    bloc.scheduleApi =
        _FakeScheduleApi(completeCountByDay: {todayIndex: 5, farIndex: 2});

    // Load today's window (today gets complete=5), then jump far (today omitted
    // from that fetch).
    await _loadWindow(bloc, today);
    final loaded = await _loadWindow(bloc, farDay);

    expect(_completeCountFor(loaded, todayIndex), 5,
        reason: 'Today was not in the far-jump fetch, so its previously '
            'retrieved completion count must be retained, not lost.');
    expect(_completeCountFor(loaded, farIndex), 2,
        reason: 'The freshly fetched far day should carry its own count.');

    await bloc.close();
  });

  test(
      'a refresh replaces a day\'s completion count authoritatively '
      '(can drop back down)', () async {
    final DateTime today = Utility.currentTime().dayDate;
    final int todayIndex = today.universalDayIndex;

    final fake = _FakeScheduleApi(completeCountByDay: {todayIndex: 3});
    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    bloc.scheduleApi = fake;

    var loaded = await _loadWindow(bloc, today);
    expect(_completeCountFor(loaded, todayIndex), 3);

    // A completion is undone on the server; a pull-to-refresh must reflect the
    // new lower count rather than resurrecting the stale one.
    fake.completeCountByDay[todayIndex] = 1;
    loaded = await _loadWindow(bloc, today);

    expect(_completeCountFor(loaded, todayIndex), 1,
        reason: 'A day present in the fresh response is authoritative, so a '
            'refresh must reflect the new (lower) completion count.');

    await bloc.close();
  });

  test(
      'a request carrying a non-null requestId still emits the day summaries',
      () async {
    final DateTime today = Utility.currentTime().dayDate;
    final int todayIndex = today.universalDayIndex;

    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    bloc.scheduleApi =
        _FakeScheduleApi(completeCountByDay: {todayIndex: 4});

    // The daily view dispatches with a non-null requestId
    // (incrementalTilerScrollId). The loaded state must still carry the data.
    final loaded =
        await _loadWindow(bloc, today, requestId: 'incremental-get-schedule');

    expect(loaded.requestId, 'incremental-get-schedule');
    expect(_completeCountFor(loaded, todayIndex), 4,
        reason: 'A requestId-tagged load must still surface the completion '
            'data (DaySummary consumes it regardless of requestId).');

    await bloc.close();
  });
}
