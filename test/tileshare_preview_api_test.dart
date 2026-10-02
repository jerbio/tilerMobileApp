// TileShare redesign Step 9.10 (T21): the accept-preview calls, tested at the
// HTTP level (route, verb, body keys, parsing, errors) against a recording
// client - no network.
//   POST api/DesignatedTile/Preview           - the preview
//   POST api/DesignatedTile/Preview/Options   - other times, a page at a time
//   POST api/DesignatedTile/Preview/Revise    - re-preview with a chosen option
//   POST api/DesignatedTile/status            - Accept, with PreviewToken + OperationId
//   GET  api/DesignatedTile/ResponseOperation - poll the accept
//   GET  api/DesignatedTile/Response          - recover an accepted response
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/recording_http_client.dart';
import 'helpers/tileshare_preview_fixtures.dart';

/// The real `injectRequestParams` reads the device (time zone, location); the
/// test adds the same keys with fixed values and remembers whether the call
/// asked for the location.
class _TestApi extends TileSharePreviewApi {
  final List<bool> locationAsks = [];

  _TestApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    locationAsks.add(includeLocationParams);
    return {
      ...Map<String, dynamic>.from(jsonMap),
      'TimeZone': 'UTC',
      'TimeZoneOffset': '0',
      'MobileApp': 'true',
      'UserLongitude': '0',
      'UserLatitude': '0',
      'UserLocationVerified': 'false',
    };
  }
}

/// The interval of the session being locked, as the preview showed it.
const _lock = const TileShareLockedTimeLine(startMs: 1789560000000, durationMs: 3600000);

