// Edit Tile redesign — Step 1.3: the loader and the submission.
//
// Two seams between the screen and the world, so the screen can be handed
// fakes and never touches an API or a bloc itself:
//
//   * `EditTileLoader` — the sub-event and its suggestions, or a TYPED
//     failure. The legacy screen ran two bloc fetches and had no failure
//     branch: a failed load was a spinner forever (plan §1.9).
//   * `EditTileSubmission` — save, RSVP, the four actions, and the what-if
//     preview. Every mutating call runs the same schedule side-effects the
//     legacy code ran inline (`EvaluateSchedule` before, `GetScheduleEvent`
//     + day-summary refresh after) through an `EditTileScheduleRefresher`,
//     with one addition: a FAILED call abandons the evaluation instead of
//     leaving the schedule "evaluating", which is what the legacy
//     `.then`-only chain did.
//
// Failure codes are allow-listed (`api_rejected`, `network_timeout`), as in
// the Add Tile submission, so nothing free-form reaches analytics.
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/prediction.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRequestMapper.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tuple/tuple.dart';

/// Allow-listed failure reasons.
const String editTileFailureApiRejected = 'api_rejected';
const String editTileFailureNetwork = 'network_timeout';

String _reasonFor(Object error) =>
    error is TilerError ? editTileFailureApiRejected : editTileFailureNetwork;

// ------------------------------------------------------------------ results

enum EditTileSaveOutcome { success, failure, nothingToSave }

class EditTileSaveResult {
  const EditTileSaveResult.success(this.tile)
      : outcome = EditTileSaveOutcome.success,
        reasonCode = null;

  const EditTileSaveResult.failure(this.reasonCode)
      : outcome = EditTileSaveOutcome.failure,
        tile = null;

  const EditTileSaveResult.nothingToSave()
      : outcome = EditTileSaveOutcome.nothingToSave,
        tile = null,
        reasonCode = null;

  final EditTileSaveOutcome outcome;

  /// The tile as the server returned it, on success. Actions that return
  /// nothing (delete, defer) leave it null.
  final SubCalendarEvent? tile;
  final String? reasonCode;
}

class EditTileLoadResult {
  const EditTileLoadResult.success(this.tile, this.suggestions)
      : reasonCode = null;

  const EditTileLoadResult.failure(this.reasonCode)
      : tile = null,
        suggestions = const <NextTileSuggestion>[];

  final SubCalendarEvent? tile;
  final List<NextTileSuggestion> suggestions;
  final String? reasonCode;

  bool get failed => tile == null;
}

/// What a change would do to the rest of the schedule. Every day the
/// preview returned, not the first (plan §6.3, D3).
///
/// A check that could not run is [failed]: empty, but not "nothing is
/// affected" — the screen says which (4.3b).
class WhatIfResult {
  const WhatIfResult({required this.tardy, required this.overflow})
      : failed = false;

  const WhatIfResult.failed()
      : tardy = const <SubCalendarEvent>[],
        overflow = const <SubCalendarEvent>[],
        failed = true;

  WhatIfResult.fromPreview(Preview after)
      : tardy = after.tardies?.dayPreviews
                ?.expand((day) => day.subEvents ?? const <TilerEvent>[])
                .whereType<SubCalendarEvent>()
                .toList() ??
            const <SubCalendarEvent>[],
        overflow = after.nonViable?.whereType<SubCalendarEvent>().toList() ??
            const <SubCalendarEvent>[],
        failed = false;

  final List<SubCalendarEvent> tardy;

  /// The server's `nonViable`: tiles that no longer fit ("overflow" in the
  /// UI, D22).
  final List<SubCalendarEvent> overflow;

  /// The check itself did not run (network, server, or no answer).
  final bool failed;

  bool get isEmpty => tardy.isEmpty && overflow.isEmpty;
}

// ------------------------------------------------------------------- seams

/// The schedule side-effects around a mutating call. The API version
/// dispatches to `ScheduleBloc` / `ScheduleSummaryBloc`; tests record.
abstract class EditTileScheduleRefresher {
  /// Before the request: the schedule shows as being re-evaluated.
  void beginEvaluation();

  /// After success: reload the schedule and the day summary.
  void refreshAfterChange();

  /// After failure: leave evaluation, reload what was there.
  void abandonEvaluation();
}

abstract class EditTileLoader {
  Future<EditTileLoadResult> load(String tileId,
      {String? source, String? thirdPartyUserId});
}

abstract class EditTileSubmission {
  Future<EditTileSaveResult> save(EditTileDraft draft);
  Future<EditTileSaveResult> rsvp(EditTileDraft draft, RsvpStatus status);
  Future<EditTileSaveResult> complete(SubCalendarEvent tile);
  Future<EditTileSaveResult> startNow(SubCalendarEvent tile);
  Future<EditTileSaveResult> delete(SubCalendarEvent tile);
  Future<EditTileSaveResult> defer(SubCalendarEvent tile, Duration by);

