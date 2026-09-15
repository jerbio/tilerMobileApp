// Edit Tile redesign — Step 1.2 / 6.0: draft → request.
//
// One endpoint, `api/SubCalendarEvent/Update` (D1), for ONE occurrence
// (D19). The map is the LEGACY map, byte-identical to what the old screen
// sends, produced by the same seam the old screen uses
// (`updateSubEventParams`) from an `EditTilerEvent` the draft fills the way
// the old screen did — pinned by `edit_tile_payload_baseline_test.dart` —
// plus `ApplicableOccurence: Single` on a dirty save (D10, D19): the field
// exists on the endpoint and this screen's answer is always "this one".
//
// The what-if preview keeps the legacy request exactly.
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';

/// The legacy model, filled the way `_EditTileState`'s `BlocListener` and
/// `dataChange()` fill it, from the draft's working copy.
EditTilerEvent toEditTilerEvent(EditTileDraft d) => EditTilerEvent()
  ..id = d.id
  ..name = d.name
  ..splitCount = d.split
  ..startTime = d.startTime
  ..endTime = d.endTime
  ..calStartTime = d.calStartTime
  ..calEndTime = d.deadline
  ..thirdPartyId = d.thirdPartyId
  ..thirdPartyType = d.thirdPartyType
  ..thirdPartyUserId = d.thirdPartyUserId
  ..note = d.note;

/// The update request for [d].
Map<String, dynamic> editTileUpdateParams(EditTileDraft d) {
  final Map<String, dynamic> map =
      SubCalendarEventApi.updateSubEventParams(toEditTilerEvent(d));
  if (d.isDirty) {
    map['ApplicableOccurence'] = d.effectiveScope.wireValue;
  }
  return map;
}

/// The what-if preview request for [d] — the legacy one, unchanged.
Map<String, dynamic> editTileWhatIfParams(EditTileDraft d) =>
    WhatIfApi.subEventEditParams(toEditTilerEvent(d));
