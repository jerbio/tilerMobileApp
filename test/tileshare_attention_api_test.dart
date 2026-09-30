// TileShare redesign Step 9.4: the two server calls Attention needs.
//   * GET  api/TileShare/Invitations        — my pending invitations (new);
//   * GET  api/TileShare/Activity           — now also PageSize / EventType /
//                                              DismissedOnly;
//   * POST api/TileShare/Activity/Dismissal — dismiss / restore one event (new).
// Tested at the HTTP level (route, verb, query keys, body, parsing, errors)
// against a recording client — no network.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/tileShareActivityApi.dart';
import 'package:tiler_app/services/api/tileShareInvitationsApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/recording_http_client.dart';

const String _activityPage =
    '{"items":[{"eventId":"e1","schemaVersion":1,"eventType":"assignment_declined","clusterId":"c1","occurredAt":1760000000000}],"nextCursor":"abc","historyAvailableFrom":1}';

/// What the deployed backend really sends: every TileShare read goes through
/// `PrivateOkResponse` -> `PostBackData`, so the payload is wrapped in
/// `{Error, Content}` like every other Tiler endpoint.
String _enveloped(Object? content,
        {String code = '0', String message = 'SUCCESS'}) =>
    jsonEncode({
      'Error': {'Code': code, 'Message': message},
      'Content': content,
    });