  /// Advisory. The API version answers [WhatIfResult.failed] when the
  /// check could not run; a null from a test seam means the same.
  Future<WhatIfResult?> preview(EditTileDraft draft);
}

// ------------------------------------------------------------ API versions

class ApiEditTileLoader implements EditTileLoader {
  ApiEditTileLoader({
    required this.subCalendarEventApi,
    required this.calendarEventApi,
  });

  final SubCalendarEventApi subCalendarEventApi;
  final CalendarEventApi calendarEventApi;

  @override
  Future<EditTileLoadResult> load(String tileId,
      {String? source, String? thirdPartyUserId}) async {
    final SubCalendarEvent tile;
    try {
      // The bloc sent the missing source as "", not null; kept.
      tile = await subCalendarEventApi.getSubEvent(tileId,
          calendarSource: source ?? '',
          thirdPartyUserId: thirdPartyUserId ?? '');
    } catch (e) {
      return EditTileLoadResult.failure(_reasonFor(e));
    }
    // Suggestions are decoration: their failure is not the tile's.
    List<NextTileSuggestion> suggestions;
    try {
      suggestions = await calendarEventApi.getNextTileSuggestion(tileId);
    } catch (_) {
      suggestions = const <NextTileSuggestion>[];
    }
    return EditTileLoadResult.success(tile, suggestions);
  }
}

class ApiEditTileSubmission implements EditTileSubmission {
  ApiEditTileSubmission({
    required this.subCalendarEventApi,
    required this.whatIfApi,
    required this.refresher,
  });

  final SubCalendarEventApi subCalendarEventApi;
  final WhatIfApi whatIfApi;
  final EditTileScheduleRefresher refresher;

  /// Runs [call] inside the schedule side-effects, mapping failure to an
  /// allow-listed code.
  Future<EditTileSaveResult> _mutate(
      Future<SubCalendarEvent?> Function() call) async {
    refresher.beginEvaluation();
    try {
      final SubCalendarEvent? tile = await call();
      refresher.refreshAfterChange();
      return EditTileSaveResult.success(tile);
    } catch (e) {
      refresher.abandonEvaluation();
      return EditTileSaveResult.failure(_reasonFor(e));
    }
  }

  @override
  Future<EditTileSaveResult> save(EditTileDraft draft) {
    if (!draft.isDirty) {
      return Future<EditTileSaveResult>.value(
          const EditTileSaveResult.nothingToSave());
    }
    return _mutate(() =>
        subCalendarEventApi.updateSubEventRequest(editTileUpdateParams(draft)));
  }

  @override
  Future<EditTileSaveResult> rsvp(EditTileDraft draft, RsvpStatus status) {
    // The tile AS LOADED plus the answer — pending edits stay pending, and
    // the request is the legacy one exactly (Step 0.1, "an RSVP change adds
    // exactly one key").
    final EditTileDraft asLoaded = EditTileDraft.fromLoaded(draft.original);
    final Map<String, dynamic> params =
        SubCalendarEventApi.updateSubEventParams(
            toEditTilerEvent(asLoaded)..rsvpStatusUpdate = status);
    return _mutate(() => subCalendarEventApi.updateSubEventRequest(params));
  }

  @override
  Future<EditTileSaveResult> complete(SubCalendarEvent tile) =>
      _mutate(() => subCalendarEventApi.complete(tile));

  @override
  Future<EditTileSaveResult> startNow(SubCalendarEvent tile) =>
      _mutate(() => subCalendarEventApi.setAsNow(tile));

  @override
  Future<EditTileSaveResult> delete(SubCalendarEvent tile) => _mutate(() async {
        // The identity the legacy playback buttons send.
        await subCalendarEventApi.delete(
          tile.id!,
          tile.thirdpartyId,
          tile.thirdPartyUserId,
          tile.thirdpartyType?.name.toString().toLowerCase() ?? '',
        );
        return null;
      });

  @override
  Future<EditTileSaveResult> defer(SubCalendarEvent tile, Duration by) =>
      _mutate(() async {
        await subCalendarEventApi.procrastinate(by, tile.id!);
        return null;
      });

  @override
  Future<WhatIfResult?> preview(EditTileDraft draft) async {
    try {
      final Tuple2<Preview, Preview>? result =
          await whatIfApi.updateSubEvent(toEditTilerEvent(draft));
      if (result == null) return const WhatIfResult.failed();
      return WhatIfResult.fromPreview(result.item2);
    } catch (_) {
      return const WhatIfResult.failed();
    }
  }
}
