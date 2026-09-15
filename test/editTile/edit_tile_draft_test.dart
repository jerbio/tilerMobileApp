// Step 1.1 / 6.0 — `EditTileDraft`: one model, widgets read from it.
//
// The legacy screen keeps its state in the WIDGETS and reads them back on
// every change. The draft inverts that: it is the single source of truth,
// seeded from the loaded sub-event, change-notified, with the rules from
// Step 0.3 reproduced as properties.
//
// Since D19 the draft holds ONE occurrence's fields — title, start, end,
// deadline. Repetition, priority, location, colour and sessions belong to
// the calendar event and live in `TileDetailDraft`.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0);
final DateTime end = DateTime.utc(2026, 9, 12, 15, 30);
final DateTime calStart = DateTime.utc(2026, 9, 10, 0, 0);
final DateTime calEnd = DateTime.utc(2026, 9, 20, 23, 59);

SubCalendarEvent loaded({
  String thirdPartyType = 'tiler',
  bool isRigid = false,
  bool isProcrastinate = false,
  bool isEnabled = true,
  bool isComplete = false,
  int split = 2,
}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': 'sub-1',
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'calendarEventStart': calStart.millisecondsSinceEpoch,
      'calendarEventEnd': calEnd.millisecondsSinceEpoch,
      'splitCount': split,
      'thirdPartyType': thirdPartyType,
      'thirdPartyId': thirdPartyType == 'tiler' ? null : 'ext-9',
      'thirdPartyUserId': thirdPartyType == 'tiler' ? null : 'ext-user-3',
      'isRigid': isRigid,
      'isProcrastinateEvent': isProcrastinate,
      'isEnabled': isEnabled,
      'isComplete': isComplete,
      'priority': 'medium',
    });

EditTileDraft draft([SubCalendarEvent? original]) =>
    EditTileDraft.fromLoaded(original ?? loaded());

