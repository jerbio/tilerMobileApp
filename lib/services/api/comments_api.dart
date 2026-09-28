import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/data/comments/comment.dart';
import 'package:tiler_app/data/comments/comment_page.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/localizationService.dart';

import '../../constants.dart' as Constants;

/// Comment thread and attachment endpoints (TilerFront feature/comments).
///
/// Thread target contract: [tileShareTiletteTargetType] with the shared
/// template's own id (`TileShareTemplate.Id`), never the per-user
/// designation id (`DesignatedTileTemplate` composite) — the server's
/// fail-closed access lookup matches `TileShareTemplates.Id` only.
///
/// Note: a 403 carrying the `cannotAuthenticate` envelope
/// ("Failed to authenticate user account") is the controller's read-access
/// denial for a *valid* token; the bounded forced credential refresh is kept
/// only as recovery for genuinely stale tokens. Comment ids may contain `+`
/// and are therefore always sent as percent-encoded query parameters, never
/// in URL paths (IIS rejects `+` in paths with a 404). Attachment ids are
/// plain ULIDs and are path-safe (status / download / cancel).
class CommentsApi extends AppApi {
  CommentsApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  static const String tileShareTiletteTargetType = 'tileshare_tilette';
  static const int defaultPageLimit = 50;

  // ---------------------------------------------------------------- helpers

  /// Truncated single-line form of [s] for console logging.
  String _snippet(String s) {
    final oneLine = s.replaceAll(RegExp(r'\s+'), ' ');
    return oneLine.length > 500 ? '${oneLine.substring(0, 500)}…' : oneLine;
  }

  Future<void> _requireHeaders() async {
    bool userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (!userIsAuthenticated) {
      debugPrint('[CommentsApi] _requireHeaders: not authenticated');
      throw TilerError(Message: 'Issues with authentication');
    }
    await checkAndReplaceCredentialCache();
    final header = getHeaders();
    if (header == null) {
      debugPrint('[CommentsApi] _requireHeaders: headers unavailable');
      throw TilerError(Message: 'Issues with authentication');
    }
  }