void main() {
  late RecordingHttpClient client;

  AuthenticationData credentials() =>
      AuthenticationData.initializedWithRestData(
          'test-token', 'Bearer', 3600, 'tiler');

  late List<String> logs;
  late void Function(String) originalSink;

  setUp(() {
    client = RecordingHttpClient();
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() {
    client.close();
    TileShareLog.sink = originalSink;
  });

  group('TileShareInvitationsApi.getInvitations', () {
    late TileShareInvitationsApi api;

    setUp(() {
      api = TileShareInvitationsApi(getContextCallBack: () => null)
        ..authentication.cachedCredentials = credentials()
        ..httpClient = client;
    });

    test('GETs api/TileShare/Invitations with the paging keys', () async {
      client.nextBody = '{"invitations":[],"nextCursor":null}';
      await api.getInvitations(clusterId: 'c1', afterId: 'asg-9', pageSize: 25);
      final sent = client.last;
      expect(sent.method, 'GET');
      expect(sent.url.path, '/api/TileShare/Invitations');
      expect(sent.url.queryParameters['PageSize'], '25');
      expect(sent.url.queryParameters['AfterId'], 'asg-9');
      expect(sent.headers['Authorization'], 'Bearer test-token');
    });

    test('omits AfterId on the first page and defaults the page size',
        () async {
      client.nextBody = '{"invitations":[]}';
      await api.getInvitations(clusterId: 'c1');
      expect(client.last.url.queryParameters.containsKey('AfterId'), isFalse);
      expect(client.last.url.queryParameters['PageSize'], '50');
    });

    test('scopes to a cluster when asked', () async {
      client.nextBody = '{"invitations":[]}';
      await api.getInvitations(clusterId: 'c7');
      expect(client.last.url.queryParameters['ClusterId'], 'c7');
    });

    test('parses the invitations and the cursor', () async {
      client.nextBody = jsonEncode({
        'invitations': [
          {
            'assignmentId': 'a1',
            'clusterId': 'c1',
            'tiletteId': 't1',
            'name': 'Review PR',
            'clusterName': 'Sprint',
            'deadline': 1760000000000,
            'inviterName': 'Sarah Kim',
          }
        ],
        'nextCursor': 'a1',
      });
      final page = await api.getInvitations(clusterId: 'c1');
      expect(page.items.single.assignmentId, 'a1');
      expect(page.items.single.inviterName, 'Sarah Kim');
      expect(page.nextCursor, 'a1');
    });

    test('401 / 403 / 404 are an access error, not a crash', () async {
      for (final status in [401, 403, 404]) {
        client.nextStatus = status;
        await expectLater(api.getInvitations(clusterId: 'c1'),
            throwsA(isA<TileShareInvitationsAccessException>()),
            reason: '$status');
      }
    });

    test('any other failure is a plain error', () async {
      client.nextStatus = 500;
      await expectLater(api.getInvitations(clusterId: 'c1'), throwsA(isA<StateError>()));
    });

    test('the error says which HTTP status it was, so a 404 (endpoint not '
        'deployed) is told apart from a 401 or a 500', () async {
      client.nextStatus = 404;
      Object? caught;
      try {
        await api.getInvitations(clusterId: 'c1');
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<TileShareInvitationsAccessException>());
      expect((caught as TileShareInvitationsAccessException).statusCode, 404);
      expect(caught.toString(), contains('404'));

      client.nextStatus = 500;
      Object? plain;
      try {
        await api.getInvitations(clusterId: 'c1');
      } catch (e) {
        plain = e;
      }
      expect(plain.toString(), contains('500'));
    });

    test('a failing call is logged with the route and the status', () async {
      client.nextStatus = 404;
      await expectLater(api.getInvitations(clusterId: 'c1'), throwsA(anything));
      expect(
          logs.any((l) =>
              l.contains('api/TileShare/Invitations') && l.contains('404')),
          isTrue,
          reason: '$logs');
    });

    test('a successful call logs nothing', () async {
      client.nextBody = '{"invitations":[]}';
      await api.getInvitations(clusterId: 'c1');
      expect(logs, isEmpty);
    });

    test('the unscoped call the server answers with a project summary is '
        'refused loudly by the flat reader, naming what it found', () async {
      client.nextBody = _enveloped({
        'projects': [
          {'clusterId': 'c1', 'name': 'Sprint', 'pendingCount': 2}
        ],
        'nextCursor': null,
      });
      Object? caught;
      try {
        await api.getInvitations(clusterId: 'c1');
      } catch (e) {
        caught = e;
      }
      expect(caught.toString(), contains('projects'));
    });

    test('reads the backend envelope: invitations live under Content',
        () async {
      client.nextBody = _enveloped({
        'invitations': [
          {
            'assignmentId': 'a1',
            'clusterId': 'c1',
            'tiletteId': 't1',
            'name': 'Review PR',
            'clusterName': 'Sprint',
            'deadline': 1760000000000,
            'inviterName': 'Sarah Kim',
          }
        ],
        'nextCursor': 'a1',
      });
      final page = await api.getInvitations(clusterId: 'c1');
      expect(page.items.single.assignmentId, 'a1');
      expect(page.nextCursor, 'a1');
      expect(logs, isEmpty);
    });

    test('a numeric success code is accepted too', () async {
      client.nextBody = jsonEncode({
        'Error': {'Code': 0, 'Message': 'SUCCESS'},
        'Content': {'invitations': []},
      });
      expect((await api.getInvitations(clusterId: 'c1')).items, isEmpty);
    });

    test('an empty envelope is a real, empty inbox', () async {
      client.nextBody = _enveloped({'invitations': [], 'nextCursor': null});
      final page = await api.getInvitations(clusterId: 'c1');
      expect(page.items, isEmpty);
    });

    test('a response with no invitations list is an error, not an empty '
        'inbox', () async {
      client.nextBody = _enveloped({'something': 'else'});
      await expectLater(api.getInvitations(clusterId: 'c1'), throwsA(isA<StateError>()));
      expect(logs.any((l) => l.contains('invitations')), isTrue,
          reason: '$logs');
    });

    test('a Tiler-level error inside a 200 is an error with its message',
        () async {
      client.nextBody = _enveloped(null, code: '7', message: 'no way');
      Object? caught;
      try {
        await api.getInvitations(clusterId: 'c1');
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<StateError>());
      expect(caught.toString(), contains('no way'));
      expect(logs.any((l) => l.contains('no way')), isTrue, reason: '$logs');
    });
  });

  group('TileShareInvitationsApi.getInvitationProjects', () {
    late TileShareInvitationsApi api;

    setUp(() {
      api = TileShareInvitationsApi(getContextCallBack: () => null)
        ..authentication.cachedCredentials = credentials()
        ..httpClient = client;
    });

    test('GETs Invitations with no scope, only the paging keys', () async {
      client.nextBody = _enveloped({'projects': [], 'nextCursor': null});
      await api.getInvitationProjects(afterId: 'c-9', pageSize: 30);
      final sent = client.last;
      expect(sent.method, 'GET');
      expect(sent.url.path, '/api/TileShare/Invitations');
      expect(sent.url.queryParameters.keys.toSet(), {'PageSize', 'AfterId'});
      expect(sent.url.queryParameters['PageSize'], '30');
      expect(sent.url.queryParameters['AfterId'], 'c-9');
    });

    test('parses each project and the cursor from the envelope', () async {
      client.nextBody = _enveloped({
        'projects': [
          {'clusterId': 'c1', 'name': 'Sprint', 'pendingCount': 3},
          {'clusterId': 'c2', 'name': 'Class 101', 'pendingCount': 1},
        ],
        'nextCursor': 'c2',
      });
      final page = await api.getInvitationProjects();
      expect(page.items.map((p) => p.clusterId), ['c1', 'c2']);
      expect(page.items.first.name, 'Sprint');
      expect(page.items.first.pendingCount, 3);
      expect(page.nextCursor, 'c2');
      expect(logs, isEmpty);
    });

    test('no projects is a real, empty inbox', () async {
      client.nextBody = _enveloped({'projects': [], 'nextCursor': null});
      expect((await api.getInvitationProjects()).items, isEmpty);
    });

    test('a response with no projects list is an error naming what it found',
        () async {
      client.nextBody = _enveloped({'invitations': []});
      Object? caught;
      try {
        await api.getInvitationProjects();
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<StateError>());
      expect(caught.toString(), contains('projects'));
      expect(caught.toString(), contains('invitations'));
    });

    test('failures carry the status and are logged like the other calls',
        () async {
      client.nextStatus = 404;
      Object? caught;
      try {
        await api.getInvitationProjects();
      } catch (e) {
        caught = e;
      }
      expect((caught as TileShareInvitationsAccessException).statusCode, 404);
      expect(logs.any((l) => l.contains('404')), isTrue, reason: '$logs');
    });
  });

  group('TileShareActivityApi.getActivity (new filters)', () {
    late TileShareActivityApi api;

    setUp(() {
      api = TileShareActivityApi(getContextCallBack: () => null)
        ..authentication.cachedCredentials = credentials()
        ..httpClient = client;
    });

    test('sends PageSize, EventType and DismissedOnly when given', () async {
      client.nextBody = _activityPage;
      await api.getActivity(
          clusterId: 'c1',
          cursor: 'cur',
          pageSize: 40,
          eventType: 'assignment_declined',
          dismissedOnly: true);
      final q = client.last.url.queryParameters;
      expect(client.last.url.path, '/api/TileShare/Activity');
      expect(q['ClusterId'], 'c1');
      expect(q['Cursor'], 'cur');
      expect(q['PageSize'], '40');
      expect(q['EventType'], 'assignment_declined');
      expect(q['DismissedOnly'], 'true');
    });

    test('the existing call is unchanged: no new keys unless asked', () async {
      client.nextBody = _activityPage;
      await api.getActivity(clusterId: 'c1');
      final q = client.last.url.queryParameters;
      expect(q.keys.toSet(), {'ClusterId'});
    });

    test('parses items and the next cursor', () async {
      client.nextBody = _activityPage;
      final page = await api.getActivity();
      expect(page.items.single.eventId, 'e1');
      expect(page.nextCursor, 'abc');
    });

    test('access errors still surface as the access exception', () async {
      client.nextStatus = 404;
      await expectLater(api.getActivity(),
          throwsA(isA<TileShareActivityAccessException>()));
    });

    test('the access error carries the HTTP status and is logged', () async {
      client.nextStatus = 403;
      Object? caught;
      try {
        await api.getActivity();
      } catch (e) {
        caught = e;
      }
      expect((caught as TileShareActivityAccessException).statusCode, 403);
      expect(caught.toString(), contains('403'));
      expect(
          logs.any((l) => l.contains('api/TileShare/Activity') && l.contains('403')),
          isTrue,
          reason: '$logs');
    });

    test('a server error names its status', () async {
      client.nextStatus = 500;
      Object? caught;
      try {
        await api.getActivity();
      } catch (e) {
        caught = e;
      }
      expect(caught.toString(), contains('500'));
    });

    test('reads the backend envelope: the page lives under Content', () async {
      client.nextBody = _enveloped(jsonDecode(_activityPage));
      final page = await api.getActivity();
      expect(page.items.single.eventId, 'e1');
      expect(page.nextCursor, 'abc');
      expect(page.historyAvailableFrom, 1);
    });

    test('a response with no items list says so instead of a cast error',
        () async {
      client.nextBody = _enveloped({'nothing': 'here'});
      Object? caught;
      try {
        await api.getActivity();
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<StateError>());
      expect(caught.toString(), contains('items'));
      expect(logs.any((l) => l.contains('items')), isTrue, reason: '$logs');
    });

    test('a Tiler-level error inside a 200 is an error with its message',
        () async {
      client.nextBody = _enveloped(null, code: '9', message: 'feed off');
      Object? caught;
      try {
        await api.getActivity();
      } catch (e) {
        caught = e;
      }
      expect(caught.toString(), contains('feed off'));
    });
  });

  group('TileShareActivityApi.setDismissed', () {
    late TileShareActivityApi api;

    setUp(() {
      api = TileShareActivityApi(getContextCallBack: () => null)
        ..authentication.cachedCredentials = credentials()
        ..httpClient = client;
    });

    test('POSTs the event id and the flag to Activity/Dismissal', () async {
      await api.setDismissed('evt-1', true);
      final sent = client.last;
      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/TileShare/Activity/Dismissal');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['EventId'], 'evt-1');
      expect(body['IsDismissed'], true);
      expect(sent.headers['Authorization'], 'Bearer test-token');
    });

    test('restoring sends IsDismissed: false', () async {
      await api.setDismissed('evt-1', false);
      expect((jsonDecode(client.last.body) as Map)['IsDismissed'], false);
    });

    test('401 / 403 / 404 are the access exception; other failures plain',
        () async {
      client.nextStatus = 404;
      await expectLater(api.setDismissed('e', true),
          throwsA(isA<TileShareActivityAccessException>()));
      client.nextStatus = 500;
      await expectLater(api.setDismissed('e', true), throwsA(isA<StateError>()));
    });

    test('a refused dismissal is logged with the route, the status and the '
        'event', () async {
      client.nextStatus = 404;
      await expectLater(api.setDismissed('evt-9', true), throwsA(anything));
      expect(
          logs.any((l) =>
              l.contains('Activity/Dismissal') &&
              l.contains('404') &&
              l.contains('evt-9')),
          isTrue,
          reason: '$logs');
    });
  });
}
