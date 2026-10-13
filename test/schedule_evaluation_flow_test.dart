import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class FakeScheduleApi extends ScheduleApi {
  FakeScheduleApi() : super(getContextCallBack: () => null);
  List<SubCalendarEvent> tiles = [];
  ScheduleStatus status =
      ScheduleStatus.fromJson({'analysisId': 'a', 'evaluationId': 'e'});
  Completer<void>? heldRead;
  Object? readError;
  Completer<ScheduleStatus>? heldStatus;
  int statusReads = 0;
  int reads = 0;
  final requestedWindows = <Timeline>[];
  final window = Timeline.fromDateTime(DateTime(2026), DateTime(2026, 1, 8));
  @override
  Future<ScheduleStatus> getScheduleStatus() async {
    statusReads++;
    return heldStatus == null ? status : await heldStatus!.future;
  }

  @override
  Future<Tuple3<List<Timeline>, List<SubCalendarEvent>, ScheduleStatus>>
      getSubEvents(Timeline window) async {
    reads++;
    requestedWindows.add(window);
    await heldRead?.future;
    if (readError != null) throw readError!;
    return Tuple3([], List.of(tiles), status);
  }
}

class ControlledClient extends http.BaseClient {
  ControlledClient(this.handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  final requests = <http.BaseRequest>[];
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return handler(request);
  }

  @override
  void close() {
    closed = true;
  }
}

