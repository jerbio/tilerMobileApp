// TileShare redesign Step 9.2 (T17): every activity event becomes a sentence
// with an actor and a subject. This is the PURE half — it decides the sentence
// kind and its parameters (who, what, when); the localized wording is applied
// by the UI (Step 9.28).
//   * "You" when the actor is the signed-in user; a name when known; else
//     unknown;
//   * the subject of recipient events comes from `targetUserId`, resolved
//     against the cluster's participants (unknown → null);
//   * a task title resolves: metadata title → tiletteTitle → context lookup;
//   * edits read as deadline / renamed / notes / generic per `changedFields`.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareActivitySentence.dart';

TileShareActivity _e(String type,
        {int version = 1,
        String? actorId,
        String? actorName,
        String? targetUserId,
        String? tiletteId,
        String? tiletteTitle,
        String? clusterTitle,
        Map<String, dynamic>? metadata}) =>
    TileShareActivity.fromJson({
      'eventId': 'e-$type',
      'schemaVersion': version,
      'eventType': type,
      'clusterId': 'c1',
      'occurredAt': 1760000000000,
      if (actorId != null) 'actorId': actorId,
      if (actorName != null) 'actorName': actorName,
      if (targetUserId != null) 'targetUserId': targetUserId,
      if (tiletteId != null) 'tiletteId': tiletteId,
      if (tiletteTitle != null) 'tiletteTitle': tiletteTitle,
      if (clusterTitle != null) 'clusterTitle': clusterTitle,
      if (metadata != null) 'metadata': metadata,
    });

