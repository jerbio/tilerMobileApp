// Each schedule change reports, once, where its time went: preparing it,
// the POST, waiting for the new schedule, reading it, and painting it, plus
// when each message was shown. Logged as `schedule_change_timing`.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';

import 'schedule_evaluation_flow_test.dart'
    show FakeScheduleApi, ControlledClient, response, flush;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TILER_SCHEDULE_TIMINGS', () {
    test('on in debug builds and off in release unless the flag says so', () {
      bool on({required bool debug, String setting = ''}) =>
          ScheduleChangeTimings.resolveEnabled(
              debugMode: debug, setting: setting);
      expect(on(debug: true), isTrue);
      expect(on(debug: false), isFalse);
      expect(on(debug: false, setting: 'true'), isTrue,
          reason: 'turned on to troubleshoot a release build');
      expect(on(debug: true, setting: 'false'), isFalse,
          reason: 'turned off in a debug build');
      expect(on(debug: false, setting: 'false'), isFalse);
      expect(on(debug: true, setting: 'TRUE'), isTrue);
      expect(on(debug: false, setting: 'nonsense'), isFalse,
          reason: 'anything else keeps the build default');
    });

    test('when off, nothing is timed or reported', () {
      final reports = <Map<String, Object?>>[];
      final frames = <VoidCallback>[];
      final timings = ScheduleChangeTimings(
          enabled: false, onNextFrame: frames.add, report: reports.add);
      final timing = timings.start(ScheduleChangeKind.complete);
      timings.mark(timing, 'sent');
      timings.finish(timing, 'failed');
      final other = timings.start(ScheduleChangeKind.revise);
      timings.finish(other, 'success', awaitRefresh: true);
      timings.readStarted();
      timings.applied();
      timings.readFinished();
      for (final frame in frames) {
        frame();
      }
      expect(reports, isEmpty);
      expect(frames, isEmpty, reason: 'no frame is even requested');
      timings.dispose();
    });

    test('the bloc reports nothing when timings are off', () async {
      SharedPreferences.setMockInitialValues({});
      final api = FakeScheduleApi();
      final reports = <Map<String, Object?>>[];
      final bloc = ScheduleBloc(
          getContextCallBack: () => null,
          timings: ScheduleChangeTimings(
              enabled: false,
              onNextFrame: (frame) => scheduleMicrotask(frame),
              report: reports.add))
        ..scheduleApi = api;
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: const [],
          timelines: const [],
          lookupTimeline: api.window,
          scheduleStatus: api.status));
      await flush();
      final client = RetryHttpClient(
          scheduleLifecycle: () => bloc,
          innerClient: ControlledClient((_) async => response()));
      await bloc.runScheduleChange(
          () => client
              .post(Uri.https('example.test', 'api/Schedule/Event/Complete')),
          kind: ScheduleChangeKind.complete);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reports, isEmpty);
      client.close();
      await bloc.close();
    });
  });

  group('ScheduleChangeTimings', () {
    late DateTime now;
    late List<Map<String, Object?>> reports;
    late List<VoidCallback> frames;
    late ScheduleChangeTimings timings;

    void after(int ms) => now = now.add(Duration(milliseconds: ms));
    void paint() {
      final pending = List.of(frames);
      frames.clear();
      for (final frame in pending) {
        frame();
      }
    }

    setUp(() {
      now = DateTime(2026, 10, 13, 9);
      reports = [];
      frames = [];
      timings = ScheduleChangeTimings(
          now: () => now,
          onNextFrame: frames.add,
          report: reports.add,
          reportAfter: const Duration(minutes: 1));
    });
    tearDown(() => timings.dispose());

    test('a successful change reports every span once it is on screen', () {
      final timing = timings.start(ScheduleChangeKind.complete);
      after(400);
      timing.requestId = 'r1';
      timings.mark(timing, 'reserved');
      timings.mark(timing, 'cardShown');
      after(100);
      timings.mark(timing, 'sent');
      after(13000);
      timings.mark(timing, 'responded', fields: {'status': 200});
      timings.finish(timing, 'success', awaitRefresh: true);
      expect(reports, isEmpty, reason: 'the calendar is not refreshed yet');

      after(5);
      timings.readStarted();
      after(9000);
      timings.applied();
      after(2);
      timings.readFinished();
      expect(reports, isEmpty, reason: 'not painted yet');
      after(40);
      paint();

      final report = reports.single;
      expect(report['requestId'], 'r1');
      expect(report['kind'], 'complete');
      expect(report['outcome'], 'success');
      expect(report['status'], 200);
      expect(report['prepareMs'], 400);
      expect(report['sendMs'], 13000);
      expect(report['waitForDataMs'], 9005);
      expect(report['readMs'], 9002);
      expect(report['renderMs'], 42);
      expect(report['totalMs'], 400 + 100 + 13000 + 5 + 9000 + 2 + 40);
      expect((report['marks'] as Map)['cardShown'], 400);
      paint();
      expect(reports, hasLength(1), reason: 'reported once');
    });

    test(
        'a schedule update that lands while the change is in flight is not '
        'its refresh; the report waits for the read after the answer', () {
      final timing = timings.start(ScheduleChangeKind.complete);
      after(1200);
      timings.mark(timing, 'reserved');
      timings.mark(timing, 'sent');
      after(3800);
      timings.applied(); // an earlier change's result, loaded meanwhile
      paint();
      after(10000);
      timings.mark(timing, 'responded', fields: {'status': 200});
      timings.finish(timing, 'success', awaitRefresh: true);
      paint();
      expect(reports, isEmpty, reason: 'its own refresh has not arrived');

      timings.readStarted();
      after(4700);
      timings.applied();
      timings.readFinished();
      after(100);
      paint();

      final report = reports.single;
      final marks = report['marks'] as Map;
      expect(marks['appliedWhilePending'], 5000);
      expect(marks['applied'], 19700);
      expect(report['waitForDataMs'], 4700);
      expect(report['readMs'], 4700);
      expect(report['renderMs'], 100);
      expect(report['totalMs'], 19800);
    });

    test('a failure is reported straight away, without refresh spans', () {
      final timing = timings.start(ScheduleChangeKind.delete);
      after(50);
      timings.mark(timing, 'sent');
      after(300);
      timings.mark(timing, 'responded', fields: {'status': 400});
      timings.finish(timing, 'failed');
      final report = reports.single;
      expect(report['outcome'], 'failed');
      expect(report['sendMs'], 300);
      expect(report['readMs'], isNull);
      expect(report['totalMs'], 350);
    });

    test('messages are on the timeline, so conflicting ones show', () {
      final timing = timings.start(ScheduleChangeKind.startNow);
      after(200);
      timings.mark(timing, 'cardShown');
      after(16000);
      timings.mark(timing, 'uncertain');
      after(18000);
      timings.mark(timing, 'told', fields: {'told': 'acknowledged'});
      timings.finish(timing, 'acknowledged', awaitRefresh: true);
      timings.readStarted();
      timings.applied();
      timings.readFinished();
      paint();
      final report = reports.single;
      expect(report['marks'], {
        'cardShown': 200,
        'uncertain': 16200,
        'told': 34200,
        'settled': 34200,
        'readStarted': 34200,
        'applied': 34200,
        'readFinished': 34200,
        'rendered': 34200
      });
      expect(report['told'], 'acknowledged');
    });

    test(
        'a change that never finishes is reported at the next timing event, '
        'without keeping a timer', () {
      final stuck = timings.start(ScheduleChangeKind.revise)
        ..requestId = 'stuck';
      after(40000);
      timings.readStarted();
      expect(reports, isEmpty, reason: 'not stale yet');
      after(30000); // past reportAfter (1 minute)
      timings.start(ScheduleChangeKind.complete);
      expect(reports.single['requestId'], stuck.requestId);
      expect(reports.single['outcome'], 'incomplete');
    });
  });

  group('ScheduleBloc', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('times a change from the tap to the refreshed calendar', () async {
      final api = FakeScheduleApi();
      final reports = <Map<String, Object?>>[];
      final bloc = ScheduleBloc(
          getContextCallBack: () => null,
          timings: ScheduleChangeTimings(
              onNextFrame: (frame) => scheduleMicrotask(frame),
              report: reports.add))
        ..scheduleApi = api;
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: const [],
          timelines: const [],
          lookupTimeline: api.window,
          scheduleStatus: api.status));
      await flush();
      final wire = Completer<http.StreamedResponse>();
      final client = RetryHttpClient(
          scheduleLifecycle: () => bloc,
          innerClient: ControlledClient((_) => wire.future));

      final pending = bloc.runScheduleChange(
          () => client
              .post(Uri.https('example.test', 'api/Schedule/Event/Complete')),
          kind: ScheduleChangeKind.complete,
          affectedTileIds: ['t1']);
      await flush();
      // The server applies it; the refresh reads the new schedule.
      api.status =
          ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
      wire.complete(response());
      await pending;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final report = reports.single;
      expect(report['outcome'], 'success');
      expect(report['kind'], 'complete');
      expect(report['status'], 200);
      for (final span in [
        'prepareMs',
        'sendMs',
        'waitForDataMs',
        'readMs',
        'renderMs',
        'totalMs'
      ]) {
        expect(report[span], isA<int>(), reason: span);
      }
      expect(
          (report['marks'] as Map).keys,
          containsAll([
            'reserved',
            'cardShown',
            'sent',
            'responded',
            'settled',
            'readStarted',
            'applied',
            'readFinished',
            'rendered'
          ]));
      client.close();
      await bloc.close();
    });

    test('a change that could not be sent is reported as such', () async {
      final api = _Unavailable();
      final reports = <Map<String, Object?>>[];
      final bloc = ScheduleBloc(
          getContextCallBack: () => null,
          timings: ScheduleChangeTimings(
              onNextFrame: (frame) => scheduleMicrotask(frame),
              report: reports.add))
        ..scheduleApi = api;
      await expectLater(
          bloc.runScheduleChange(() async => true,
              kind: ScheduleChangeKind.complete),
          throwsA(isA<ScheduleServerUnavailable>()));
      await flush();
      expect(reports.single['outcome'], 'not_sent');
      expect(reports.single['sendMs'], isNull);
      await bloc.close();
    });
  });
}

class _Unavailable extends FakeScheduleApi {
  @override
  Future<ScheduleStatus> getScheduleStatus() =>
      Future.error(ScheduleServerUnavailable(status: 503));
}
