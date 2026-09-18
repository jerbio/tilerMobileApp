// Step 0.1 — the sub-event update payload, frozen.
//
// `SubCalendarEventApi.updateSubEvent` is the one request the Edit Tile
// screen makes on Save. Before any of it is rewritten, today's exact query
// map is pinned as a LITERAL for four representative tiles, so the redesign's
// mapper (Step 1.2) has something to be equal to rather than something to
// resemble. The Add Tile redesign learned this the hard way (its D54: three
// contract faults surfaced in one pass once a payload was diffed field by
// field).
//
// Pinned as-is, quirks included. Two are worth naming so nobody "fixes" them
// in the mapper without a decision:
//
//   * `thirdPartyId`, `thirdPartyUserId` and `note` reach the wire through
//     `.toString()`, so a NULL is sent as the four-letter string "null", not
//     omitted. For a real Tiler tile the ids are NOT null: `TilerEvent`
//     defaults both to the empty string, so the screen sends `''` — the
//     "null" case arises only for the note, which stays null when the
//     sub-event has no `noteData`.
//   * `Notes` is sent on every update although notes persist themselves
//     through the Notes API (see `edit_tile_notes_test.dart`).
//
// Times are epoch milliseconds in UTC; the fixtures use explicit UTC
// constructors so the literals do not depend on the machine's zone.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0); // 1789221600000
final DateTime end = DateTime.utc(2026, 9, 12, 15, 30); // 1789227000000
final DateTime calStart = DateTime.utc(2026, 9, 10, 0, 0); // 1788998400000
final DateTime calEnd = DateTime.utc(2026, 9, 20, 23, 59); // 1789948740000

/// A Tiler-owned tile the way `EditTile` seeds it from a loaded sub-event.
EditTilerEvent tilerTile() => EditTilerEvent()
  ..id = 'sub-1'
  ..name = 'Write report'
  ..splitCount = 2
  ..startTime = start
  ..endTime = end
  ..calStartTime = calStart
  ..calEndTime = calEnd
  ..thirdPartyType = 'tiler'
  // As `TilerEvent` parses them for a Tiler tile: empty, not null.
  ..thirdPartyId = ''
  ..thirdPartyUserId = ''
  ..note = null;

void main() {
  group('updateSubEvent query map — frozen', () {
    test('a Tiler tile with nothing optional set', () {
      expect(SubCalendarEventApi.updateSubEventParams(tilerTile()), {
        'EventID': 'sub-1',
        'EventName': 'Write report',
        'Start': '1789221600000',
        'End': '1789227000000',
        'CalStart': '1788998400000',
        'CalEnd': '1789948740000',
        'Split': '2',
        'ThirdPartyEventID': '',
        'ThirdPartyUserID': '',
        'ThirdPartyType': 'tiler',
        // No noteData → the note stays null → the STRING "null" (header).
        'Notes': 'null',
      });
    });

    test('a null id would go out as the string "null" (toString quirk)', () {
      // Not a case the screen produces for its ids (they default to ''),
      // but it is how the map treats ANY null, and how the note travels.
      final map = SubCalendarEventApi.updateSubEventParams(tilerTile()
        ..thirdPartyId = null
        ..thirdPartyUserId = null);
      expect(map['ThirdPartyEventID'], 'null');
      expect(map['ThirdPartyUserID'], 'null');
    });

    test('a tile with a note sends the note text under Notes', () {
      final map = SubCalendarEventApi.updateSubEventParams(
          tilerTile()..note = 'bring the charts');
      expect(map['Notes'], 'bring the charts');
      expect(map.length, 11,
          reason: 'no field appears or disappears with a note');
    });

    test('a third-party tile carries its provider identity', () {
      final map = SubCalendarEventApi.updateSubEventParams(tilerTile()
        ..id = 'gcal-evt-9'
        ..thirdPartyType = 'google'
        ..thirdPartyId = 'gcal-evt-9'
        ..thirdPartyUserId = 'gcal-user-3');
      expect(map['EventID'], 'gcal-evt-9',
          reason: 'EditTile seeds id from thirdpartyId for non-Tiler tiles');
      expect(map['ThirdPartyEventID'], 'gcal-evt-9');
      expect(map['ThirdPartyUserID'], 'gcal-user-3');
      expect(map['ThirdPartyType'], 'google');
      expect(map.containsKey('RsvpStatusUpdate'), isFalse,
          reason: 'no RSVP change → the key is absent, not empty');
    });

    test('an RSVP change adds exactly one key, capitalised', () {
      for (final (RsvpStatus status, String wire) in <(RsvpStatus, String)>[
        (RsvpStatus.accepted, 'Accepted'),
        (RsvpStatus.declined, 'Declined'),
        (RsvpStatus.tentative, 'Tentative'),
      ]) {
        final map = SubCalendarEventApi.updateSubEventParams(
            tilerTile()..rsvpStatusUpdate = status);
        expect(map['RsvpStatusUpdate'], wire);
        expect(map.length, 12);
      }
    });

    test('needsAction and notApplicable are not sent as an update', () {
      for (final RsvpStatus status in <RsvpStatus>[
        RsvpStatus.needsAction,
        RsvpStatus.notApplicable,
      ]) {
        final map = SubCalendarEventApi.updateSubEventParams(
            tilerTile()..rsvpStatusUpdate = status);
        expect(map.containsKey('RsvpStatusUpdate'), isFalse,
            reason: '$status has no wire form in getRsvpStatusUpdateString');
      }
    });

    test('times are sent as UTC epoch milliseconds regardless of zone', () {
      // A local-zone DateTime with the same instant must produce the same
      // literal: the API calls `.toUtc()` before reading milliseconds.
      final map = SubCalendarEventApi.updateSubEventParams(
          tilerTile()..startTime = start.toLocal());
      expect(map['Start'], '1789221600000');
    });
  });

  whatIfBaseline();
}

/// The what-if preview is a dry run of the same edit, so its map is pinned
/// RELATIVE to the update map rather than as a second literal: identical,
/// minus the RSVP key, which the preview endpoint never receives even when a
/// status change is pending.
void whatIfBaseline() {
  group('WhatIf SubeventEdit query map — frozen', () {
    test('it is the update map without RsvpStatusUpdate', () {
      final EditTilerEvent tile = tilerTile()..note = 'bring the charts';
      expect(
        WhatIfApi.subEventEditParams(tile),
        SubCalendarEventApi.updateSubEventParams(tile),
      );
    });

    test('a pending RSVP change is NOT previewed', () {
      final EditTilerEvent tile = tilerTile()
        ..rsvpStatusUpdate = RsvpStatus.accepted;
      final Map<String, dynamic> preview = WhatIfApi.subEventEditParams(tile);
      expect(preview.containsKey('RsvpStatusUpdate'), isFalse);
      expect(preview.length, 11);
    });
  });
}
