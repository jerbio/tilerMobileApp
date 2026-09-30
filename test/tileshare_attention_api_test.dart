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

import 'helpers/recording_http_client.dart';

const String _activityPage =
    '{"items":[{"eventId":"e1","schemaVersion":1,"eventType":"assignment_declined","clusterId":"c1","occurredAt":1760000000000}],"nextCursor":"abc","historyAvailableFrom":1}';

void main() {
  late RecordingHttpClient client;

  AuthenticationData credentials() =>
      AuthenticationData.initializedWithRestData(
          'test-token', 'Bearer', 3600, 'tiler');

  setUp(() => client = RecordingHttpClient());
  tearDown(() => client.close());

  group('TileShareInvitationsApi.getInvitations', () {
    late TileShareInvitationsApi api;

    setUp(() {
      api = TileShareInvitationsApi(getContextCallBack: () => null)
        ..authentication.cachedCredentials = credentials()
        ..httpClient = client;
    });

    test('GETs api/TileShare/Invitations with the paging keys', () async {
      client.nextBody = '{"invitations":[],"nextCursor":null}';
      await api.getInvitations(afterId: 'asg-9', pageSize: 25);
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
      await api.getInvitations();
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
      final page = await api.getInvitations();
      expect(page.items.single.assignmentId, 'a1');
      expect(page.items.single.inviterName, 'Sarah Kim');
      expect(page.nextCursor, 'a1');
    });

    test('401 / 403 / 404 are an access error, not a crash', () async {
      for (final status in [401, 403, 404]) {
        client.nextStatus = status;
        await expectLater(api.getInvitations(),
            throwsA(isA<TileShareInvitationsAccessException>()),
            reason: '$status');
      }
    });

    test('any other failure is a plain error', () async {
      client.nextStatus = 500;
      await expectLater(api.getInvitations(), throwsA(isA<StateError>()));
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
  });
}
