// Step 6.2 — the mapper equals the Step 0.2 baseline.
//
// `TileDetailDraft` → `EditCalendarEvent` (+ the `clearLocation` flag) →
// `CalendarEventApi.updateCalEventParams`. For an UNCHANGED draft the map
// is the Step 0.2 literal (`edit_tile_series_payload_baseline_test.dart`);
// a dirty draft changes exactly the slots the user touched, plus
// `Priority` when the priority moved (D16 / D20).
//
// The location rules reproduce `TileDetail.calEventUpdate()` end to end —
// including its "hack" that nulls an unchanged address so the server does
// not re-verify it, and the quirk that a tile with NO place saves with
// `IsLocationCleared: true` (the legacy `''` never equals the loaded
// `null`). Both pinned as-is, not endorsed.
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/repetition.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tileColor.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRequestMapper.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';

import 'tile_detail_draft_test.dart' as fx;

/// The Step 0.2 literal for the plain fixture (with its 90-minute duration).
const Map<String, dynamic> legacyMap = <String, dynamic>{
  'EventID': 'cal-1',
  'EventName': 'Write report',
  'Start': '1789221600000',
  'End': '1789948740000',
  'Split': '3',
  'ThirdPartyEventID': '',
  'ThirdPartyUserID': '',
  'ThirdPartyType': 'tiler',
  'Notes': '',
  'IsAutoDeadline': null,
  'IsAutoReviseDeadline': 'true',
  'CalAddress': null,
  'CalAddressDescription': null,
  'IsCalAddressVerified': null,
  'IsLocationCleared': false,
  'RestrictionProfileId': null,
  'RestrictiveWeek': null,
  'RepetitionConfig': null,
  'ColorConfig': null,
  'Duration': '5400000',
};

TileDetailDraft draft([dynamic original]) =>
    TileDetailDraft.fromLoaded(original ?? fx.loaded());

