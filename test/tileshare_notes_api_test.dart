// TileShare redesign Step 9.16h: a tilette's notes through their own
// endpoint, the tile notes contract, tested at the HTTP level - no network.
//   GET api/TileshareTemplate/Notes?Id=<tilette>  -> {Id, UserNote, Etag}
//   PUT api/TileshareTemplate/Notes {Id, UserNote, Etag}
//       -> {Id, UserNote, Etag[, concurrencyConflict]}
// The client is a NotesApi, so the app's notes editor (auto-save, conflicts)
// edits a tilette's notes exactly as it edits a tile's.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/services/api/authenticationData.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/services/api/tileShareNotesApi.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/recording_http_client.dart';

class _TestApi extends TileShareNotesApi {
  _TestApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, dynamic>> injectRequestParams(Map jsonMap,
          {bool includeLocationParams = false}) async =>
      {...Map<String, dynamic>.from(jsonMap), 'TimeZone': 'UTC'};
}

String _ok(Object? content) => jsonEncode({
      'Error': {'Code': '0', 'Message': 'SUCCESS'},
      'Content': content,
    });

void main() {
  late RecordingHttpClient client;
  late _TestApi api;
  late void Function(String) originalSink;

  setUp(() {
    client = RecordingHttpClient();
    api = _TestApi()
      ..authentication.cachedCredentials =
          AuthenticationData.initializedWithRestData(
              'test-token', 'Bearer', 3600, 'tiler')
      ..httpClient = client;
    originalSink = TileShareLog.sink;
    TileShareLog.sink = (_) {};
  });
  tearDown(() {
    client.close();
    TileShareLog.sink = originalSink;
  });

  test('is the app\'s notes client', () {
    expect(api, isA<NotesApi>());
  });

  test('reads a tilette\'s notes and their etag', () async {
    client.nextBody =
        _ok({'Id': 't1', 'UserNote': 'Use **tape**', 'Etag': 'e1'});
    final payload = await api.getNotes('t1');
    expect(client.last.method, 'GET');
    expect(client.last.url.path, '/api/TileshareTemplate/Notes');
    expect(client.last.url.queryParameters['Id'], 't1');
    expect(client.last.headers['Authorization'], 'Bearer test-token');
    expect(payload.eventId, 't1');
    expect(payload.userNote, 'Use **tape**');
    expect(payload.etag, 'e1');
    expect(payload.concurrencyConflict, isFalse);
  });

  test('writes them with the etag it read', () async {
    client.nextBody = _ok({'Id': 't1', 'UserNote': 'Bring tape', 'Etag': 'e2'});
    final payload =
        await api.updateNotes(eventId: 't1', userNote: 'Bring tape', etag: 'e1');
    expect(client.last.method, 'PUT');
    expect(client.last.url.path, '/api/TileshareTemplate/Notes');
    final sent = jsonDecode(client.last.body) as Map<String, dynamic>;
    expect([sent['Id'], sent['UserNote'], sent['Etag']],
        ['t1', 'Bring tape', 'e1']);
    expect(payload.etag, 'e2');
  });

  test('a stale etag is a conflict that carries the server\'s note', () async {
    client.nextBody = _ok({
      'Id': 't1',
      'UserNote': 'someone else\'s',
      'Etag': 'e3',
      'concurrencyConflict': true
    });
    final payload =
        await api.updateNotes(eventId: 't1', userNote: 'mine', etag: 'old');
    expect(payload.concurrencyConflict, isTrue);
    expect(payload.userNote, 'someone else\'s');
    expect(payload.etag, 'e3');
  });

  test('a tilette that is gone is a failure of that kind', () async {
    client.nextStatus = 404;
    client.nextBody = '';
    await expectLater(
        api.getNotes('t1'),
        throwsA(isA<TileShareNotesFailure>()
            .having((f) => f.kind, 'kind', TileShareFailureKind.notFound)));
  });
}
