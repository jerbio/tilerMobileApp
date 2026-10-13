// When a schedule change cannot start because the schedule cannot be read
// first (the server is down or still starting), nothing is sent and the user
// is told so, once, with a safe Retry. An unavailable server is told apart
// from a malformed answer, and a struggling server does not stretch the
// re-checks of an unconfirmed change.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';

import 'schedule_evaluation_flow_test.dart'
    show FakeScheduleApi, ControlledClient, response, flush;

class _UnreachableStatus extends FakeScheduleApi {
  Object? statusError;
  @override
  Future<ScheduleStatus> getScheduleStatus() {
    final error = statusError;
    if (error != null) {
      statusReads++;
      return Future.error(error);
    }
    return super.getScheduleStatus();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));
  final complete = Uri.https('example.test', 'api/Schedule/Event/Complete');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('decodeServerJson', () {
    test('an error page is an unavailable server, with its status', () {
      expect(
          () => decodeServerJson(
              http.Response('<html>Service Unavailable</html>', 503,
                  headers: {'content-type': 'text/html'}),
              operation: 'status'),
          throwsA(isA<ScheduleServerUnavailable>()
              .having((e) => e.status, 'status', 503)
              .having((e) => e.contentType, 'contentType', 'text/html')));
    });

    test('an empty or non-JSON success body is unavailable too', () {
      expect(
          () => decodeServerJson(http.Response('', 200), operation: 'status'),
          throwsA(isA<ScheduleServerUnavailable>()
              .having((e) => e.status, 'status', 200)));
    });

    test('JSON is decoded as before, whatever the status', () {
      expect(
          decodeServerJson(http.Response('{"Error":{"Code":"0"}}', 200),
              operation: 'status'),
          {
            'Error': {'Code': '0'}
          });
      expect(
          decodeServerJson(http.Response('{"Message":"denied"}', 401),
              operation: 'status'),
          {'Message': 'denied'});
    });
  });

  group('a change that cannot start', () {
    test('is not sent, and the user is told it was not sent', () async {
      final api = _UnreachableStatus()
        ..statusError = ScheduleServerUnavailable(status: 503);
      final bloc = ScheduleBloc(getContextCallBack: () => null)
        ..scheduleApi = api;
      final outcomes = <ScheduleChangeOutcome>[];
      final sub = bloc.outcomes.listen(outcomes.add);
      final inner = ControlledClient((_) async => response());
      final client =
          RetryHttpClient(scheduleLifecycle: () => bloc, innerClient: inner);

      await expectLater(
          bloc.runScheduleChange(() => client.post(complete),
              kind: ScheduleChangeKind.complete,
              eventName: 'Gym',
              affectedTileIds: ['t1']),
          throwsA(isA<ScheduleServerUnavailable>()));
      await flush();

      expect(inner.requests, isEmpty);
      expect(bloc.activeEvaluation, isNull);
      expect(bloc.scheduleChangesBlocked, isFalse);
      final told = outcomes.single;
      expect(told.kind, ScheduleChangeOutcomeKind.notSent);
      expect(told.evaluation.kind, ScheduleChangeKind.complete);
      expect(told.evaluation.eventName, 'Gym');
      expect(bloc.latestOutcome?.kind, ScheduleChangeOutcomeKind.notSent);

      // Once the server is back, the same change goes through.
      api.statusError = null;
      await bloc.runScheduleChange(() => client.post(complete),
          kind: ScheduleChangeKind.complete,
          eventName: 'Gym',
          affectedTileIds: ['t1']);
      expect(inner.requests, hasLength(1));
      await sub.cancel();
      client.close();
      await bloc.close();
    });

    testWidgets('its screen says it was not sent and offers Retry',
        (tester) async {
      final bloc = _Told(ScheduleChangeOutcome(
          ScheduleEvaluation(
              id: 'unsent',
              kind: ScheduleChangeKind.complete,
              account: 'user',
              startedAt: DateTime.now(),
              expiresAt: DateTime.now(),
              baseline: const ScheduleRevision(null, null),
              baselineObservedAt: DateTime.now(),
              eventName: 'Gym',
              affectedEventCount: 1),
          ScheduleChangeOutcomeKind.notSent));
      var retried = 0;
      await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
          value: bloc,
          child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                  body: Builder(
                      builder: (context) => TextButton(
                          onPressed: () => showScheduleChangeFailure(context,
                              kind: ScheduleChangeKind.complete,
                              eventName: 'Gym',
                              onRetry: () => retried++),
                          child: const Text('Report')))))));
      await tester.tap(find.text('Report'));
      await tester.pump();
      expect(find.text(l10n.scheduleChangeNotSent('${l10n.complete} · Gym')),
          findsOneWidget);
      await tester.pumpAndSettle(); // let the message finish sliding in
      await tester.tap(find.text(l10n.addTileRetry));
      expect(retried, 1, reason: 'nothing reached the server: Retry is safe');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(bloc.close);
    });
  });

  test('a re-check gives up on a silent server, keeping the cadence', () async {
    final api = FakeScheduleApi();
    final bloc = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: const ScheduleEvaluationConfig(
          reconcileFastInterval: Duration(milliseconds: 20),
          reconcileFastWindow: Duration(seconds: 1),
          reconcileReadTimeout: Duration(milliseconds: 30),
        ))
      ..scheduleApi = api;
    bloc.revisions.observe(api.status);
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: ControlledClient((_) async => response(503)));
    await expectLater(
        bloc.runScheduleChange(() => client.post(complete),
            kind: ScheduleChangeKind.complete),
        throwsA(isA<http.ClientException>()));
    final reads = api.statusReads;
    api.heldStatus = Completer<ScheduleStatus>(); // the server stops answering
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(api.statusReads - reads, greaterThanOrEqualTo(3),
        reason: 'each silent read gives up quickly, so checks continue');
    client.close();
    await bloc.close();
  });
}

class _Told extends ScheduleBloc {
  _Told(this.told) : super(getContextCallBack: () => null);
  final ScheduleChangeOutcome told;
  @override
  ScheduleChangeOutcome? get latestOutcome => told;
}