void main() {
  group('An unchanged draft is the legacy request', () {
    test('the update map equals the Step 0.2 literal', () {
      // `ThirdPartyEventID` / `ThirdPartyUserID` are '' not 'null' (the model
      // defaults, Step 0.1);
      // `Notes` is '' (the legacy seed writes '' before reading the note);
      // `IsAutoDeadline` is null (never parsed from the wire today).
      expect(tileDetailUpdateParams(draft()), legacyMap);
    });

    test('and equals what the legacy API builds from the same event', () {
      final TileDetailDraft d = draft();
      final TileDetailRequest r = toTileDetailRequest(d);
      expect(
          tileDetailUpdateParams(d),
          CalendarEventApi.updateCalEventParams(r.event,
              clearLocation: r.clearLocation));
    });

    test('a loaded rule, colour, place and restriction travel as loaded', () {
      final TileDetailDraft d = draft(fx.loaded(
          repetition: fx.weeklyJson(),
          color: const Color(0xFFE91E63),
          location: fx.place('Work', '456 Market St')));
      final Map<String, dynamic> map = tileDetailUpdateParams(d);
      expect(map['RepetitionConfig'],
          Repetition.fromRepetitionData(fx.weekly()).toRequestJson());
      expect(map['ColorConfig'],
          TileColor.fromColor(const Color(0xFFE91E63)).toRequestJson());
      expect(map['CalAddress'], isNull,
          reason: 'a clean draft is the seed state: nothing sent for the '
              'place, as the Step 0.2 literal');
      expect(map['IsLocationCleared'], false);
      expect(map['Notes'], '');
    });

    test('an untouched rule is passed through, not rebuilt', () {
      // The picker's shape (RepetitionData) has no tile timeline; a loaded
      // rule that carries one must reach the wire intact when the user did
      // not touch the rule.
      final TileDetailDraft d = draft(fx.loaded(repetition: <String, dynamic>{
        ...fx.weeklyJson(),
        'tileTimeline': <String, dynamic>{
          'start': fx.start.millisecondsSinceEpoch,
          'end': fx.start.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        },
      }))
        ..setSplit(4);
      final Map<String, dynamic> rule =
          tileDetailUpdateParams(d)['RepetitionConfig'] as Map<String, dynamic>;
      expect(rule['TileStart'], fx.start.millisecondsSinceEpoch);
      expect(rule['TileEnd'], isNotNull);
    });

    test('a loaded profile travels without its id; a chosen one with it', () {
      // The legacy seed set `restrictionProfile` but never
      // `restrictionProfileId`; the selector wrote both. Reproduced.
      final Map<String, dynamic> loadedProfile = <String, dynamic>{
        'id': 'rp-loaded',
        'isEnabled': true,
        'daySelection': <Map<String, dynamic>?>[
          null,
          null,
          null,
          null,
          null,
          null,
          null
        ],
      };
      final TileDetailDraft clean =
          draft(fx.loaded(restrictionProfile: loadedProfile))..setSplit(4);
      final Map<String, dynamic> map = tileDetailUpdateParams(clean);
      expect(map['RestrictionProfileId'], isNull);
      expect(map['RestrictiveWeek'], isNotNull);

      final TileDetailDraft chosen = draft()
        ..setRestrictionProfile(RestrictionProfile.noRestriction()
          ..id = 'rp-7'
          ..isEnabled = true);
      expect(tileDetailUpdateParams(chosen)['RestrictionProfileId'], 'rp-7');
      final TileDetailDraft anytime =
          draft(fx.loaded(restrictionProfile: loadedProfile))
            ..setRestrictionProfile(null);
      expect(tileDetailUpdateParams(anytime)['RestrictionProfileId'], isNull);
      expect(tileDetailUpdateParams(anytime)['RestrictiveWeek'], isNull);
    });

    test('a third-party event keeps its provider identity', () {
      final Map<String, dynamic> map =
          tileDetailUpdateParams(draft(fx.loaded(thirdPartyType: 'google')));
      expect(map['EventID'], 'cal-1');
      expect(map['ThirdPartyEventID'], 'ext-9');
      expect(map['ThirdPartyUserID'], 'ext-user-3');
      expect(map['ThirdPartyType'], 'google');
    });

    test('the vocabulary is closed: Step 0.2 keys plus Priority only', () {
      final Set<String> clean = tileDetailUpdateParams(draft()).keys.toSet();
      expect(clean, legacyMap.keys.toSet());
      final Set<String> dirty =
          tileDetailUpdateParams(draft()..setPriority(TilePriority.high))
              .keys
              .toSet();
      expect(dirty, <String>{...legacyMap.keys, 'Priority'});
    });
  });

  group('A change touches only its slot', () {
    test('name, sessions, duration', () {
      final TileDetailDraft d = draft()
        ..setName('Write REPORT')
        ..setSplit(5)
        ..setDuration(const Duration(hours: 2));
      expect(tileDetailUpdateParams(d), <String, dynamic>{
        ...legacyMap,
        'EventName': 'Write REPORT',
        'Split': '5',
        'Duration': '7200000',
        // The place-less quirk below: a dirty save writes '' / '' and a
        // clear, whatever else changed.
        'CalAddress': '',
        'CalAddressDescription': '',
        'IsLocationCleared': true,
      });
    });

    test('a duration removed drops the Duration key', () {
      final TileDetailDraft d = draft()..setDuration(null);
      expect(tileDetailUpdateParams(d).containsKey('Duration'), isFalse);
    });

    test('a repetition rule in request form; removing it sends null', () {
      final TileDetailDraft d = draft()..setRepetition(fx.weekly());
      expect(tileDetailUpdateParams(d)['RepetitionConfig'],
          Repetition.fromRepetitionData(fx.weekly()).toRequestJson());
      final TileDetailDraft cleared =
          draft(fx.loaded(repetition: fx.weeklyJson()))..setRepetition(null);
      expect(tileDetailUpdateParams(cleared)['RepetitionConfig'], isNull);
    });

    test('a colour as ColorConfig; removing it sends null', () {
      final TileDetailDraft d = draft()..setColor(const Color(0xFF2196F3));
      expect(tileDetailUpdateParams(d)['ColorConfig'], <String, dynamic>{
        'IsEnabled': true,
        'Red': 33,
        'Green': 150,
        'Blue': 243,
        'Opacity': 1.0,
      });
      final TileDetailDraft cleared =
          draft(fx.loaded(color: const Color(0xFF2196F3)))..setColor(null);
      expect(tileDetailUpdateParams(cleared)['ColorConfig'], isNull);
    });

    test('Priority travels only when it moved (D20), lowercase (D7)', () {
      expect(
          tileDetailUpdateParams(draft()..setName('x')).containsKey('Priority'),
          isFalse);
      expect(
          tileDetailUpdateParams(
              draft()..setPriority(TilePriority.low))['Priority'],
          'low');
      expect(
          tileDetailUpdateParams(
              draft()..setPriority(TilePriority.high))['Priority'],
          'high');
    });
  });

  group('Location reproduces calEventUpdate()', () {
    test('a new place travels with its verification', () {
      final TileDetailDraft d = draft()
        ..setLocation(fx.place('Work', '456 Market St'));
      final Map<String, dynamic> map = tileDetailUpdateParams(d);
      expect(map['CalAddress'], '456 Market St');
      expect(map['CalAddressDescription'], 'Work');
      expect(map['IsCalAddressVerified'], 'true');
      expect(map['IsLocationCleared'], false);
    });

    test('an unchanged place on a dirty save is nulled (the legacy hack)', () {
      // "so there isn\'t a database refresh or check" — TileDetail nulls the
      // address, description and verification when they equal the loaded
      // ones, and does not flag a clear.
      final TileDetailDraft d =
          draft(fx.loaded(location: fx.place('Work', '456 Market St')))
            ..setSplit(4);
      final Map<String, dynamic> map = tileDetailUpdateParams(d);
      expect(map['CalAddress'], isNull);
      expect(map['CalAddressDescription'], isNull);
      expect(map['IsCalAddressVerified'], isNull);
      expect(map['IsLocationCleared'], false);
    });

    test('a cleared place sends empty strings and the clear flag', () {
      final TileDetailDraft d =
          draft(fx.loaded(location: fx.place('Work', '456 Market St')))
            ..clearLocation();
      final Map<String, dynamic> map = tileDetailUpdateParams(d);
      expect(map['CalAddress'], '');
      expect(map['CalAddressDescription'], '');
      expect(map['IsCalAddressVerified'], isNull);
      expect(map['IsLocationCleared'], true);
    });

    test('a dirty save of a tile with no place flags a clear (legacy quirk)',
        () {
      // dataChange() writes \'\' for "no place"; calEventUpdate() then sees
      // \'\' != the loaded null and reports a clear. Harmless, and what the
      // server receives today — pinned so a change of it is deliberate.
      final TileDetailDraft d = draft()..setSplit(4);
      final Map<String, dynamic> map = tileDetailUpdateParams(d);
      expect(map['CalAddress'], '');
      expect(map['CalAddressDescription'], '');
      expect(map['IsLocationCleared'], true);
    });
  });
}