void main() {
  group('Seeding', () {
    test('every field comes from the loaded sub-event', () {
      final d = draft();
      expect(d.name, 'Write report');
      expect(d.startTime.millisecondsSinceEpoch, start.millisecondsSinceEpoch);
      expect(d.endTime.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
      expect(d.deadline?.millisecondsSinceEpoch, calEnd.millisecondsSinceEpoch);
      expect(d.deadline?.isUtc, isFalse, reason: 'held local for the picker');
      expect(d.split, 2, reason: 'passthrough: edited on Tile Detail (D19)');
    });

    test('a seeded draft is clean and valid', () {
      final d = draft();
      expect(d.isDirty, isFalse);
      expect(d.dirtyFields, isEmpty);
      expect(d.isValid, isTrue);
      expect(d.invalidReason, isNull);
      expect(d.canSave, isFalse, reason: 'nothing to save yet');
    });

    test('identity travels through untouched', () {
      final d = draft(loaded(thirdPartyType: 'google'));
      expect(d.id, 'ext-9',
          reason: 'a non-Tiler tile is addressed by its provider id, as the '
              'legacy screen seeds it');
      expect(d.thirdPartyId, 'ext-9');
      expect(d.thirdPartyUserId, 'ext-user-3');
      expect(d.thirdPartyType, 'google');
      expect(draft().id, 'sub-1');
    });
  });

  group('Dirtiness is per field, against the original', () {
    test('each setter marks exactly its own field', () {
      final cases = <EditTileField, void Function(EditTileDraft)>{
        EditTileField.name: (d) => d.setName('Write REPORT'),
        EditTileField.startTime: (d) =>
            d.setStartTime(start.add(const Duration(minutes: 5))),
        EditTileField.endTime: (d) =>
            d.setEndTime(end.add(const Duration(minutes: 5))),
        EditTileField.deadline: (d) =>
            d.setDeadline(calEnd.add(const Duration(days: 1))),
      };
      for (final MapEntry<EditTileField, void Function(EditTileDraft)> c
          in cases.entries) {
        final d = draft();
        c.value(d);
        expect(d.dirtyFields, <EditTileField>{c.key},
            reason: '${c.key} must dirty itself and nothing else');
        expect(d.isDirty, isTrue);
      }
    });

    test('reverting a value clears its dirtiness', () {
      final d = draft()..setName('Changed');
      expect(d.isDirty, isTrue);
      d.setName('Write report');
      expect(d.isDirty, isFalse);
    });

    test('times compare by instant, not by zone or identity', () {
      final d = draft()..setStartTime(start.toLocal());
      expect(d.isDirty, isFalse);
    });

    test('timeIsDirty is what the what-if preview watches', () {
      expect((draft()..setName('x')).timeIsDirty, isFalse);
      expect(
          (draft()..setDeadline(calEnd.add(const Duration(days: 1))))
              .timeIsDirty,
          isTrue);
      expect(
          (draft()..setEndTime(end.add(const Duration(minutes: 5))))
              .timeIsDirty,
          isTrue);
    });

    test('every change notifies once', () {
      final d = draft();
      int notified = 0;
      d.addListener(() => notified++);
      d.setName('x');
      d.setEndTime(end.add(const Duration(minutes: 5)));
      expect(notified, 2);
    });
  });

  group('Validity names its reason', () {
    test('an empty or whitespace name', () {
      for (final String bad in <String>['', '   ']) {
        final d = draft()..setName(bad);
        expect(d.isValid, isFalse);
        expect(d.invalidReason, EditTileInvalidReason.nameRequired);
      }
    });

    test('an end at or before the start', () {
      final d = draft()..setEndTime(start);
      expect(d.isValid, isFalse);
      expect(d.invalidReason, EditTileInvalidReason.endNotAfterStart);
    });

    test('the first failing rule wins, in the legacy order', () {
      final d = draft()
        ..setName('')
        ..setEndTime(start);
      expect(d.invalidReason, EditTileInvalidReason.nameRequired);
    });
  });

  group('Mode', () {
    test('a live Tiler tile is editable', () {
      expect(draft().mode, EditTileMode.editable);
    });

    test('a completed or disabled tile is read-only', () {
      expect(draft(loaded(isComplete: true)).mode, EditTileMode.readOnly);
      expect(draft(loaded(isEnabled: false)).mode, EditTileMode.readOnly);
    });

    test('a provider tile is third-party, whatever else it is', () {
      expect(draft(loaded(thirdPartyType: 'google')).mode,
          EditTileMode.thirdParty);
      expect(draft(loaded(thirdPartyType: 'outlook', isComplete: true)).mode,
          EditTileMode.thirdParty);
    });

    test('a blocked-out tile is procrastinate unless it is over', () {
      expect(draft(loaded(isProcrastinate: true)).mode,
          EditTileMode.procrastinate);
      expect(draft(loaded(isProcrastinate: true, isComplete: true)).mode,
          EditTileMode.readOnly);
    });

    test('the kind follows rigidity and is not editable (D3)', () {
      expect(draft().isRigid, isFalse);
      expect(draft(loaded(isRigid: true)).isRigid, isTrue);
    });
  });

  group('canSave reproduces editTileCanProceed (Step 0.3)', () {
    test('a normal tile: dirty AND valid', () {
      expect(draft().canSave, isFalse);
      expect((draft()..setName('Changed')).canSave, isTrue);
      expect((draft()..setName('')).canSave, isFalse);
    });

    test('a blocked-out tile: a moved time saves even when otherwise invalid',
        () {
      final d = draft(loaded(isProcrastinate: true))
        ..setName('')
        ..setStartTime(start.add(const Duration(minutes: 5)));
      expect(d.canSave, isTrue);
      expect(d.invalidReason, EditTileInvalidReason.nameRequired);
    });

    test('a blocked-out tile: a moved time with a negative frame does not', () {
      final d = draft(loaded(isProcrastinate: true))..setEndTime(start);
      expect(d.canSave, isFalse);
    });
  });

  group('Scope (D19)', () {
    test('always this occurrence', () {
      expect(draft().effectiveScope, ApplicableOccurrence.single);
      expect(
          (draft()..setName('x')).effectiveScope, ApplicableOccurrence.single);
      expect(ApplicableOccurrence.single.wireValue, 'Single');
      expect(ApplicableOccurrence.all.wireValue, 'All');
    });
  });
}
