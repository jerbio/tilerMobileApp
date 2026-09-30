// TileShare redesign Step 9.2 (T7, T20): the Attention inbox is DERIVED, purely,
// from what the server already tells us:
//   * Invitation  — pending assignments from `GET api/TileShare/Invitations`
//                   (one item per cluster; expired ones excluded);
//   * AtRisk      — my accepted work that no longer fits (isViable == false);
//   * Declined / DeliveryFailed — owner-side responses from the activity feed;
//   * Changed / Completed — other people's edits / completions.
// Events I performed myself never need my attention, dismissed events are
// gone, and there is at most one item per (cluster, type).
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareInvitation.dart';
import 'package:tiler_app/data/tileShareMode.dart';

final DateTime _now = DateTime.utc(2026, 9, 29, 12);
int _ms(Duration fromNow) => _now.add(fromNow).millisecondsSinceEpoch;
const String _me = 'me';

TileShareInvitation _inv(String assignmentId, String cluster,
        {int? deadline, String inviter = 'Sarah Kim', String name = 'Task'}) =>
    TileShareInvitation.fromJson({
      'assignmentId': assignmentId,
      'clusterId': cluster,
      'tiletteId': 't-$assignmentId',
      'name': name,
      'clusterName': 'Cluster $cluster',
      if (deadline != null) 'deadline': deadline,
      'inviterName': inviter,
    });

TileShareActivity _ev(String id, String type,
        {String cluster = 'c1',
        String? actorId = 'other',
        String? actorName = 'Jordan',
        int? atMsFromNow = 0,
        Map<String, dynamic>? metadata,
        String? tiletteId}) =>
    TileShareActivity.fromJson({
      'eventId': id,
      'schemaVersion': 1,
      'eventType': type,
      'clusterId': cluster,
      'clusterTitle': 'Cluster $cluster',
      'occurredAt': _now.millisecondsSinceEpoch + (atMsFromNow ?? 0),
      if (actorId != null) 'actorId': actorId,
      if (actorId != null && actorName != null) 'actorName': actorName,
      if (tiletteId != null) 'tiletteId': tiletteId,
      if (metadata != null) 'metadata': metadata,
    });

DesignatedTile _tile(String id, String cluster,
        {String status = 'accepted', bool? viable, int? end}) =>
    DesignatedTile.fromJson({
      'id': id,
      'name': 'Tile $id',
      'invitationStatus': status,
      if (viable != null) 'isViable': viable,
      'template': {
        'id': 'tpl-$id',
        'clusterId': cluster,
        'name': 'Tile $id',
        if (end != null) 'end': end,
      },
    });

List<AttentionItem> _derive({
  Map<String, String> clusterTitles = const {},
  Iterable<TileShareInvitation> invitations = const [],
  Iterable<TileShareActivity> activity = const [],
  Iterable<DesignatedTile> received = const [],
  Set<String> dismissed = const {},
  Map<String, TileShareMode> modes = const {},
}) =>
    AttentionItems.derive(
      now: _now,
      currentUserId: _me,
      invitations: invitations,
      activity: activity,
      received: received,
      dismissedEventIds: dismissed,
      modes: modes,
      clusterTitles: clusterTitles,
    );

Iterable<AttentionType> _types(List<AttentionItem> items) =>
    items.map((i) => i.type);

