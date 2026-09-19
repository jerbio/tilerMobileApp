// Where a search result's Edit goes (2026-09-19).
//
// The search API returns two kinds of row under one shape:
//
//   * a TILER row's `id` is a CALENDAR EVENT — the series;
//   * a GOOGLE / MICROSOFT row's `thirdPartyEventId` is a SUB-EVENT — one
//     occurrence on the provider's calendar.
//
// The redesigned screens are keyed the same way: Tile details loads a
// calendar event, Edit Tile loads a sub-event. So a Tiler row opens Tile
// details and a provider row opens Edit Tile. Before this, every row went to
// Edit Tile, which asked the sub-event endpoint for a series id and failed to
// load.
//
// Pure — the search widget itself is not pumpable in a test, so the decision
// lives here where it can be.
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/calendarSearch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart';

/// The screen to push for [item]'s Edit, or null when the row carries no
/// usable id.
Widget? searchResultEditorFor(CalendarSearchItem item) {
  if (item.isFromTiler) {
    final String id = item.id;
    if (id.isEmpty) return null;
    return TileDetailRoute(tileId: id);
  }
  final String subEventId = item.thirdPartyEventId ?? '';
  if (subEventId.isEmpty) return null;
  return EditTileRoute(
    tileId: subEventId,
    tileSource: tileSourceOfSearchItem(item),
    thirdPartyUserId: item.thirdPartyUserId,
  );
}

/// The wire says `microsoft`; the app's [TileSource] says `outlook`.
TileSource tileSourceOfSearchItem(CalendarSearchItem item) {
  switch (item.sourceKind) {
    case CalendarSearchSource.google:
      return TileSource.google;
    case CalendarSearchSource.microsoft:
      return TileSource.outlook;
    default:
      return TileSource.tiler;
  }
}
