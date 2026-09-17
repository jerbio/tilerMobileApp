// Step 6.1 — `TileDetailDraft`: the calendar-event editor's one model.
//
// The legacy `TileDetail` keeps its state in widgets and rebuilds an
// `EditCalendarEvent` on every change (`dataChange`), then decides Save
// from `updateProceed`. The draft inverts that: seeded once from the loaded
// `CalendarEvent`, change-notified, read by stateless widgets.
//
// Fields (plan §5.4, D19): name, per-tile duration, sessions (split),
// location, repetition, priority, colour. Passthrough (sent as loaded,
// D14): the series window, deadline automation, restriction profile,
// identity, note.
//
// Rules reproduced:
//   * dirtiness — per field against the original, using the legacy
//     equivalence (`isEditTileEventEquivalentToCalendarEvent`): duration by
//     minutes, location by address + description, repetition by rule;
//   * `isValid` — `EditCalendarEvent.isValid` on the editable fields (name
//     present, sessions ≥ 1), naming the failing reason;
//   * `canSave` — `TileDetail.updateProceed`: valid AND not equivalent;
//   * `mode` — ownership, then lifecycle, as Edit Tile.
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0);
final DateTime end = DateTime.utc(2026, 9, 20, 23, 59);

Map<String, dynamic> weeklyJson(
        {List<String> days = const ['monday', 'wednesday', 'friday']}) =>
    <String, dynamic>{
      'isEnabled': true,
      'isForever': false,
      'frequency': 'weekly',
      'weekday': days,
      'repetitionTimeline': <String, dynamic>{
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
      },
    };

Location place(String name, String address) =>
    Location.fromJson(<String, dynamic>{
      'description': name,
      'address': address,
      'isNull': false,
      'isDefault': false,
      'isVerified': true,
    });

CalendarEvent loaded({
  String? thirdPartyType = 'tiler',
  bool isRigid = false,
  bool isProcrastinate = false,
  bool isEnabled = true,
  bool isComplete = false,
  int split = 3,
  int? durationMinutes = 90,
  String priority = 'medium',
  Map<String, dynamic>? repetition,
  Location? location,
  Color? color,
  String? note,
  Map<String, dynamic>? restrictionProfile,
}) =>
    CalendarEvent.fromJson(<String, dynamic>{
      'id': 'cal-1',
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'splitCount': split,
      // Null: the key is ABSENT, as `api/CalendarEvent` sends it today.
      if (thirdPartyType != null) 'thirdPartyType': thirdPartyType,
      'thirdPartyId':
          thirdPartyType == null || thirdPartyType == 'tiler' ? null : 'ext-9',
      'thirdPartyUserId': thirdPartyType == null || thirdPartyType == 'tiler'
          ? null
          : 'ext-user-3',
      'isRigid': isRigid,
      'isProcrastinateEvent': isProcrastinate,
      'isEnabled': isEnabled,
      'isComplete': isComplete,
      'isAutoReviseDeadline': true,
      'priority': priority,
      if (durationMinutes != null)
        // The model casts this as a double; an int would parse as absent.
        'eachTileDuration': (durationMinutes * 60 * 1000).toDouble(),
      if (repetition != null) 'repetition': repetition,
      if (location != null)
        'location': <String, dynamic>{
          'description': location.description,
          'address': location.address,
          'isNull': false,
          'isDefault': false,
          'isVerified': true,
        },
      if (color != null)
        'uiConfig': <String, dynamic>{
          'color': <String, dynamic>{
            'r': (color.r * 255).round(),
            'g': (color.g * 255).round(),
            'b': (color.b * 255).round(),
            'o': color.a,
          },
        },
      if (note != null) 'blob': <String, dynamic>{'note': note},
      if (restrictionProfile != null) 'restrictionProfile': restrictionProfile,
    });

TileDetailDraft draft([CalendarEvent? original]) =>
    TileDetailDraft.fromLoaded(original ?? loaded());

RepetitionData weekly({Set<int> days = const <int>{1, 3, 5}}) => RepetitionData(
      frequency: RepetitionFrequency.weekly,
      repetitionStart: start,
      repetitionEnd: end,
      weeklyRepetition: days,
      isEnabled: true,
    );

