// Step 6.3 — the seams behind the Tile Detail shell.
//
//   * `TileDetailLoader` → the calendar event AND its separately fetched
//     location (the legacy `LocationBloc` path); the location's failure is
//     not the event's;
//   * `TileDetailSubmission` → save (the mapper's map, via a request seam
//     on the API so `Priority` reaches the wire) and delete the series,
//     each inside the schedule side-effects the legacy screen dispatched.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/redesignLog.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRequestMapper.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/data/request/TilerError.dart';

import 'tile_detail_draft_test.dart' as fx;

class FakeCalendarEventApi extends CalendarEventApi {
  FakeCalendarEventApi() : super(getContextCallBack: () => null);

  final List<String> calls = <String>[];
  final List<Map<String, dynamic>> updates = <Map<String, dynamic>>[];
  Object? failWith;
  CalendarEvent? answer;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<CalendarEvent> getCalEvent({String? id, String? designatedTileId}) =>
      _answer('get:$id:$designatedTileId', answer ?? fx.loaded());

  @override
  Future<CalendarEvent> updateCalEventRequest(
      Map<String, dynamic> params) async {
    updates.add(Map<String, dynamic>.from(params));
    return _answer('update', answer ?? fx.loaded());
  }

  @override
  Future<CalendarEvent> delete(String eventId, String thirdPartyId) =>
      _answer('delete:$eventId:$thirdPartyId', answer ?? fx.loaded());
}

class FakeLocationApi extends LocationApi {
  FakeLocationApi() : super(getContextCallBack: () => null);

  final List<String> calls = <String>[];
  Location? answer;
  Object? failWith;

  @override
  Future<Location?> getLocationById(
      {String? id, String? calendarId, String? subEventId}) async {
    calls.add('byCal:$calendarId');
    if (failWith != null) throw failWith!;
    return answer;
  }
}

class RecordingRefresher implements EditTileScheduleRefresher {
  final List<String> events = <String>[];
  @override
  void beginEvaluation() => events.add('begin');
  @override
  void refreshAfterChange() => events.add('refresh');
  @override
  void abandonEvaluation() => events.add('abandon');
}