void main() {
  group('TileShareInvitation model', () {
    test('parses the Invitations endpoint shape', () {
      final i = TileShareInvitation.fromJson({
        'assignmentId': 'a1',
        'clusterId': 'c1',
        'tiletteId': 't1',
        'name': 'Review PR',
        'clusterName': 'Sprint',
        'deadline': 1760000000000,
        'inviterName': 'Sarah Kim',
      });
      expect(i.assignmentId, 'a1');
      expect(i.clusterId, 'c1');
      expect(i.tiletteId, 't1');
      expect(i.name, 'Review PR');
      expect(i.clusterName, 'Sprint');
      expect(i.deadlineMs, 1760000000000);
      expect(i.inviterName, 'Sarah Kim');
    });

    test('a missing or non-numeric deadline is null; a double is truncated',
        () {
      expect(TileShareInvitation.fromJson({'assignmentId': 'a', 'clusterId': 'c'}).deadlineMs,
          isNull);
      expect(
          TileShareInvitation.fromJson(
                  {'assignmentId': 'a', 'clusterId': 'c', 'deadline': 'soon'})
              .deadlineMs,
          isNull);
      expect(
          TileShareInvitation.fromJson(
                  {'assignmentId': 'a', 'clusterId': 'c', 'deadline': 1760000000000.0})
              .deadlineMs,
          1760000000000);
    });

    test('a page parses its items and cursor', () {
      final page = TileShareInvitationPage.fromJson({
        'invitations': [
          {'assignmentId': 'a1', 'clusterId': 'c1'},
          {'assignmentId': 'a2', 'clusterId': 'c1'},
        ],
        'nextCursor': 'a2',
      });
      expect(page.items.map((i) => i.assignmentId), ['a1', 'a2']);
      expect(page.nextCursor, 'a2');
      expect(TileShareInvitationPage.fromJson({'invitations': []}).nextCursor,
          isNull);
    });
  });

  group('nothing to do', () {
    test('no input → no items', () => expect(_derive(), isEmpty));
  });

  group('Invitation', () {
    test('two assignments in one cluster are ONE item (Project: “N tasks”)', () {
      final items = _derive(invitations: [
        _inv('a1', 'c1', deadline: _ms(const Duration(days: 5))),
        _inv('a2', 'c1', deadline: _ms(const Duration(days: 2))),
      ]);
      expect(items.length, 1);
      final item = items.single;
      expect(item.type, AttentionType.invitation);
      expect(item.clusterId, 'c1');
      expect(item.clusterTitle, 'Cluster c1');
      expect(item.inviterName, 'Sarah Kim');
      expect(item.count, 2);
      expect(item.assignmentIds, ['a1', 'a2']);
      expect(item.deadlineMs, _ms(const Duration(days: 2)),
          reason: 'the earliest deadline drives urgency');
      expect(item.id, 'invitation:c1');
    });

    test('different clusters are separate items', () {
      expect(
          _derive(invitations: [_inv('a1', 'c1'), _inv('a2', 'c2')]).length, 2);
    });

    test('an expired invitation is excluded; a missing deadline is kept', () {
      final items = _derive(invitations: [
        _inv('old', 'c1', deadline: _ms(const Duration(hours: -1))),
        _inv('open', 'c2'),
      ]);
      expect(items.map((i) => i.clusterId), ['c2']);
    });

    test('the mode comes from the supplied lookup, else it is unknown', () {
      final withMode = _derive(
          invitations: [_inv('a1', 'c1')],
          modes: {'c1': TileShareMode.class_});
      expect(withMode.single.mode, TileShareMode.class_);
      expect(_derive(invitations: [_inv('a1', 'c1')]).single.mode, isNull);
    });
  });

  group('AtRisk', () {
    test('accepted work that no longer fits', () {
      final items = _derive(received: [
        _tile('d1', 'c1', viable: false, end: _ms(const Duration(days: 1))),
      ]);
      expect(items.single.type, AttentionType.atRisk);
      expect(items.single.clusterId, 'c1');
      expect(items.single.count, 1);
      expect(items.single.deadlineMs, _ms(const Duration(days: 1)));
    });

    test('viable, unknown-viability, or not-accepted tiles are ignored', () {
      final items = _derive(received: [
        _tile('a', 'c1', viable: true),
        _tile('b', 'c1'),
        _tile('c', 'c1', status: 'none', viable: false),
        _tile('d', 'c1', status: 'declined', viable: false),
      ]);
      expect(items, isEmpty);
    });

    test('the status string may carry the enum prefix', () {
      final items = _derive(received: [
        _tile('a', 'c1', status: 'InvitationStatus.accepted', viable: false),
      ]);
      expect(items.length, 1);
    });

    test('several tiles in one cluster collapse into one item', () {
      final items = _derive(received: [
        _tile('a', 'c1', viable: false),
        _tile('b', 'c1', viable: false),
        _tile('c', 'c2', viable: false),
      ]);
      expect(items.length, 2);
      expect(items.firstWhere((i) => i.clusterId == 'c1').count, 2);
    });
  });

  group('cluster titles', () {
    test('an item without a title of its own takes the cluster name', () {
      final items = _derive(
        received: [_tile('d1', 'c-risk', viable: false)],
        clusterTitles: {'c-risk': 'Sprint 42'},
      );
      expect(items.single.clusterTitle, 'Sprint 42');
    });

    test('a title the item already has wins over the lookup', () {
      final items = _derive(
        invitations: [_inv('a1', 'c1')],
        activity: [_ev('e1', 'assignment_declined', cluster: 'c2')],
        clusterTitles: {'c1': 'From the lookup', 'c2': 'From the lookup'},
      );
      expect(items.map((i) => i.clusterTitle).toSet(),
          {'Cluster c1', 'Cluster c2'});
    });

    test('no lookup entry leaves the title empty, as before', () {
      final items = _derive(received: [_tile('d1', 'c-risk', viable: false)]);
      expect(items.single.clusterTitle, isNull);
    });
  });

  group('activity-derived items (other people only)', () {
    test('Changed: shows what changed, latest first, counts the edits', () {
      final items = _derive(activity: [
        _ev('e2', 'tilette_edited', atMsFromNow: -1000, metadata: {
          'changedFields': ['deadline'],
          'deadlineBefore': 1760000000000,
          'deadlineAfter': 1760086400000,
        }),
        _ev('e1', 'tilette_edited', atMsFromNow: -5000, metadata: {
          'changedFields': ['name'],
        }),
      ]);
      expect(items.length, 1);
      final item = items.single;
      expect(item.type, AttentionType.changed);
      expect(item.count, 2);
      expect(item.actorName, 'Jordan');
      expect(item.changedFields, unorderedEquals(['deadline', 'name']));
      expect(item.deadlineAfter,
          DateTime.fromMillisecondsSinceEpoch(1760086400000, isUtc: true));
      expect(item.eventIds, ['e2', 'e1']);
      expect(item.occurredAtMs, _now.millisecondsSinceEpoch - 1000);
    });

    test('my own edits, completions and declines never need my attention', () {
      final items = _derive(activity: [
        _ev('a', 'tilette_edited', actorId: _me),
        _ev('b', 'assignment_completed', actorId: _me),
        _ev('c', 'assignment_declined', actorId: _me),
      ]);
      expect(items, isEmpty);
    });

    test('Completed and Declined come from other people', () {
      final items = _derive(activity: [
        _ev('a', 'assignment_completed', tiletteId: 't1'),
        _ev('b', 'assignment_declined', cluster: 'c2'),
      ]);
      expect(_types(items).toSet(),
          {AttentionType.completed, AttentionType.declined});
    });

    test('DeliveryFailed covers failed and unknown sends; a sent invite does not',
        () {
      final failed = _derive(activity: [
        _ev('a', 'invitation_send_failed', actorId: _me),
        _ev('b', 'invitation_send_unknown', actorId: _me),
        _ev('c', 'invitation_sent', actorId: _me),
      ]);
      expect(failed.single.type, AttentionType.deliveryFailed);
      expect(failed.single.count, 2);
      expect(failed.single.hasUnknownOutcome, isTrue);
      expect(failed.single.eventIds, unorderedEquals(['a', 'b']));
    });

    test('delivery problems are the owner\'s own actions — they still show', () {
      final items = _derive(
          activity: [_ev('a', 'invitation_send_failed', actorId: _me)]);
      expect(items.length, 1);
    });

    test('unknown types and future schemas are ignored', () {
      final future = TileShareActivity.fromJson({
        'eventId': 'f',
        'schemaVersion': 99,
        'eventType': 'assignment_declined',
        'clusterId': 'c1',
        'occurredAt': _now.millisecondsSinceEpoch,
        'actorId': 'other',
      });
      final unknown = _ev('u', 'legacy_custom_event');
      expect(_derive(activity: [future, unknown]), isEmpty);
    });

    test('a dismissed event is gone; the rest of its cluster group stays', () {
      final events = [
        _ev('e1', 'tilette_edited', atMsFromNow: -1000, metadata: {
          'changedFields': ['name']
        }),
        _ev('e2', 'tilette_edited', atMsFromNow: -2000, metadata: {
          'changedFields': ['note']
        }),
      ];
      expect(_derive(activity: events, dismissed: {'e1', 'e2'}), isEmpty);
      final partial = _derive(activity: events, dismissed: {'e1'});
      expect(partial.single.count, 1);
      expect(partial.single.eventIds, ['e2']);
      expect(partial.single.changedFields, ['note']);
    });

    test('at most one item per (cluster, type)', () {
      final items = _derive(activity: [
        _ev('a', 'assignment_declined', cluster: 'c1'),
        _ev('b', 'assignment_declined', cluster: 'c1'),
        _ev('c', 'assignment_declined', cluster: 'c2'),
      ]);
      expect(items.length, 2);
      expect(items.map((i) => i.id).toSet().length, 2);
    });
  });

  group('ordering', () {
    test('by urgency: invitation, at risk, declined, delivery, changed, completed',
        () {
      final items = _derive(
        invitations: [_inv('a1', 'c1')],
        received: [_tile('d1', 'c2', viable: false)],
        activity: [
          _ev('e1', 'assignment_completed', cluster: 'c6'),
          _ev('e2', 'tilette_edited', cluster: 'c5'),
          _ev('e3', 'invitation_send_failed', cluster: 'c4', actorId: _me),
          _ev('e4', 'assignment_declined', cluster: 'c3'),
        ],
      );
      expect(_types(items).toList(), [
        AttentionType.invitation,
        AttentionType.atRisk,
        AttentionType.declined,
        AttentionType.deliveryFailed,
        AttentionType.changed,
        AttentionType.completed,
      ]);
    });

    test('deadline-driven items: earliest deadline first, no deadline last', () {
      final items = _derive(invitations: [
        _inv('a', 'c-late', deadline: _ms(const Duration(days: 9))),
        _inv('b', 'c-none'),
        _inv('c', 'c-soon', deadline: _ms(const Duration(days: 1))),
      ]);
      expect(items.map((i) => i.clusterId), ['c-soon', 'c-late', 'c-none']);
    });

    test('event-driven items: newest first', () {
      final items = _derive(activity: [
        _ev('old', 'assignment_completed', cluster: 'c-old', atMsFromNow: -9000),
        _ev('new', 'assignment_completed', cluster: 'c-new', atMsFromNow: -1000),
      ]);
      expect(items.map((i) => i.clusterId), ['c-new', 'c-old']);
    });

    test('deterministic: the same input gives the same output', () {
      List<String> run() => _derive(
            invitations: [_inv('a1', 'c1'), _inv('a2', 'c2')],
            activity: [
              _ev('e1', 'assignment_declined', cluster: 'c3'),
              _ev('e2', 'assignment_declined', cluster: 'c4'),
            ],
          ).map((i) => i.id).toList();
      expect(run(), run());
    });
  });
}
