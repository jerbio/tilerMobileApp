// Device round, 2026-09-16: an Edit Tile load failed with
// `error=Instance of 'TilerError'` and nothing else — `getSubEvent` threw a
// bare `TilerError()` on a rejected response, discarding the server's
// reason. The redesign logs `Message` when there is one (`RedesignLog`), so
// the API must attach it. Pinned against a mock client, as
// `integrations_api_delete_test.dart` does.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';

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

/// Skips the location/device params so no platform channel is touched.
class _TestSubEventApi extends SubCalendarEventApi {
  _TestSubEventApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
      {bool includeLocationParams = false}) async {
    return Map<String, dynamic>.from(jsonMap);
  }
}

void main() {
  late _MockHttpClient client;
  late _TestSubEventApi api;

  setUp(() {
    client = _MockHttpClient();
    api = _TestSubEventApi()
      ..authentication.cachedCredentials =
          AuthenticationData.initializedWithRestData(
              'test-token', 'Bearer', 3600, 'tiler')
      ..httpClient = client;
  });

  tearDown(() => client.close());

  test('a rejected getSubEvent carries the server\'s message and code',
      () async {
    client.nextResponseBody =
        '{"Error":{"Code":"40","Message":"Sub event not found"}}';
    try {
      await api.getSubEvent('sub-x');
      fail('expected a TilerError');
    } on TilerError catch (e) {
      expect(e.Message, 'Sub event not found');
      expect(e.Code, '40');
    }
  });

  test('an OK response without Content is still a TilerError', () async {
    client.nextResponseBody = '{"Error":{"Code":"0"}}';
    expect(() => api.getSubEvent('sub-x'), throwsA(isA<TilerError>()));
  });
}
