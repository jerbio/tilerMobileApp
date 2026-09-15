// Step 1.3 — the loader and the submission.
//
// Everything the legacy screen did inline — `subEventUpdate()`'s bloc
// dispatches, `handleRsvpUpdate`, the playback callback's refresh, the
// what-if call, the two-bloc load — lives behind two seams the screen can be
// handed fakes of:
//
//   * `EditTileLoader.load` → the sub-event and its suggestions, or a typed
//     failure (the legacy screen had no failure state at all: a failed load
//     was a spinner forever);
//   * `EditTileSubmission` → save / rsvp / the four actions / preview, each
//     returning a typed result and each running the schedule side-effects
//     through an `EditTileScheduleRefresher` rather than touching blocs.
//
// The fakes below subclass the real API classes and override only the
// network methods, so the request each seam builds is the real one and can
// be asserted against the Step 1.2 mapper.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/prediction.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRequestMapper.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tuple/tuple.dart';

final DateTime start = DateTime.utc(2026, 9, 12, 14, 0);
final DateTime end = DateTime.utc(2026, 9, 12, 15, 30);

SubCalendarEvent loaded(
        {String thirdPartyType = 'tiler', String id = 'sub-1'}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': id,
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'calendarEventStart': start.millisecondsSinceEpoch,
      'calendarEventEnd': end.millisecondsSinceEpoch,
      'splitCount': 1,
      'thirdPartyType': thirdPartyType,
      'thirdPartyId': thirdPartyType == 'tiler' ? null : 'gcal-evt-9',
      'thirdPartyUserId': thirdPartyType == 'tiler' ? null : 'gcal-user-3',
      'priority': 'medium',
    });

/// Records what the screen would have sent, answers what it is told to.
class FakeSubEventApi extends SubCalendarEventApi {
  FakeSubEventApi() : super(getContextCallBack: () => null);

  final List<Map<String, dynamic>> updates = <Map<String, dynamic>>[];
  final List<String> calls = <String>[];
  Object? failWith;
  SubCalendarEvent? answer;
  SubCalendarEvent? loadAnswer;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<SubCalendarEvent> updateSubEventRequest(
      Map<String, dynamic> params) async {
    updates.add(Map<String, dynamic>.from(params));
    return _answer('update', answer ?? loaded());
  }

  @override
  Future<SubCalendarEvent> setAsNow(SubCalendarEvent subEvent) =>
      _answer('setAsNow:${subEvent.id}', answer ?? subEvent);

  @override
  Future<SubCalendarEvent> complete(SubCalendarEvent subEvent) =>
      _answer('complete:${subEvent.id}', answer ?? subEvent);

  @override
  Future<CalendarEvent?> delete(String eventId, String? thirdPartyEventID,
          String? thirdPartyUserId, String? thirdPartyType) =>
      _answer(
          'delete:$eventId:$thirdPartyEventID:$thirdPartyUserId:$thirdPartyType',
          null);

  @override
  Future procrastinate(Duration duration, String tileId) =>
      _answer('procrastinate:$tileId:${duration.inMinutes}', null);

  @override
  Future<SubCalendarEvent> getSubEvent(String id,
          {String calendarSource = '', String thirdPartyUserId = ''}) =>
      _answer('get:$id:$calendarSource:$thirdPartyUserId',
          loadAnswer ?? loaded(id: id));
}

class FakeWhatIfApi extends WhatIfApi {
  FakeWhatIfApi() : super(getContextCallBack: () => null);

  final List<EditTilerEvent> previews = <EditTilerEvent>[];
  Tuple2<Preview, Preview>? answer;
  Object? failWith;

  @override
  Future<Tuple2<Preview, Preview>?> updateSubEvent(
      EditTilerEvent subEvent) async {
    previews.add(subEvent);
    if (failWith != null) throw failWith!;
    return answer;
  }
}

class FakeCalendarEventApi extends CalendarEventApi {
  FakeCalendarEventApi() : super(getContextCallBack: () => null);

  List<NextTileSuggestion> suggestions = <NextTileSuggestion>[];
  Object? failWith;

