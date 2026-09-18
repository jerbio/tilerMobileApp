// Submitting the redesigned Add Tile draft to the backend.
//
// Until now the redesign built a payload and showed it in a debug SnackBar:
// the draft -> mapper -> CTA path was verifiable on device, but nothing was
// ever written. The mapping itself was never the risk — it is pinned
// field-for-field against the legacy flow — so what was missing is the
// ORCHESTRATION the legacy screen performs around the call (D49).
//
// This file owns only the network half of that. Everything with a lifecycle —
// bloc dispatch, returning the created tile to the caller — stays in the shell,
// which has a `State` and can check `mounted` after the await. The legacy
// screen does that work inline against a context it captured before the call.
//
// `TilerError` is a RETURNED value here, not a thrown one: `addNewTile`
// answers with a `Tuple2<SubCalendarEvent?, TilerError?>` and reserves
// exceptions for transport failures. Both are failures to a user, so
// [AddTileSubmissionResult] flattens them into one shape and the shell has a
// single path to handle.
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';

/// The outcome of one submission attempt.
class AddTileSubmissionResult {
  const AddTileSubmissionResult.success(this.tile)
      : failed = false,
        reasonCode = null;

  /// [reasonCode] is an ALLOW-LISTED enum value, never a server or exception
  /// message: those can embed the user's own tile content, and §12 forbids
  /// user-entered text reaching analytics.
  const AddTileSubmissionResult.failure(this.reasonCode)
      : failed = true,
        tile = null;

  /// The event the server created, when it reported one.
  final SubCalendarEvent? tile;

  final bool failed;
  final String? reasonCode;
}

/// Creates a tile on the server.
///
/// An interface so the shell can be driven without a network, and so the
/// edit-tile flow can supply its own implementation later.
abstract class AddTileSubmission {
  Future<AddTileSubmissionResult> create(NewTile tile);
}

/// The real implementation, over `ScheduleApi`.
class ApiAddTileSubmission implements AddTileSubmission {
  ApiAddTileSubmission({required this.scheduleApi});

  final ScheduleApi scheduleApi;

  @override
  Future<AddTileSubmissionResult> create(NewTile tile) async {
    try {
      final result = await scheduleApi.addNewTile(tile);
      final SubCalendarEvent? created = result.item1;
      if (result.item2 != null && created == null) {
        // The server declined. Its message is deliberately not read.
        return const AddTileSubmissionResult.failure('api_rejected');
      }
      return AddTileSubmissionResult.success(created);
    } catch (_) {
      // Transport failure. The exception is not inspected or logged for the
      // same reason the server message is not.
      //
      // `network_timeout` rather than a more precise "unreachable": the
      // reason codes are a documented schema (§12.1) with an asserted
      // allow-list, and widening it is a product decision rather than
      // something to slip in with a wiring change.
      return const AddTileSubmissionResult.failure('network_timeout');
    }
  }
}
