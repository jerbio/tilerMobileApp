import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/tileShareEnvelope.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// What kind of failure a preview call had.
enum PreviewFailureKind {
  /// 401 / 403, or not signed in.
  unauthorized,

  /// 404: no access any more, or no longer there.
  notFound,

  /// 503: previews are switched off on the server.
  unavailable,

  /// 400: the server did not accept the request.
  invalid,

  /// 409: the preview or the assignment moved on; [TileSharePreviewFailure.reason]
  /// says how (`previewExpired`, `scheduleChanged`, `assignmentChanged`,
  /// `responseInProgress`, `invalidProposal`, `operationMismatch`, ...).
  conflict,

  /// Anything else, including a timeout.
  server,
}

/// A preview call that did not succeed, with enough to act on and to log.
class TileSharePreviewFailure implements Exception {
  final PreviewFailureKind kind;
  final int? statusCode;
  final String? reason;

  const TileSharePreviewFailure(this.kind, {this.statusCode, this.reason});

  @override
  String toString() => 'TileSharePreviewFailure(${kind.name}'
      '${statusCode == null ? '' : ', HTTP $statusCode'}'
      '${reason == null ? '' : ', $reason'})';
}

/// The accept preview (redesign T21): the forecast of accepting one assignment,
/// other times for it, re-previewing with a choice, and accepting exactly what
/// was previewed.
///
/// * [preview], [options], [revise] are POSTs carrying who and where the user is
///   (the forecast depends on both); previews are slow on the server, so they
///   use the long request timeout.
/// * [accept] is `status` with the `PreviewToken` and a client-made
///   `OperationId`: the server queues it and answers with an operation to
///   [operation]-poll. The same id can be sent again, so a retry never accepts
///   twice.
/// * [response] recovers an accepted assignment (and its calendar event).
///
/// A failure is a [TileSharePreviewFailure] and is logged with its route, status
/// and reason; a response that is not shaped as expected is a `StateError`.
class TileSharePreviewApi extends AppApi {
  static const String _tag = 'TileSharePreviewApi';
  static const String _previewRoute = 'api/DesignatedTile/Preview';
  static const String _optionsRoute = 'api/DesignatedTile/Preview/Options';
  static const String _reviseRoute = 'api/DesignatedTile/Preview/Revise';
  static const String _statusRoute = 'api/DesignatedTile/status';
  static const String _operationRoute = 'api/DesignatedTile/ResponseOperation';
  static const String _responseRoute = 'api/DesignatedTile/Response';

  TileSharePreviewApi({required super.getContextCallBack});