  @override
  Future<List<NextTileSuggestion>> getNextTileSuggestion(String id) async {
    if (failWith != null) throw failWith!;
    return suggestions;
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

Preview previewJson(Map<String, dynamic> json) => Preview.fromJson(json);

Map<String, dynamic> tile(String id, int dayMs) => <String, dynamic>{
      'id': id,
      'name': id,
      'start': dayMs,
      'end': dayMs + 3600000,
      'thirdPartyType': 'tiler',
    };

void main() {
  late FakeSubEventApi subApi;
  late FakeWhatIfApi whatIf;
  late FakeCalendarEventApi calApi;
  late RecordingRefresher refresher;
  late ApiEditTileSubmission submission;

  setUp(() {
    subApi = FakeSubEventApi();
    whatIf = FakeWhatIfApi();
    calApi = FakeCalendarEventApi();
    refresher = RecordingRefresher();
    submission = ApiEditTileSubmission(
      subCalendarEventApi: subApi,
      whatIfApi: whatIf,
      refresher: refresher,
    );
  });

  group('save', () {
    test('a clean draft sends nothing', () async {
      final result = await submission.save(EditTileDraft.fromLoaded(loaded()));
      expect(result.outcome, EditTileSaveOutcome.nothingToSave);
      expect(subApi.updates, isEmpty);
      expect(refresher.events, isEmpty);
    });

    test('a dirty draft sends exactly the mapper\'s request, once', () async {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded())
        ..setName('Write REPORT');
      final result = await submission.save(d);

      expect(result.outcome, EditTileSaveOutcome.success);
      expect(subApi.updates, <Map<String, dynamic>>[editTileUpdateParams(d)]);
      expect(result.tile, isNotNull);
    });

    test('the schedule is put into evaluation before and refreshed after',
        () async {
      await submission
          .save(EditTileDraft.fromLoaded(loaded())..setName('Renamed'));
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test(
        'a server rejection is a typed failure and the evaluation is abandoned',
        () async {
      // The legacy screen dispatched EvaluateSchedule and then, on failure,
      // never dispatched anything else — the schedule stayed "evaluating".
      subApi.failWith = TilerError(Message: 'no');
      final result = await submission
          .save(EditTileDraft.fromLoaded(loaded())..setName('Renamed'));
      expect(result.outcome, EditTileSaveOutcome.failure);
      expect(result.reasonCode, 'api_rejected');
      expect(refresher.events, <String>['begin', 'abandon']);
    });

    test('anything else is a network failure', () async {
      subApi.failWith = StateError('socket');
      final result = await submission
          .save(EditTileDraft.fromLoaded(loaded())..setName('Renamed'));
      expect(result.outcome, EditTileSaveOutcome.failure);
      expect(result.reasonCode, 'network_timeout');
    });
  });

  group('rsvp', () {
    test('sends the legacy update with RsvpStatusUpdate and nothing new',
        () async {
      final EditTileDraft d =
          EditTileDraft.fromLoaded(loaded(thirdPartyType: 'google'));
      final result = await submission.rsvp(d, RsvpStatus.accepted);

      expect(result.outcome, EditTileSaveOutcome.success);
      final Map<String, dynamic> sent = subApi.updates.single;
      expect(sent['RsvpStatusUpdate'], 'Accepted');
      expect(sent['EventID'], 'gcal-evt-9');
      expect(sent.containsKey('ApplicableOccurence'), isFalse,
          reason: 'an RSVP is not a draft change');
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test('ignores the draft\'s unsaved edits', () async {
      // RSVP saves the tile AS LOADED plus the answer; pending edits stay
      // pending, as on the legacy screen.
      final EditTileDraft d =
          EditTileDraft.fromLoaded(loaded(thirdPartyType: 'google'))
            ..setName('Edited');
      await submission.rsvp(d, RsvpStatus.declined);
      expect(subApi.updates.single['EventName'], 'Write report');
    });
  });

  group('actions', () {
    test('complete', () async {
      final result = await submission.complete(loaded());
      expect(result.outcome, EditTileSaveOutcome.success);
      expect(subApi.calls, <String>['complete:sub-1']);
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test('start now', () async {
      await submission.startNow(loaded());
      expect(subApi.calls, <String>['setAsNow:sub-1']);
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test('delete, with the provider identity the legacy buttons send',
        () async {
      await submission.delete(loaded(thirdPartyType: 'google'));
      // First argument is the sub-event's OWN id, then the provider's — the
      // order `PlayBack.deleteTile` has always used.
      expect(
          subApi.calls, <String>['delete:sub-1:gcal-evt-9:gcal-user-3:google']);
      await submission.delete(loaded());
      expect(subApi.calls.last, 'delete:sub-1::' ':tiler',
          reason: 'a Tiler tile sends its empty provider ids, as parsed');
    });

    test('defer, by a duration', () async {
      await submission.defer(loaded(), const Duration(hours: 2));
      expect(subApi.calls, <String>['procrastinate:sub-1:120']);
      expect(refresher.events, <String>['begin', 'refresh']);
    });

    test('a failed action abandons the evaluation and names the reason',
        () async {
      subApi.failWith = TilerError(Message: 'no');
      final result = await submission.complete(loaded());
      expect(result.outcome, EditTileSaveOutcome.failure);
      expect(result.reasonCode, 'api_rejected');
      expect(refresher.events, <String>['begin', 'abandon']);
    });
  });

  group('preview (what-if)', () {
    test('sends the legacy preview request for the draft', () async {
      final EditTileDraft d = EditTileDraft.fromLoaded(loaded())
        ..setStartTime(start.add(const Duration(minutes: 5)));
      await submission.preview(d);
      expect(WhatIfApi.subEventEditParams(whatIf.previews.single),
          editTileWhatIfParams(d));
      expect(refresher.events, isEmpty, reason: 'a preview touches nothing');
    });

    test('lists tardy and overflow tiles across ALL days', () async {
      // The legacy sheet rendered `dayPreviews.first` only.
      final int day1 = DateTime.utc(2026, 9, 12).millisecondsSinceEpoch;
      final int day2 = DateTime.utc(2026, 9, 13).millisecondsSinceEpoch;
      whatIf.answer = Tuple2<Preview, Preview>(
        previewJson(<String, dynamic>{}),
        previewJson(<String, dynamic>{
          'tardy': <String, dynamic>{
            'days': <String, dynamic>{
              '$day1': <Map<String, dynamic>>[tile('t1', day1)],
              '$day2': <Map<String, dynamic>>[tile('t2', day2)],
            }
          },
          'nonViable': <Map<String, dynamic>>[
            tile('u1', day1),
            tile('u2', day2),
          ],
        }),
      );
      final WhatIfResult? result =
          await submission.preview(EditTileDraft.fromLoaded(loaded()));
      expect(result, isNotNull);
      expect(result!.tardy.map((t) => t.id), <String>['t1', 't2']);
      expect(result.overflow.map((t) => t.id), <String>['u1', 'u2']);
      expect(result.isEmpty, isFalse);
    });

    test('no consequences is an empty result, not null', () async {
      whatIf.answer = Tuple2<Preview, Preview>(
          previewJson(<String, dynamic>{}), previewJson(<String, dynamic>{}));
      final WhatIfResult? result =
          await submission.preview(EditTileDraft.fromLoaded(loaded()));
      expect(result?.isEmpty, isTrue);
    });

    test('a failure is a failed result, never a throw (4.3b)', () async {
      // Advisory: nothing blocks on it, but the screen must be able to
      // tell "nothing affected" from "could not check".
      whatIf.failWith = StateError('socket');
      WhatIfResult? result =
          await submission.preview(EditTileDraft.fromLoaded(loaded()));
      expect(result?.failed, isTrue);
      expect(result?.isEmpty, isTrue);
      whatIf.failWith = null;
      whatIf.answer = null;
      result = await submission.preview(EditTileDraft.fromLoaded(loaded()));
      expect(result?.failed, isTrue);
    });

    test('a real answer is never marked failed (4.3b)', () async {
      whatIf.answer = Tuple2<Preview, Preview>(
          previewJson(<String, dynamic>{}), previewJson(<String, dynamic>{}));
      final WhatIfResult? result =
          await submission.preview(EditTileDraft.fromLoaded(loaded()));
      expect(result?.failed, isFalse);
    });
  });

  group('load', () {
    late ApiEditTileLoader loader;
    setUp(() {
      loader = ApiEditTileLoader(
          subCalendarEventApi: subApi, calendarEventApi: calApi);
    });

    test('fetches the tile with its provider identity, and its suggestions',
        () async {
      calApi.suggestions = <NextTileSuggestion>[
        NextTileSuggestion.fromJson(<String, dynamic>{'name': 'next'})
      ];
      final result = await loader.load('sub-1',
          source: 'google', thirdPartyUserId: 'gcal-user-3');
      expect(result.tile?.id, 'sub-1');
      expect(subApi.calls, <String>['get:sub-1:google:gcal-user-3']);
      expect(result.suggestions.map((s) => s.name), <String>['next']);
      expect(result.failed, isFalse);
    });

    test('a missing source is sent as the empty string, as the bloc does',
        () async {
      await loader.load('sub-1');
      expect(subApi.calls, <String>['get:sub-1::']);
    });

    test('suggestions failing does not fail the load', () async {
      calApi.failWith = StateError('socket');
      final result = await loader.load('sub-1');
      expect(result.failed, isFalse);
      expect(result.suggestions, isEmpty);
    });

    test('the tile failing is a typed failure', () async {
      subApi.failWith = TilerError(Message: 'gone');
      final result = await loader.load('sub-1');
      expect(result.failed, isTrue);
      expect(result.reasonCode, 'api_rejected');
      expect(result.tile, isNull);
    });
  });
}
