// TileShare redesign (T13, as decided 2026-09-29): NO cluster-level progress
// ships. Completion exists only per assignment (one recipient on one tilette),
// so it is shown per tilette/assignment and never rolled up. What lists and
// headers show instead is the RSVP STATUS summary — “3 of 5 accepted” —
// derived from the tilettes' assignments:
//   * Broadcast — counts assignments;
//   * Class     — counts PEOPLE (matched across tasks); a person is accepted
//                 only when accepted on every task they hold, declined only
//                 when declined on every one, otherwise still pending;
//   * Project   — counts TILETTES: accepted when anyone accepted it, declined
//                 when everyone assigned declined, otherwise pending.
// The pure layer must also tolerate the statuses the server can send
// (`tentative` = still pending) instead of throwing.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareRsvpSummary.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';

Map<String, dynamic> _as(String? email, String? rsvp, {String? id}) => {
      'id': id ?? 'asg-$email-$rsvp',
      if (rsvp != null) 'rsvpStatus': rsvp,
      if (email != null) 'userProfile': {'id': 'u-$email', 'email': email},
    };

TileShareTemplate _t(String id, List<Map<String, dynamic>> assignments) =>
    TileShareTemplate.fromJson({
      'id': id,
      'name': id,
      'clusterId': 'c',
      'designatedUsers': assignments,
    });

List<DesignatedUser> _users(List<String?> statuses) => [
      for (int i = 0; i < statuses.length; i++)
        DesignatedUser.fromJson({
          'id': 'u$i',
          if (statuses[i] != null) 'rsvpStatus': statuses[i],
        })
    ];

(int, int, int, int) _c(TileShareRsvpSummary s) =>
    (s.total, s.accepted, s.declined, s.pending);

