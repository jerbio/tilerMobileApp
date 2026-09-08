import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';

/// Regression test for disconnecting (deleting) a connected calendar.
///
/// `DELETE api/Integrations` is acknowledged by the server with
/// `Error.Code == '0'` and NO `Content` — a delete has nothing to echo back.
/// The old code only reported success when the response ALSO carried a
/// non-null `Content`, so a successful delete was treated as a failure and the
/// integration row stayed on the list ("I cannot disconnect a microsoft
/// integration"). These tests pin the fixed behavior against a mock client:
/// success is judged by the `Error.Code`, not the presence of `Content`, and a
/// failed delete surfaces the server's message.
void main() {
  group('deleteIntegration', () {
    late _MockHttpClient client;
    late _TestIntegrationApi api;
    late CalendarIntegration integration;

    setUp(() {
      client = _MockHttpClient();
      // A non-expired cached credential makes isUserAuthenticated(), the
      // credential-cache check, and getHeaders() resolve without any network
      // or platform-channel access.
      api = _TestIntegrationApi()
        ..authentication.cachedCredentials =
            AuthenticationData.initializedWithRestData(
                'test-token', 'Bearer', 3600, 'tiler')
        ..httpClient = client;
      integration = CalendarIntegration.fromJson({
        'id': 'integration-1',
        'provider': 'microsoft',
        'email': 'test@example.com',
      });
    });

    tearDown(() {
      client.close();
    });

    test('returns true on Error.Code 0 even with no Content', () async {
      client.nextResponseBody = '{"Error":{"Code":"0"}}';
      expect(await api.deleteIntegration(integration), isTrue);
    });

    test('returns true on Error.Code 0 with a null Content', () async {
      client.nextResponseBody = '{"Error":{"Code":"0"},"Content":null}';
      expect(await api.deleteIntegration(integration), isTrue);
    });

    test('sends the delete with a boolean MobileApp marker and correct ids',
        () async {
      client.nextResponseBody = '{"Error":{"Code":"0"}}';
      await api.deleteIntegration(integration);

      final sent = client.lastRequest as http.Request;
      expect(sent.method, 'DELETE');
      expect(sent.url.path, endsWith('/api/Integrations'));
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['MobileApp'], isTrue);
      expect(body['IntegrationId'], 'integration-1');
      expect(body['Provider'], 'microsoft');
    });

    test('throws a TilerError carrying the server message on failure',
        () async {
      client.nextResponseBody =
          '{"Error":{"Code":"500","Message":"The integration is in use"}}';
      expect(
        api.deleteIntegration(integration),
        throwsA(isA<TilerError>()
            .having((e) => e.Message, 'Message', 'The integration is in use')),
      );
    });
  });
}

/// [IntegrationApi] with [injectRequestParams] short-circuited so the test does
/// not reach the platform-channel-based timezone/location lookups.
class _TestIntegrationApi extends IntegrationApi {
  _TestIntegrationApi() : super(getContextCallBack: null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    return Map<String, dynamic>.from(jsonMap);
  }
}

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