void main() {
  group('sentence kind per event type', () {
    const expected = <String, ActivitySentenceKind>{
      'cluster_created': ActivitySentenceKind.clusterCreated,
      'cluster_deleted': ActivitySentenceKind.clusterDeleted,
      'cluster_invitation': ActivitySentenceKind.clusterInvitation,
      'tilette_added': ActivitySentenceKind.tiletteAdded,
      'tilette_deleted': ActivitySentenceKind.tiletteDeleted,
      'tilette_restored': ActivitySentenceKind.tiletteRestored,
      'recipient_added': ActivitySentenceKind.recipientAdded,
      'recipient_removed': ActivitySentenceKind.recipientRemoved,
      'recipient_restored': ActivitySentenceKind.recipientRestored,
      'invitation_sent': ActivitySentenceKind.invitationSent,
      'invitation_send_failed': ActivitySentenceKind.invitationSendFailed,
      'invitation_send_unknown': ActivitySentenceKind.invitationSendUnknown,
      'assignment_accepted': ActivitySentenceKind.assignmentAccepted,
      'assignment_declined': ActivitySentenceKind.assignmentDeclined,
      'assignment_completed': ActivitySentenceKind.assignmentCompleted,
      'assignment_reopened': ActivitySentenceKind.assignmentReopened,
    };
    expected.forEach((type, kind) {
      test(type, () => expect(ActivitySentence.of(_e(type)).kind, kind));
    });

    test('an unknown type or a future schema is `unknown`', () {
      expect(ActivitySentence.of(_e('legacy_custom_event')).kind,
          ActivitySentenceKind.unknown);
      expect(ActivitySentence.of(_e('assignment_accepted', version: 99)).kind,
          ActivitySentenceKind.unknown);
    });
  });

  group('actor', () {
    const ctx = ActivityContext(currentUserId: 'me');

    test('me → isMe, whatever the name', () {
      final s = ActivitySentence.of(
          _e('assignment_accepted', actorId: 'me', actorName: 'Jerome B'),
          context: ctx);
      expect(s.actor.isMe, isTrue);
      expect(s.actor.isKnown, isTrue);
    });

    test('someone else with a name', () {
      final s = ActivitySentence.of(
          _e('assignment_accepted', actorId: 'u2', actorName: 'Sarah Kim'),
          context: ctx);
      expect(s.actor.isMe, isFalse);
      expect(s.actor.name, 'Sarah Kim');
      expect(s.actor.isKnown, isTrue);
    });

    test('no actor (deleted account) is unknown, never "me"', () {
      final s = ActivitySentence.of(_e('assignment_accepted'), context: ctx);
      expect(s.actor.isMe, isFalse);
      expect(s.actor.name, isNull);
      expect(s.actor.isKnown, isFalse);
    });

    test('without a signed-in user nobody is "me"', () {
      final s = ActivitySentence.of(
          _e('assignment_accepted', actorId: 'me', actorName: 'X'));
      expect(s.actor.isMe, isFalse);
    });
  });

  group('edit sentences follow the changed fields', () {
    ActivitySentence edit(List<String> fields, {bool withDeadline = false}) =>
        ActivitySentence.of(_e('tilette_edited', metadata: {
          'changedFields': fields,
          if (withDeadline) 'deadlineBefore': 1760000000000,
          if (withDeadline) 'deadlineAfter': 1760086400000,
        }));

    test('deadline only → deadlineChanged with old and new', () {
      final s = edit(['deadline'], withDeadline: true);
      expect(s.kind, ActivitySentenceKind.tiletteDeadlineChanged);
      expect(s.deadlineBefore,
          DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true));
      expect(s.deadlineAfter,
          DateTime.fromMillisecondsSinceEpoch(1760086400000, isUtc: true));
    });

    test('name only → renamed; note only → notes updated', () {
      expect(edit(['name']).kind, ActivitySentenceKind.tiletteRenamed);
      expect(edit(['note']).kind, ActivitySentenceKind.tiletteNotesUpdated);
    });

    test('several fields, or none known → generic updated', () {
      expect(edit(['name', 'deadline'], withDeadline: true).kind,
          ActivitySentenceKind.tiletteUpdated);
      expect(edit(const []).kind, ActivitySentenceKind.tiletteUpdated);
      expect(ActivitySentence.of(_e('tilette_edited')).kind,
          ActivitySentenceKind.tiletteUpdated);
    });
  });

  group('task title resolution', () {
    String? lookup(String? id) => id == 't1' ? 'From the lookup' : null;

    test('metadata title wins (it is the snapshot for deletions)', () {
      final s = ActivitySentence.of(
          _e('tilette_deleted',
              tiletteId: 't1',
              tiletteTitle: 'Current',
              metadata: {'title': 'Snapshot'}),
          context: ActivityContext(titleOfTilette: lookup));
      expect(s.taskTitle, 'Snapshot');
    });

    test('then the server-projected tiletteTitle', () {
      final s = ActivitySentence.of(
          _e('assignment_completed', tiletteId: 't1', tiletteTitle: 'Current'),
          context: ActivityContext(titleOfTilette: lookup));
      expect(s.taskTitle, 'Current');
    });

    test('then the context lookup, then null', () {
      expect(
          ActivitySentence.of(_e('assignment_completed', tiletteId: 't1'),
                  context: ActivityContext(titleOfTilette: lookup))
              .taskTitle,
          'From the lookup');
      expect(
          ActivitySentence.of(_e('assignment_completed', tiletteId: 'gone'),
                  context: ActivityContext(titleOfTilette: lookup))
              .taskTitle,
          isNull);
      expect(ActivitySentence.of(_e('assignment_completed')).taskTitle,
          isNull);
    });

    test('the cluster title is passed through', () {
      expect(
          ActivitySentence.of(_e('cluster_created', clusterTitle: 'Launch Prep'))
              .clusterTitle,
          'Launch Prep');
    });
  });

  group('subject of recipient events', () {
    String? names(String? id) => const {'u9': 'Marcus Lee'}[id];
    final ctx = ActivityContext(currentUserId: 'me', nameOfUser: names);

    test('resolved from targetUserId against the participants', () {
      final s = ActivitySentence.of(
          _e('recipient_added', actorId: 'owner', targetUserId: 'u9'),
          context: ctx);
      expect(s.subject, isNotNull);
      expect(s.subject!.name, 'Marcus Lee');
      expect(s.subject!.isMe, isFalse);
    });

    test('the target being me is flagged', () {
      final s = ActivitySentence.of(
          _e('recipient_added', actorId: 'owner', targetUserId: 'me'),
          context: ctx);
      expect(s.subject!.isMe, isTrue);
    });

    test('an unresolvable target is an unknown subject, not a crash', () {
      final s = ActivitySentence.of(
          _e('recipient_removed', actorId: 'owner', targetUserId: 'ghost'),
          context: ctx);
      expect(s.subject, isNotNull);
      expect(s.subject!.isKnown, isFalse);
    });

    test('no target, or a non-recipient event, has no subject', () {
      expect(ActivitySentence.of(_e('recipient_added'), context: ctx).subject,
          isNull);
      expect(
          ActivitySentence.of(_e('assignment_accepted', targetUserId: 'u9'),
                  context: ctx)
              .subject,
          isNull);
    });
  });

  group('delivery events carry the channel', () {
    test('email / sms / push are passed through; others dropped', () {
      for (final channel in ['email', 'sms', 'push']) {
        expect(
            ActivitySentence.of(
                    _e('invitation_sent', metadata: {'channel': channel}))
                .channel,
            channel);
      }
      expect(
          ActivitySentence.of(
                  _e('invitation_sent', metadata: {'channel': 'fax'}))
              .channel,
          isNull);
    });
  });
}