void main() {
  group('TileShareRsvpSummary.fromUsers (Broadcast)', () {
    test('no assignments → zeros', () {
      expect(_c(TileShareRsvpSummary.fromUsers(const [])), (0, 0, 0, 0));
    });

    test('everyone pending (none / missing / tentative)', () {
      final s = TileShareRsvpSummary.fromUsers(
          _users(['none', null, 'tentative']));
      expect(_c(s), (3, 0, 0, 3));
    });

    test('accepted / declined / pending are counted separately', () {
      final s = TileShareRsvpSummary.fromUsers(
          _users(['accepted', 'accepted', 'declined', 'none']));
      expect(_c(s), (4, 2, 1, 1));
    });
  });

  group('TileShareRsvpSummary.fromClass (people, across their tasks)', () {
    test('two people accepted on every task', () {
      final s = TileShareRsvpSummary.fromClass([
        _t('t1', [_as('a@x.com', 'accepted'), _as('b@x.com', 'accepted')]),
        _t('t2', [_as('a@x.com', 'accepted'), _as('b@x.com', 'accepted')]),
      ]);
      expect(_c(s), (2, 2, 0, 0));
    });

    test('accepted only when accepted on EVERY task they hold', () {
      final s = TileShareRsvpSummary.fromClass([
        _t('t1', [_as('a@x.com', 'accepted'), _as('b@x.com', 'accepted')]),
        _t('t2', [_as('a@x.com', 'none'), _as('b@x.com', 'accepted')]),
      ]);
      expect(_c(s), (2, 1, 0, 1));
    });

    test('declined only when declined on every task; a mix is pending', () {
      final s = TileShareRsvpSummary.fromClass([
        _t('t1', [_as('a@x.com', 'declined'), _as('b@x.com', 'declined')]),
        _t('t2', [_as('a@x.com', 'declined'), _as('b@x.com', 'accepted')]),
      ]);
      expect(_c(s), (2, 0, 1, 1));
    });

    test('a person missing from a task is judged on the tasks they hold', () {
      final s = TileShareRsvpSummary.fromClass([
        _t('t1', [_as('a@x.com', 'accepted')]),
        _t('t2', const []),
      ]);
      expect(_c(s), (1, 1, 0, 0));
    });

    test('the same person is matched across tasks by email, case-insensitively',
        () {
      final s = TileShareRsvpSummary.fromClass([
        _t('t1', [_as('Ann@X.com', 'accepted')]),
        _t('t2', [_as('ann@x.com', 'accepted')]),
      ]);
      expect(s.total, 1);
    });

    test('an assignment with no usable identity counts as its own person', () {
      final s = TileShareRsvpSummary.fromClass([
        _t('t1', [_as(null, 'accepted', id: 'anon-1')]),
        _t('t2', [_as(null, 'accepted', id: 'anon-2')]),
      ]);
      expect(s.total, 2);
    });

    test('no tilettes / no assignments → zeros', () {
      expect(TileShareRsvpSummary.fromClass(const []).total, 0);
      expect(TileShareRsvpSummary.fromClass([_t('t1', const [])]).total, 0);
    });
  });

  group('TileShareRsvpSummary.fromTilettes (Project)', () {
    test('counts are per tilette: accepted / declined / pending', () {
      final s = TileShareRsvpSummary.fromTilettes([
        _t('acc', [_as('a@x.com', 'accepted'), _as('b@x.com', 'declined')]),
        _t('dec', [_as('a@x.com', 'declined'), _as('b@x.com', 'declined')]),
        _t('pen', [_as('a@x.com', 'none')]),
        _t('empty', const []),
      ]);
      expect(_c(s), (4, 1, 1, 2));
    });

    test('no tilettes → zeros', () {
      expect(_c(TileShareRsvpSummary.fromTilettes(const [])), (0, 0, 0, 0));
    });
  });

  group('TileShareRsvpSummary.forCluster picks the counting rule by mode', () {
    final tilettes = [
      _t('t1', [_as('a@x.com', 'accepted'), _as('b@x.com', 'none')]),
      _t('t2', [_as('a@x.com', 'accepted'), _as('b@x.com', 'none')]),
    ];

    test('class → people', () {
      expect(_c(TileShareRsvpSummary.forCluster(TileShareMode.class_, tilettes)),
          (2, 1, 0, 1));
    });

    test('project → tilettes', () {
      expect(
          _c(TileShareRsvpSummary.forCluster(TileShareMode.project, tilettes)),
          (2, 2, 0, 0));
    });

    test('broadcast → the assignments of the share (all tilettes flattened)', () {
      expect(
          _c(TileShareRsvpSummary.forCluster(
              TileShareMode.broadcast, [tilettes.first])),
          (2, 1, 0, 1));
      expect(
          _c(TileShareRsvpSummary.forCluster(TileShareMode.broadcast, tilettes)),
          (4, 2, 0, 2));
    });

    test('no tilettes → zeros in every mode', () {
      for (final mode in TileShareMode.values) {
        expect(TileShareRsvpSummary.forCluster(mode, const []).total, 0);
      }
    });
  });

  group('invitation status parsing tolerates what the server can send', () {
    test('`tentative` is still pending; unknown / empty are null, not a throw',
        () {
      expect(DesignatedTile.stringToInvitationStatus('tentative'),
          InvitationStatus.none);
      expect(DesignatedTile.stringToInvitationStatus('Accepted'),
          InvitationStatus.accepted);
      expect(DesignatedTile.stringToInvitationStatus('declined'),
          InvitationStatus.declined);
      expect(DesignatedTile.stringToInvitationStatus('garbage'), isNull);
      expect(DesignatedTile.stringToInvitationStatus(''), isNull);
    });

    test('DesignatedUser.fromJson survives a `tentative` or unknown status',
        () {
      expect(
          () => DesignatedUser.fromJson({'id': 'u', 'rsvpStatus': 'tentative'}),
          returnsNormally);
      expect(
          DesignatedUser.fromJson({'id': 'u', 'rsvpStatus': 'tentative'})
              .rsvpStatus,
          InvitationStatus.none);
      expect(
          DesignatedUser.fromJson({'id': 'u', 'rsvpStatus': 'garbage'})
              .rsvpStatus,
          isNull);
    });
  });
}
