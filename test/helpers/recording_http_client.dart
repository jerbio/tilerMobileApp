import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tiler_app/services/api/retryHttpClient.dart';

/// A stand-in HTTP client for API tests: records every request and answers
/// with a configurable status and body, with no network access.
class RecordingHttpClient extends RetryHttpClient {
  int nextStatus = 200;
  String nextBody = '{}';
  Map<String, String> nextHeaders = <String, String>{
    'content-type': 'application/json'
  };
  final List<http.BaseRequest> requests = <http.BaseRequest>[];

  http.Request get last => requests.last as http.Request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(nextBody)),
      nextStatus,
      headers: nextHeaders,
    );
  }
}
