// TileShare redesign Step 9.2 (T18): fan-out is grouped. A Class creates one
// event per task, so consecutive events with the same actor, type and cluster
// that are at most 60 s apart collapse into one row.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareActivityRows.dart';

const int _base = 1760000000000;

TileShareActivity _e(
  String id, {
  String type = 'recipient_added',
  String cluster = 'c1',
  String? actor = 'owner',
  String? tilette,
  String? target,
  required int secondsAgo,
}) =>
    TileShareActivity.fromJson({
      'eventId': id,
      'schemaVersion': 1,
      'eventType': type,
      'clusterId': cluster,
      'occurredAt': _base - secondsAgo * 1000,
      if (actor != null) 'actorId': actor,
      if (tilette != null) 'tiletteId': tilette,
      if (target != null) 'targetUserId': target,
    });

List<List<String>> _ids(List<ActivityRow> rows) =>
    rows.map((r) => r.events.map((e) => e.eventId).toList()).toList();

void main() {
  group('ActivityRows.group', () {
    test('empty and single', () {
      expect(ActivityRows.group(const []), isEmpty);
      final rows = ActivityRows.group([_e('a', secondsAgo: 0)]);
      expect(_ids(rows), [
        ['a']
      ]);
      expect(rows.single.count, 1);
    });

    test('a Class fan-out (4 tasks, same actor/type/cluster) is one row', () {
      final rows = ActivityRows.group([
        _e('a', tilette: 't1', target: 'sam', secondsAgo: 0),
        _e('b', tilette: 't2', target: 'sam', secondsAgo: 1),
        _e('c', tilette: 't3', target: 'sam', secondsAgo: 2),
        _e('d', tilette: 't4', target: 'sam', secondsAgo: 3),
      ]);
      expect(_ids(rows), [
        ['a', 'b', 'c', 'd']
      ]);
      expect(rows.single.count, 4);
      expect(rows.single.distinctTilettes, 4);
      expect(rows.single.distinctTargets, 1);
      expect(rows.single.first.eventId, 'a');
    });

    test('several people added to one task also collapse (distinct targets)',
        () {
      final rows = ActivityRows.group([
        _e('a', tilette: 't1', target: 'x', secondsAgo: 0),
        _e('b', tilette: 't1', target: 'y', secondsAgo: 2),
      ]);
      expect(rows.single.distinctTargets, 2);
      expect(rows.single.distinctTilettes, 1);
    });

    test('a gap of exactly 60 s still groups; 61 s splits', () {
      expect(
          ActivityRows.group(
              [_e('a', secondsAgo: 0), _e('b', secondsAgo: 60)]).length,
          1);
      expect(
          ActivityRows.group(
              [_e('a', secondsAgo: 0), _e('b', secondsAgo: 61)]).length,
          2);
    });

    test('the gap is measured between neighbours, so a chain groups', () {
      final rows = ActivityRows.group([
        _e('a', secondsAgo: 0),
        _e('b', secondsAgo: 50),
        _e('c', secondsAgo: 100),
        _e('d', secondsAgo: 150),
      ]);
      expect(_ids(rows), [
        ['a', 'b', 'c', 'd']
      ]);
    });

    test('a different actor, type or cluster starts a new row', () {
      expect(
          ActivityRows.group([
            _e('a', secondsAgo: 0),
            _e('b', actor: 'someone-else', secondsAgo: 1),
          ]).length,
          2);
      expect(
          ActivityRows.group([
            _e('a', secondsAgo: 0),
            _e('b', type: 'recipient_removed', secondsAgo: 1),
          ]).length,
          2);
      expect(
          ActivityRows.group([
            _e('a', secondsAgo: 0),
            _e('b', cluster: 'c2', secondsAgo: 1),
          ]).length,
          2);
    });

    test('unattributed events group with each other, not with attributed ones',
        () {
      expect(
          ActivityRows.group([
            _e('a', actor: null, secondsAgo: 0),
            _e('b', actor: null, secondsAgo: 1),
          ]).length,
          1);
      expect(
          ActivityRows.group([
            _e('a', actor: null, secondsAgo: 0),
            _e('b', secondsAgo: 1),
          ]).length,
          2);
    });

    test('only NEIGHBOURS merge: A, B, A stays three rows; order is kept', () {
      final rows = ActivityRows.group([
        _e('a1', secondsAgo: 0),
        _e('b', type: 'recipient_removed', secondsAgo: 1),
        _e('a2', secondsAgo: 2),
      ]);
      expect(_ids(rows), [
        ['a1'],
        ['b'],
        ['a2']
      ]);
    });

    test('the window is configurable', () {
      final rows = ActivityRows.group(
          [_e('a', secondsAgo: 0), _e('b', secondsAgo: 5)],
          window: const Duration(seconds: 2));
      expect(rows.length, 2);
    });

    test('unknown event types group by their raw type string', () {
      final rows = ActivityRows.group([
        _e('a', type: 'future_thing', secondsAgo: 0),
        _e('b', type: 'future_thing', secondsAgo: 1),
      ]);
      expect(rows.length, 1);
    });
  });
}
