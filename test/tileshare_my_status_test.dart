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
    final s = MyClusterStatus.byCluster(userId: 'me', [tile('a', 'c1', InvitationStatus.none)])['c1']!;
    expect(s.taskCount, 1);
    expect(s.pending, 1);
    expect(s.answer, MyClusterAnswer.pending);
    expect(s.needsAnswer, isTrue);
  });

  test('all accepted / all declined are accepted / declined', () {
    final accepted = MyClusterStatus.byCluster(userId: 'me', [
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.accepted),
    ])['c1']!;
    expect(accepted.answer, MyClusterAnswer.accepted);
    expect(accepted.needsAnswer, isFalse);
    expect(accepted.taskCount, 2);

    final declined = MyClusterStatus.byCluster(userId: 'me', [
      tile('a', 'c1', InvitationStatus.declined),
    ])['c1']!;
    expect(declined.answer, MyClusterAnswer.declined);
  });

  test('a mix of answered and unanswered tasks is mixed and still needs an '
      'answer', () {
    final s = MyClusterStatus.byCluster(userId: 'me', [
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.none),
      tile('c', 'c1', InvitationStatus.declined),
    ])['c1']!;
    expect(s.answer, MyClusterAnswer.mixed);
    expect([s.taskCount, s.accepted, s.declined, s.pending], [3, 1, 1, 1]);
    expect(s.needsAnswer, isTrue);
  });

  test('the tasks still to answer are named, so one can be previewed '
      '(Step 9.11b)', () {
    final s = MyClusterStatus.byCluster(userId: 'me', [
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.none),
      tile('c', 'c1', InvitationStatus.declined),
      tile('d', 'c1', InvitationStatus.none),
    ])['c1']!;
    expect(s.pendingAssignmentIds, ['b', 'd']);
    expect(
        MyClusterStatus.byCluster(userId: 'me', [tile('a', 'c1', InvitationStatus.accepted)])[
                'c1']!
            .pendingAssignmentIds,
        isEmpty);
  });

  test('accepted on some and declined on the rest, none pending, is mixed '
      'and needs nothing', () {
    final s = MyClusterStatus.byCluster(userId: 'me', [
      tile('a', 'c1', InvitationStatus.accepted),
      tile('b', 'c1', InvitationStatus.declined),
    ])['c1']!;
    expect(s.answer, MyClusterAnswer.mixed);
    expect(s.needsAnswer, isFalse);
  });

  test('clusters are told apart, and tiles with no cluster are ignored', () {
    final map = MyClusterStatus.byCluster(userId: 'me', [
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
          'template': {
            'id': 't$id',
            'clusterId': 'c1',
            'designatedUsers': [
              {'designatedTileTemplateId': id, 'userId': 'me'}
            ],
          },
        });
    final s = MyClusterStatus.byCluster(userId: 'me', [
      raw('a', 'InvitationStatus.accepted'),
      raw('b', 'tentative'),
      raw('c', 'something-new'),
    ])['c1']!;
    expect([s.accepted, s.pending], [1, 2],
        reason: 'tentative and unknown count as still to answer');
  });

  // Step 9.11b fix: only designated tile templates designated to the
  // signed-in user are mine - otherwise "Check fit" previewed someone else's
  // template and the server answered 404.
  group('only my own assignments', () {
    test('another person\'s assignment in the same cluster is not mine',
        () {
      final s = MyClusterStatus.byCluster(userId: 'me', [
        tsDesignatedTile('mine', clusterId: 'c1'),
        tsDesignatedTile('theirs', clusterId: 'c1', ownerId: 'someone'),
      ])['c1']!;
      expect([s.taskCount, s.pending], [1, 1]);
      expect(s.pendingAssignmentIds, ['mine']);
    });

    test('a cluster where I hold nothing has no status', () {
      expect(
          MyClusterStatus.byCluster(userId: 'me', [
            tsDesignatedTile('theirs', clusterId: 'c1', ownerId: 'someone'),
          ]),
          isEmpty);
    });

    test('an assignment whose owner is not known is never mine', () {
      expect(
          MyClusterStatus.byCluster(userId: 'me', [
            tsDesignatedTile('unknown', clusterId: 'c1', ownerId: null),
          ]),
          isEmpty);
    });

    test('without a signed-in user nothing is mine', () {
      expect(
          MyClusterStatus.byCluster(userId: null, [
            tsDesignatedTile('mine', clusterId: 'c1'),
          ]),
          isEmpty);
    });
  });

  // The designated tile template's user, read as the web reads it: the
  // tilette's `designatedUsers` entry for this template, by `userId`.
  group('whose designated tile template a tile is', () {
    test('the user of this template\'s entry in its tilette', () {
      final tile = DesignatedTile.fromJson({
        'id': 'a1',
        'template': {
          'id': 't1',
          'clusterId': 'c1',
          'designatedUsers': [
            {'designatedTileTemplateId': 'a0', 'userId': 'other'},
            {'designatedTileTemplateId': 'a1', 'userId': 'u1'},
          ],
        },
      });
      expect(tile.designatedUserId, 'u1');
    });

    test('the entry\'s profile id when it has no userId', () {
      final tile = DesignatedTile.fromJson({
        'id': 'a1',
        'template': {
          'id': 't1',
          'designatedUsers': [
            {'designatedTileTemplateId': 'a1', 'userProfile': {'id': 'u1'}},
          ],
        },
      });
      expect(tile.designatedUserId, 'u1');
    });

    test('never the tile-level `user`: it is not the template\'s designated '
        'user (seen on device - Check fit vanished for recipients)', () {
      final tile = DesignatedTile.fromJson({
        'id': 'a1',
        'user': {'id': 'owner'},
        'template': {
          'id': 't1',
          'designatedUsers': [
            {'designatedTileTemplateId': 'a1', 'userId': 'recipient'},
          ],
        },
      });
      expect(tile.designatedUserId, 'recipient');
      expect(
          DesignatedTile.fromJson({'id': 'a1', 'user': {'id': 'owner'}})
              .designatedUserId,
          isNull);
    });

    test('not known without an entry for this template', () {
      expect(DesignatedTile.fromJson({'id': 'a1'}).designatedUserId, isNull);
    });
  });

  test('nothing in, nothing out', () {
    expect(MyClusterStatus.byCluster(const <DesignatedTile>[], userId: 'me'), isEmpty);
  });
}
