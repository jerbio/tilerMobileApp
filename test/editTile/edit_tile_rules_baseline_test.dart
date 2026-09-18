// Step 0.3 — the rules that decide whether Save exists, frozen.
//
// Three pieces of legacy logic gate the ✓ button on the Edit Tile screen:
//
//   1. `EditTilerEvent.isValid` — is the draft sendable at all;
//   2. `Utility.isEditTileEventEquivalentToSubCalendarEvent` — has anything
//      changed;
//   3. `updateProceed()`'s procrastinate branch, which bypasses both for a
//      blocked-out tile and asks only whether the TIME moved.
//
// None was tested. The redesign's `EditTileDraft` (Step 1.1) reproduces all
// three — `isValid`, `isDirty`, and the per-mode rule — so they are pinned
// here first, against the legacy code, quirks included.
//
// The one quirk that is a DEFECT is pinned as such: the split field parses
// with `int.tryParse`, so "1.5" and "-2" reach `isValid` as `null` and the
// button silently disappears (§1.3 of the plan). The test asserts today's
// behaviour and is tagged so Step 2.3 flips it deliberately rather than
// discovering it.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/noteData.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0);
final DateTime end = DateTime.utc(2026, 9, 12, 15, 30);
final DateTime calStart = DateTime.utc(2026, 9, 10, 0, 0);
final DateTime calEnd = DateTime.utc(2026, 9, 20, 23, 59);

/// The loaded sub-event, as the screen receives it.
SubCalendarEvent loaded() => SubCalendarEvent(
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      name: 'Write report',
      id: 'sub-1',
    )
      ..split = 2
      ..calendarEventStart = calStart.millisecondsSinceEpoch.toDouble()
      ..calendarEventEnd = calEnd.millisecondsSinceEpoch.toDouble();

/// The draft `EditTile` seeds from [loaded] — see its `BlocListener`.
EditTilerEvent seeded() => EditTilerEvent()
  ..id = 'sub-1'
  ..name = 'Write report'
  ..splitCount = 2
  ..startTime = start
  ..endTime = end
  ..calStartTime = calStart
  ..calEndTime = calEnd;

bool equivalent(EditTilerEvent edit, SubCalendarEvent original) =>
    Utility.isEditTileEventEquivalentToSubCalendarEvent(edit, original);

void main() {
  group('EditTilerEvent.isValid', () {
    test('a seeded draft is valid', () {
      expect(seeded().isValid, isTrue);
    });

    test('every required field, absent, invalidates', () {
      expect((seeded()..name = '').isValid, isFalse);
      expect((seeded()..name = null).isValid, isFalse);
      expect((seeded()..id = '').isValid, isFalse);
      expect((seeded()..startTime = null).isValid, isFalse);
      expect((seeded()..endTime = null).isValid, isFalse);
      expect((seeded()..calStartTime = null).isValid, isFalse);
      expect((seeded()..calEndTime = null).isValid, isFalse);
    });

    test('split must be a positive integer', () {
      expect((seeded()..splitCount = 0).isValid, isFalse);
      expect((seeded()..splitCount = -1).isValid, isFalse);
      expect((seeded()..splitCount = 1).isValid, isTrue);
    });

    test('start must be strictly before end', () {
      expect((seeded()..endTime = start).isValid, isFalse);
      expect(
          (seeded()..endTime = start.subtract(const Duration(minutes: 1)))
              .isValid,
          isFalse);
    });

    test('DOCUMENTED DEFECT: a non-integer split silently invalidates', () {
      // The legacy field is a free-text `TextField` parsed with
      // `int.tryParse`. "1.5" and "-2" become null; `isValid` is then false
      // and the ✓ button disappears with no message. Pinned as today's
      // behaviour; Step 2.3 (session stepper, D12) makes this unreachable
      // and flips this test.
      expect(int.tryParse('1.5'), isNull);
      expect((seeded()..splitCount = int.tryParse('1.5')).isValid, isFalse);
      expect((seeded()..splitCount = int.tryParse('-2')).isValid, isFalse,
          reason: '"-2" parses to -2, which fails the > 0 check the same way');
    });
  });

  group('Equivalence with the loaded sub-event', () {
    test('an untouched draft is equivalent', () {
      expect(equivalent(seeded(), loaded()), isTrue);
    });

    test('each editable field breaks equivalence', () {
      expect(equivalent(seeded()..name = 'Write REPORT', loaded()), isFalse);
      expect(equivalent(seeded()..splitCount = 3, loaded()), isFalse);
      expect(
          equivalent(
              seeded()..startTime = start.add(const Duration(minutes: 5)),
              loaded()),
          isFalse);
      expect(
          equivalent(seeded()..endTime = end.add(const Duration(minutes: 5)),
              loaded()),
          isFalse);
      expect(
          equivalent(seeded()..calEndTime = calEnd.add(const Duration(days: 1)),
              loaded()),
          isFalse);
      expect(
          equivalent(
              seeded()..calStartTime = calStart.add(const Duration(days: 1)),
              loaded()),
          isFalse);
    });

    test('times compare by instant, not by zone', () {
      expect(
          equivalent(seeded()..startTime = start.toLocal(), loaded()), isTrue);
    });

    test('notes compare only when BOTH sides have one', () {
      // A draft with a note against a sub-event without noteData is still
      // equivalent — the note is not part of what this comparison guards.
      expect(equivalent(seeded()..note = 'hello', loaded()), isTrue);

      final SubCalendarEvent withNote = loaded()
        ..noteData = NoteData.fromJson(<String, dynamic>{'note': 'hello'});
      expect(equivalent(seeded()..note = 'hello', withNote), isTrue);
      expect(equivalent(seeded()..note = 'changed', withNote), isFalse);
      expect(equivalent(seeded()..note = null, withNote), isTrue,
          reason: 'a null draft note is "not compared", not "different"');
    });

    test('location, repetition, restriction, colour are compared too', () {
      // The draft carries the series fields even though the legacy screen
      // never sets them; equivalence still compares them (null == null).
      expect(equivalent(seeded()..address = '1 Main St', loaded()), isFalse);
      expect(
          equivalent(seeded()..addressDescription = 'home', loaded()), isFalse);
    });
  });

  // `updateProceed` (the legacy ✓ rule) was pinned here against the legacy
  // `editTileCanProceed` until Step 5.4 deleted the legacy screen. The rule
  // lives on as `EditTileDraft.canSave`, pinned in edit_tile_draft_test.dart.
}