void main() {
  late RecordingHttpClient client;
  late _TestApi api;
  late List<String> logs;
  late void Function(String) originalSink;

  setUp(() {
    client = RecordingHttpClient();
    api = _TestApi()
      ..authentication.cachedCredentials =
          AuthenticationData.initializedWithRestData(
              'test-token', 'Bearer', 3600, 'tiler')
      ..httpClient = client;
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() {
    client.close();
    TileShareLog.sink = originalSink;
  });

  Map<String, dynamic> sentBody() =>
      jsonDecode(client.last.body) as Map<String, dynamic>;

  group('preview', () {
    test('POSTs the assignment id, with who and where the user is', () async {
      client.nextBody = previewBody(previewFixture('preview_viable'));
      final p = await api.preview(kPreviewAssignmentId);
      final sent = client.last;
      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/DesignatedTile/Preview');
      expect(sent.headers['Authorization'], 'Bearer test-token');
      expect(sentBody()['Id'], kPreviewAssignmentId);
      expect(sentBody()['TimeZone'], 'UTC');
      expect(p.previewToken, kPreviewToken);
      expect(p.canAccept, isTrue);
    });

    test('asks for the user\'s location, because the forecast depends on it',
        () async {
      client.nextBody = previewBody(previewFixture('preview_viable'));
      await api.preview(kPreviewAssignmentId);
      expect(api.locationAsks, [true]);
    });

    test('parses a preview that is not viable', () async {
      client.nextBody = previewBody(previewFixture('preview_not_viable'));
      final p = await api.preview(kPreviewAssignmentId);
      expect(p.isViable, isFalse);
      expect(p.canAccept, isFalse);
      expect(p.conflicts, hasLength(1));
    });

    test('parses an unsupported one', () async {
      client.nextBody =
          previewBody(previewFixture('preview_unsupported_already_accepted'));
      final p = await api.preview(kPreviewAssignmentId);
      expect(p.unsupportedReason, PreviewUnsupportedReason.alreadyAccepted);
    });

    test('a response with no assignment in it is an error that says so, '
        'and is logged', () async {
      client.nextBody = previewBody({'something': 'else'});
      Object? caught;
      try {
        await api.preview(kPreviewAssignmentId);
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<StateError>());
      expect(caught.toString(), contains('assignmentId'));
      expect(logs.any((l) => l.contains('assignmentId')), isTrue, reason: '$logs');
    });

    test('a Tiler-level error inside a 200 carries its message', () async {
      client.nextBody = previewBody(null, code: '7', message: 'no preview today');
      await expectLater(api.preview(kPreviewAssignmentId),
          throwsA(predicate((e) => e.toString().contains('no preview today'))));
    });
  });

  group('other times', () {
    test('POSTs the token, the session and where to start', () async {
      client.nextBody = previewBody(previewFixture('options_page'));
      final page = await api.options(
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          sessionKey: '0',
          offset: 4);
      expect(client.last.url.path, '/api/DesignatedTile/Preview/Options');
      final body = sentBody();
      expect(body['Id'], kPreviewAssignmentId);
      expect(body['PreviewToken'], kPreviewToken);
      expect(body['SessionKey'], '0');
      expect(body['Offset'], 4);
      expect(page.options, hasLength(4));
      expect(page.nextOffset, 4);
      expect(page.options.first.preview!.previewToken,
          page.options.first.optionId);
    });

    test('starts at zero by default', () async {
      client.nextBody = previewBody(previewFixture('options_last_page'));
      final page = await api.options(
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          sessionKey: '0');
      expect(sentBody()['Offset'], 0);
      expect(page.hasMore, isFalse);
    });

    test('a response with no options list is an error', () async {
      client.nextBody = previewBody({'nextOffset': 4});
      await expectLater(
          api.options(
              assignmentId: kPreviewAssignmentId,
              previewToken: kPreviewToken,
              sessionKey: '0'),
          throwsA(isA<StateError>()));
    });
  });

  group('revise', () {
    test('choosing an option sends its id and nothing about locking',
        () async {
      client.nextBody = previewBody(previewFixture('revise_moved'));
      final p = await api.revise(
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          optionId: 'opt-1');
      expect(client.last.url.path, '/api/DesignatedTile/Preview/Revise');
      final body = sentBody();
      expect(body['Id'], kPreviewAssignmentId);
      expect(body['PreviewToken'], kPreviewToken);
      expect(body['OptionId'], 'opt-1');
      expect(body.containsKey('Fixed'), isFalse);
      expect(body.containsKey('SessionKey'), isFalse);
      expect(p.previewToken, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      expect(p.sessions.single.startMs, isNot(
          TileSharePreview.fromJson(previewFixture('preview_viable'))
              .sessions.single.startMs));
    });

    test('locking a session is available to the API (the screen keeps it '
        'off)', () async {
      client.nextBody = previewBody(previewFixture('revise_moved'));
      await api.revise(
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          sessionKey: '0',
          fixed: true);
      expect(sentBody()['SessionKey'], '0');
      expect(sentBody()['Fixed'], true);
    });
  });

  group('accept', () {
    test('sends Status accepted with the token and an operation id', () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      final op = await api.accept(
          mode: TileShareAcceptanceMode.flexible,
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      expect(client.last.url.path, '/api/DesignatedTile/status');
      final body = sentBody();
      expect(body['Id'], kPreviewAssignmentId);
      expect(body['Status'], 'accepted');
      expect(body['PreviewToken'], kPreviewToken);
      expect(body['OperationId'], kPreviewOperationId);
      expect(op.state, OperationState.queued);
      expect(op.operationId, kPreviewOperationId);
    });

    test('Accept is Flexible: the mode is named and there is no lock target',
        () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      await api.accept(
          mode: TileShareAcceptanceMode.flexible,
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      final body = sentBody();
      expect(body['AcceptanceMode'], 'Flexible');
      expect(body.containsKey('SessionKey'), isFalse);
    });

    test('Accept and lock names the one session to fix', () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      await api.accept(
          mode: TileShareAcceptanceMode.lockSession,
          lockedTimeLine: _lock,
          sessionKey: '1',
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      final body = sentBody();
      expect(body['Status'], 'accepted');
      expect(body['AcceptanceMode'], 'LockSession');
      expect(body['SessionKey'], '1');
      expect(body['PreviewToken'], kPreviewToken);
    });

    test('Accept and lock also sends the interval it locks, which the server '
        'checks against its own stored session', () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      await api.accept(
          mode: TileShareAcceptanceMode.lockSession,
          lockedTimeLine: _lock,
          sessionKey: '0',
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      expect(sentBody()['LockedTimeLineRequest'], {
        'StartTimeUnixMsUtc': 1789560000000,
        'DurationInMs': 3600000,
      });
      expect(sentBody()['AcceptanceMode'], 'LockSession');
      expect(sentBody()['SessionKey'], '0');
    });

    test('a flexible accept never carries a lock interval', () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      await api.accept(
          mode: TileShareAcceptanceMode.flexible,
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      expect(sentBody().containsKey('LockedTimeLineRequest'), isFalse);
    });

    test('locking without the interval is refused before sending (the server '
        'would answer 400)', () async {
      await expectLater(
          api.accept(
              mode: TileShareAcceptanceMode.lockSession,
              sessionKey: '0',
              assignmentId: kPreviewAssignmentId,
              previewToken: kPreviewToken,
              operationId: kPreviewOperationId),
          throwsA(isA<ArgumentError>()));
      expect(client.requests, isEmpty);
    });

    test('an interval with no length is refused before sending', () async {
      for (final d in [0, -60000]) {
        await expectLater(
            api.accept(
                mode: TileShareAcceptanceMode.lockSession,
                sessionKey: '0',
                lockedTimeLine:
                    TileShareLockedTimeLine(startMs: 1789560000000, durationMs: d),
                assignmentId: kPreviewAssignmentId,
                previewToken: kPreviewToken,
                operationId: kPreviewOperationId),
            throwsA(isA<ArgumentError>()),
            reason: '$d');
      }
      expect(client.requests, isEmpty);
    });

    test('a flexible accept with an interval is refused before sending',
        () async {
      await expectLater(
          api.accept(
              mode: TileShareAcceptanceMode.flexible,
              lockedTimeLine: _lock,
              assignmentId: kPreviewAssignmentId,
              previewToken: kPreviewToken,
              operationId: kPreviewOperationId),
          throwsA(isA<ArgumentError>()));
      expect(client.requests, isEmpty);
    });

    test('the accept answers with the operation, which may already be final '
        '(the server finishes scheduling inside the request)', () async {
      client.nextBody = previewBody(previewFixture('operation_completed'));
      final op = await api.accept(
          mode: TileShareAcceptanceMode.lockSession,
          lockedTimeLine: _lock,
          sessionKey: '0',
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      expect(op.isFinal, isTrue);
      expect(op.succeeded, isTrue);
      expect(op.calendarId, isNotNull);
    });

    test('locking without saying which session is refused before sending',
        () async {
      for (final key in [null, '', '  ']) {
        await expectLater(
            api.accept(
                mode: TileShareAcceptanceMode.lockSession,
                lockedTimeLine: _lock,
                sessionKey: key,
                assignmentId: kPreviewAssignmentId,
                previewToken: kPreviewToken,
                operationId: kPreviewOperationId),
            throwsA(isA<ArgumentError>()),
            reason: '"$key"');
      }
      expect(client.requests, isEmpty);
    });

    test('a flexible accept with a lock target is refused before sending '
        '(the server would answer 400)', () async {
      await expectLater(
          api.accept(
              mode: TileShareAcceptanceMode.flexible,
              sessionKey: '0',
              assignmentId: kPreviewAssignmentId,
              previewToken: kPreviewToken,
              operationId: kPreviewOperationId),
          throwsA(isA<ArgumentError>()));
      expect(client.requests, isEmpty);
    });

    test('a retry keeps its mode and session, so the server accepts it as '
        'the same command', () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      for (var i = 0; i < 2; i++) {
        await api.accept(
            mode: TileShareAcceptanceMode.lockSession,
            lockedTimeLine: _lock,
            sessionKey: '1',
            assignmentId: kPreviewAssignmentId,
            previewToken: kPreviewToken,
            operationId: kPreviewOperationId);
      }
      final a = jsonDecode((client.requests[0] as dynamic).body);
      final b = jsonDecode((client.requests[1] as dynamic).body);
      expect([
        a['OperationId'],
        a['AcceptanceMode'],
        a['SessionKey'],
        a['LockedTimeLineRequest']
      ], [
        b['OperationId'],
        b['AcceptanceMode'],
        b['SessionKey'],
        b['LockedTimeLineRequest']
      ]);
    });

    test('a new operation id is 32 hex characters, and different each time',
        () {
      final a = TileSharePreviewApi.newOperationId();
      final b = TileSharePreviewApi.newOperationId();
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(b, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });

    test('the same operation id can be sent again (a retry is idempotent on '
        'the server)', () async {
      client.nextBody = previewBody(previewFixture('operation_queued'));
      await api.accept(
          mode: TileShareAcceptanceMode.flexible,
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      await api.accept(
          mode: TileShareAcceptanceMode.flexible,
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: kPreviewOperationId);
      expect(client.requests, hasLength(2));
      expect(jsonDecode((client.requests[0] as dynamic).body)['OperationId'],
          jsonDecode((client.requests[1] as dynamic).body)['OperationId']);
    });

    test('refuses to accept without a token (plain Accept is another call)',
        () async {
      await expectLater(
          api.accept(
              mode: TileShareAcceptanceMode.flexible,
              assignmentId: kPreviewAssignmentId,
              previewToken: '',
              operationId: kPreviewOperationId),
          throwsA(isA<ArgumentError>()));
      expect(client.requests, isEmpty);
    });

    test('refuses an operation id that is not 32 hex characters', () async {
      await expectLater(
          api.accept(
              mode: TileShareAcceptanceMode.flexible,
              assignmentId: kPreviewAssignmentId,
              previewToken: kPreviewToken,
              operationId: 'not-hex'),
          throwsA(isA<ArgumentError>()));
      expect(client.requests, isEmpty);
    });
  });

  group('polling and recovery', () {
    test('GETs the operation by id', () async {
      client.nextBody = previewBody(previewFixture('operation_completed'));
      final op = await api.operation(kPreviewOperationId);
      expect(client.last.method, 'GET');
      expect(client.last.url.path, '/api/DesignatedTile/ResponseOperation');
      expect(client.last.url.queryParameters['id'], kPreviewOperationId);
      expect(client.last.headers['Authorization'], 'Bearer test-token');
      expect(op.succeeded, isTrue);
    });

    test('GETs an accepted response by assignment id', () async {
      client.nextBody = previewBody(previewFixture('response_accepted'));
      final r = await api.response(kPreviewAssignmentId);
      expect(client.last.url.path, '/api/DesignatedTile/Response');
      expect(client.last.url.queryParameters['id'], kPreviewAssignmentId);
      expect(r.isAccepted, isTrue);
      expect(r.calendarId, isNotNull);
    });
  });

  group('failures', () {
    Future<TileSharePreviewFailure> failure(Future<Object?> call) async {
      try {
        await call;
      } catch (e) {
        if (e is TileSharePreviewFailure) return e;
        rethrow;
      }
      fail('expected a failure');
    }

    test('404 is "gone": no access, or no longer there', () async {
      client.nextStatus = 404;
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.notFound);
      expect(f.statusCode, 404);
    });

    test('401 is "sign in again"', () async {
      client.nextStatus = 401;
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.unauthorized);
    });

    test('503 is "previews are switched off"', () async {
      client.nextStatus = 503;
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.unavailable);
    });

    test('400 is an invalid request', () async {
      client.nextStatus = 400;
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.invalid);
    });

    test('any other failure is a server error', () async {
      client.nextStatus = 500;
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.server);
      expect(f.statusCode, 500);
    });

    test('409 carries the reason the server gave', () async {
      for (final reason in [
        'previewExpired',
        'scheduleChanged',
        'assignmentChanged',
        'responseInProgress',
        'invalidProposal',
        'operationMismatch',
      ]) {
        client.nextStatus = 409;
        client.nextBody = previewConflictBody(reason);
        final f = await failure(api.accept(
            mode: TileShareAcceptanceMode.flexible,
            assignmentId: kPreviewAssignmentId,
            previewToken: kPreviewToken,
            operationId: kPreviewOperationId));
        expect(f.kind, PreviewFailureKind.conflict, reason: reason);
        expect(f.reason, reason);
        expect(f.toString(), contains(reason));
      }
    });

    test('the lock-specific conflicts keep their reason', () async {
      for (final reason in ['invalidSession', 'operationMismatch']) {
        client.nextStatus = 409;
        client.nextBody = previewConflictBody(reason);
        final f = await failure(api.accept(
            mode: TileShareAcceptanceMode.lockSession,
            lockedTimeLine: _lock,
            sessionKey: '9',
            assignmentId: kPreviewAssignmentId,
            previewToken: kPreviewToken,
            operationId: kPreviewOperationId));
        expect(f.kind, PreviewFailureKind.conflict);
        expect(f.reason, reason);
      }
    });

    test('a 409 with a body we cannot read still says it was a conflict',
        () async {
      client.nextStatus = 409;
      client.nextBody = 'The assignment changed. Refresh and try again.';
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.conflict);
      expect(f.reason, contains('assignment changed'));
    });

    test('every call fails the same way', () async {
      client.nextStatus = 409;
      client.nextBody = previewConflictBody('previewExpired');
      // Started one at a time, so none fails before it is awaited.
      final calls = <Future<Object?> Function()>[
        () => api.options(
            assignmentId: kPreviewAssignmentId,
            previewToken: kPreviewToken,
            sessionKey: '0'),
        () => api.revise(
            assignmentId: kPreviewAssignmentId,
            previewToken: kPreviewToken,
            optionId: 'o'),
        () => api.operation(kPreviewOperationId),
        () => api.response(kPreviewAssignmentId),
      ];
      for (final call in calls) {
        expect((await failure(call())).reason, 'previewExpired');
      }
    });

    test('not signed in fails before anything is sent', () async {
      api.authentication.cachedCredentials = null;
      final f = await failure(api.preview(kPreviewAssignmentId));
      expect(f.kind, PreviewFailureKind.unauthorized);
      expect(client.requests, isEmpty);
    });

    test('a failing call is logged with its route, status and reason',
        () async {
      client.nextStatus = 409;
      client.nextBody = previewConflictBody('previewExpired');
      await failure(api.revise(
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          optionId: 'o'));
      expect(
          logs.any((l) =>
              l.contains('Preview/Revise') &&
              l.contains('409') &&
              l.contains('previewExpired')),
          isTrue,
          reason: '$logs');
    });

    test('a successful call logs nothing', () async {
      client.nextBody = previewBody(previewFixture('preview_viable'));
      await api.preview(kPreviewAssignmentId);
      expect(logs, isEmpty);
    });
  });
}
