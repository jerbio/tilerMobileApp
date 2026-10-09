import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/services/api/tileShareEnvelope.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';

/// A tilette notes call that did not succeed.
class TileShareNotesFailure implements Exception {
  final TileShareFailureKind kind;
  final int? statusCode;
  final String? reason;

  const TileShareNotesFailure(this.kind, {this.statusCode, this.reason});

  @override
  String toString() => 'TileShareNotesFailure(${kind.name}'
      '${statusCode == null ? '' : ', HTTP $statusCode'}'
      '${reason == null ? '' : ', $reason'})';
}

/// A tilette's notes (redesign Step 9.16h) through
/// `api/TileshareTemplate/Notes` - the tile notes contract: the note and an
/// etag; a write carries the etag it read, and a stale one comes back as
/// `concurrencyConflict` with the server's note instead of overwriting it.
///
/// It is a [NotesApi], so the app's notes editor (`EditTileNote`,
/// `NoteFullPage`: auto-save, the conflict banner) edits a tilette's notes
/// exactly as it edits a tile's - pass the tilette's id as the event id. The
/// scope does not apply to tilettes and is ignored.
class TileShareNotesApi extends NotesApi with TileShareTransport {
  static const String _tag = 'TileShareNotesApi';
  static const String _route = 'api/TileshareTemplate/Notes';

  TileShareNotesApi({required super.getContextCallBack});

  @override
  String get transportTag => _tag;

  @override
  Exception transportFailure(TileShareFailureKind kind,
          {int? statusCode, String? reason}) =>
      TileShareNotesFailure(kind, statusCode: statusCode, reason: reason);

  @override
  Future<NotesPayload> getNotes(String eventId,
      {NotesScope scope = NotesScope.auto}) async {
    final String body =
        await tileShareSend('GET', _route, query: {'Id': eventId});
    return _payload(body, 'Read tilette notes');
  }

  @override
  Future<NotesPayload> updateNotes({
    required String eventId,
    required String userNote,
    required String etag,
    NotesScope scope = NotesScope.auto,
  }) async {
    final String body = await tileShareSend('PUT', _route,
        body: {'Id': eventId, 'UserNote': userNote, 'Etag': etag});
    return _payload(body, 'Save tilette notes');
  }

  static NotesPayload _payload(String body, String what) {
    final Map<String, dynamic> content = readTileShareContent(body,
        tag: _tag, what: what, requiredKey: 'Etag');
    // The tilette's id comes back as `Id`; the notes editor knows it as the
    // event id.
    return NotesPayload.fromJson(
        <String, dynamic>{...content, 'EventId': content['Id']});
  }
}
