import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// How a TileShare request failed, by HTTP status.
enum TileShareFailureKind {
  /// 401 / 403, or not signed in.
  unauthorized,

  /// 404: no access any more, or no longer there.
  notFound,

  /// 503: switched off on the server.
  unavailable,

  /// 400: the server did not accept the request.
  invalid,

  /// 409: the state moved on; the failure's reason says how.
  conflict,

  /// Anything else, including a timeout.
  server,
}

/// The HTTP plumbing the TileShare APIs share: credentials, the time zone and
/// account fields (never the device location), the long request timeout, a
/// failure per HTTP status with the server's reason, and one log line for what
/// was sent and one for what came back - the fields the API set (a preview
/// token shortened), only the *names* of the injected ones, the envelope's
/// code and message, and the keys of its `Content`.
///
/// Each API names its log tag ([transportTag]) and turns a failure into its
/// own exception type ([transportFailure]).
mixin TileShareTransport on AppApi {
  String get transportTag;

  Exception transportFailure(TileShareFailureKind kind,
      {int? statusCode, String? reason});

  /// Sends [verb] to [route] - a JSON [body] (POST / PUT / DELETE) or a
  /// [query] (GET) - and returns the body of a 2xx answer; throws
  /// [transportFailure] otherwise.
  Future<String> tileShareSend(String verb, String route,
      {Map<String, Object?>? body, Map<String, String>? query}) async {
    final Map<String, String> headers = await _headers(verb, route);
    Map<String, dynamic>? injected;
    if (body != null) {
      try {
        injected =
            await injectRequestParams(body, includeLocationParams: false);
      } catch (error) {
        // Before anything is sent: time zone and account fields.
        TileShareLog.d(
            transportTag, '$verb $route not sent: preparing it failed: $error');
        rethrow;
      }
      TileShareLog.d(
          transportTag, '-> $verb $route ${_describeSent(body, injected)}');
    } else {
      TileShareLog.d(transportTag, '-> $verb $route ${query ?? {}}');
    }
    final Uri uri = Uri.https(constants.tilerDomain, route, query);
    final String? encoded = injected == null ? null : jsonEncode(injected);
    try {
      final http.Response response;
      switch (verb) {
        case 'GET':
          response = await httpClient
              .get(uri, headers: headers)
              .timeout(AppApi.requestTimeout);
        case 'PUT':
          response = await httpClient
              .put(uri, headers: headers, body: encoded)
              .timeout(AppApi.requestTimeout);
        case 'DELETE':
          response = await httpClient
              .delete(uri, headers: headers, body: encoded)
              .timeout(AppApi.requestTimeout);
        default:
          response = await httpClient
              .post(uri, headers: headers, body: encoded)
              .timeout(AppApi.requestTimeout);
      }
      TileShareLog.d(
          transportTag,
          '<- $verb $route HTTP ${response.statusCode} '
          '(${response.body.length} bytes) ${_describeReceived(response.body)}');
      return _body(verb, route, response.statusCode, response.body);
    } on TimeoutException {
      TileShareLog.d(transportTag, '$verb $route timed out');
      throw transportFailure(TileShareFailureKind.server, reason: 'timed out');
    }
  }

  Future<Map<String, String>> _headers(String verb, String route) async {
    if (!(await authentication.isUserAuthenticated()).item1) {
      TileShareLog.d(transportTag, '$verb $route not sent: not signed in');
      throw transportFailure(TileShareFailureKind.unauthorized);
    }
    await checkAndReplaceCredentialCache();
    final Map<String, String>? headers = getHeaders();
    if (headers == null) {
      TileShareLog.d(transportTag, '$verb $route not sent: no credentials');
      throw transportFailure(TileShareFailureKind.unauthorized);
    }
    return headers;
  }

  String _body(String verb, String route, int status, String body) {
    if (status >= 200 && status < 300) return body;
    final String? reason = _reasonOf(body);
    TileShareLog.d(transportTag,
        '$verb $route -> HTTP $status${reason == null ? '' : ' ($reason)'}');
    final TileShareFailureKind kind;
    switch (status) {
      case 401:
      case 403:
        kind = TileShareFailureKind.unauthorized;
      case 404:
        kind = TileShareFailureKind.notFound;
      case 409:
        kind = TileShareFailureKind.conflict;
      case 400:
        kind = TileShareFailureKind.invalid;
      case 503:
        kind = TileShareFailureKind.unavailable;
      default:
        kind = TileShareFailureKind.server;
    }
    throw transportFailure(kind, statusCode: status, reason: reason);
  }

  static String _describeSent(
      Map<String, Object?> body, Map<String, dynamic> injected) {
    final List<String> fields = <String>[
      for (final MapEntry<String, Object?> e in body.entries)
        '${e.key}=${e.key == 'PreviewToken' ? _shortToken(e.value) : e.value is Map ? jsonEncode(e.value) : e.value}',
    ];
    final List<String> added =
        injected.keys.where((k) => !body.containsKey(k)).toList();
    return '{${fields.join(', ')}} + [${added.join(', ')}]';
  }

  static String _shortToken(Object? token) {
    final String text = '${token ?? ''}';
    return text.length <= 6 ? text : '${text.substring(0, 6)}…';
  }

  static String _describeReceived(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return 'empty';
    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return 'not JSON: ${_short(trimmed)}';
    }
    if (decoded is! Map) return 'JSON ${decoded.runtimeType}';
    final List<String> parts = <String>[];
    final Object? error = decoded['Error'];
    if (error is Map) parts.add('code ${error['Code']} (${error['Message']})');
    final Object? content = decoded.containsKey('Content') || error != null
        ? decoded['Content']
        : decoded;
    if (content is Map) {
      final List<String> keys = <String>[
        for (final MapEntry<dynamic, dynamic> e in content.entries)
          e.value is List
              ? '${e.key}(${(e.value as List).length})'
              : '${e.key}',
      ];
      parts.add('content: ${keys.take(30).join(', ')}'
          '${keys.length > 30 ? ', …' : ''}');
    } else {
      parts.add(
          content == null ? 'no content' : 'content ${content.runtimeType}');
    }
    return parts.join('; ');
  }

  /// The server's reason for a failure: the envelope's error message when the
  /// body is one, else the body itself (shortened).
  static String? _reasonOf(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final Object? error = decoded['Error'];
        if (error is Map && error['Message'] != null) {
          final String message = error['Message'].toString();
          if (message.isNotEmpty && message != 'SUCCESS') return message;
        }
        final Object? message = decoded['error'] ?? decoded['Message'];
        if (message is String && message.isNotEmpty) return message;
        return null;
      }
      if (decoded is String && decoded.isNotEmpty) return _short(decoded);
    } catch (_) {
      // Not JSON: fall through to the raw text.
    }
    return _short(trimmed);
  }

  static String _short(String text) =>
      text.length <= 160 ? text : '${text.substring(0, 157)}...';
}
