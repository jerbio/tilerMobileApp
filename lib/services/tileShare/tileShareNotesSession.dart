import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/services/api/notesApi.dart';

/// Reuses notes and their concurrency token during one tilette visit.
/// The detail and editor share this session; reopening starts a fresh one.
/// Borrowed API clients remain owned by the share host.
class TileShareNotesSession extends NotesApi {
  final NotesApi _reader;
  final NotesApi? _writer;
  final _reads = <(String, NotesScope), Future<NotesPayload>>{};
  int _saveCount = 0;
  int get saveCount => _saveCount;

  TileShareNotesSession({required NotesApi reader, NotesApi? writer})
      : _reader = reader,
        _writer = writer,
        super(getContextCallBack: () => null);

  @override
  Future<NotesPayload> getNotes(String eventId,
      {NotesScope scope = NotesScope.auto}) async {
    final key = (eventId, scope);
    final cached = _reads[key];
    if (cached != null) return cached;
    final request = Future<NotesPayload>.sync(
        () => _reader.getNotes(eventId, scope: scope));
    _reads[key] = request;
    try {
      return await request;
    } catch (_) {
      if (identical(_reads[key], request)) _reads.remove(key);
      rethrow;
    }
  }

  @override
  Future<NotesPayload> updateNotes({
    required String eventId,
    required String userNote,
    required String etag,
    NotesScope scope = NotesScope.auto,
  }) async {
    final writer = _writer;
    if (writer == null) throw StateError('Notes are read-only');
    final payload = await writer.updateNotes(
        eventId: eventId, userNote: userNote, etag: etag, scope: scope);
    // Even a conflict carries the latest server note and token.
    _reads[(eventId, scope)] = Future.value(payload);
    if (!payload.concurrencyConflict) _saveCount++;
    return payload;
  }
}