  /// True when the response body is the Tiler auth-failure envelope — i.e.
  /// the Bearer token itself was rejected, as opposed to a permission
  /// failure for a valid token.
  bool _isAuthFailureBody(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return false;
      final error = json['Error'];
      final message = error is Map<String, dynamic>
          ? error['Message']
          : json['Message'];
      return message is String &&
          message.toLowerCase().contains('authenticate');
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _fetch(Uri uri, Map<String, String> header) {
    return httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.requestTimeout);
    });
  }

  /// PUT/POST with the shared timeout; anything that is not a PUT is a POST
  /// (mirrors the previous inline ternary).
  Future<http.Response> _sendRequest(
    Uri uri,
    String method,
    String encodedBody,
    Map<String, String> header,
  ) {
    Future<http.Response> send() => method == 'PUT'
        ? httpClient.put(uri, headers: header, body: encodedBody)
        : httpClient.post(uri, headers: header, body: encodedBody);
    return send().timeout(AppApi.requestTimeout, onTimeout: () {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.requestTimeout);
    });
  }

  /// Unwraps the standard Tiler envelope or throws a [TilerError].
  Map<String, dynamic> _unwrapEnvelope(Map<String, dynamic> jsonResult) {
    if (isJsonResponseOk(jsonResult)) {
      final content = jsonResult['Content'];
      if (content is Map<String, dynamic>) {
        return content;
      }
      return const <String, dynamic>{};
    }
    if (isTilerRequestError(jsonResult)) {
      final errorJson = jsonResult['Error'];
      debugPrint(
          '[CommentsApi] server error envelope: '
          '${_snippet(jsonEncode(errorJson ?? const <String, dynamic>{}))}');
      final error = TilerError.fromJson(
          errorJson is Map<String, dynamic> ? errorJson : <String, dynamic>{});
      throw error;
    }
    debugPrint('[CommentsApi] unexpected envelope shape: '
        '${_snippet(jsonEncode(jsonResult))}');
    throw TilerError(Message: 'Issues with reaching Tiler servers');
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      await _requireHeaders();
      final header = getHeaders()!;
      var response = await _fetch(uri, header);
      // The server rejected the Bearer token: force a re-authentication
      // round-trip and retry once. Providers that cannot re-authenticate
      // (email-code / third-party sign-in) surface the auth error as-is —
      // the user must sign out and back in.
      if ((response.statusCode == 401 || response.statusCode == 403) &&
          _isAuthFailureBody(response.body)) {
        debugPrint('[CommentsApi] HTTP ${response.statusCode} auth failure '
            'on $uri; forcing credential refresh');
        final refreshed = await this.authentication.forceRefreshCredentials();
        final retryHeader = refreshed != null ? getHeaders() : null;
        if (retryHeader != null) {
          debugPrint('[CommentsApi] re-authenticated; retrying GET $uri');
          response = await _fetch(uri, retryHeader);
        } else {
          debugPrint('[CommentsApi] no fresh credential available; a '
              'sign-in is required to recover');
        }
      }
      if (response.statusCode >= 400) {
        debugPrint('[CommentsApi] GET $uri -> HTTP ${response.statusCode}: '
            '${_snippet(response.body)}');
      }
      final jsonResult = jsonDecode(response.body);
      return _unwrapEnvelope(jsonResult is Map<String, dynamic>
          ? jsonResult
          : const <String, dynamic>{});
    } on TilerError catch (e, st) {
      debugPrint('[CommentsApi] GET $uri failed: ${e.Message}\n$st');
      rethrow;
    } catch (e, st) {
      debugPrint('[CommentsApi] GET $uri failed: $e\n$st');
      throw TilerError(
          Message: 'Issues with reaching Tiler servers (${e.toString()})');
    }
  }

  Future<Map<String, dynamic>> _sendJson(
    Uri uri, {
    required String method,
    required Map<String, dynamic> body,
  }) async {
    try {
      await _requireHeaders();
      final header = getHeaders()!;
      header['Content-Type'] = 'application/json';
      final encoded = jsonEncode(body);
      var response = await _sendRequest(uri, method, encoded, header);
      // Same recovery as [_getJson]: a rejected Bearer token is not a
      // permission failure — force a re-authentication and retry once. The
      // server rejects authentication before any mutation runs, so the
      // retry cannot double-apply a create/update.
      if ((response.statusCode == 401 || response.statusCode == 403) &&
          _isAuthFailureBody(response.body)) {
        debugPrint('[CommentsApi] $method $uri HTTP ${response.statusCode} '
            'auth failure; forcing credential refresh');
        final refreshed =
            await this.authentication.forceRefreshCredentials();
        if (refreshed != null) {
          final retryHeader = getHeaders()!;
          retryHeader['Content-Type'] = 'application/json';
          debugPrint(
              '[CommentsApi] re-authenticated; retrying $method $uri');
          response = await _sendRequest(uri, method, encoded, retryHeader);
        } else {
          debugPrint('[CommentsApi] no fresh credential available; a '
              'sign-in is required to recover');
        }
      }
      if (response.statusCode >= 400) {
        debugPrint('[CommentsApi] $method $uri -> HTTP '
            '${response.statusCode}: ${_snippet(response.body)}');
      }
      final jsonResult = jsonDecode(response.body);
      return _unwrapEnvelope(jsonResult is Map<String, dynamic>
          ? jsonResult
          : const <String, dynamic>{});
    } on TilerError {
      rethrow;
    } catch (e) {
      throw TilerError(
          Message: 'Issues with reaching Tiler servers (${e.toString()})');
    }
  }

  // ---------------------------------------------------------------- thread

  /// One page of root comments (newest-first). Pass [cursor] from a previous
  /// page to load the next older page; omit it for the first page.
  Future<CommentPage> getComments({
    required String targetType,
    required String targetId,
    String? cursor,
    int limit = defaultPageLimit,
  }) async {
    final params = <String, String>{
      'targetType': targetType,
      'targetId': targetId,
      'limit': '$limit',
    };
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    final uri = Uri.https(Constants.tilerDomain, 'api/Comments', params);
    final content = await _getJson(uri);
    return CommentPage.fromJson(content);
  }

  /// One page of replies under a root comment (newest-first). [commentId]
  /// may contain `+` and is therefore a query parameter only.
  Future<CommentPage> getReplies({
    required String commentId,
    String? cursor,
    int limit = defaultPageLimit,
  }) async {
    final params = <String, String>{
      'commentId': commentId,
      'limit': '$limit',
    };
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    final uri =
        Uri.https(Constants.tilerDomain, 'api/Comments/replies', params);
    final content = await _getJson(uri);
    return CommentPage.fromJson(content);
  }

  /// People who can be @mentioned on the target. Failures are non-fatal for
  /// the thread (the composer simply shows no suggestions).
  Future<CommentParticipantPage> getParticipants({
    required String targetType,
    required String targetId,
  }) async {
    final uri = Uri.https(
        Constants.tilerDomain,
        'api/Comments/participants',
        <String, String>{'targetType': targetType, 'targetId': targetId});
    final content = await _getJson(uri);
    return CommentParticipantPage.fromJson(content);
  }

  /// Creates a root comment (no [rootCommentId]) or a reply.
  ///
  /// [idempotencyKey] must be a fresh UUIDv4 per logical action and reused
  /// unchanged when retrying that same action. [mentionedUserIds] must equal
  /// the set of `<@userId>` tokens in [text] (order/duplicates ignored).
  /// [attachmentIds] must reference the caller's `ready` quarantine rows;
  /// the server claims them all-or-nothing.
  Future<Comment> createComment({
    required String targetType,
    required String targetId,
    required String text,
    required String idempotencyKey,
    String? rootCommentId,
    List<String> attachmentIds = const [],
    List<String> mentionedUserIds = const [],
  }) async {
    final uri = Uri.https(Constants.tilerDomain, 'api/Comments');
    final body = <String, dynamic>{
      'targetType': targetType,
      'targetId': targetId,
      'text': text,
      'idempotencyKey': idempotencyKey,
      if (rootCommentId != null) 'rootCommentId': rootCommentId,
      if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
      if (mentionedUserIds.isNotEmpty) 'mentionedUserIds': mentionedUserIds,
    };
    final content = await _sendJson(uri, method: 'POST', body: body);
    final commentJson = content['comment'];
    if (commentJson is Map<String, dynamic>) {
      return Comment.fromJson(commentJson);
    }
    throw TilerError(Message: 'Unexpected comments response');
  }

  /// Edits a comment's text. [commentId] may contain `+` — query param only.
  /// [mentionedUserIds] must equal the set of `<@userId>` tokens in [text].
  Future<Comment> editComment({
    required String commentId,
    required String text,
    required String idempotencyKey,
    List<String> mentionedUserIds = const [],
  }) async {
    final uri = Uri.https(Constants.tilerDomain, 'api/Comments',
        <String, String>{'id': commentId});
    final body = <String, dynamic>{
      'text': text,
      'idempotencyKey': idempotencyKey,
      if (mentionedUserIds.isNotEmpty) 'mentionedUserIds': mentionedUserIds,
    };
    final content = await _sendJson(uri, method: 'PUT', body: body);
    final commentJson = content['comment'];
    if (commentJson is Map<String, dynamic>) {
      return Comment.fromJson(commentJson);
    }
    throw TilerError(Message: 'Unexpected comments response');
  }

  /// Soft-deletes a comment (row kept, text blanked, marked deleted).
  Future<Comment> deleteComment({
    required String commentId,
    required String idempotencyKey,
  }) async {
    final uri = Uri.https(Constants.tilerDomain, 'api/Comments',
        <String, String>{'id': commentId});
    final content = await _sendJson(uri, method: 'DELETE', body: <String, dynamic>{
      'idempotencyKey': idempotencyKey,
    });
    final commentJson = content['comment'];
    if (commentJson is Map<String, dynamic>) {
      return Comment.fromJson(commentJson);
    }
    throw TilerError(Message: 'Unexpected comments response');
  }

  // ---------------------------------------------------------- attachments

  /// Uploads one file to the attachment quarantine (multipart).
  ///
  /// The multipart **field order matters**: the backend streams parts in
  /// order and the file must be **last**:
  /// 1. `targetType`  2. `targetId`  3. `retryKey` (optional)  4. `file`.
  /// Returns the uploaded [Attachment]; its [Attachment.state] is `ready`
  /// (scan passed) or `rejected` (failed the allowlist/scan).
  Future<Attachment> uploadAttachment({
    required String targetType,
    required String targetId,
    required File file,
    String? retryKey,
  }) async {
    await _requireHeaders();
    final header = getHeaders()!;
    final uri = Uri.https(Constants.tilerDomain, 'api/CommentAttachments');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(header);
    // The backend streams multipart parts in order, so the field order
    // matters: targetType â†’ targetId â†’ retryKey (optional) â†’ file (last).
    request.fields['targetType'] = targetType;
    request.fields['targetId'] = targetId;
    if (retryKey != null && retryKey.isNotEmpty) {
      request.fields['retryKey'] = retryKey;
    }
    // The binary part must be added last.
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'attachment';
    request.files.add(await http.MultipartFile('file', file.openRead(),
        file.lengthSync(), filename: fileName));

    try {
      final streamed =
          await request.send().timeout(const Duration(minutes: 10));
      if (streamed.statusCode >= 400) {
        final bodyText = await streamed.stream.bytesToString();
        try {
          final decoded = jsonDecode(bodyText);
          if (decoded is Map<String, dynamic> &&
              isTilerRequestError(decoded)) {
            final errorJson = decoded['Error'];
            final error = TilerError.fromJson(
                errorJson is Map<String, dynamic>
                    ? errorJson
                    : <String, dynamic>{});
            throw error;
          }
        } on TilerError {
          rethrow;
        } catch (_) {
          // fall through to the generic error below
        }
        throw TilerError(Message: 'Issues with reaching Tiler servers');
      }
      final bodyText = await streamed.stream.bytesToString();
      final decoded = jsonDecode(bodyText);
      final content = _unwrapEnvelope(decoded is Map<String, dynamic>
          ? decoded
          : const <String, dynamic>{});
      final attachmentJson = content['attachment'];
      if (attachmentJson is Map<String, dynamic>) {
        return Attachment.fromJson(attachmentJson);
      }
      throw TilerError(Message: 'Unexpected attachment response');
    } on TilerError {
      rethrow;
    } catch (e) {
      throw TilerError(
          Message: 'Issues with reaching Tiler servers (${e.toString()})');
    }
  }

  /// Polls a quarantine row until it reaches a terminal state (`ready` or
  /// `rejected`) or [maxAttempts] polls are used up. Attachment ids are
  /// plain ULIDs, so the path form is safe here.
  Future<Attachment> getAttachmentStatus({
    required String attachmentId,
    Duration pollInterval = const Duration(milliseconds: 700),
    int maxAttempts = 60,
  }) async {
    var last = await _getAttachmentOnce(attachmentId);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (last.isTerminal) {
        return last;
      }
      await Future<void>.delayed(pollInterval);
      last = await _getAttachmentOnce(attachmentId);
    }
    return last;
  }

  Future<Attachment> _getAttachmentOnce(String attachmentId) async {
    final uri = Uri.https(
        Constants.tilerDomain, 'api/CommentAttachments/$attachmentId');
    final content = await _getJson(uri);
    final attachmentJson = content['attachment'];
    if (attachmentJson is Map<String, dynamic>) {
      return Attachment.fromJson(attachmentJson);
    }
    throw TilerError(Message: 'Unexpected attachment response');
  }

  /// Downloads the bytes of a quarantine or attached file, honouring the
  /// `Content-Disposition` filename.
  Future<({String fileName, List<int> bytes})> downloadAttachment({
    required String attachmentId,
  }) async {
    await _requireHeaders();
    final header = getHeaders()!;
    final uri = Uri.https(Constants.tilerDomain,
        'api/CommentAttachments/$attachmentId/download');
    try {
      final streamed = await httpClient
          .send(http.Request('GET', uri)..headers.addAll(header))
          .timeout(AppApi.requestTimeout, onTimeout: () {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.requestTimeout);
      });
      if (streamed.statusCode >= 400) {
        throw TilerError(Message: 'Issues with reaching Tiler servers');
      }
      final bytes = <int>[];
      await for (final chunk in streamed.stream) {
        bytes.addAll(chunk);
      }
      var fileName = 'attachment';
      final disposition = streamed.headers['content-disposition'];
      if (disposition != null) {
        final match = RegExp('filename\\*?=(?:UTF-8\'\')?"?([^";]+)"?')
            .firstMatch(disposition);
        if (match != null) {
          fileName = Uri.decodeComponent(match.group(1)!.trim());
        }
      }
      return (fileName: fileName, bytes: bytes);
    } on TilerError {
      rethrow;
    } catch (e) {
      throw TilerError(
          Message: 'Issues with reaching Tiler servers (${e.toString()})');
    }
  }

  /// Cancels an unclaimed quarantine upload. Returns the cancelled id.
  Future<String> cancelAttachment({required String attachmentId}) async {
    await _requireHeaders();
    final header = getHeaders()!;
    final uri = Uri.https(Constants.tilerDomain,
        'api/CommentAttachments/$attachmentId');
    try {
      final response =
          await httpClient.delete(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(Message:
              LocalizationService.instance.translations.requestTimeout);
        },
      );
      final jsonResult = jsonDecode(response.body);
      final content = _unwrapEnvelope(jsonResult is Map<String, dynamic>
          ? jsonResult
          : const <String, dynamic>{});
      return content['id']?.toString() ?? attachmentId;
    } on TilerError {
      rethrow;
    } catch (e) {
      throw TilerError(
          Message: 'Issues with reaching Tiler servers (${e.toString()})');
    }
  }
}
