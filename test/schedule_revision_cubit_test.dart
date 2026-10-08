import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/data/scheduleStatus.dart';

ScheduleStatus status(String id) => ScheduleStatus.fromJson({
      'analysisId': id,
      'evaluationId': id,
    });

void main() {
  test('retries unchanged status, publishes once, and stops on change',
      () async {
    var calls = 0;
    final cubit = ScheduleRevisionCubit(
      fetchStatus: () async => status(++calls < 3 ? 'old' : 'new'),
      retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
    );
    cubit.observe(status('old'));
    final observed = <ScheduleRevision?>[];
    final subscription = cubit.stream.listen(observed.add);
    final changed = cubit.stream.firstWhere((r) => r?.evaluationId == 'new');
    cubit.checkAfterChange();
    await changed;
    cubit.observe(status('new'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 3);
    expect(observed, [const ScheduleRevision('new', 'new')]);
    await subscription.cancel();
    await cubit.close();
  });

  test('unchanged status exhausts a bounded budget', () async {
    var calls = 0;
    final cubit = ScheduleRevisionCubit(
      fetchStatus: () async {
        calls++;
        return status('old');
      },
      retryDelays: const [Duration.zero, Duration.zero],
    );
    cubit.observe(status('old'));
    cubit.checkAfterChange();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 3);
    await cubit.close();
  });

  test('transient failures retry and publish the recovered revision', () async {
    var calls = 0;
    final cubit = ScheduleRevisionCubit(
      fetchStatus: () async {
        if (++calls == 1) throw Exception('offline');
        return status('new');
      },
      retryDelays: const [Duration.zero],
    );
    cubit.observe(status('old'));
    final changed = cubit.stream.firstWhere((r) => r?.evaluationId == 'new');
    cubit.checkAfterChange();
    await changed;
    expect(calls, 2);
    await cubit.close();
  });

  test('closing cancels scheduled retries', () async {
    var calls = 0;
    final cubit = ScheduleRevisionCubit(
      fetchStatus: () async {
        calls++;
        return status('old');
      },
      retryDelays: const [Duration(milliseconds: 20)],
    );
    cubit.observe(status('old'));
    cubit.checkAfterChange();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1);
  });

  test('recovery checks unchanged IDs and signals failed-read retry', () async {
    var calls = 0;
    final cubit = ScheduleRevisionCubit(
      fetchStatus: () async {
        calls++;
        return status('old');
      },
      retryDelays: const [],
    );
    cubit.observe(status('old'));
    var recoveries = 0;
    final subscription = cubit.recovery.listen((_) => recoveries++);
    cubit.recover();
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    expect(recoveries, greaterThanOrEqualTo(1));
    expect(cubit.state, const ScheduleRevision('old', 'old'));
    await subscription.cancel();
    await cubit.close();
  });

  test('suspension discards in-flight work and recovery starts fresh',
      () async {
    final pending = Completer<ScheduleStatus>();
    var calls = 0;
    final cubit = ScheduleRevisionCubit(
      fetchStatus: () =>
          ++calls == 1 ? pending.future : Future.value(status('new')),
      retryDelays: const [],
    );
    cubit.observe(status('old'));
    cubit.checkAfterChange();
    cubit.suspend();
    pending.complete(status('stale'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, const ScheduleRevision('old', 'old'));
    cubit.recover();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, const ScheduleRevision('new', 'new'));
    expect(calls, 2);
    await cubit.close();
  });

  test('reset discards an outstanding response', () async {
    final response = Completer<ScheduleStatus>();
    final cubit = ScheduleRevisionCubit(fetchStatus: () => response.future);
    cubit.observe(status('old'));
    cubit.checkAfterChange();
    cubit.reset();
    response.complete(status('new'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isNull);
    await cubit.close();
  });
}
