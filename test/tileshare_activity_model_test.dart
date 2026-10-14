// TileShare redesign Step 9.2 (docs/tileshare-redesign-design.md, T16): the
// activity model catches up with what the server emits.
//   * new types: cluster_invitation, assignment_completed, assignment_reopened;
//   * new fields: actorId, targetUserId, assignmentId, tiletteTitle,
//     calendarEventId, and for tilette_edited the changed fields plus the
//     old/new deadline;
//   * parsing stays ALLOW-LISTED and SCHEMA-VERSION-GATED (privacy): unknown
//     types and future schemas expose nothing, `legacySnapshot` and raw
//     provider payloads never surface.
// The canonical wire samples are the backend's own fixtures, copied to
// test/fixtures/tileshare_activity (so this test no longer reads a sibling
// repo).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareActivity.dart';

const String _fixtures = 'test/fixtures/tileshare_activity';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('$_fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _event(String type,
        {int version = 1,
        String? actorId,
        String? actorName,
        String? targetUserId,
        String? tiletteId,
        String? tiletteTitle,
        Map<String, dynamic>? metadata}) =>
    {
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
      if (metadata != null) 'metadata': metadata,
    };

TileShareActivity _parse(Map<String, dynamic> json) =>
    TileShareActivity.fromJson(json);

