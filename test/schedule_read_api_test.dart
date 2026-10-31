import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tuple/tuple.dart';
import 'schedule_evaluation_flow_test.dart' show ControlledClient;

class ReadAuthentication extends Authentication {
  ReadAuthentication(this.result);
  final Tuple2<bool, String> result;
  @override
  Future<Tuple2<bool, String>> isUserAuthenticated() async => result;
}

class _ReadApi extends ScheduleApi {
  _ReadApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map params,
          {bool includeLocationParams = false}) async =>
      Map<String, dynamic>.from(params);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScheduleApi api;
  final range =
      Timeline.fromDateTime(DateTime(2026, 10, 27), DateTime(2026, 10, 28));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = _ReadApi();
  });
  tearDown(() => api.dispose());

  test('missing credentials produce authentication failure, not empty events',
      () async {
    api.authentication = ReadAuthentication(const Tuple2(false, ''));
    await expectLater(api.getSubEvents(range),
        throwsA(isA<ScheduleAuthenticationRequired>()));
  });

  test('unreachable authentication service remains a retryable load failure',
      () async {
    api.authentication =
        ReadAuthentication(Tuple2(false, constants.cannotVerifyError));
    await expectLater(
        api.getSubEvents(range),
        throwsA(allOf(
            isA<TilerError>(), isNot(isA<ScheduleAuthenticationRequired>()))));
  });

  void respond(int status, String body) {
    api.authentication = ReadAuthentication(const Tuple2(true, ''))
      ..cachedCredentials = AuthenticationData.initializedWithRestData(
          'test-token', 'Bearer', 3600, 'tiler');
    api.httpClient.close();
    api.httpClient = RetryHttpClient(
        innerClient: ControlledClient((_) async => http.StreamedResponse(
            Stream.value(body.codeUnits), status,
            headers: {'content-type': 'application/json'})));
  }

  test('401 is an authentication failure even when its body looks empty',
      () async {
    respond(401, '{"Error":{"Code":"0"},"Content":{"subCalendarEvents":[]}}');
    await expectLater(api.getSubEvents(range),
        throwsA(isA<ScheduleAuthenticationRequired>()));
  });

  test('server failure is never accepted as a successful empty response',
      () async {
    respond(503, '{"Error":{"Code":"0"},"Content":{"subCalendarEvents":[]}}');
    await expectLater(
        api.getSubEvents(range), throwsA(isA<ScheduleServerUnavailable>()));
  });

  test('a valid empty schedule is successful data', () async {
    respond(200, '{"Error":{"Code":"0"},"Content":{"subCalendarEvents":[]}}');
    expect((await api.getSubEvents(range)).item2, isEmpty);
  });

  test('numeric success codes work for schedule reads and status', () async {
    respond(200,
        '{"Error":{"Code":0},"Content":{"subCalendarEvents":[],"evaluationId":"e"}}');
    expect((await api.getSubEvents(range)).item2, isEmpty);
    expect((await api.getScheduleStatus()).evaluationId, 'e');
  });

  for (final status in [401, 403, 500, 503]) {
    test('status HTTP $status cannot supply a mutation baseline', () async {
      respond(status, '{"Error":{"Code":"0"},"Content":{"evaluationId":"e"}}');
      await expectLater(
          api.getScheduleStatus(),
          throwsA(status < 500
              ? isA<ScheduleAuthenticationRequired>()
              : isA<ScheduleServerUnavailable>()));
    });
  }

  test('status with missing credentials reports authentication failure',
      () async {
    api.authentication = ReadAuthentication(const Tuple2(false, ''));
    await expectLater(api.getScheduleStatus(),
        throwsA(isA<ScheduleAuthenticationRequired>()));
  });

  test('malformed status content produces a controlled API error', () async {
    respond(200, '{"Error":{"Code":"0"},"Content":[]}');
    await expectLater(api.getScheduleStatus(), throwsA(isA<TilerError>()));
  });
}
