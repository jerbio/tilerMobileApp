// Tile Detail redesign — Step 6.2: draft → request.
//
// `TileDetailDraft` → the `EditCalendarEvent` (+ `clearLocation` flag) the
// legacy screen hands `CalendarEventApi.updateCalEvent`. The map itself is
// built by the API's own `updateCalEventParams`, frozen in Step 0.2, so
// the ONLY thing this file decides is what goes into the event.
//
// Faithful to `TileDetail` in three places that are easy to "improve" by
// accident (each pinned in `tile_detail_mapper_test.dart`):
//
//   * the seed: `Notes` is '' when the event has no note object, identity
//     strings come from the model's defaults ('' not null), the
//     restriction profile travels but its id is never set on load;
//   * `dataChange()`: "no place" is written as '' / '';
//   * `calEventUpdate()`: a place equal to the loaded one is nulled out
//     ("so there isn't a database refresh or check") and not flagged as a
//     clear; an empty place IS flagged — which, since '' never equals a
//     loaded null, makes every save of a place-less tile a "clear".
//
// New (D16 / D20): `Priority`, lowercase, only when it moved.
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetition.dart';
import 'package:tiler_app/data/tileColor.dart';
import 'package:tiler_app/data/uiConfig.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';

/// What `updateCalEvent` takes: the event and the separate clear flag.
class TileDetailRequest {
  const TileDetailRequest({required this.event, required this.clearLocation});
  final EditCalendarEvent event;
  final bool clearLocation;
}

TileDetailRequest toTileDetailRequest(TileDetailDraft d) {
  final EditCalendarEvent e = EditCalendarEvent()
    ..id = d.id
    ..name = d.name
    ..splitCount = d.split
    // The start as loaded (D14); the end is the editable deadline.
    ..startTime = d.windowStart
    ..endTime = d.deadline
    // Required by `isValid`, never sent: the legacy seed uses "now".
    ..calStartTime = d.windowStart
    ..calEndTime = d.deadline
    ..thirdPartyId = d.thirdPartyId
    ..thirdPartyUserId = d.thirdPartyUserId
    ..thirdPartyType = d.thirdPartyType
    ..isAutoDeadline = d.isAutoDeadline
    ..isAutoReviseDeadline = d.isAutoReviseDeadline
    // The legacy seed writes '' and then the note object's text if there
    // is one — so a missing note is '', not null; a note persisted from
    // this screen is mirrored into the next save, as `onNotePersisted` did.
    ..note = d.rawNote
    ..tileDuration = d.duration
    // As loaded the profile travels without its id (the legacy seed never
    // set one); a profile the user CHOSE travels with it, as the legacy
    // selector wrote both.
    ..restrictionProfile = d.restrictionProfile
    ..restrictionProfileId = d.dirtyFields.contains(TileDetailField.restriction)
        ? d.restrictionProfile?.id
        : null;

  // A loaded rule / colour is passed through untouched so nothing is lost
  // in a round trip; only a CHANGED one is rebuilt from the picker's shape.
  final Set<TileDetailField> dirty = d.dirtyFields;
  // A changed rule is rebuilt from the picker's shape but keeps the loaded
  // rule's tile timeline (TileStart/TileEnd), as the legacy
  // RepetitionSelectorWidget copied it onto the rebuilt one.
  e.repetition = dirty.contains(TileDetailField.repetition)
      ? (d.repetition == null
          ? null
          : (Repetition.fromRepetitionData(d.repetition!)
            ..tileTimeline = d.original.repetition?.tileTimeline))
      : d.original.repetition;
  e.uiConfig = dirty.contains(TileDetailField.color)
      ? (d.color == null
          ? null
          : (UIConfig.fromJson(<String, dynamic>{})
            ..tileColor = TileColor.fromColor(d.color!)))
      : d.original.uiConfig;

  // ---- location: the seed for a clean draft; dataChange + calEventUpdate
  // for a dirty one.
  bool clear = false;
  if (d.isDirty) {
    final Location? place = d.location;
    String? address = place?.address ?? '';
    String? description = place?.description ?? '';
    bool? verified = place?.isVerified;
    clear = address.isEmpty && description.isEmpty;

    final Location? loaded = d.originalLocation;
    final String? loadedAddress = loaded?.address ?? d.original.address;
    final String? loadedDescription =
        loaded?.description ?? d.original.addressDescription;
    if (loadedAddress == address && loadedDescription == description) {
      // "this is a hack so there isn't a database refresh or check"
      address = null;
      description = null;
      verified = null;
      clear = false;
    }
    e
      ..address = address
      ..addressDescription = description
      ..isAddressVerified = verified;
  }
  return TileDetailRequest(event: e, clearLocation: clear);
}

/// The `api/CalendarEvent/Update` map: the frozen legacy map, plus
/// `Priority` when the priority moved.
Map<String, dynamic> tileDetailUpdateParams(TileDetailDraft d) {
  final TileDetailRequest r = toTileDetailRequest(d);
  final Map<String, dynamic> map = CalendarEventApi.updateCalEventParams(
      r.event,
      clearLocation: r.clearLocation);
  if (d.dirtyFields.contains(TileDetailField.priority)) {
    map['Priority'] = d.priority.name;
  }
  return map;
}
