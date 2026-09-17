// Step 1.2 / 6.0 — the mapper equals the Step 0.1 baseline.
//
// `EditTileDraft` → the sub-event update map. For an UNCHANGED draft the map
// is byte-identical to what the legacy screen sends today
// (`edit_tile_payload_baseline_test.dart`). A dirty save adds exactly one
// key, `ApplicableOccurence: Single` — Edit Tile edits one occurrence (D19).
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRequestMapper.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0); // 1789221600000
final DateTime end = DateTime.utc(2026, 9, 12, 15, 30); // 1789227000000
final DateTime calStart = DateTime.utc(2026, 9, 10, 0, 0); // 1788998400000
final DateTime calEnd = DateTime.utc(2026, 9, 20, 23, 59); // 1789948740000

SubCalendarEvent loaded({String thirdPartyType = 'tiler', String? note}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': 'sub-1',
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'calendarEventStart': calStart.millisecondsSinceEpoch,
      'calendarEventEnd': calEnd.millisecondsSinceEpoch,
      'splitCount': 2,
      'thirdPartyType': thirdPartyType,
      'thirdPartyId': thirdPartyType == 'tiler' ? null : 'gcal-evt-9',
      'thirdPartyUserId': thirdPartyType == 'tiler' ? null : 'gcal-user-3',
      'priority': 'medium',
      if (note != null) 'blob': <String, dynamic>{'note': note},
    });

/// The Step 0.1 literal for the Tiler fixture.
const Map<String, dynamic> legacyMap = <String, dynamic>{
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
  'Notes': 'null',
};

void main() {
  group('An unchanged draft is the legacy request', () {
    test('the update map equals the Step 0.1 literal', () {
      expect(
          editTileUpdateParams(EditTileDraft.fromLoaded(loaded())), legacyMap);
    });

    test('and equals what the legacy API builds from the same draft', () {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded());
      expect(editTileUpdateParams(d),
          SubCalendarEventApi.updateSubEventParams(toEditTilerEvent(d)));
    });

    test('the what-if map is the legacy preview request', () {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded());
      expect(editTileWhatIfParams(d),
          WhatIfApi.subEventEditParams(toEditTilerEvent(d)));
      expect(editTileWhatIfParams(d), legacyMap);
    });

    test('a stored "null" note goes back as the legacy "null", untrimmed', () {
      final EditTileDraft d =
          EditTileDraft.fromLoaded(loaded(note: ' padded '));
      expect(d.note, 'padded', reason: 'display is sanitised');
      expect(editTileUpdateParams(d)['Notes'], ' padded ',
          reason: 'the wire is not');
    });

    test('a third-party tile is addressed by its provider id', () {
      final Map<String, dynamic> map = editTileUpdateParams(
          EditTileDraft.fromLoaded(loaded(thirdPartyType: 'google')));
      expect(map['EventID'], 'gcal-evt-9');
      expect(map['ThirdPartyEventID'], 'gcal-evt-9');
      expect(map['ThirdPartyUserID'], 'gcal-user-3');
      expect(map['ThirdPartyType'], 'google');
    });
  });

  group('A change adds only the scope, always Single (D19)', () {
    test('a renamed tile', () {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded())
        ..setName('Write REPORT');
      expect(editTileUpdateParams(d), <String, dynamic>{
        ...legacyMap,
        'EventName': 'Write REPORT',
        'ApplicableOccurence': 'Single',
      });
    });

    test('times and the deadline travel in the legacy slots', () {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded())
        ..setStartTime(start.add(const Duration(minutes: 5)))
        ..setEndTime(end.add(const Duration(minutes: 5)))
        ..setDeadline(calEnd.add(const Duration(days: 1)));
      final Map<String, dynamic> map = editTileUpdateParams(d);
      expect(map['Start'], '1789221900000');
      expect(map['End'], '1789227300000');
      expect(map['CalEnd'], '1790035140000');
      expect(map['Split'], '2', reason: 'sessions pass through unchanged');
      expect(map['ApplicableOccurence'], 'Single');
      expect(
          map.keys.toSet(), <String>{...legacyMap.keys, 'ApplicableOccurence'},
          reason: 'the vocabulary is closed: no series field ever travels '
              'from this screen');
    });

    test('the what-if preview never carries the scope', () {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded())
        ..setStartTime(start.add(const Duration(minutes: 5)));
      expect(
          editTileWhatIfParams(d).containsKey('ApplicableOccurence'), isFalse);
    });
  });
}
