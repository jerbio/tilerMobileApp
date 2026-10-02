// TileShare redesign Step 9.11 (T26): an accept that was sent and not confirmed
// (timeout, lost connection, app closed) is recovered by repeating the SAME
// command - same operation id, token, mode, session and interval - so the app
// keeps that command per account and assignment until its outcome is known.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/tileShare/tileSharePendingAccept.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 2, 12);

  PendingAccept flexible({String assignment = 'a1', DateTime? savedAt}) =>
      PendingAccept(
        operationId: 'op' * 16,
        assignmentId: assignment,
        previewToken: 'tok' * 8,
        mode: TileShareAcceptanceMode.flexible,
        savedAtMs: (savedAt ?? now).millisecondsSinceEpoch,
      );

  PendingAccept locked() => PendingAccept(
        operationId: 'cd' * 16,
        assignmentId: 'a1',
        previewToken: 'tok' * 8,
        mode: TileShareAcceptanceMode.lockSession,
        sessionKey: '1',
        lockedTimeLine:
            const TileShareLockedTimeLine(startMs: 1789560000000, durationMs: 3600000),
        savedAtMs: now.millisecondsSinceEpoch,
      );

  StoredTileSharePendingAcceptStore store(
          {String account = 'me', DateTime Function()? clock}) =>
      StoredTileSharePendingAcceptStore(
          accountKey: account, clock: clock ?? () => now);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing saved is nothing to resume', () async {
    expect(await store().read('a1'), isNull);
  });

  test('a flexible accept comes back whole', () async {
    final saved = flexible();
    await store().save(saved);
    final read = (await store().read('a1'))!;
    expect(read.operationId, saved.operationId);
    expect(read.assignmentId, 'a1');
    expect(read.previewToken, saved.previewToken);
    expect(read.mode, TileShareAcceptanceMode.flexible);
    expect(read.sessionKey, isNull);
    expect(read.lockedTimeLine, isNull);
  });

  test('a lock comes back with its session and its interval', () async {
    await store().save(locked());
    final read = (await store().read('a1'))!;
    expect(read.mode, TileShareAcceptanceMode.lockSession);
    expect(read.sessionKey, '1');
    expect(read.lockedTimeLine,
        const TileShareLockedTimeLine(startMs: 1789560000000, durationMs: 3600000));
  });

  test('is kept per assignment', () async {
    await store().save(flexible(assignment: 'a1'));
    await store().save(flexible(assignment: 'a2'));
    expect((await store().read('a1'))!.assignmentId, 'a1');
    expect((await store().read('a2'))!.assignmentId, 'a2');
    expect(await store().read('a3'), isNull);
  });

  test('is kept per account: another account never sees it', () async {
    await store(account: 'me').save(flexible());
    expect(await store(account: 'someone-else').read('a1'), isNull);
    expect(await store(account: 'me').read('a1'), isNotNull);
  });

  test('saving again replaces it', () async {
    await store().save(flexible());
    await store().save(locked());
    expect((await store().read('a1'))!.mode, TileShareAcceptanceMode.lockSession);
  });

  test('clearing removes it, and only that assignment\'s', () async {
    await store().save(flexible(assignment: 'a1'));
    await store().save(flexible(assignment: 'a2'));
    await store().clear('a1');
    expect(await store().read('a1'), isNull);
    expect(await store().read('a2'), isNotNull);
  });

  test('a command older than the server keeps outcomes is dropped', () async {
    await store().save(flexible(savedAt: now.subtract(const Duration(days: 6))));
    expect(await store().read('a1'), isNotNull, reason: 'six days: still there');

    await store().save(flexible(savedAt: now.subtract(const Duration(days: 8))));
    expect(await store().read('a1'), isNull);
    expect(await store().read('a1'), isNull, reason: 'and it was cleared');
  });

  test('a stored value that cannot be read is nothing, never a crash',
      () async {
    SharedPreferences.setMockInitialValues({
      'tileSharePendingAccept:me:a1': 'not json at all',
      'tileSharePendingAccept:me:a2': '{"operationId": 7}',
      'tileSharePendingAccept:me:a3':
          '{"operationId":"x","assignmentId":"a3","previewToken":"t","mode":"Melt","savedAtMs":1}',
    });
    for (final id in ['a1', 'a2', 'a3']) {
      expect(await store().read(id), isNull, reason: id);
    }
  });

  test('a lock without its session or interval is not a command that can be '
      'repeated', () async {
    SharedPreferences.setMockInitialValues({
      'tileSharePendingAccept:me:a1':
          '{"operationId":"x","assignmentId":"a1","previewToken":"t","mode":"LockSession","savedAtMs":${now.millisecondsSinceEpoch}}',
    });
    expect(await store().read('a1'), isNull);
  });
}
