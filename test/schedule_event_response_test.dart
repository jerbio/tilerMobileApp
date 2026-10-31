import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tiler_app/bloc/schedule/schedule_evaluation.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileSubmission.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/scheduleEventResponse.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tuple/tuple.dart';

class _Authenticated extends Authentication {
  _Authenticated() {
    cachedCredentials = AuthenticationData.initializedWithRestData(
        'test-token', 'Bearer', 3600, 'tiler');
  }
  @override
  Future<Tuple2<bool, String>> isUserAuthenticated() async =>
      const Tuple2(true, '');
}

class _Api extends ScheduleApi {
  _Api(String body, {int status = 200})
      : super(getContextCallBack: () => null) {
    authentication = _Authenticated();
    httpClient.close();
    httpClient = RetryHttpClient(innerClient: MockClient((request) async {
      expect(request.url.path, '/api/Schedule/Event');
      return http.Response(body, status);
    }));
  }

  @override
  Future<void> checkAndReplaceCredentialCache() async {}

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map params,
          {bool includeLocationParams = true}) async =>
      Map<String, dynamic>.from(params);
}

class _MissingBaselineApi extends ScheduleApi {
  _MissingBaselineApi() : super(getContextCallBack: () => null);

  @override
  Future<Tuple2<SubCalendarEvent?, TilerError?>> addNewTile(
      NewTile tile) async {
    throw ScheduleInitializationFailed();
  }
}

final event = <String, dynamic>{
  'id': 'created-1',
  'name': 'Plan the week',
  'start': 1792544400000,
  'end': 1792548000000,
};
Map<String, dynamic> ok(Object? content) => {
      'Error': {'Code': '0', 'Message': 'Success'},
      'Content': content,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing baseline surfaces refresh guidance instead of a timeout',
      () async {
    final api = _MissingBaselineApi();
    addTearDown(api.dispose);
    final result =
        await ApiAddTileSubmission(scheduleApi: api).create(NewTile());
    expect(result.failed, isTrue);
    expect(result.tile, isNull);
    expect(result.reasonCode, 'api_rejected');
    expect(result.message, ScheduleInitializationFailed().Message);
  });

  for (final rigid in [false, true]) {
    test('API and submission unwrap the current response (rigid=$rigid)',
        () async {
      final api = _Api(jsonEncode(ok({
        'tilerEvent': {...event, 'isRigid': rigid},
        'subEvents': [],
        'responseTimeline': {'start': 0, 'end': 1},
        'idempotencyKey': 'request-1',
        'futureField': true,
      })));
      addTearDown(api.dispose);
      final result = await ApiAddTileSubmission(scheduleApi: api)
          .create(NewTile()..Rigid = rigid.toString());
      expect(result.failed, isFalse);
      expect(result.tile!.id, event['id']);
      expect(result.tile!.name, event['name']);
      expect(result.tile!.isRigid, rigid);
      expect(result.tile!.start, event['start']);
    });
  }

  test('legacy response supports parent duration as an integer or double', () {
    for (final duration in <num>[3600000, 3600000.0]) {
      final created = parseCreatedScheduleEvent(
          jsonEncode(ok({
            ...event,
            'calendarEvent': {
              ...event,
              'id': 'parent',
              'eachTileDuration': duration
            },
          })),
          status: 200);
      expect(created.calendarEvent!.id, 'parent');
    }
  });

  test('null parent and numeric success codes are supported', () {
    final response = ok({...event, 'calendarEvent': null});
    response['Error'] = {'Code': 0};
    expect(parseCreatedScheduleEvent(jsonEncode(response), status: 200).id,
        event['id']);
  });

  final incompatible = <Object?>[
    null,
    [],
    {},
    {'Error': null},
    {'Error': []},
    {
      'Error': {'Code': null}
    },
    {
      'Error': {'Code': false}
    },
    {'Content': event},
    ok(null),
    ok([]),
    ok('Success'),
    ok({
      'subEvents': [event]
    }),
    ok({'tilerEvent': null}),
    ok({'tilerEvent': [], ...event}),
    ok({...event, 'id': ''}),
    ok({...event, 'name': {}}),
    ok({...event, 'start': '1792544400000'}),
    ok({...event, 'end': 1}),
    ok({...event, 'start': 8640000000000001}),
    ok({...event, 'calendarEvent': []}),
    ok({...event, 'calendarEvent': {}}),
    ok({...event, 'isRigid': 'true'}),
  ];
  for (var i = 0; i < incompatible.length; i++) {
    test('incompatible contract $i becomes a controlled error', () {
      expect(
          () => parseCreatedScheduleEvent(jsonEncode(incompatible[i]),
              status: 200),
          throwsA(isA<ScheduleEventResponseError>()));
    });
  }

  test('invalid JSON and HTTP failures never report success', () {
    expect(
        () =>
            parseCreatedScheduleEvent('<html>Bad gateway</html>', status: 502),
        throwsA(isA<ScheduleEventResponseError>()));
    expect(() => parseCreatedScheduleEvent(jsonEncode(ok(event)), status: 500),
        throwsA(isA<TilerError>()));
  });

  test('API rejection preserves its error even with HTTP 200', () {
    expect(
        () => parseCreatedScheduleEvent(
            jsonEncode({
              'Error': {'Code': '42', 'Message': 'Schedule is locked'},
              'Content': event,
            }),
            status: 200),
        throwsA(isA<TilerError>().having(
            (error) => error.Message, 'message', 'Schedule is locked')));
  });

  test('malformed API response surfaces a message and never returns success',
      () async {
    final api = _Api(jsonEncode(ok({
      'subEvents': [event]
    })));
    addTearDown(api.dispose);
    final result =
        await ApiAddTileSubmission(scheduleApi: api).create(NewTile());
    expect(result.failed, isTrue);
    expect(result.tile, isNull);
    expect(result.message, contains('Check your schedule'));
  });
}