  /// A fresh operation id: 32 lower-case hex characters, which is the format
  /// the server requires.
  static String newOperationId() {
    final Random random = Random.secure();
    return List<String>.generate(
        32, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  static final RegExp _operationIdFormat = RegExp(r'^[0-9a-f]{32}$');

  Future<TileSharePreview> preview(String assignmentId) async {
    final String body = await _post(_previewRoute, {'Id': assignmentId});
    return TileSharePreview.fromJson(readTileShareContent(body,
        tag: _tag, what: 'Preview', requiredKey: 'assignmentId'));
  }

  Future<PreviewOptionsPage> options({
    required String assignmentId,
    required String previewToken,
    required String sessionKey,
    int offset = 0,
  }) async {
    final String body = await _post(_optionsRoute, {
      'Id': assignmentId,
      'PreviewToken': previewToken,
      'SessionKey': sessionKey,
      'Offset': offset,
    });
    return PreviewOptionsPage.fromJson(readTileShareContent(body,
        tag: _tag, what: 'Preview options', listKey: 'options'));
  }

  /// Re-previews with [optionId] chosen, or with [sessionKey] locked / unlocked
  /// ([fixed]); returns the new preview under a new token.
  Future<TileSharePreview> revise({
    required String assignmentId,
    required String previewToken,
    String? optionId,
    String? sessionKey,
    bool? fixed,
  }) async {
    final String body = await _post(_reviseRoute, {
      'Id': assignmentId,
      'PreviewToken': previewToken,
      if (optionId != null) 'OptionId': optionId,
      if (sessionKey != null) 'SessionKey': sessionKey,
      if (fixed != null) 'Fixed': fixed,
    });
    return TileSharePreview.fromJson(readTileShareContent(body,
        tag: _tag, what: 'Preview revision', requiredKey: 'assignmentId'));
  }

  /// Accepts exactly the previewed schedule, in [mode]. Returns the queued
  /// operation.
  ///
  /// The mode is always stated (an omitted one would mean the older "constraints
  /// bound to the token" behaviour). [TileShareAcceptanceMode.lockSession]
  /// needs the [sessionKey] of the one session to fix and the [lockedTimeLine]
  /// the user was shown for it; the server refuses a key it does not find among
  /// the stored proposal's viable sessions, or an interval that is not exactly
  /// that session's (409 `invalidSession`). A flexible accept has neither.
  /// Retrying the same [operationId] with another mode, session or interval is a
  /// 409 `operationMismatch`, so a retry must repeat all of them.
  ///
  /// The server finishes scheduling inside this request, so the answer is often
  /// already final and the call can take a while.
  Future<TileShareOperation> accept({
    required String assignmentId,
    required String previewToken,
    required String operationId,
    required TileShareAcceptanceMode mode,
    String? sessionKey,
    TileShareLockedTimeLine? lockedTimeLine,
  }) async {
    if (previewToken.isEmpty) {
      throw ArgumentError.value(previewToken, 'previewToken',
          'a preview can only be accepted with its token');
    }
    if (!_operationIdFormat.hasMatch(operationId)) {
      throw ArgumentError.value(
          operationId, 'operationId', 'must be 32 lower-case hex characters');
    }
    final bool locking = mode == TileShareAcceptanceMode.lockSession;
    if (locking && (sessionKey == null || sessionKey.trim().isEmpty)) {
      throw ArgumentError.value(sessionKey, 'sessionKey',
          'locking a session needs the session to lock');
    }
    if (!locking && sessionKey != null) {
      throw ArgumentError.value(
          sessionKey, 'sessionKey', 'a flexible accept has no session to lock');
    }
    if (locking && lockedTimeLine == null) {
      throw ArgumentError.notNull('lockedTimeLine');
    }
    if (locking && lockedTimeLine!.durationMs <= 0) {
      throw ArgumentError.value(lockedTimeLine, 'lockedTimeLine',
          'the interval to lock must have a length');
    }
    if (!locking && lockedTimeLine != null) {
      throw ArgumentError.value(lockedTimeLine, 'lockedTimeLine',
          'a flexible accept has no interval to lock');
    }
    final String body = await _post(_statusRoute, {
      'Id': assignmentId,
      'Status': 'accepted',
      'PreviewToken': previewToken,
      'OperationId': operationId,
      'AcceptanceMode': mode.wire,
      if (locking) 'SessionKey': sessionKey,
      if (locking) 'LockedTimeLineRequest': lockedTimeLine!.toJson(),
    });
    return TileShareOperation.fromJson(readTileShareContent(body,
        tag: _tag, what: 'Accept', requiredKey: 'operationId'));
  }

  Future<TileShareOperation> operation(String operationId) async {
    final String body = await _get(_operationRoute, {'id': operationId});
    return TileShareOperation.fromJson(readTileShareContent(body,
        tag: _tag, what: 'Accept operation', requiredKey: 'operationId'));
  }

  Future<TileShareAssignmentResponse> response(String assignmentId) async {
    final String body = await _get(_responseRoute, {'id': assignmentId});
    return TileShareAssignmentResponse.fromJson(readTileShareContent(body,
        tag: _tag, what: 'Response', requiredKey: 'id'));
  }

  // ---- transport ---------------------------------------------------------------

  Future<Map<String, String>> _headers(String verb, String route) async {
    if (!(await authentication.isUserAuthenticated()).item1) {
      TileShareLog.d(_tag, '$verb $route not sent: not signed in');
      throw const TileSharePreviewFailure(PreviewFailureKind.unauthorized);
    }
    await checkAndReplaceCredentialCache();
    final Map<String, String>? headers = getHeaders();
    if (headers == null) {
      TileShareLog.d(_tag, '$verb $route not sent: no credentials');
      throw const TileSharePreviewFailure(PreviewFailureKind.unauthorized);
    }
    return headers;
  }

  Future<String> _post(String route, Map<String, Object?> body) async {
    final Map<String, String> headers = await _headers('POST', route);
    // The time zone and account fields are added; the device location is not
    // asked for (owner's decision, 2026-10-03).
    final Map<String, dynamic> injected;
    try {
      injected = await injectRequestParams(body, includeLocationParams: false);
    } catch (error) {
      // Before anything is sent: time zone, location and account fields.
      TileShareLog.d(_tag, 'POST $route not sent: preparing it failed: $error');
      rethrow;
    }
    TileShareLog.d(_tag, '-> POST $route ${_describeSent(body, injected)}');
    try {
      final response = await httpClient
          .post(Uri.https(constants.tilerDomain, route),
              headers: headers, body: jsonEncode(injected))
          .timeout(AppApi.requestTimeout);
      TileShareLog.d(
          _tag,
          '<- POST $route HTTP ${response.statusCode} '
          '(${response.body.length} bytes) ${_describeReceived(response.body)}');
      return _body('POST', route, response.statusCode, response.body);
    } on TimeoutException {
      TileShareLog.d(_tag, 'POST $route timed out');
      throw const TileSharePreviewFailure(PreviewFailureKind.server,
          reason: 'timed out');
    }
  }

  Future<String> _get(String route, Map<String, String> query) async {
    final Map<String, String> headers = await _headers('GET', route);
    TileShareLog.d(_tag, '-> GET $route $query');
    try {
      final response = await httpClient
          .get(Uri.https(constants.tilerDomain, route, query), headers: headers)
          .timeout(AppApi.requestTimeout);
      TileShareLog.d(
          _tag,
          '<- GET $route HTTP ${response.statusCode} '
          '(${response.body.length} bytes) ${_describeReceived(response.body)}');
      return _body('GET', route, response.statusCode, response.body);
    } on TimeoutException {
      TileShareLog.d(_tag, 'GET $route timed out');
      throw const TileSharePreviewFailure(PreviewFailureKind.server,
          reason: 'timed out');
    }
  }

  String _body(String verb, String route, int status, String body) {
    if (status >= 200 && status < 300) return body;
    final String? reason = _reasonOf(body);
    TileShareLog.d(_tag,
        '$verb $route -> HTTP $status${reason == null ? '' : ' ($reason)'}');
    final PreviewFailureKind kind;
    switch (status) {
      case 401:
      case 403:
        kind = PreviewFailureKind.unauthorized;
      case 404:
        kind = PreviewFailureKind.notFound;
      case 409:
        kind = PreviewFailureKind.conflict;
      case 400:
        kind = PreviewFailureKind.invalid;
      case 503:
        kind = PreviewFailureKind.unavailable;
      default:
        kind = PreviewFailureKind.server;
    }
    throw TileSharePreviewFailure(kind, statusCode: status, reason: reason);
  }

  /// What a request carried, for the log: the fields this API set, with the
  /// preview token shortened, and only the *names* of the fields
  /// `injectRequestParams` added (they include where the user is).
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

  /// What a reply held, for the log: the envelope's code and message, and the
  /// keys of its `Content` (lists with their length); raw text, shortened,
  /// when it is not JSON.
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