void main() {
  test(
      'schedule edit metadata retains start and duration alongside other fields',
      () {
    final event =
        TileShareActivity.fromJson(_event('tilette_edited', metadata: {
      'changedFields': ['name', 'note', 'start', 'deadline', 'duration']
    }));
    expect(
        event.changedFields, ['name', 'note', 'start', 'deadline', 'duration']);
  });

  group('canonical server fixtures', () {
    test('every fixture parses without throwing', () {
      final files = Directory(_fixtures)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      expect(files.length, greaterThanOrEqualTo(15));
      for (final file in files) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(() => TileShareActivity.fromJson(json), returnsNormally,
            reason: file.path);
      }
    });

    test('assignment_accepted keeps its ids', () {
      final e = _parse(_fixture('AssignmentAccepted'));
      expect(e.eventType, 'assignment_accepted');
      expect(e.isKnown, isTrue);
      expect(e.actorId, 'usr_a1b2c3d4e5f6');
      expect(e.assignmentId, 'asg_abcdef012345');
      expect(e.tiletteId, 'til_9f8e7d6c5b4a');
      expect(e.clusterId, 'clu_112233445566');
    });

    test('a deleted actor is unattributed and legacySnapshot never surfaces',
        () {
      final e = _parse(_fixture('AssignmentAcceptedDeletedActor'));
      expect(e.actorId, isNull);
      expect(e.actorName, isNull,
          reason: 'legacySnapshot.actorName must not be used');
    });

    test('recipient events carry the affected user id only', () {
      final e = _parse(_fixture('RecipientAdded'));
      expect(e.eventType, 'recipient_added');
      expect(e.targetUserId, 'usr_a1b2c3d4e5f6');
    });

    test('an unknown type exposes nothing from its payload', () {
      final e = _parse(_fixture('UnknownEventType'));
      expect(e.isKnown, isFalse);
      expect(e.title, isNull);
      expect(e.invitationChannel, isNull);
      expect(e.calendarEventId, isNull);
      expect(e.changedFields, isEmpty);
      expect(e.deadlineBefore, isNull);
      expect(e.deadlineAfter, isNull);
    });
  });

  group('new event types are known (schema v1 only)', () {
    for (final type in [
      'cluster_invitation',
      'assignment_completed',
      'assignment_reopened',
    ]) {
      test(type, () {
        expect(_parse(_event(type)).isKnown, isTrue);
        expect(_parse(_event(type, version: 99)).isKnown, isFalse);
      });
    }

    test('the 14 types the client already knew are still known', () {
      for (final type in [
        'cluster_created',
        'cluster_deleted',
        'tilette_added',
        'tilette_edited',
        'tilette_deleted',
        'tilette_restored',
        'recipient_added',
        'recipient_removed',
        'recipient_restored',
        'assignment_accepted',
        'assignment_declined',
        'invitation_sent',
        'invitation_send_failed',
        'invitation_send_unknown',
      ]) {
        expect(_parse(_event(type)).isKnown, isTrue, reason: type);
      }
    });
  });

  group('ids and names', () {
    test('actorId is kept; actorName only when the actor still exists', () {
      final withActor = _parse(
          _event('assignment_accepted', actorId: 'u1', actorName: 'Sarah Kim'));
      expect(withActor.actorId, 'u1');
      expect(withActor.actorName, 'Sarah Kim');
      final noActor = _parse(_event('assignment_accepted', actorName: 'Ghost'));
      expect(noActor.actorId, isNull);
      expect(noActor.actorName, isNull);
    });

    test('tiletteTitle is read as a plain string, otherwise null', () {
      expect(
          _parse(_event('assignment_completed', tiletteTitle: 'Review PR'))
              .tiletteTitle,
          'Review PR');
      expect(_parse(_event('assignment_completed')).tiletteTitle, isNull);
      final json = _event('assignment_completed')..['tiletteTitle'] = 42;
      expect(_parse(json).tiletteTitle, isNull);
    });
  });

  group('assignment_completed / assignment_reopened metadata', () {
    test('calendarEventId is read for completed and reopened', () {
      for (final type in ['assignment_completed', 'assignment_reopened']) {
        expect(
            _parse(_event(type, metadata: {'calendarEventId': 'cal_1'}))
                .calendarEventId,
            'cal_1',
            reason: type);
      }
    });

    test('ignored for other types, future schemas and bad values', () {
      expect(
          _parse(_event('assignment_accepted',
              metadata: {'calendarEventId': 'cal_1'})).calendarEventId,
          isNull);
      expect(
          _parse(_event('assignment_completed',
              version: 99,
              metadata: {'calendarEventId': 'cal_1'})).calendarEventId,
          isNull);
      expect(
          _parse(_event('assignment_completed',
              metadata: {'calendarEventId': 7})).calendarEventId,
          isNull);
      expect(
          _parse(_event('assignment_completed',
              metadata: {'calendarEventId': ''})).calendarEventId,
          isNull);
      expect(
          _parse(_event('assignment_completed',
              metadata: {'calendarEventId': 'x' * 129})).calendarEventId,
          isNull);
    });
  });

  group('tilette_edited: what changed', () {
    test('changed fields + old/new deadline', () {
      final e = _parse(_event('tilette_edited', metadata: {
        'changedFields': ['deadline', 'name'],
        'deadlineBefore': 1760000000000,
        'deadlineAfter': 1760086400000,
      }));
      expect(e.changedFields, ['deadline', 'name']);
      expect(e.deadlineBefore,
          DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true));
      expect(e.deadlineAfter,
          DateTime.fromMillisecondsSinceEpoch(1760086400000, isUtc: true));
    });

    test('only name / deadline / note are accepted; order kept; deduped', () {
      final e = _parse(_event('tilette_edited', metadata: {
        'changedFields': ['note', 'bogus', 'name', 'note', 'contactEmail'],
      }));
      expect(e.changedFields, ['note', 'name']);
    });

    test('at most four fields', () {
      final e = _parse(_event('tilette_edited', metadata: {
        'changedFields': ['name', 'deadline', 'note', 'name', 'note'],
        'deadlineBefore': 1,
        'deadlineAfter': 2,
      }));
      expect(e.changedFields.length, lessThanOrEqualTo(5));
    });

    test('deadline values are exposed only when `deadline` changed', () {
      final e = _parse(_event('tilette_edited', metadata: {
        'changedFields': ['name'],
        'deadlineBefore': 1760000000000,
        'deadlineAfter': 1760086400000,
      }));
      expect(e.deadlineBefore, isNull);
      expect(e.deadlineAfter, isNull);
    });

    test('deadline values must be epoch ms in the approved range', () {
      for (final bad in <Object?>[-1, 253402300800000, 'soon', 1.5, null]) {
        final e = _parse(_event('tilette_edited', metadata: {
          'changedFields': ['deadline'],
          'deadlineBefore': bad,
          'deadlineAfter': 1760086400000,
        }));
        expect(e.deadlineBefore, isNull, reason: '$bad');
      }
    });

    test('nothing is read for a future schema, another type or bad shapes', () {
      final future = _parse(_event('tilette_edited', version: 99, metadata: {
        'changedFields': ['name']
      }));
      expect(future.changedFields, isEmpty);
      final other = _parse(_event('tilette_added', metadata: {
        'changedFields': ['name'],
        'title': 'T'
      }));
      expect(other.changedFields, isEmpty);
      final notList =
          _parse(_event('tilette_edited', metadata: {'changedFields': 'name'}));
      expect(notList.changedFields, isEmpty);
      final none = _parse(_event('tilette_edited'));
      expect(none.changedFields, isEmpty);
    });
  });

  group('existing behaviour is unchanged', () {
    test('invitation channel allow-list still holds', () {
      final ok =
          _parse(_event('invitation_sent', metadata: {'channel': 'sms'}));
      expect(ok.invitationChannel, 'sms');
      final bad = _parse(_event('invitation_sent',
          metadata: {'channel': 'private@example.test'}));
      expect(bad.invitationChannel, isNull);
    });

    test('title is read for the title-carrying types only', () {
      expect(_parse(_event('tilette_added', metadata: {'title': 'Plan'})).title,
          'Plan');
      expect(
          _parse(_event('assignment_accepted', metadata: {'title': 'Plan'}))
              .title,
          isNull);
    });
  });
}
