import 'dart:convert';
import 'dart:io';

import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';

import '../../constants.dart' as Constants;

/// Client for the `/api/CalendarEvent/Notes` read/write endpoints.
///
/// Mirrors the TilerWeb `NotesApi`: the server resolves either the parent
/// calendar-event MiscData blob or the sub-event MiscData blob based on the
/// supplied [NotesScope], and uses an opaque [NotesPayload.etag] for
/// concurrency control. On etag mismatch the server returns 200 with
/// `concurrencyConflict: true` so callers can surface a merge UI.
class NotesApi extends AppApi {
  static const String _route = 'api/CalendarEvent/Notes';

  NotesApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  /// `GET /api/CalendarEvent/Notes?EventID=...&Scope=...`
  Future<NotesPayload> getNotes(
    String eventId, {
    NotesScope scope = NotesScope.auto,
  }) async {
    if (!(await this.authentication.isUserAuthenticated()).item1) {
      throw TilerError(Message: 'User is not authenticated');
    }
    await checkAndReplaceCredentialCache();
    final header = this.getHeaders();
    if (header == null) {
      throw TilerError(Message: 'Issues with authentication');
    }

    final queryParameters = <String, String>{
      'EventID': eventId,
      'Scope': scope.wireValue,
      'MobileApp': true.toString(),
    };
    final uri = Uri.https(Constants.tilerDomain, _route, queryParameters);
    final response = await httpClient.get(uri, headers: header).timeout(
      AppApi.requestTimeout,
      onTimeout: () {
        throw TilerError(
            Message:
                'Request timed out after ${AppApi.requestTimeout.inSeconds} seconds');
      },
    );
    return _parseResponse(response);
  }

  /// `PUT /api/CalendarEvent/Notes`
  ///
  /// Pass the [etag] from the last successful [getNotes] or [updateNotes];
  /// use empty string for a first write. The returned payload always carries
  /// the latest server-side etag — even when [NotesPayload.concurrencyConflict]
  /// is `true`, in which case it also carries the freshest server-side note so
  /// the UI can offer a merge.
  Future<NotesPayload> updateNotes({
    required String eventId,
    required String userNote,
    required String etag,
    NotesScope scope = NotesScope.auto,
  }) async {
    if (!(await this.authentication.isUserAuthenticated()).item1) {
      throw TilerError(Message: 'User is not authenticated');
    }
    await checkAndReplaceCredentialCache();
    final header = this.getHeaders();
    if (header == null) {
      throw TilerError(Message: 'Issues with authentication');
    }

    final body = <String, dynamic>{
      'EventID': eventId,
      'Scope': scope.wireValue,
      'UserNote': userNote,
      'Etag': etag,
      'MobileApp': true.toString(),
    };

    final uri = Uri.https(Constants.tilerDomain, _route);
    final response = await httpClient
        .put(uri, headers: header, body: jsonEncode(body))
        .timeout(
      AppApi.requestTimeout,
      onTimeout: () {
        throw TilerError(
            Message:
                'Request timed out after ${AppApi.requestTimeout.inSeconds} seconds');
      },
    );
    return _parseResponse(response);
  }

  NotesPayload _parseResponse(dynamic response) {
    if (response.statusCode != HttpStatus.ok) {
      throw TilerError(
          Message: 'Notes request failed with status ${response.statusCode}');
    }
    final Map<String, dynamic> jsonResult =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (isJsonResponseOk(jsonResult) && isContentInResponse(jsonResult)) {
      return NotesPayload.fromJson(
          jsonResult['Content'] as Map<String, dynamic>);
    }
    throw TilerError(Message: errorMessage(jsonResult));
  }
}
