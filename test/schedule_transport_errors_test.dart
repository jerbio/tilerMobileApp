import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tuple/tuple.dart';

import 'schedule_evaluation_flow_test.dart'
    show FakeScheduleApi, ControlledClient, flush, response;

class _TestApi extends AppApi {
  _TestApi(ScheduleBloc bloc) : super(getContextCallBack: () => bloc) {
    authentication.cachedCredentials =
        AuthenticationData.initializedWithRestData(
            'test-token', 'Bearer', 3600, 'tiler');
  }

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
          {bool includeLocationParams = true}) async =>
      Map<String, dynamic>.from(jsonMap);
}

class _NoAuthentication extends Authentication {
  @override
  Future<Tuple2<bool, String>> isUserAuthenticated() async =>
      const Tuple2(false, 'No authentication');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScheduleBloc bloc;
  late _TestApi api;
  late ControlledClient wire;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bloc = ScheduleBloc(getContextCallBack: () => null)
      ..scheduleApi = FakeScheduleApi();
    bloc.revisions.observe((bloc.scheduleApi as FakeScheduleApi).status);
    api = _TestApi(bloc);
    api.httpClient.close();
    wire = ControlledClient((_) async => response());
    api.httpClient =
        RetryHttpClient(innerClient: wire, scheduleLifecycle: () => bloc);
  });

  tearDown(() async {
    api.dispose();
    if (!bloc.isClosed) await bloc.close();
  });

  Future<http.Response> send({bool put = false}) =>
      api.sendPostRequest('api/Schedule/Event/Complete', {},
          injectLocation: false, analyze: false, usePutRequest: put);

  // Headers arrive first, so the lifecycle has observed a sent write but
  // cannot yet settle it. Losing the response must remain uncertain.
  for (final put in [false, true]) {
    for (final error in <Object>[
      const SocketException('offline'),
      http.ClientException('reset'),
      TimeoutException('response timed out'),
    ]) {
      test(
          '${put ? 'PUT' : 'POST'} preserves ${error.runtimeType} through AppApi',
          () async {
        api.httpClient.close();
        wire = ControlledClient((_) async => throw error);
        // Bypass the response observer to exercise the callback's error
        // classification while still recording the send boundary.
        api.httpClient = RetryHttpClient(innerClient: wire);
        final original = Completer<http.StreamedResponse>();
        final pending = bloc.runScheduleChange(() async {
          unawaited(bloc
              .observeScheduleResponse(() => original.future,
                  kind: ScheduleChangeKind.complete)
              .catchError((Object _) => response()));
          await flush();
          return send(put: put);
        }, kind: ScheduleChangeKind.complete);
        await expectLater(pending, throwsA(isA<TilerError>()));
        await flush();
        expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
        expect(wire.requests, hasLength(1));
        original.complete(response());
        await flush();
      });
    }
  }

  for (final status in [400, 408, 500]) {
    test('AppApi HTTP $status keeps the lifecycle outcome', () async {
      api.httpClient.close();
      wire = ControlledClient((_) async => response(status));
      api.httpClient =
          RetryHttpClient(innerClient: wire, scheduleLifecycle: () => bloc);
      await expectLater(send(), throwsA(isA<TilerError>()));
      await flush();
      expect(
          bloc.activeEvaluation!.phase,
          status == 400
              ? ScheduleEvaluationPhase.failed
              : ScheduleEvaluationPhase.uncertain);
      expect(wire.requests, hasLength(1));
    });
  }

  test('pre-send preparation error fails without sending', () async {
    api.authentication = _NoAuthentication();
    await expectLater(send(), throwsA(isA<TilerError>()));
    expect(wire.requests, isEmpty);
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.failed);
  });

  testWidgets('request-level timeout stays uncertain and a late 2xx settles it',
      (tester) async {
    await tester.runAsync(bloc.close);
    bloc = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: const ScheduleEvaluationConfig(
            operationTimeout: Duration(minutes: 10)))
      ..scheduleApi = FakeScheduleApi();
    bloc.revisions.observe((bloc.scheduleApi as FakeScheduleApi).status);
    api.dispose();
    api = _TestApi(bloc);
    api.httpClient.close();
    final original = Completer<http.StreamedResponse>();
    wire = ControlledClient((_) => original.future);
    api.httpClient = RetryHttpClient(
        innerClient: wire,
        scheduleLifecycle: () => bloc,
        mutationTimeout: const Duration(minutes: 5));
    final result = expectLater(send(), throwsA(isA<TilerError>()));
    await tester.pump();
    expect(wire.requests, hasLength(1));
    await tester.pump(AppApi.requestTimeout);
    await result;
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
    original.complete(response());
    await tester.pump();
    expect(bloc.activeEvaluation, isNull);
    expect(wire.requests, hasLength(1));
    await tester.runAsync(bloc.close);
  });

  test('body failure after 2xx does not reverse confirmed success', () async {
    api.httpClient.close();
    wire = ControlledClient((_) async => http.StreamedResponse(
        Stream<List<int>>.error(const SocketException('body lost')), 202));
    api.httpClient =
        RetryHttpClient(innerClient: wire, scheduleLifecycle: () => bloc);
    await expectLater(send(), throwsA(isA<TilerError>()));
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(wire.requests, hasLength(1));
  });
}
