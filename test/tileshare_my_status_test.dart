// TileShare redesign Step 9.8: what the signed-in user has answered in each
// cluster shared with them - the "my status + my task count" of a recipient
// card (section 5.3). Pure: derived from the user's own assignments.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';

import 'helpers/tileshare_fixtures.dart';

void main() {
  DesignatedTile tile(String id, String cluster, InvitationStatus status) =>
      tsDesignatedTile(id, clusterId: cluster, status: status);

  test('one unanswered task is pending and needs an answer', () {
    final s = MyClusterStatus.byCluster(
        [tile('a', 'c1', InvitationStatus.none)])['c1']!;
    expect(s.taskCount, 1);
    expect(s.pending, 1);
    expect(s.answer, MyClusterAnswer.pending);
    expect(s.needsAnswer, isTrue);
  });

  test('all accepted / all declined are accepted / declined', () {
    final accepted = MyClusterStatus.byCluster([
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.accepted),
    ])['c1']!;
    expect(accepted.answer, MyClusterAnswer.accepted);
    expect(accepted.needsAnswer, isFalse);
    expect(accepted.taskCount, 2);

    final declined = MyClusterStatus.byCluster([
      tile('a', 'c1', InvitationStatus.declined),
    ])['c1']!;
    expect(declined.answer, MyClusterAnswer.declined);
  });

  test('a mix of answered and unanswered tasks is mixed and still needs an '
      'answer', () {
    final s = MyClusterStatus.byCluster([
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.none),
      tile('c', 'c1', InvitationStatus.declined),
    ])['c1']!;
    expect(s.answer, MyClusterAnswer.mixed);
    expect([s.taskCount, s.accepted, s.declined, s.pending], [3, 1, 1, 1]);
    expect(s.needsAnswer, isTrue);
  });

  test('accepted on some and declined on the rest, none pending, is mixed '
      'and needs nothing', () {
    final s = MyClusterStatus.byCluster([
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.declined),
    ])['c1']!;
    expect(s.answer, MyClusterAnswer.mixed);
    expect(s.needsAnswer, isFalse);
  });

  test('clusters are told apart, and tiles with no cluster are ignored', () {
    final map = MyClusterStatus.byCluster([
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c2', InvitationStatus.none),
      tsDesignatedTile('x', clusterId: '', status: InvitationStatus.none),
    ]);
    expect(map.keys.toSet(), {'c1', 'c2'});
    expect(map['c1']!.answer, MyClusterAnswer.accepted);
    expect(map['c2']!.answer, MyClusterAnswer.pending);
  });

  test('server spellings are understood: prefixed, tentative, unknown', () {
    DesignatedTile raw(String id, String status) => DesignatedTile.fromJson({
          'id': id,
          'invitationStatus': status,
          'template': {'id': 't$id', 'clusterId': 'c1'},
        });
    final s = MyClusterStatus.byCluster([
      raw('a', 'InvitationStatus.accepted'),
      raw('b', 'tentative'),
      raw('c', 'something-new'),
    ])['c1']!;
    expect([s.accepted, s.pending], [1, 2],
        reason: 'tentative and unknown count as still to answer');
  });

  test('nothing in, nothing out', () {
    expect(MyClusterStatus.byCluster(const <DesignatedTile>[]), isEmpty);
  });
}