void main() {
  group('Seeding', () {
    test('every editable field comes from the loaded calendar event', () {
      final d = draft(loaded(
          repetition: weeklyJson(),
          location: place('Work', '456 Market St'),
          color: const Color(0xFFE91E63),
          priority: 'high'));
      expect(d.name, 'Write report');
      expect(d.duration, const Duration(minutes: 90));
      expect(d.split, 3);
      expect(d.priority, TilePriority.high);
      expect(d.color, const Color(0xFFE91E63));
      expect(d.location?.description, 'Work');
      expect(d.location?.address, '456 Market St');
      expect(d.repetition?.frequency, RepetitionFrequency.weekly);
      expect(d.repetition?.weeklyRepetition, <int>{1, 3, 5});
    });

    test('absent optionals seed as absent', () {
      final d = draft(loaded(durationMinutes: null));
      expect(d.duration, isNull);
      expect(d.location, isNull);
      expect(d.repetition, isNull);
      expect(d.color, isNull);
      expect(d.priority, TilePriority.medium, reason: 'the model default');
    });

    test('a seeded draft is clean, valid, and cannot be saved', () {
      final d = draft();
      expect(d.isDirty, isFalse);
      expect(d.dirtyFields, isEmpty);
      expect(d.isValid, isTrue);
      expect(d.invalidReason, isNull);
      expect(d.canSave, isFalse);
    });

    test('identity and passthrough travel untouched (D14)', () {
      final d = draft(loaded(note: 'bring the charts'));
      expect(d.id, 'cal-1');
      expect(d.thirdPartyType, 'tiler');
      expect(d.thirdPartyId, '',
          reason: 'the model defaults it to empty, not null (Step 0.1)');
      expect(
          d.windowStart.millisecondsSinceEpoch, start.millisecondsSinceEpoch);
      expect(d.windowEnd.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
      expect(d.isAutoReviseDeadline, isTrue);
      expect(d.isAutoDeadline, isNull,
          reason: 'never parsed from the wire today; sent back as loaded');
      expect(d.restrictionProfile, isNull);
      expect(d.note, 'bring the charts');
      final CalendarEvent ext = loaded(thirdPartyType: 'google');
      expect(draft(ext).thirdPartyId, 'ext-9');
      expect(draft(ext).thirdPartyUserId, 'ext-user-3');
      expect(draft(ext).thirdPartyType, 'google');
    });

    test('a loader-supplied location wins over the event\'s own', () {
      // The legacy screen fetches the location separately (LocationBloc)
      // and that answer is what it edits.
      final d = TileDetailDraft.fromLoaded(
          loaded(location: place('Old', '1 Old St')),
          location: place('New', '2 New St'));
      expect(d.location?.description, 'New');
      expect(d.isDirty, isFalse,
          reason: 'the supplied location IS the original');
    });
  });

  group('Note', () {
    test('empty and the legacy literal "null" read as no note', () {
      expect(draft(loaded(note: 'bring the charts')).note, 'bring the charts');
      expect(draft(loaded(note: 'null')).note, isNull);
      expect(draft(loaded(note: ' ')).note, isNull);
      expect(draft().note, isNull);
    });
  });

  group('Dirtiness is per field, against the original', () {
    test('each setter marks exactly its own field', () {
      final cases = <TileDetailField, void Function(TileDetailDraft)>{
        TileDetailField.name: (d) => d.setName('Write REPORT'),
        TileDetailField.duration: (d) =>
            d.setDuration(const Duration(minutes: 120)),
        TileDetailField.split: (d) => d.setSplit(4),
        TileDetailField.location: (d) =>
            d.setLocation(place('Work', '456 Market St')),
        TileDetailField.repetition: (d) => d.setRepetition(weekly()),
        TileDetailField.priority: (d) => d.setPriority(TilePriority.high),
        TileDetailField.color: (d) => d.setColor(const Color(0xFFE91E63)),
      };
      for (final MapEntry<TileDetailField, void Function(TileDetailDraft)> c
          in cases.entries) {
        final d = draft();
        c.value(d);
        expect(d.dirtyFields, <TileDetailField>{c.key},
            reason: '${c.key} must dirty itself and nothing else');
      }
    });

    test('reverting a value clears its dirtiness', () {
      final d = draft()..setSplit(5);
      expect(d.isDirty, isTrue);
      d.setSplit(3);
      expect(d.isDirty, isFalse);
    });

    test('duration compares by minutes, as the legacy equivalence does', () {
      final d = draft()..setDuration(const Duration(minutes: 90, seconds: 20));
      expect(d.isDirty, isFalse);
    });

    test('location compares by address and description', () {
      final d = draft(loaded(location: place('Work', '456 Market St')));
      d.setLocation(place('Work', '456 Market St'));
      expect(d.isDirty, isFalse, reason: 'a different object, same place');
      d.setLocation(place('Work', '789 Pine Ave'));
      expect(d.dirtyFields, <TileDetailField>{TileDetailField.location});
    });

    test('clearing a loaded location is a change; clearing none is not', () {
      expect((draft()..clearLocation()).isDirty, isFalse);
      final d = draft(loaded(location: place('Work', '456 Market St')))
        ..clearLocation();
      expect(d.location, isNull);
      expect(d.dirtyFields, <TileDetailField>{TileDetailField.location});
      expect(d.locationCleared, isTrue);
      expect(draft().locationCleared, isFalse,
          reason: 'nothing to clear on the server');
    });

    test('repetition compares by rule, not identity', () {
      final d = draft(loaded(repetition: weeklyJson()));
      d.setRepetition(weekly());
      expect(d.isDirty, isFalse, reason: 'the same Mon/Wed/Fri rule');
      d.setRepetition(weekly(days: <int>{1, 3}));
      expect(d.dirtyFields, <TileDetailField>{TileDetailField.repetition});
      d.setRepetition(null);
      expect(d.dirtyFields, <TileDetailField>{TileDetailField.repetition},
          reason: 'removing the rule is a change');
    });

    test('every change notifies once', () {
      final d = draft();
      int notified = 0;
      d.addListener(() => notified++);
      d.setName('x');
      d.setPriority(TilePriority.low);
      d.clearLocation();
      expect(notified, 3);
    });
  });

  group('Restriction profile (6.4)', () {
    test('editable, dirty by the legacy equivalence, null means Anytime', () {
      final d = draft();
      expect(d.restrictionProfile, isNull);
      d.setRestrictionProfile(RestrictionProfile.noRestriction()
        ..id = 'rp-7'
        ..isEnabled = true);
      expect(d.dirtyFields, <TileDetailField>{TileDetailField.restriction});
      d.setRestrictionProfile(null);
      expect(d.isDirty, isFalse);
    });
  });

  group('Note mirror (D13)', () {
    test('a persisted note shows, is sent, and never dirties', () {
      final d = draft();
      int notified = 0;
      d.addListener(() => notified++);
      d.mirrorNote('new note');
      expect(d.note, 'new note');
      expect(d.rawNote, 'new note');
      expect(d.isDirty, isFalse);
      expect(notified, 1);
      expect(draft().rawNote, '', reason: 'the legacy seed for no note object');
    });
  });

  group('Validity names its reason (EditCalendarEvent.isValid)', () {
    test('an empty or whitespace name', () {
      for (final String bad in <String>['', '   ']) {
        final d = draft()..setName(bad);
        expect(d.isValid, isFalse);
        expect(d.invalidReason, TileDetailInvalidReason.nameRequired);
      }
    });

    test('fewer than one session', () {
      final d = draft()..setSplit(0);
      expect(d.isValid, isFalse);
      expect(d.invalidReason, TileDetailInvalidReason.splitRequired);
    });

    test('the first failing rule wins, in the legacy order', () {
      final d = draft()
        ..setName('')
        ..setSplit(0);
      expect(d.invalidReason, TileDetailInvalidReason.nameRequired);
    });
  });

  group('Mode', () {
    test('a live Tiler event is editable', () {
      expect(draft().mode, EditTileMode.editable);
    });

    test('a completed or disabled event is read-only', () {
      expect(draft(loaded(isComplete: true)).mode, EditTileMode.readOnly);
      expect(draft(loaded(isEnabled: false)).mode, EditTileMode.readOnly);
    });

    test('no thirdPartyType on the wire is a Tiler event, not a provider one',
        () {
      // Seen on device 2026-09-15: `api/CalendarEvent` omits the field, so
      // every series read as provider-owned and locked. The legacy screen
      // seeds it as '' and never locks on it.
      final d = draft(loaded(thirdPartyType: null));
      expect(d.mode, EditTileMode.editable);
      expect(d.isProviderOwned, isFalse);
      expect(d.thirdPartyType, '', reason: 'the legacy seed');
      expect(draft(loaded(thirdPartyType: 'google')).isProviderOwned, isTrue);
    });

    test('a provider event is third-party, whatever else it is', () {
      expect(draft(loaded(thirdPartyType: 'google')).mode,
          EditTileMode.thirdParty);
      expect(draft(loaded(thirdPartyType: 'google', isComplete: true)).mode,
          EditTileMode.thirdParty);
    });

    test('a blocked-out event is procrastinate unless it is over', () {
      expect(draft(loaded(isProcrastinate: true)).mode,
          EditTileMode.procrastinate);
      expect(draft(loaded(isProcrastinate: true, isComplete: true)).mode,
          EditTileMode.readOnly);
    });

    test('the kind follows rigidity (D3)', () {
      expect(draft().isRigid, isFalse);
      expect(draft(loaded(isRigid: true)).isRigid, isTrue);
    });
  });

  group('canSave reproduces TileDetail.updateProceed', () {
    test('dirty AND valid', () {
      expect(draft().canSave, isFalse);
      expect((draft()..setSplit(4)).canSave, isTrue);
      expect((draft()..setName('')).canSave, isFalse);
      expect(
          (draft()
                ..setName('x')
                ..setSplit(0))
              .canSave,
          isFalse);
    });

    test(
        'a blocked-out event: the window is not editable here, so the '
        'legacy time-moved shortcut never fires', () {
      // updateProceed let a procrastinate tile save on a moved time even
      // when otherwise invalid; the redesign sends the window as loaded
      // (D14), so that path is unreachable and the plain rule applies.
      final d = draft(loaded(isProcrastinate: true))..setName('');
      expect(d.canSave, isFalse);
      expect(
          (draft(loaded(isProcrastinate: true))..setSplit(4)).canSave, isTrue);
    });
  });
}
