import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/tileShare/tileShareNotesSession.dart';

import 'helpers/tileshare_fakes.dart';

void main() {
  late FakeTileShareNotesApi source;
  late TileShareNotesSession session;
  setUp(() {
    source =
        FakeTileShareNotesApi(FakeTileShareClustersSource(tilettesByCluster: {
      'share': [
        TileShareTemplate.fromJson({
          'id': 'task',
          'miscData': {'userNote': 'Existing note'},
        })
      ]
    }));
    session = TileShareNotesSession(reader: source, writer: source);
  });
  tearDown(() {
    session.dispose();
    source.dispose();
  });

  test('concurrent and later reads share a single request and token', () async {
    source.hold();
    final first = session.getNotes('task');
    final second = session.getNotes('task');
    expect(source.calls, ['get(task)']);
    source.release();
    final results = await Future.wait([first, second]);
    expect(identical(results.first, results.last), isTrue);
    expect((await session.getNotes('task')).etag, results.first.etag);
    expect(source.calls, ['get(task)']);
  });

  test('failed reads can be retried', () async {
    source.failNext(StateError('offline'));
    await expectLater(session.getNotes('task'), throwsStateError);
    expect((await session.getNotes('task')).userNote, 'Existing note');
    expect(source.calls, ['get(task)', 'get(task)']);
  });

  test('saved notes and new tokens replace the cached payload', () async {
    final original = await session.getNotes('task');
    final saved = await session.updateNotes(
        eventId: 'task', userNote: 'Updated note', etag: original.etag);
    final reopened = await session.getNotes('task');
    expect(reopened.userNote, 'Updated note');
    expect(reopened.etag, saved.etag);
    expect(reopened.etag, isNot(original.etag));
    expect(session.saveCount, 1);
    expect(source.calls.where((c) => c.startsWith('get')).length, 1);
  });

  test('a stale token preserves the server note and its conflict response',
      () async {
    final original = await session.getNotes('task');
    source.store('task', 'Someone else saved this');
    final conflict = await session.updateNotes(
        eventId: 'task', userNote: 'My edit', etag: original.etag);
    expect(conflict.concurrencyConflict, isTrue);
    expect(
        (await session.getNotes('task')).userNote, 'Someone else saved this');
    expect(session.saveCount, 0);
    final saved = await session.updateNotes(
        eventId: 'task', userNote: 'Merged note', etag: conflict.etag);
    expect(saved.concurrencyConflict, isFalse);
    expect(session.saveCount, 1);
  });

  test('a new visit reads again and read-only sessions cannot save', () async {
    await session.getNotes('task');
    source.store('task', 'New server note');
    final next = TileShareNotesSession(reader: source);
    addTearDown(next.dispose);
    expect((await next.getNotes('task')).userNote, 'New server note');
    await expectLater(
        next.updateNotes(eventId: 'task', userNote: 'Edit', etag: ''),
        throwsStateError);
    expect(source.calls, ['get(task)', 'get(task)']);
  });

  test('cache entries keep different ids and scopes separate', () async {
    await session.getNotes('task');
    await session.getNotes('other');
    await session.getNotes('task', scope: NotesScope.calendar);
    expect(source.calls, ['get(task)', 'get(other)', 'get(task)']);
  });
}
