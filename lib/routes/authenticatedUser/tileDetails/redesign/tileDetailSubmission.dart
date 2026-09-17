// Tile Detail redesign — Step 6.3: the seams behind the shell.
//
// As `editTileSubmission.dart`: the shell talks to a loader and a
// submission; the API versions wrap the existing `CalendarEventApi` and
// `LocationApi` and the schedule refresher Edit Tile already ports from
// the legacy bloc dispatches. Tests supply fakes.
//
// Faithful to the legacy `TileDetail`:
//   * the location is fetched SEPARATELY, by calendar-event id (the
//     `LocationBloc` path), and its failure does not fail the load;
//   * a save dispatches EvaluateSchedule before and GetSchedule + the day
//     summary after (`calEventUpdate`), abandoning the evaluation on
//     failure — a fix over the legacy, which left it evaluating;
//   * delete is the `CalendarTileBloc` request: id and provider id.
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/subEventPaging.dart'
    show kSubEventBatchSize;
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart'
    show
        EditTileSaveOutcome,
        EditTileScheduleRefresher,
        editTileFailureApiRejected,
        editTileFailureNetwork;
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/redesignLog.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRequestMapper.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/data/request/TilerError.dart';

String _reasonFor(Object error) =>
    error is TilerError ? editTileFailureApiRejected : editTileFailureNetwork;

// ------------------------------------------------------------------ results

class TileDetailSaveResult {
  const TileDetailSaveResult.success(this.event)
      : outcome = EditTileSaveOutcome.success,
        reasonCode = null;

  const TileDetailSaveResult.failure(this.reasonCode)
      : outcome = EditTileSaveOutcome.failure,
        event = null;

  const TileDetailSaveResult.nothingToSave()
      : outcome = EditTileSaveOutcome.nothingToSave,
        event = null,
        reasonCode = null;

  final EditTileSaveOutcome outcome;
  final CalendarEvent? event;
  final String? reasonCode;
}

class TileDetailLoadResult {
  const TileDetailLoadResult.success(this.event, this.location)
      : reasonCode = null;

  const TileDetailLoadResult.failure(this.reasonCode)
      : event = null,
        location = null;

  final CalendarEvent? event;

  /// The separately fetched place, or null (none, or the fetch failed).
  final Location? location;
  final String? reasonCode;

  bool get failed => event == null;
}

// ------------------------------------------------------------------- seams

abstract class TileDetailLoader {
  Future<TileDetailLoadResult> load(String calendarEventId);
}

abstract class TileDetailSubmission {
  Future<TileDetailSaveResult> save(TileDetailDraft draft);
  Future<TileDetailSaveResult> deleteSeries(TileDetailDraft draft);
}

/// The paged occurrences of a series (6.5): the legacy bloc's initial
/// `ProximityToNow` page, then `Id`-ordered pages either side of a cursor.
abstract class TileDetailOccurrences {
  Future<List<SubCalendarEvent>> initial(String calendarEventId);
  Future<List<SubCalendarEvent>> after(String calendarEventId, String cursorId);
  Future<List<SubCalendarEvent>> before(
      String calendarEventId, String cursorId);
}

// ------------------------------------------------------------ API versions

class ApiTileDetailLoader implements TileDetailLoader {
  ApiTileDetailLoader({
    required this.calendarEventApi,
    required this.locationApi,
  });

  final CalendarEventApi calendarEventApi;
  final LocationApi locationApi;

  @override
  Future<TileDetailLoadResult> load(String calendarEventId) async {
    final CalendarEvent event;
    try {
      event = await calendarEventApi.getCalEvent(id: calendarEventId);
    } catch (e, st) {
      RedesignLog.event(
          'tile_detail_load_failed',
          <String, Object?>{
            'calendarEventId': calendarEventId,
            'code': _reasonFor(e)
          },
          error: e,
          stack: st);
      return TileDetailLoadResult.failure(_reasonFor(e));
    }
    Location? location;
    try {
      location = await locationApi.getLocationById(calendarId: calendarEventId);
    } catch (e, st) {
      // Not the event's failure; still worth a line.
      RedesignLog.event('tile_detail_location_failed',
          <String, Object?>{'calendarEventId': calendarEventId},
          error: e, stack: st);
      location = null;
    }
    RedesignLog.event('tile_detail_opened', <String, Object?>{
      'calendarEventId': calendarEventId,
      'hasLocation': location != null,
    });
    return TileDetailLoadResult.success(event, location);
  }
}

class ApiTileDetailOccurrences implements TileDetailOccurrences {
  ApiTileDetailOccurrences({required this.calendarEventApi});
  final CalendarEventApi calendarEventApi;

  @override
  Future<List<SubCalendarEvent>> initial(String calendarEventId) =>
      calendarEventApi.getSubEvents(calendarEventId,
          batchSize: kSubEventBatchSize, orderingEngine: 'ProximityToNow');

  @override
  Future<List<SubCalendarEvent>> after(
          String calendarEventId, String cursorId) =>
      calendarEventApi.getSubEvents(calendarEventId,
          batchSize: kSubEventBatchSize,
          orderingEngine: 'Id',
          afterSubEventId: cursorId);

  @override
  Future<List<SubCalendarEvent>> before(
          String calendarEventId, String cursorId) =>
      calendarEventApi.getSubEvents(calendarEventId,
          batchSize: kSubEventBatchSize,
          orderingEngine: 'Id',
          beforeSubEventId: cursorId);
}

class ApiTileDetailSubmission implements TileDetailSubmission {
  ApiTileDetailSubmission({
    required this.calendarEventApi,
    required this.refresher,
  });

  final CalendarEventApi calendarEventApi;
  final EditTileScheduleRefresher refresher;

  Future<TileDetailSaveResult> _mutate(String event, Map<String, Object?> data,
      Future<CalendarEvent?> Function() call) async {
    refresher.beginEvaluation();
    try {
      final CalendarEvent? result = await call();
      refresher.refreshAfterChange();
      return TileDetailSaveResult.success(result);
    } catch (e, st) {
      refresher.abandonEvaluation();
      RedesignLog.event(
          '${event}_failed', <String, Object?>{...data, 'code': _reasonFor(e)},
          error: e, stack: st);
      return TileDetailSaveResult.failure(_reasonFor(e));
    }
  }

  @override
  Future<TileDetailSaveResult> save(TileDetailDraft draft) {
    if (!draft.isDirty) {
      return Future<TileDetailSaveResult>.value(
          const TileDetailSaveResult.nothingToSave());
    }
    return _mutate(
        'tile_detail_save',
        <String, Object?>{
          'calendarEventId': draft.id,
          'dirty': draft.dirtyFields.map((f) => f.name).join('|'),
        },
        () => calendarEventApi
            .updateCalEventRequest(tileDetailUpdateParams(draft)));
  }

  @override
  Future<TileDetailSaveResult> deleteSeries(TileDetailDraft draft) => _mutate(
      'tile_detail_delete',
      <String, Object?>{'calendarEventId': draft.id},
      () => calendarEventApi.delete(draft.id ?? '', draft.thirdPartyId ?? ''));
}