void main() {
  late FakeCalendarEventApi calApi;
  late FakeLocationApi locationApi;
  late RecordingRefresher refresher;
  late ApiTileDetailLoader loader;
  late ApiTileDetailSubmission submission;

  setUp(() {
    calApi = FakeCalendarEventApi();
    locationApi = FakeLocationApi();
    refresher = RecordingRefresher();
    loader =
        ApiTileDetailLoader(calendarEventApi: calApi, locationApi: locationApi);
    submission =
        ApiTileDetailSubmission(calendarEventApi: calApi, refresher: refresher);
  });

  group('load', () {
    test('fetches the event by id and its location by calendar id', () async {
      locationApi.answer = fx.place('Work', '456 Market St');
      final TileDetailLoadResult r =
          await loader.load(const TileDetailTarget.calendarEvent('cal-1'));
      expect(r.failed, isFalse);
      expect(r.event?.id, 'cal-1');
      expect(r.location?.description, 'Work');
      expect(calApi.calls, <String>['get:cal-1:null']);
      expect(locationApi.calls, <String>['byCal:cal-1']);
    });

    test(
        'a designated tile template loads its calendar event by template '
        'id, then the location by the LOADED event\'s id', () async {
      // `TileDetail.byDesignatedTileId`: the tile-share path. The legacy
      // bloc called getCalEvent(designatedTileId:) and everything after
      // used state.calEvent.id.
      locationApi.answer = fx.place('Work', '456 Market St');
      final TileDetailLoadResult r =
          await loader.load(const TileDetailTarget.designatedTile('tpl-9'));
      expect(r.failed, isFalse);
      expect(r.event?.id, 'cal-1');
      expect(calApi.calls, <String>['get:null:tpl-9']);
      expect(locationApi.calls, <String>['byCal:cal-1']);
    });

    test('a missing or failed location is not the event\'s failure', () async {
      locationApi.failWith = StateError('socket');
      final TileDetailLoadResult r =
          await loader.load(const TileDetailTarget.calendarEvent('cal-1'));
      expect(r.failed, isFalse);
      expect(r.location, isNull);
    });

    test('a failed event is a typed failure', () async {
      calApi.failWith = TilerError(Message: 'no');
      TileDetailLoadResult r =
          await loader.load(const TileDetailTarget.calendarEvent('cal-1'));
      expect(r.failed, isTrue);
      expect(r.reasonCode, editTileFailureApiRejected);
      calApi.failWith = StateError('socket');
      r = await loader.load(const TileDetailTarget.calendarEvent('cal-1'));
      expect(r.reasonCode, editTileFailureNetwork);
      expect(locationApi.calls, isEmpty,
          reason: 'no location fetch without an event');
    });
  });

  group('save', () {
    test('a clean draft sends nothing', () async {
      final r = await submission.save(TileDetailDraft.fromLoaded(fx.loaded()));
      expect(r.outcome, EditTileSaveOutcome.nothingToSave);
      expect(calApi.updates, isEmpty);
      expect(refresher.events, isEmpty);
    });

    test(
        'a dirty draft sends exactly the mapper\'s map, once, with the '
        'schedule put into evaluation before and refreshed after', () async {
      final TileDetailDraft d = TileDetailDraft.fromLoaded(fx.loaded())
        ..setPriority(TilePriority.high);
      final r = await submission.save(d);
      expect(r.outcome, EditTileSaveOutcome.success);
      expect(r.event, isNotNull);
      expect(calApi.updates, <Map<String, dynamic>>[tileDetailUpdateParams(d)]);
      expect(calApi.updates.single['Priority'], 'high',
          reason: 'the request seam carries what updateCalEvent cannot');
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test('a rejection is a typed failure and the evaluation is abandoned',
        () async {
      calApi.failWith = TilerError(Message: 'no');
      final r = await submission
          .save(TileDetailDraft.fromLoaded(fx.loaded())..setSplit(4));
      expect(r.outcome, EditTileSaveOutcome.failure);
      expect(r.reasonCode, editTileFailureApiRejected);
      expect(refresher.events, <String>['begin', 'abandon']);
    });
  });

  group('logging', () {
    final List<String> logged = <String>[];
    setUp(() {
      logged.clear();
      RedesignLog.sink = (String event, Map<String, Object?> data) => logged.add(
          '$event ${data.entries.map((e) => '${e.key}=${e.value}').join(',')}');
    });
    tearDown(() => RedesignLog.sink = null);

    test('load, save, delete and occurrence failures are named', () async {
      calApi.failWith = TilerError(Message: 'gone');
      await loader.load(const TileDetailTarget.calendarEvent('cal-1'));
      await submission
          .save(TileDetailDraft.fromLoaded(fx.loaded())..setSplit(4));
      await submission.deleteSeries(TileDetailDraft.fromLoaded(fx.loaded()));
      expect(logged.map((String l) => l.split(' ').first), <String>[
        'tile_detail_load_failed',
        'tile_detail_save_failed',
        'tile_detail_delete_failed',
      ]);
      expect(logged.first, contains('calendarEventId=cal-1'));
      expect(logged.first, contains('gone'));
    });
  });

  group('delete series', () {
    test(
        'sends the calendar-event delete with the provider id, inside the '
        'schedule side-effects', () async {
      final TileDetailDraft d =
          TileDetailDraft.fromLoaded(fx.loaded(thirdPartyType: 'google'));
      final r = await submission.deleteSeries(d);
      expect(r.outcome, EditTileSaveOutcome.success);
      expect(calApi.calls, <String>['delete:cal-1:ext-9']);
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test('a Tiler event sends its empty provider id, as the bloc does',
        () async {
      await submission.deleteSeries(TileDetailDraft.fromLoaded(fx.loaded()));
      expect(calApi.calls, <String>['delete:cal-1:']);
    });
  });
}
