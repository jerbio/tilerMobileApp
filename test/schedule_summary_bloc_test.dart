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

import 'dart:async';
import 'package:fake_async/fake_async.dart';
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
  Object? failure;
  Completer<void>? held;

  @override
  Future<Map<int, TimelineSummary>> getDaySummary(Timeline timeline) async {
    requestedTimelines.add(timeline);
    await held?.future;
    if (failure != null) throw failure!;
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
  bloc.add(GetScheduleDaySummaryEvent(
      timeline: _windowAround(day), requestId: requestId));
  return loaded;
}

int _completeCountFor(ScheduleDaySummaryLoaded loaded, int dayIndex) {
  final summary = loaded.dayData!.firstWhere((s) => s.dayIndex == dayIndex);
  return summary.complete?.length ?? 0;
}

void main() {
  test('closing a hung summary completes without waiting for HTTP', () async {
    final api = _FakeScheduleApi()..held = Completer<void>();
    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
      ..scheduleApi = api;
    final loading =
        bloc.stream.firstWhere((s) => s is ScheduleDaySummaryLoading);
    bloc.add(GetScheduleDaySummaryEvent());
    await loading;
    await bloc.close().timeout(const Duration(seconds: 1));
    expect(bloc.isClosed, isTrue);
  });

  for (final elapsed in [false, true]) {
    test(
        'closing a hung ${elapsed ? 'elapsed' : 'day'} read cancels its deadline',
        () {
      fakeAsync((clock) {
        final api = _FakeScheduleApi()..held = Completer<void>();
        final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
          ..scheduleApi = api;
        bloc.add(
            elapsed ? GetElapsedTasksEvent() : GetScheduleDaySummaryEvent());
        clock.flushMicrotasks();
        expect(clock.pendingTimers, hasLength(1));

        unawaited(bloc.close());
        clock.flushMicrotasks();
        // Leave the network unresolved: cleanup must not depend on its answer.
        expect(clock.pendingTimers, isEmpty);
      });
    });
  }

  test('a newer day read cancels the old deadline and consumes its late error',
      () {
    fakeAsync((clock) {
      final oldAnswer = Completer<void>();
      final api = _FakeScheduleApi()..held = oldAnswer;
      final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
        ..scheduleApi = api;
      bloc.add(GetScheduleDaySummaryEvent(requestId: 'old'));
      clock.flushMicrotasks();
      expect(clock.pendingTimers, hasLength(1));

      final newAnswer = Completer<void>();
      api.held = newAnswer;
      bloc.add(GetScheduleDaySummaryEvent(requestId: 'new'));
      clock.flushMicrotasks();
      expect(api.requestedTimelines, hasLength(2));
      expect(clock.pendingTimers, hasLength(1),
          reason: 'Only the latest read should retain a deadline.');

      newAnswer.complete();
      clock.flushMicrotasks();
      expect((bloc.state as ScheduleDaySummaryLoaded).requestId, 'new');
      expect(clock.pendingTimers, isEmpty);

      api.failure = StateError('late network failure');
      oldAnswer.complete();
      clock.flushMicrotasks();
      expect(bloc.state, isA<ScheduleDaySummaryLoaded>());
      bloc.close();
      clock.flushMicrotasks();
    });
  });

  test('logout cancels both day and elapsed deadlines without a network answer',
      () {
    fakeAsync((clock) {
      final api = _FakeScheduleApi()..held = Completer<void>();
      final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
        ..scheduleApi = api;
      bloc.add(GetScheduleDaySummaryEvent());
      bloc.add(GetElapsedTasksEvent());
      clock.flushMicrotasks();
      expect(clock.pendingTimers, hasLength(2));
      bloc.add(LogOutScheduleDaySummaryEvent());
      clock.flushMicrotasks();
      expect(bloc.state, isA<LoggedOutScheduleSummaryState>());
      expect(clock.pendingTimers, isEmpty);
      bloc.close();
      clock.flushMicrotasks();
    });
  });

  test('a hung summary still fails at its deadline and ignores late completion',
      () {
    fakeAsync((clock) {
      final api = _FakeScheduleApi()..held = Completer<void>();
      final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
        ..scheduleApi = api;
      bloc.add(GetScheduleDaySummaryEvent());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 25));
      clock.flushMicrotasks();
      expect(bloc.state, isA<ScheduleSummaryErrorState>());
      expect(clock.pendingTimers, isEmpty);
      api.held!.complete();
      clock.flushMicrotasks();
      expect(bloc.state, isA<ScheduleSummaryErrorState>());
      bloc.close();
      clock.flushMicrotasks();
    });
  });

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

  test('retention preserves the completion COUNT for a day a later fetch omits',
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

  test('a request carrying a non-null requestId still emits the day summaries',
      () async {
    final DateTime today = Utility.currentTime().dayDate;
    final int todayIndex = today.universalDayIndex;

    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null);
    bloc.scheduleApi = _FakeScheduleApi(completeCountByDay: {todayIndex: 4});

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

  test('failed summary retains counts and can recover on retry', () async {
    final day = Utility.currentTime().dayDate;
    final index = day.universalDayIndex;
    final api = _FakeScheduleApi(completeCountByDay: {index: 4});
    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
      ..scheduleApi = api;
    await _loadWindow(bloc, day);
    api.failure = StateError('offline');
    final error = bloc.stream.firstWhere((s) => s is ScheduleSummaryErrorState);
    bloc.add(GetScheduleDaySummaryEvent(timeline: _windowAround(day)));
    final failed = await error as ScheduleSummaryErrorState;
    expect(failed.dayData.firstWhere((s) => s.dayIndex == index).complete,
        hasLength(4));
    api.failure = null;
    api.completeCountByDay[index] = 2;
    expect(_completeCountFor(await _loadWindow(bloc, day), index), 2);
    await bloc.close();
  });

  test('logout prevents a late summary from restoring another account data',
      () async {
    final api = _FakeScheduleApi()..held = Completer<void>();
    final bloc = ScheduleSummaryBloc(getContextCallBack: () => null)
      ..scheduleApi = api;
    final loading =
        bloc.stream.firstWhere((s) => s is ScheduleDaySummaryLoading);
    bloc.add(GetScheduleDaySummaryEvent(
        timeline: _windowAround(Utility.currentTime())));
    await loading;
    final loggedOut =
        bloc.stream.firstWhere((s) => s is LoggedOutScheduleSummaryState);
    bloc.add(LogOutScheduleDaySummaryEvent());
    await loggedOut;
    api.held!.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<LoggedOutScheduleSummaryState>());
    await bloc.close();
  });
}
