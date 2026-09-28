import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/comments_api.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';

/// Regression test for deleting a comment.
///
/// `DELETE api/Comments?id=...` used to be sent over the wire as a POST:
/// [_sendRequest] (private, in [CommentsApi]) forwarded every verb that was
/// not `PUT` to `httpClient.post`. The server's attribute routing dispatched
/// on the real HTTP method, so the request landed on the CREATE action with
/// a body containing only `idempotencyKey` — create requires
/// `targetType`/`targetId`/`text`, so the server answered HTTP 400 with the
/// generic `BadRequestError` envelope ("check if the request body is in the
/// correct format and all required fields are included") and the comment was
/// never deleted. These tests pin the fixed behavior against a mock client:
/// the logical verb must arrive as the real HTTP verb, the `+`-separated
/// composite id must survive as a percent-encoded query parameter, and the
/// `idempotencyKey` must still travel in the DELETE body.
void main() {
  group('deleteComment', () {
    late _MockHttpClient client;
    late CommentsApi api;

    setUp(() {
      client = _MockHttpClient();
      // A non-expired cached credential makes isUserAuthenticated(), the
      // credential-cache check, and getHeaders() resolve without any network
      // or platform-channel access.
      api = CommentsApi(getContextCallBack: null)
        ..authentication.cachedCredentials =
            AuthenticationData.initializedWithRestData(
                'test-token', 'Bearer', 3600, 'tiler')
        ..httpClient = client;
    });

    tearDown(() {
      client.close();
    });

    test('sends the delete as a real DELETE verb with id in the query',
        () async {
      client.nextResponseBody =
          '{"Error":{"Code":"0"},"Content":{"comment":{"id":"$commentId","isDeleted":true}}}';
      await api.deleteComment(
          commentId: commentId, idempotencyKey: 'idem-1');

      final sent = client.lastRequest as http.Request;
      expect(sent.method, 'DELETE');
      expect(sent.url.path, endsWith('/api/Comments'));
      // Comment ids are '+'-separated composites: they must arrive as a
      // percent-encoded query parameter and decode back to the exact id.
      expect(sent.url.queryParameters['id'], commentId);
      expect(sent.url.query, contains('%2B'));
      // The server binds DeleteCommentRequest from the DELETE body.
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['idempotencyKey'], 'idem-1');
    });

    test('parses the soft-deleted comment from the response', () async {
      client.nextResponseBody =
          '{"Error":{"Code":"0"},"Content":{"comment":{"id":"$commentId","text":"","isDeleted":true,"canDelete":false}}}';
      final comment =
          await api.deleteComment(commentId: commentId, idempotencyKey: 'k');
      expect(comment.id, commentId);
      expect(comment.isDeleted, isTrue);
      expect(comment.canDelete, isFalse);
    });

    test('throws a TilerError carrying the server message on failure',
        () async {
      client.nextResponseBody =
          '{"Error":{"Code":"400","Message":"Bad Request Error, check if the request body is in the correct format and all required fields are included"}}';
      expect(
        api.deleteComment(commentId: commentId, idempotencyKey: 'k'),
        throwsA(isA<TilerError>()),
      );
    });
  });

  group('editComment', () {
    // PUT goes through the same helper; pin the verb so a future
    // "everything that is not X is POST" shortcut cannot regress either side.
    late _MockHttpClient client;
    late CommentsApi api;

    setUp(() {
      client = _MockHttpClient();
      api = CommentsApi(getContextCallBack: null)
        ..authentication.cachedCredentials =
            AuthenticationData.initializedWithRestData(
                'test-token', 'Bearer', 3600, 'tiler')
        ..httpClient = client;
    });

    tearDown(() {
      client.close();
    });

    test('sends the edit as a real PUT verb with the id in the query',
        () async {
      client.nextResponseBody =
          '{"Error":{"Code":"0"},"Content":{"comment":{"id":"$commentId","text":"edited"}}}';
      await api.editComment(
          commentId: commentId, text: 'edited', idempotencyKey: 'idem-2');

      final sent = client.lastRequest as http.Request;
      expect(sent.method, 'PUT');
      expect(sent.url.queryParameters['id'], commentId);
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['text'], 'edited');
      expect(body['idempotencyKey'], 'idem-2');
    });
  });
}

/// A '+'-separated composite comment id, as stored by the server
/// (targetType + targetId + ULID segments).
const String commentId =
    'Comment+tileshare_tilette+TileShareTemplate+01KVDT3BCRRAQAATRTR49PQMPK+01KVDT3BCRQX2Q58FCVH8AR9ZH+01M3KSSPGC4XS1FJ9EV35D93KF';

/// [http.BaseClient] that records the last request and returns a canned body.
class _MockHttpClient extends RetryHttpClient {
  String nextResponseBody = '{"Error":{"Code":"0"}}';
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(nextResponseBody)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}