// Edit Tile redesign — Step 2.2: which actions a tile offers.
//
// A pure restatement of the legacy `playbackOptions` logic in
// `_EditTileState.build`, pinned by `edit_tile_phase2_test.dart` so the
// Actions card cannot quietly offer more or less than the old buttons did.
// One deliberate difference, D9: a completed or disabled tile may still be
// deleted (legacy removed every button, leaving no way to tidy up).
//
// "Defer" is the legacy "Procrastinate"; "Start now" is "Now".
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';

enum EditTileAction { complete, startNow, defer, delete }

List<EditTileAction> editTileActionsFor(EditTileDraft draft) {
  switch (draft.mode) {
    case EditTileMode.thirdParty:
      // `if (!subEvent.isFromTiler) playbackOptions = [Delete]`.
      return const <EditTileAction>[EditTileAction.delete];
    case EditTileMode.readOnly:
      // Legacy: nothing. D9: Delete only.
      return const <EditTileAction>[EditTileAction.delete];
    case EditTileMode.procrastinate:
      // Legacy removed Procrastinate, PlayPause and Now.
      return const <EditTileAction>[
        EditTileAction.complete,
        EditTileAction.delete,
      ];
    case EditTileMode.editable:
      return const <EditTileAction>[
        EditTileAction.complete,
        EditTileAction.startNow,
        EditTileAction.defer,
        EditTileAction.delete,
      ];
  }
}