http.StreamedResponse response([int status = 200]) =>
    http.StreamedResponse(const Stream<List<int>>.empty(), status);
Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScheduleBloc bloc;
  late FakeScheduleApi api;
  final tile = SubCalendarEvent(id: 'existing', name: 'Existing tile');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeScheduleApi()..tiles = [tile];
    bloc = ScheduleBloc(getContextCallBack: () => null)..scheduleApi = api;
  });
  tearDown(() async {
    await bloc.close();
  });
  Future<void> seed() async {
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [tile],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: api.status));
    await flush();
  }

  ScheduleEvaluation interrupted(
      {String id = 'interrupted',
      DateTime? startedAt,
      Duration timeout = const Duration(seconds: 180)}) {
    final start =
        startedAt ?? DateTime.now().subtract(const Duration(seconds: 10));
    return ScheduleEvaluation(
        id: id,
        kind: ScheduleChangeKind.delete,
        account: 'user',
        startedAt: start,
        expiresAt: start.add(timeout),
        baseline: const ScheduleRevision('a', 'e'),
        baselineObservedAt: start);
  }

  test('complete remains evaluating through GET and local reload', () async {
    await seed();
    final mutation = Completer<SubCalendarEvent>();
    final pending = bloc.runScheduleChange(() => mutation.future,
        kind: ScheduleChangeKind.complete, affectedTileIds: ['existing']);
    await flush();
    final id = bloc.activeEvaluation!.id;
    expect((bloc.state as ScheduleEvaluationState).subEvents, [tile]);
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect((bloc.state as ScheduleEvaluationState).evaluation!.id, id);
    expect((bloc.state as ScheduleEvaluationState).subEvents, [tile]);
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [tile],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: api.status));
    await flush();
    expect((bloc.state as ScheduleEvaluationState).evaluation!.id, id);
    api.heldRead = Completer<void>();
    mutation.complete(tile);
    await pending;
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(bloc.state, isA<ScheduleLoadedState>());
    expect((bloc.state as ScheduleLoadedState).subEvents, [tile]);
    api.heldRead!.complete();
    await flush();
  });

  test('the revision an admitted write produces is attributed to it, once',
      () async {
    await seed();
    final changes = <ScheduleChange>[];
    final sub = bloc.changeFeed.changes.listen(changes.add);
    final mutation = Completer<SubCalendarEvent>();
    final pending = bloc.runScheduleChange(() => mutation.future,
        kind: ScheduleChangeKind.complete, affectedTileIds: ['existing']);
    await flush();
    // The new schedule is read while the write is still evaluating.
    final moved = SubCalendarEvent(id: 'pushed', name: 'Pushed tile');
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [tile, moved],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: ScheduleStatus.fromJson(
            {'analysisId': 'a2', 'evaluationId': 'e2'})));
    await flush();
    expect(bloc.state, isA<ScheduleEvaluationState>());
    expect(changes, hasLength(1));
    expect(
        changes.single.attribution.origin, ScheduleChangeOrigin.userComplete);
    expect(changes.single.attribution.subjectId, 'existing');

    api.status =
        ScheduleStatus.fromJson({'analysisId': 'a2', 'evaluationId': 'e2'});
    api.tiles = [tile, moved];
    mutation.complete(tile);
    await pending;
    await flush();
    await flush();
    expect(bloc.state, isA<ScheduleLoadedState>());
    // Settling on the same revision is not another change.
    expect(changes, hasLength(1));
    await sub.cancel();
  });

  test('a failed write does not claim the next revision', () async {
    await seed();
    await expectLater(
        bloc.runScheduleChange(() async => throw StateError('rejected'),
            kind: ScheduleChangeKind.complete),
        throwsStateError);
    await flush();
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [tile],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: ScheduleStatus.fromJson(
            {'analysisId': 'a3', 'evaluationId': 'e3'})));
    await flush();
    expect(bloc.changeFeed.latest!.attribution.isRefresh, isTrue);
  });

  test('refresh without previousSubEvents retains existing tiles while loading',
      () async {
    await seed();
    api.heldRead = Completer<void>();
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    final loading = bloc.state as ScheduleLoadingState;
    expect(loading.subEvents, [tile]);
    expect(loading.isAlreadyLoaded, isTrue);
    api.heldRead!.complete();
    await flush();
  });

  test('the command keeps its captured name when a refresh renames the tile',
      () async {
    await seed();
    final wire = Completer<void>();
    final pending = bloc.runScheduleChange(() => wire.future,
        kind: ScheduleChangeKind.complete, affectedTileIds: ['existing']);
    expect(bloc.activeEvaluation!.eventName, 'Existing tile');
    expect(bloc.activeEvaluation!.affectedEventCount, 1);
    api.tiles = [
      SubCalendarEvent(id: 'existing', name: 'Renamed after request')
    ];
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect(bloc.activeEvaluation!.eventName, 'Existing tile');
    await expectLater(
        bloc.runScheduleChange(() async {},
            kind: ScheduleChangeKind.delete, eventName: 'Another event'),
        throwsA(isA<ScheduleChangeBlocked>()));
    expect(bloc.activeEvaluation!.eventName, 'Existing tile');
    wire.complete();
    await pending;
  });

  test(
      'nested API details fill an unknown target without changing request ownership',
      () async {
    await seed();
    final wire = Completer<void>();
    final pending = bloc.runScheduleChange(
        () => bloc.runScheduleChange(() => wire.future,
            kind: ScheduleChangeKind.edit,
            eventName: 'Off-screen event',
            affectedTileIds: ['off-screen']),
        kind: ScheduleChangeKind.edit);
    final original = bloc.activeEvaluation!;
    expect(original.eventName, 'Off-screen event');
    expect(original.affectedEventCount, 1);
    expect(original.affectedTileIds, ['off-screen']);
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect(bloc.activeEvaluation!.id, original.id);
    expect(bloc.activeEvaluation!.expiresAt, original.expiresAt);
    wire.complete();
    await pending;
  });

  test('bulk command ids are counted separately instead of as one csv value',
      () async {
    await seed();
    final wire = Completer<void>();
    final pending = bloc.runScheduleChange(() => wire.future,
        kind: ScheduleChangeKind.complete, affectedTileIds: ['one,two,three']);
    expect(bloc.activeEvaluation!.affectedEventCount, 3);
    expect(bloc.activeEvaluation!.eventName, isNull);
    wire.complete();
    await pending;
  });

  test('persisted uncertainty restores the command name and target count',
      () async {
    final store = await ScheduleEvaluationStore.load();
    final scoped =
        ScheduleBloc(getContextCallBack: () => null, evaluationStore: store)
          ..scheduleApi = api;
    scoped.revisions.observe(api.status);
    scoped.bindEvaluationAccount('user');
    final client = RetryHttpClient(
        scheduleLifecycle: () => scoped,
        innerClient: ControlledClient((_) async => response(408)));
    await expectLater(
        scoped.runScheduleChange(
            () =>
                client.delete(Uri.https('example.test', 'api/Schedule/Event')),
            kind: ScheduleChangeKind.delete,
            eventName: 'Off-screen event',
            affectedTileIds: ['off-screen']),
        throwsA(isA<http.ClientException>()));
    final original = scoped.activeEvaluation!;
    expect(original.eventName, 'Off-screen event');
    expect(store.read('user')!['eventName'], 'Off-screen event');
    client.close();
    await scoped.close();
    final restored = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationStore: await ScheduleEvaluationStore.load())
      ..scheduleApi = api;
    restored.bindEvaluationAccount('user');
    await flush();
    expect(restored.activeEvaluation!.eventName, 'Off-screen event');
    expect(restored.activeEvaluation!.affectedEventCount, 1);
    expect(restored.activeEvaluation!.kind, ScheduleChangeKind.delete);
    expect(restored.activeEvaluation!.id, original.id);
    expect(restored.activeEvaluation!.expiresAt.millisecondsSinceEpoch,
        original.expiresAt.millisecondsSinceEpoch);
    await restored.close();
  });

  test('second mutation rejects before invoking its request function',
      () async {
    await seed();
    final first = Completer<void>();
    final pending = bloc.runScheduleChange(() => first.future);
    var sent = false;
    await expectLater(bloc.runScheduleChange(() async {
      sent = true;
    }), throwsA(isA<ScheduleChangeBlocked>()));
    expect(sent, isFalse);
    first.complete();
    await pending;
    await flush();
  });

  test('view changes and failed reads cannot finish deletion', () async {
    await seed();
    final mutation = Completer<void>();
    final pending = bloc.runScheduleChange(() => mutation.future,
        kind: ScheduleChangeKind.delete);
    await flush();
    final id = bloc.activeEvaluation!.id;
    api.readError = const SocketException('read offline');
    bloc.add(ChangeViewEvent(AuthorizedRouteTileListPage.Weekly));
    await flush();
    expect(bloc.state.currentView, AuthorizedRouteTileListPage.Weekly);
    expect((bloc.state as ScheduleEvaluationState).subEvents, [tile]);
    expect(bloc.activeEvaluation!.id, id);
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect(bloc.activeEvaluation!.id, id);
    expect((bloc.state as ScheduleEvaluationState).subEvents, [tile]);
    mutation.complete();
    await pending;
    await flush();
  });

  test(
      'typed callback failure keeps data and never throws catchError type error',
      () async {
    await seed();
    final mutation = Completer<SubCalendarEvent>();
    bloc.add(EvaluateSchedule(
        renderedSubEvents: [tile],
        renderedTimelines: [],
        renderedScheduleTimeline: api.window,
        isAlreadyLoaded: true,
        scheduleStatus: api.status,
        kind: ScheduleChangeKind.startNow,
        request: () => mutation.future));
    await flush();
    mutation.completeError(StateError('request rejected'));
    await flush();
    final failed = bloc.state as ScheduleEvaluationState;
    expect(failed.evaluation!.phase, ScheduleEvaluationPhase.failed);
    expect(failed.subEvents, [tile]);
    expect(bloc.scheduleChangesBlocked, isFalse);
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect((bloc.state as ScheduleEvaluationState).evaluation!.phase,
        ScheduleEvaluationPhase.failed);
  });

  test('failure followed by another request has a new evaluation identity',
      () async {
    await seed();
    await expectLater(
        bloc.runScheduleChange(() async => throw StateError('rejected')),
        throwsStateError);
    await flush();
    final oldId = bloc.activeEvaluation!.id;
    final next = Completer<void>();
    final pending = bloc.runScheduleChange(() => next.future);
    await flush();
    expect(bloc.activeEvaluation!.id, isNot(oldId));
    expect((bloc.state as ScheduleEvaluationState).evaluation!.phase,
        ScheduleEvaluationPhase.pending);
    next.complete();
    await pending;
    await flush();
  });

  test('a fast typed failure is observed before its evaluation event arrives',
      () async {
    await seed();
    final pending = bloc.runScheduleChange<SubCalendarEvent>(
        () async => throw StateError('fast failure'),
        kind: ScheduleChangeKind.complete);
    await flush();
    final id = bloc.activeEvaluation!.id;
    bloc.add(EvaluateSchedule(
        renderedSubEvents: [tile],
        renderedTimelines: [],
        renderedScheduleTimeline: api.window,
        isAlreadyLoaded: true,
        scheduleStatus: api.status,
        callBack: pending));
    await flush();
    expect(bloc.activeEvaluation!.id, id);
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.failed);
    await expectLater(pending, throwsStateError);
  });

  test(
      'a recovered unconfirmed write is checked in the background and does '
      'not block the first new write', () async {
    final store = await ScheduleEvaluationStore.load();
    await store.write('user', interrupted().toRecord());
    final scoped =
        ScheduleBloc(getContextCallBack: () => null, evaluationStore: store)
          ..scheduleApi = api;
    final inner = ControlledClient((_) async => response());
    final client =
        RetryHttpClient(scheduleLifecycle: () => scoped, innerClient: inner);
    await scoped.runScheduleChange(() {
      scoped.bindEvaluationAccount('user');
      return client.post(Uri.https('example.test', 'api/Schedule/Revise'));
    });
    expect(inner.requests, hasLength(1));
    expect(scoped.activeEvaluation, isNull);
    final unresolved = scoped.unresolvedChanges.single;
    expect(unresolved.id, 'interrupted');
    expect(unresolved.kind, ScheduleChangeKind.delete);
    expect(unresolved.phase, ScheduleEvaluationPhase.uncertain);
    client.close();
    await scoped.close();
  });

  test('HTTP 2xx settles evaluation before body or revision changes', () async {
    await seed();
    final body = StreamController<List<int>>();
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: ControlledClient(
            (_) async => http.StreamedResponse(body.stream, 202)));
    final request = client.send(
        http.Request('POST', Uri.https('example.test', 'api/Schedule/Revise')));
    final headers = await request;
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(bloc.revisions.state!.evaluationId, 'e');
    final drain = headers.stream.drain<void>();
    await body.close();
    await drain;
    client.close();
  });

  for (final status in [400, 408, 500]) {
    test('HTTP $status retains failure or uncertainty across reads', () async {
      await seed();
      final inner = ControlledClient((_) async => response(status));
      final client =
          RetryHttpClient(scheduleLifecycle: () => bloc, innerClient: inner);
      await expectLater(
          client.post(Uri.https('example.test', 'api/Schedule/Revise')),
          throwsA(isA<http.ClientException>()));
      final phase = status == 400
          ? ScheduleEvaluationPhase.failed
          : ScheduleEvaluationPhase.uncertain;
      expect(bloc.activeEvaluation!.phase, phase);
      bloc.add(GetScheduleEvent(forceRefresh: true));
      await flush();
      expect((bloc.state as ScheduleEvaluationState).evaluation!.phase, phase);
      // Neither a refusal nor an unknown outcome holds other writes back.
      expect(bloc.scheduleChangesBlocked, isFalse);
      expect(inner.requests.length, 1);
      client.close();
    });
  }

  test(
      'API writes join their owning evaluation; another API write rejects before auth',
      () async {
    await seed();
    final wire = Completer<http.StreamedResponse>();
    final inner = ControlledClient((_) => wire.future);
    final client =
        RetryHttpClient(scheduleLifecycle: () => bloc, innerClient: inner);
    final service = ScheduleApi(getContextCallBack: () => bloc);
    final pending = bloc.runScheduleChange(
        () => service.runScheduleMutation(
            ScheduleChangeKind.complete,
            () => client.post(
                Uri.https('example.test', 'api/Schedule/Event/Complete'))),
        kind: ScheduleChangeKind.complete);
    await flush();
    expect(bloc.activeEvaluation!.kind, ScheduleChangeKind.complete);
    await expectLater(service.sendPostRequest('api/CalendarEvent/Update', {}),
        throwsA(isA<ScheduleChangeBlocked>()));
    expect(inner.requests.length, 1);
    wire.complete(response());
    await pending;
    client.close();
    service.dispose();
  });

  test('first headers adopt the account before persisting a mutation',
      () async {
    final store = await ScheduleEvaluationStore.load();
    final scoped =
        ScheduleBloc(getContextCallBack: () => null, evaluationStore: store)
          ..scheduleApi = api;
    final wire = Completer<http.StreamedResponse>();
    final client = RetryHttpClient(
        scheduleLifecycle: () => scoped,
        innerClient: ControlledClient((_) => wire.future));
    final pending = scoped.runScheduleChange(() {
      scoped.bindEvaluationAccount('user');
      return client
          .post(Uri.https('example.test', 'api/Schedule/Event/Complete'));
    });
    await flush();
    expect(store.read('user'), isNotNull);
    expect(store.read('session'), isNull);
    wire.complete(response());
    await pending;
    expect(store.read('user'), isNull);
    client.close();
    await scoped.close();
  });

  test(
      'timeout and unchanged revision retain uncertainty; late 2xx settles original request',
      () async {
    await seed();
    final wire = Completer<http.StreamedResponse>();
    final inner = ControlledClient((_) => wire.future);
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: inner,
        mutationTimeout: const Duration(milliseconds: 10));
    await expectLater(
        client.post(Uri.https('example.test', 'api/Schedule/Revise')),
        throwsA(isA<TimeoutException>()));
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
    bloc.revisions.recover();
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
    expect(bloc.scheduleChangesBlocked, isFalse);
    expect(inner.requests.length, 1);
    wire.complete(response());
    await flush();
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(inner.requests.length, 1);
    client.close();
  });

  test('uncertainty also blocks a retry inside the original request scope',
      () async {
    await seed();
    final wire = Completer<http.StreamedResponse>();
    final inner = ControlledClient((_) => wire.future);
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: inner,
        mutationTimeout: const Duration(milliseconds: 10));
    await expectLater(bloc.runScheduleChange(() async {
      try {
        await client.post(Uri.https('example.test', 'api/Schedule/Revise'));
      } on TimeoutException {
        return client.post(Uri.https('example.test', 'api/Schedule/Revise'));
      }
      return response();
    }), throwsA(isA<ScheduleChangeBlocked>()));
    expect(inner.requests.length, 1);
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
    wire.complete(response());
    await flush();
    await flush();
    client.close();
  });

  test('logout prevents an old typed response from updating the next session',
      () async {
    await seed();
    final mutation = Completer<SubCalendarEvent>();
    final pending = bloc.runScheduleChange(() => mutation.future);
    await flush();
    bloc.add(LogOutScheduleEvent(() => null));
    await flush();
    mutation.complete(tile);
    await pending;
    await flush();
    expect(bloc.state, isA<ScheduleLoggedOutState>());
    expect(bloc.activeEvaluation, isNull);
  });

  test('restart restores an interrupted request as uncertain for its account',
      () async {
    final store = await ScheduleEvaluationStore.load();
    final record = interrupted(id: 'request');
    await store.write('user', record.toRecord());
    final restored = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationStore: await ScheduleEvaluationStore.load())
      ..scheduleApi = api;
    restored.bindEvaluationAccount('user');
    expect(restored.activeEvaluation, isNull);
    await flush();
    expect(restored.activeEvaluation!.kind, ScheduleChangeKind.delete);
    expect(restored.scheduleChangesBlocked, isFalse);
    expect(restored.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
    expect(restored.activeEvaluation!.startedAt.millisecondsSinceEpoch,
        record.startedAt.millisecondsSinceEpoch);
    expect(restored.activeEvaluation!.expiresAt.millisecondsSinceEpoch,
        record.expiresAt.millisecondsSinceEpoch);
    await restored.close();
  });

  test('initialization has no mutation lock and serializes concurrent writes',
      () async {
    api.heldStatus = Completer<ScheduleStatus>();
    var sent = false;
    final wire = Completer<void>();
    final pending = bloc.runScheduleChange(() {
      sent = true;
      return wire.future;
    });
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(bloc.scheduleChangesBlocked, isFalse);
    expect(sent, isFalse);
    await expectLater(bloc.runScheduleChange(() async {}),
        throwsA(isA<ScheduleChangeBlocked>()));
    api.heldStatus!.complete(api.status);
    await flush();
    expect(sent, isTrue);
    expect(bloc.activeEvaluation!.baseline.isKnown, isTrue);
    expect(
        bloc.activeEvaluation!.baselineObservedAt
            .isAfter(bloc.activeEvaluation!.startedAt),
        isFalse);
    wire.complete();
    await pending;
  });

  test('unknown hashes abort initialization without sending or locking',
      () async {
    api.status = ScheduleStatus();
    var sent = false;
    await expectLater(bloc.runScheduleChange(() async {
      sent = true;
    }), throwsA(isA<ScheduleInitializationFailed>()));
    expect(sent, isFalse);
    expect(bloc.activeEvaluation, isNull);
    expect(bloc.scheduleChangesBlocked, isFalse);
    api.status =
        ScheduleStatus.fromJson({'analysisId': 'a', 'evaluationId': 'e'});
    await bloc.runScheduleChange(() async {
      sent = true;
    });
    expect(sent, isTrue);
  });

  test('initialization timeout leaves no lock and permits a fresh attempt',
      () async {
    final scoped = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: const ScheduleEvaluationConfig(
            initializationTimeout: Duration(milliseconds: 20)))
      ..scheduleApi = api;
    api.heldStatus = Completer<ScheduleStatus>();
    var sent = false;
    await expectLater(scoped.runScheduleChange(() async {
      sent = true;
    }), throwsA(isA<TimeoutException>()));
    expect(sent, isFalse);
    expect(scoped.activeEvaluation, isNull);
    api.heldStatus!.complete(api.status);
    api.heldStatus = null;
    await scoped.runScheduleChange(() async {
      sent = true;
    });
    expect(sent, isTrue);
    await scoped.close();
  });

  test('a stale baseline is refreshed before invoking the mutation', () async {
    var now = DateTime(2026, 10, 11);
    final scoped = ScheduleBloc(getContextCallBack: () => null, now: () => now)
      ..scheduleApi = api;
    scoped.revisions.observe(api.status);
    now = now.add(const Duration(minutes: 1));
    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    final wire = Completer<void>();
    final pending = scoped.runScheduleChange(() => wire.future);
    expect(scoped.activeEvaluation, isNull);
    await flush();
    expect(api.statusReads, 1);
    expect(scoped.activeEvaluation!.baseline,
        const ScheduleRevision('new', 'new'));
    expect(scoped.activeEvaluation!.startedAt, now);
    wire.complete();
    await pending;
    await scoped.close();
  });

  test('changed hashes preserve a live pending request', () async {
    await seed();
    final wire = Completer<void>();
    final pending = bloc.runScheduleChange(() => wire.future);
    final id = bloc.activeEvaluation!.id;
    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    bloc.add(GetScheduleEvent(forceRefresh: true));
    await flush();
    expect(bloc.activeEvaluation!.id, id);
    expect(bloc.scheduleChangesBlocked, isTrue);
    wire.complete();
    await pending;
  });

  test('changed hashes release an interrupted request without replay',
      () async {
    await seed();
    final wire = Completer<http.StreamedResponse>();
    final inner = ControlledClient((_) => wire.future);
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: inner,
        mutationTimeout: const Duration(milliseconds: 10));
    await expectLater(
        client.post(Uri.https('example.test', 'api/Schedule/Revise')),
        throwsA(isA<TimeoutException>()));
    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    bloc.refreshEvaluationSchedule();
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(bloc.scheduleChangesBlocked, isFalse);
    expect(bloc.state, isA<ScheduleLoadedState>());
    expect(inner.requests.length, 1);
    final next = Completer<void>();
    final pending = bloc.runScheduleChange(() => next.future);
    final nextId = bloc.activeEvaluation!.id;
    wire.complete(response());
    await flush();
    expect(bloc.activeEvaluation!.id, nextId);
    next.complete();
    await pending;
    client.close();
  });

  test('deadline releases unchanged uncertainty and preserves the calendar',
      () async {
    final scoped = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: const ScheduleEvaluationConfig(
            operationTimeout: Duration(milliseconds: 80)))
      ..scheduleApi = api;
    scoped.add(ReloadLocalScheduleEvent(
        subEvents: [tile],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: api.status));
    await flush();
    final releases = <ScheduleEvaluationReleasedState>[];
    final subscription = scoped.stream.listen((state) {
      if (state is ScheduleEvaluationReleasedState) releases.add(state);
    });
    final wire = Completer<http.StreamedResponse>();
    final inner = ControlledClient((_) => wire.future);
    final client = RetryHttpClient(
        scheduleLifecycle: () => scoped,
        innerClient: inner,
        mutationTimeout: const Duration(milliseconds: 10));
    await expectLater(
        client.post(Uri.https('example.test', 'api/Schedule/Revise')),
        throwsA(isA<TimeoutException>()));
    final deadline = scoped.activeEvaluation!.expiresAt;
    scoped.refreshEvaluationSchedule();
    await flush();
    expect(scoped.activeEvaluation!.expiresAt, deadline);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(scoped.activeEvaluation, isNull);
    expect(scoped.scheduleChangesBlocked, isFalse);
    expect((scoped.state as ScheduleLoadedState).subEvents, [tile]);
    expect(scoped.evaluationStore.read('session'), isNull);
    expect(scoped.revisions.observedAt, isNull);
    expect(releases.length, 1);
    expect(releases.single.reason, 'deadline_expired');
    expect(scoped.lastChangeUnconfirmed, isTrue);
    scoped.refreshEvaluationSchedule();
    await flush();
    expect(releases.length, 1);
    wire.complete(response());
    await flush();
    client.close();
    await subscription.cancel();
    await scoped.close();
  });

  test('deadline stops a hung preparation and prevents its later send',
      () async {
    final scoped = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: const ScheduleEvaluationConfig(
            operationTimeout: Duration(milliseconds: 20)))
      ..scheduleApi = api;
    scoped.revisions.observe(api.status);
    final prepared = Completer<void>();
    var sent = false;
    final pending = scoped.runScheduleChange(() async {
      await prepared.future;
      return scoped.observeScheduleResponse(() async {
        sent = true;
        return response();
      }, kind: ScheduleChangeKind.revise);
    });
    await expectLater(pending, throwsA(isA<TimeoutException>()));
    expect(scoped.scheduleChangesBlocked, isFalse);
    prepared.complete();
    await flush();
    expect(sent, isFalse);
    await scoped.close();
  });

  test('wall-clock expiry is enforced on refresh before the timer fires',
      () async {
    var now = DateTime(2026, 10, 11);
    final scoped = ScheduleBloc(getContextCallBack: () => null, now: () => now)
      ..scheduleApi = api;
    scoped.revisions.observe(api.status);
    final wire = Completer<void>();
    final pending = scoped.runScheduleChange(() => wire.future);
    final assertion = expectLater(pending, throwsA(isA<TimeoutException>()));
    now = now.add(const Duration(minutes: 4));
    expect(scoped.scheduleChangesBlocked, isFalse);
    scoped.refreshEvaluationSchedule();
    await flush();
    await assertion;
    expect(scoped.activeEvaluation, isNull);
    wire.complete();
    await scoped.close();
  });

  test('2xx confirmation prevents a timeout during later body handling',
      () async {
    final scoped = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: const ScheduleEvaluationConfig(
            operationTimeout: Duration(milliseconds: 20)))
      ..scheduleApi = api;
    scoped.revisions.observe(api.status);
    final result = await scoped.runScheduleChange(() async {
      await scoped.observeScheduleResponse(() async => response(202),
          kind: ScheduleChangeKind.complete);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return tile;
    });
    expect(result, tile);
    expect(scoped.activeEvaluation, isNull);
    await scoped.close();
  });

  test('expired and legacy journals cannot restore locks', () async {
    final store = await ScheduleEvaluationStore.load();
    for (final record in [
      {'id': 'legacy', 'kind': 'delete'},
      interrupted(
              startedAt: DateTime.now().subtract(const Duration(minutes: 5)))
          .toRecord(),
      {...interrupted().toRecord(), 'analysisId': ''},
      interrupted(startedAt: DateTime.now().add(const Duration(minutes: 1)))
          .toRecord(),
    ]) {
      await store.write('user', record);
      final scoped =
          ScheduleBloc(getContextCallBack: () => null, evaluationStore: store)
            ..scheduleApi = api;
      scoped.bindEvaluationAccount('user');
      await flush();
      expect(scoped.activeEvaluation, isNull);
      expect(scoped.scheduleChangesBlocked, isFalse);
      expect(store.read('user'), isNull);
      await scoped.close();
    }
  });

  test('restoration waits for fresh hashes and uses the remaining deadline',
      () async {
    final store = await ScheduleEvaluationStore.load();
    final record = interrupted(
        startedAt: DateTime.now().subtract(const Duration(milliseconds: 100)),
        timeout: const Duration(milliseconds: 220));
    await store.write('user', record.toRecord());
    api.heldStatus = Completer<ScheduleStatus>();
    final scoped =
        ScheduleBloc(getContextCallBack: () => null, evaluationStore: store)
          ..scheduleApi = api;
    scoped.bindEvaluationAccount('user');
    await flush();
    expect(scoped.activeEvaluation, isNull);
    expect(scoped.scheduleChangesBlocked, isFalse);
    api.heldStatus!.complete(api.status);
    await flush();
    expect(scoped.activeEvaluation!.startedAt.millisecondsSinceEpoch,
        record.startedAt.millisecondsSinceEpoch);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(scoped.activeEvaluation, isNull);
    expect(store.read('user'), isNull);
    await scoped.close();
  });

  test('changed hashes discard a restored request at initialization', () async {
    final store = await ScheduleEvaluationStore.load();
    await store.write('user', interrupted().toRecord());
    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    final scoped =
        ScheduleBloc(getContextCallBack: () => null, evaluationStore: store)
          ..scheduleApi = api;
    scoped.bindEvaluationAccount('user');
    await flush();
    expect(scoped.activeEvaluation, isNull);
    expect(store.read('user'), isNull);
    await scoped.close();
  });

  test('GET retry preserves the connection carrying a pending write', () async {
    await seed();
    final wire = Completer<http.StreamedResponse>();
    final original = ControlledClient((r) {
      if (r.method == 'GET') throw const SocketException('stale');
      return wire.future;
    });
    final fresh = ControlledClient((_) async => response());
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: original,
        clientFactory: () => fresh,
        retryDelay: Duration.zero);
    final write = client.post(Uri.https('example.test', 'api/Schedule/Revise'));
    await flush();
    await client.get(Uri.https('example.test', 'api/Schedule/status'));
    expect(original.closed, isFalse);
    expect(bloc.scheduleChangesBlocked, isTrue);
    wire.complete(response());
    await write;
    expect(original.closed, isTrue);
    client.close();
  });

  testWidgets('local failure feedback distinguishes an uncertain response',
      (tester) async {
    await tester.runAsync(bloc.close);
    var now = DateTime.now();
    bloc = ScheduleBloc(getContextCallBack: () => null, now: () => now)
      ..scheduleApi = api;
    bloc.revisions.observe(api.status);
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: ControlledClient((_) async => response(408)));
    await expectLater(
        client.post(Uri.https('example.test', 'api/Schedule/Revise')),
        throwsA(isA<http.ClientException>()));
    await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) => Scaffold(
                    body: Text(scheduleChangeFailureMessage(context)))))));
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.textContaining(l10n.scheduleChangeUncertain), findsOneWidget);
    expect(find.text(l10n.scheduleChangeFailed), findsNothing);
    expect(bloc.scheduleChangesBlocked, isFalse);
    now = now.add(const Duration(minutes: 4));
    bloc.refreshEvaluationSchedule();
    await tester.pump();
    await tester.pump();
    expect(bloc.scheduleChangesBlocked, isFalse);
    expect(
        find.text(l10n.scheduleChangeUnconfirmed(
            '${l10n.reOptimizeChip} · ${l10n.scheduleChangeTargetSchedule}')),
        findsOneWidget);
    expect(find.text(l10n.scheduleChangeFailed), findsNothing);
    client.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });

  testWidgets(
      'feedback identifies the command and target across phases on a narrow screen',
      (tester) async {
    await tester.runAsync(bloc.close);
    bloc = ScheduleBloc(getContextCallBack: () => null)..scheduleApi = api;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final now = DateTime.now();
    const longName =
        'Team planning and review with the product team and external partners';
    for (final (kind, phase, name, count, target, icon) in [
      (
        ScheduleChangeKind.complete,
        ScheduleEvaluationPhase.pending,
        longName,
        1,
        longName,
        Icons.check_circle_outline
      ),
      (
        ScheduleChangeKind.delete,
        ScheduleEvaluationPhase.uncertain,
        'Lunch',
        1,
        'Lunch',
        Icons.delete_outline
      ),
      (
        ScheduleChangeKind.delete,
        ScheduleEvaluationPhase.failed,
        'Lunch',
        1,
        'Lunch',
        Icons.delete_outline
      ),
      (
        ScheduleChangeKind.complete,
        ScheduleEvaluationPhase.pending,
        null,
        3,
        l10n.scheduleChangeEventCount(3),
        Icons.check_circle_outline
      ),
      (
        ScheduleChangeKind.revise,
        ScheduleEvaluationPhase.pending,
        null,
        0,
        l10n.scheduleChangeTargetSchedule,
        Icons.autorenew
      ),
      (
        ScheduleChangeKind.defer,
        ScheduleEvaluationPhase.pending,
        null,
        0,
        l10n.scheduleChangeAllEvents,
        Icons.snooze_outlined
      ),
      (
        ScheduleChangeKind.edit,
        ScheduleEvaluationPhase.pending,
        null,
        1,
        l10n.scheduleChangeTargetEvent,
        Icons.edit_calendar_outlined
      ),
      (
        ScheduleChangeKind.add,
        ScheduleEvaluationPhase.pending,
        'New event',
        1,
        'New event',
        Icons.add_circle_outline
      ),
      (
        ScheduleChangeKind.settings,
        ScheduleEvaluationPhase.pending,
        null,
        0,
        l10n.scheduleChangeTargetSchedule,
        Icons.tune
      ),
    ]) {
      final evaluation = ScheduleEvaluation(
          id: 'display',
          kind: kind,
          account: 'user',
          startedAt: now,
          expiresAt: now.add(const Duration(minutes: 3)),
          baseline: const ScheduleRevision('a', 'e'),
          baselineObservedAt: now,
          eventName: name,
          affectedEventCount: count,
          phase: phase);
      await tester.pumpWidget(BlocProvider.value(
          value: bloc,
          child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                  body: ScheduleEvaluationFeedback(
                      state: ScheduleEvaluationState(
                          subEvents: [],
                          timelines: [],
                          lookupTimeline: api.window,
                          evaluationTime: now,
                          currentView: AuthorizedRouteTileListPage.Daily,
                          scheduleStatus: api.status,
                          evaluation: evaluation))))));
      expect(find.text(target), findsOneWidget);
      expect(
          tester
              .widget<Icon>(
                  find.byKey(const ValueKey('scheduleEvaluationActionIcon')))
              .icon,
          icon);
      expect(
          find.byType(CircularProgressIndicator),
          phase == ScheduleEvaluationPhase.pending
              ? findsOneWidget
              : findsNothing);
      if (phase != ScheduleEvaluationPhase.pending) {
        expect(find.text(l10n.delete), findsOneWidget);
        expect(find.text(l10n.deleting), findsNothing);
      }
      expect(tester.takeException(), isNull, reason: '$kind $phase');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });

  for (final (kind, label) in [
    (ScheduleChangeKind.complete, 'Completing'),
    (ScheduleChangeKind.delete, 'Deleting')
  ]) {
    testWidgets(
        '$label feedback and real daily grid survive GET until request finishes',
        (tester) async {
      await tester.runAsync(bloc.close);
      bloc = ScheduleBloc(getContextCallBack: () => null)..scheduleApi = api;
      final day = Utility.currentTime().dayDate.add(const Duration(days: 1));
      final visible = SubCalendarEvent(
          id: 'visible',
          name: 'Visible tile',
          start: day.add(const Duration(hours: 9)).millisecondsSinceEpoch,
          end: day.add(const Duration(hours: 10)).millisecondsSinceEpoch);
      api.tiles = [visible];
      final dates = UiDateManagerBloc();
      final carousel = TileListCarouselBloc();
      final subTiles = SubCalendarTileBloc(getContextCallBack: () => null);
      final layout = DailyViewLayoutCubit();
      await tester.pump();
      await layout.toggle();
      dates.add(DateChangeEvent(selectedDate: day));
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: [visible],
          timelines: [],
          lookupTimeline: Timeline.fromDateTime(
              day.subtract(const Duration(days: 3)),
              day.add(const Duration(days: 3))),
          scheduleStatus: api.status));
      await tester.pump();
      await tester.pumpWidget(MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: dates),
            BlocProvider.value(value: carousel),
            BlocProvider.value(value: subTiles),
            BlocProvider.value(value: layout),
          ],
          child: MaterialApp(
              theme: TileThemeData.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                  body: LayoutBuilder(
                      builder: (_, constraints) => DailyTileList(
                          carouselHeight: constraints.maxHeight))))));
      await tester.pump();
      final grid = find.byKey(ValueKey('daygrid_${day.universalDayIndex}'));
      final original = tester.state(grid);
      final mutation = Completer<SubCalendarEvent>();
      final pending = bloc.runScheduleChange(() => mutation.future,
          kind: kind, affectedTileIds: ['visible']);
      await tester.pump();
      await tester.pump();
      expect(bloc.state, isA<ScheduleEvaluationState>());
      expect(find.text(label), findsOneWidget);
      expect(find.byType(ScheduleEvaluationFeedback), findsOneWidget);
      expect(find.text('Visible tile'), findsNWidgets(2));
      expect(
          find.descendant(
              of: find.byType(ScheduleEvaluationFeedback),
              matching: find.text('Visible tile')),
          findsOneWidget);
      expect(
          find.byIcon(kind == ScheduleChangeKind.complete
              ? Icons.check_circle_outline
              : Icons.delete_outline),
          findsWidgets);
      expect(tester.state(grid), same(original));
      bloc.add(GetScheduleEvent(forceRefresh: true));
      await tester.pump();
      await tester.pump();
      expect(find.text(label), findsOneWidget);
      expect(tester.state(grid), same(original));
      api.heldRead = Completer<void>();
      mutation.complete(visible);
      await pending;
      await tester.pump();
      expect(find.byType(ScheduleEvaluationFeedback), findsNothing);
      expect(find.text('Visible tile'), findsOneWidget);
      expect(tester.state(grid), same(original));
      api.heldRead!.complete();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await dates.close();
        await carousel.close();
        await subTiles.close();
        await layout.close();
        await bloc.close();
      });
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
