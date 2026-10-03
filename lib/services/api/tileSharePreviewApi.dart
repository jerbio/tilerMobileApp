import 'dart:async';
import 'dart:math';

import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/tileShareEnvelope.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';

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
class TileSharePreviewApi extends AppApi with TileShareTransport {
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

  @override
  String get transportTag => _tag;

  @override
  Exception transportFailure(TileShareFailureKind kind,
          {int? statusCode, String? reason}) =>
      TileSharePreviewFailure(PreviewFailureKind.values.byName(kind.name),
          statusCode: statusCode, reason: reason);

  Future<String> _post(String route, Map<String, Object?> body) =>
      tileShareSend('POST', route, body: body);

  Future<String> _get(String route, Map<String, String> query) =>
      tileShareSend('GET', route, query: query);
}
