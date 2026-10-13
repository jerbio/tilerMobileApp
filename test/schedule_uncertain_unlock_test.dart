// A write whose outcome is unknown informs the user but does not lock the
// app: other changes can go ahead, the schedule is re-read until it shows
// the change (or the deadline passes), the card can be dismissed, and the
// write itself is never sent again unless the user chooses to.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/util.dart';

import 'schedule_evaluation_flow_test.dart'
    show FakeScheduleApi, ControlledClient, response, flush;

const _fast = ScheduleEvaluationConfig(
  reconcileFastInterval: Duration(milliseconds: 20),
  reconcileFastWindow: Duration(milliseconds: 60),
  reconcileSlowInterval: Duration(milliseconds: 50),
);

final _complete = Uri.https('example.test', 'api/Schedule/Event/Complete');
final _revise = Uri.https('example.test', 'api/Schedule/Revise');
const _changed = ScheduleRevision('new', 'new');

Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));
  late FakeScheduleApi api;
  final tile = SubCalendarEvent(id: 't1', name: 'Gym');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeScheduleApi()..tiles = [tile];
  });

  Future<ScheduleBloc> make(
      {ScheduleEvaluationConfig config = _fast,
      ScheduleEvaluationStore? store}) async {
    final bloc = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: config,
        evaluationStore: store)
      ..scheduleApi = api;
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [tile],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: api.status));
    await flush();
    return bloc;
  }

  /// Completes Gym; the server answers 408, so the outcome is unknown.
  Future<void> uncertainComplete(ScheduleBloc bloc, RetryHttpClient client,
      {String tileId = 't1'}) async {
    await expectLater(
        bloc.runScheduleChange(() => client.post(_complete),
            kind: ScheduleChangeKind.complete,
            eventName: 'Gym',
            affectedTileIds: [tileId]),
        throwsA(isA<http.ClientException>()));
    expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
  }

  RetryHttpClient clientFor(ScheduleBloc bloc, ControlledClient inner,
          {Duration mutationTimeout = const Duration(seconds: 180)}) =>
      RetryHttpClient(
          scheduleLifecycle: () => bloc,
          innerClient: inner,
          mutationTimeout: mutationTimeout);

  test('an uncertain write does not block another write', () async {
    final bloc = await make();
    final inner = ControlledClient((request) async =>
        response(request.url.path.contains('Complete') ? 408 : 200));
    final client = clientFor(bloc, inner);
    await uncertainComplete(bloc, client);

    expect(bloc.scheduleChangesBlocked, isFalse);
    await bloc.runScheduleChange(() => client.post(_revise),
        kind: ScheduleChangeKind.revise);
    expect(inner.requests.map((r) => r.url.path),
        ['/api/Schedule/Event/Complete', '/api/Schedule/Revise']);
    client.close();
    await bloc.close();
  });

  test('a pending write still blocks another write', () async {
    final bloc = await make();
    final wire = Completer<http.StreamedResponse>();
    final inner = ControlledClient((_) => wire.future);
    final client = clientFor(bloc, inner);
    final first = bloc.runScheduleChange(() => client.post(_complete),
        kind: ScheduleChangeKind.complete, affectedTileIds: ['t1']);
    await flush();
    expect(bloc.scheduleChangesBlocked, isTrue);
    await expectLater(
        bloc.runScheduleChange(() => client.post(_revise),
            kind: ScheduleChangeKind.revise),
        throwsA(isA<ScheduleChangeBlocked>()));
    expect(inner.requests, hasLength(1));
    wire.complete(response());
    await first;
    client.close();
    await bloc.close();
  });

  test(
      'a new write first re-reads the schedule; a changed schedule '
      'acknowledges the earlier write before the new one starts', () async {
    final bloc = await make(
        config: const ScheduleEvaluationConfig(
            reconcileFastInterval: Duration(seconds: 30)));
    final outcomes = <ScheduleChangeOutcome>[];
    final sub = bloc.outcomes.listen(outcomes.add);
    final inner = ControlledClient((request) async =>
        response(request.url.path.contains('Complete') ? 408 : 200));
    final client = clientFor(bloc, inner);
    await uncertainComplete(bloc, client);
    final earlier = bloc.activeEvaluation!.id;
    await flush();
    final readsBefore = api.statusReads;

    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    ScheduleChangeOutcome? toldWhenSent;
    var readsWhenSent = 0;
    await bloc.runScheduleChange(() {
      toldWhenSent = bloc.lastOutcome;
      readsWhenSent = api.statusReads;
      return client.post(_revise);
    }, kind: ScheduleChangeKind.revise);

    expect(readsWhenSent, greaterThan(readsBefore));
    expect(toldWhenSent?.kind, ScheduleChangeOutcomeKind.acknowledged);
    expect(toldWhenSent?.evaluation.id, earlier);
    await flush();
    expect(outcomes.single.evaluation.id, earlier);
    expect(bloc.unresolvedChanges, isEmpty);
    await sub.cancel();
    client.close();
    await bloc.close();
  });

  test(
      'a write superseded while unconfirmed keeps being checked, and its '
      'late answer is reported without disturbing the new write', () async {
    final bloc = await make();
    final outcomes = <ScheduleChangeOutcome>[];
    final sub = bloc.outcomes.listen(outcomes.add);
    final late = Completer<http.StreamedResponse>();
    final next = Completer<http.StreamedResponse>();
    final inner = ControlledClient((request) =>
        request.url.path.contains('Complete') ? late.future : next.future);
    // The first answer is slow enough to time out; the second is not.
    final slow = clientFor(bloc, inner,
        mutationTimeout: const Duration(milliseconds: 10));
    final client = clientFor(bloc, inner);
    await expectLater(
        bloc.runScheduleChange(() => slow.post(_complete),
            kind: ScheduleChangeKind.complete, affectedTileIds: ['t1']),
        throwsA(isA<TimeoutException>()));
    final earlier = bloc.activeEvaluation!.id;

    final pending = bloc.runScheduleChange(() => client.post(_revise),
        kind: ScheduleChangeKind.revise);
    await wait(5);
    final current = bloc.activeEvaluation!;
    expect(current.kind, ScheduleChangeKind.revise);
    expect(current.phase, ScheduleEvaluationPhase.pending);
    expect(bloc.unresolvedChanges.map((e) => e.id), [earlier]);

    late.complete(response());
    await wait(5);
    expect(outcomes.map((o) => (o.evaluation.id, o.kind)),
        [(earlier, ScheduleChangeOutcomeKind.confirmed)]);
    expect(bloc.unresolvedChanges, isEmpty);
    expect(bloc.activeEvaluation!.id, current.id);
    expect(inner.requests, hasLength(2));

    next.complete(response());
    await expectLater(pending, completes);
    await sub.cancel();
    slow.close();
    client.close();
    await bloc.close();
  });

  test(
      'an unconfirmed write re-reads the status at once, then on the cadence, '
      'and pauses while the app is away', () async {
    final bloc = await make(
        config: const ScheduleEvaluationConfig(
      reconcileFastInterval: Duration(milliseconds: 20),
      reconcileFastWindow: Duration(milliseconds: 60),
      reconcileSlowInterval: Duration(milliseconds: 80),
      operationTimeout: Duration(milliseconds: 400),
    ));
    final client =
        clientFor(bloc, ControlledClient((_) async => response(408)));
    final start = api.statusReads;
    await uncertainComplete(bloc, client);
    await wait(5);
    expect(api.statusReads, start + 1, reason: 'checked straight away');

    await wait(70); // the 5 s phase: every 20 ms
    final fast = api.statusReads - start;
    expect(fast, greaterThanOrEqualTo(3));

    await wait(90); // the 15 s phase: every 80 ms
    expect(api.statusReads - start - fast, inInclusiveRange(1, 2));

    bloc.pauseReconciliation();
    final paused = api.statusReads;
    await wait(120);
    expect(api.statusReads, paused);
    bloc.resumeReconciliation();
    await wait(5);
    expect(api.statusReads, paused + 1, reason: 'checked again on return');
    client.close();
    await bloc.close();
  });

  test('re-checking never sends the write again', () async {
    final bloc = await make();
    final inner = ControlledClient((_) async => response(408));
    final client = clientFor(bloc, inner);
    await uncertainComplete(bloc, client);
    await wait(150);
    bloc.revisions.recover();
    bloc.refreshEvaluationSchedule();
    await wait(50);
    expect(api.statusReads, greaterThan(3));
    expect(inner.requests, hasLength(1));
    client.close();
    await bloc.close();
  });

  test(
      'a changed schedule seen while re-checking loads it, clears the card '
      'and is told as the write\'s change', () async {
    final bloc = await make();
    final outcomes = <ScheduleChangeOutcome>[];
    final sub = bloc.outcomes.listen(outcomes.add);
    final client =
        clientFor(bloc, ControlledClient((_) async => response(408)));
    await uncertainComplete(bloc, client);
    final reads = api.reads;

    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    await wait(60);

    expect(bloc.activeEvaluation, isNull);
    expect(bloc.state, isNot(isA<ScheduleEvaluationState>()));
    expect(api.reads, greaterThan(reads), reason: 'the new schedule loads');
    expect(outcomes.single.kind, ScheduleChangeOutcomeKind.acknowledged);
    expect(bloc.changeTracker.resolve(_changed).origin,
        ScheduleChangeOrigin.userComplete);
    await sub.cancel();
    client.close();
    await bloc.close();
  });

  test(
      'at the deadline the user is told, checking stops, and the next write '
      'starts from a fresh read', () async {
    final bloc = await make(
        config: const ScheduleEvaluationConfig(
      reconcileFastInterval: Duration(milliseconds: 20),
      reconcileFastWindow: Duration(milliseconds: 60),
      reconcileSlowInterval: Duration(milliseconds: 50),
      operationTimeout: Duration(milliseconds: 150),
    ));
    final outcomes = <ScheduleChangeOutcome>[];
    final sub = bloc.outcomes.listen(outcomes.add);
    final inner = ControlledClient((_) async => response(408));
    final client = clientFor(bloc, inner);
    await uncertainComplete(bloc, client);

    await wait(220);
    expect(outcomes.single.kind, ScheduleChangeOutcomeKind.unconfirmed);
    expect(bloc.activeEvaluation, isNull);
    final stopped = api.statusReads;
    await wait(120);
    expect(api.statusReads, stopped);

    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    bloc.revisions.observe(api.status);
    expect(bloc.changeTracker.resolve(_changed).isRefresh, isTrue,
        reason: 'the expired write no longer claims later changes');

    bloc.revisions.invalidateObservation();
    final before = api.statusReads;
    var readsWhenSent = 0;
    await bloc.runScheduleChange(() async {
      readsWhenSent = api.statusReads;
      return true;
    }, kind: ScheduleChangeKind.revise);
    expect(readsWhenSent, before + 1);
    await sub.cancel();
    client.close();
    await bloc.close();
  });

  test(
      'a dismissed card stays hidden, even after a restart, while the write '
      'keeps being checked and its outcome still reported', () async {
    final store = await ScheduleEvaluationStore.load();
    final bloc = await make(store: store);
    final client =
        clientFor(bloc, ControlledClient((_) async => response(408)));
    await uncertainComplete(bloc, client);
    final id = bloc.activeEvaluation!.id;

    bloc.dismissUncertainty();
    await flush();
    expect(bloc.activeEvaluation, isNull);
    expect(bloc.state, isNot(isA<ScheduleEvaluationState>()));
    expect(bloc.unresolvedChanges.map((e) => e.id), [id]);
    final reads = api.statusReads;
    await wait(60);
    expect(api.statusReads, greaterThan(reads), reason: 'still checking');
    client.close();
    await bloc.close();

    final restarted = await make(store: await ScheduleEvaluationStore.load());
    final outcomes = <ScheduleChangeOutcome>[];
    final sub = restarted.outcomes.listen(outcomes.add);
    restarted.bindEvaluationAccount('user');
    await wait(30);
    expect(restarted.activeEvaluation, isNull, reason: 'still dismissed');
    expect(restarted.unresolvedChanges.map((e) => e.id), [id]);

    api.status =
        ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
    await wait(60);
    expect(outcomes.map((o) => (o.evaluation.id, o.kind)),
        [(id, ScheduleChangeOutcomeKind.acknowledged)]);
    expect(restarted.unresolvedChanges, isEmpty);
    await sub.cancel();
    await restarted.close();
  });

  test(
      'repeating the same change on the same tile asks first; declining '
      'sends nothing', () async {
    final bloc = await make(
        config: const ScheduleEvaluationConfig(
            reconcileFastInterval: Duration(seconds: 30)));
    inner0 = 0;
    final inner = ControlledClient((request) async => response(
        request.url.path.contains('Complete') && inner0 == 0 ? 408 : 200));
    final client = clientFor(bloc, inner);
    await uncertainComplete(bloc, client);
    inner0 = 1;
    final unconfirmed = bloc.activeEvaluation!.id;
    final asked = <String>[];
    var answer = false;
    bloc.confirmReattempt = (previous) async {
      asked.add(previous.id);
      return answer;
    };

    await expectLater(
        bloc.runScheduleChange(() => client.post(_complete),
            kind: ScheduleChangeKind.complete, affectedTileIds: ['t1']),
        throwsA(isA<ScheduleChangeDeclined>()));
    expect(asked, [unconfirmed]);
    expect(inner.requests, hasLength(1));
    expect(bloc.lastDeclinedChange?.id, unconfirmed);

    // A different tile is not a repeat.
    await bloc.runScheduleChange(() => client.post(_complete),
        kind: ScheduleChangeKind.complete, affectedTileIds: ['t2']);
    expect(asked, hasLength(1));
    expect(inner.requests, hasLength(2));

    answer = true;
    await bloc.runScheduleChange(() => client.post(_complete),
        kind: ScheduleChangeKind.complete, affectedTileIds: ['t1']);
    expect(asked, [unconfirmed, unconfirmed]);
    expect(inner.requests, hasLength(3));
    client.close();
    await bloc.close();
  });

  test(
      'after a restart an unconfirmed write is shown and checked, '
      'without locking, for its remaining time', () async {
    final store = await ScheduleEvaluationStore.load();
    final bloc = await make(store: store);
    final client =
        clientFor(bloc, ControlledClient((_) async => response(408)));
    await uncertainComplete(bloc, client);
    final original = bloc.activeEvaluation!;
    client.close();
    await bloc.close();

    final restarted = await make(store: await ScheduleEvaluationStore.load());
    final reads = api.statusReads;
    restarted.bindEvaluationAccount('user');
    await wait(60);
    final restored = restarted.activeEvaluation!;
    expect(restored.id, original.id);
    expect(restored.phase, ScheduleEvaluationPhase.uncertain);
    expect(restored.expiresAt.millisecondsSinceEpoch,
        original.expiresAt.millisecondsSinceEpoch);
    expect(restarted.scheduleChangesBlocked, isFalse);
    expect(api.statusReads, greaterThan(reads + 1), reason: 'checking');
    await restarted.close();
  });

  group('told once', () {
    test(
        'the screen that sent the change hears nothing until the schedule '
        'has been checked, and the card never says unconfirmed before then',
        () async {
      final bloc = await make();
      final phases = <ScheduleEvaluationPhase?>[];
      final states = bloc.stream.listen((state) {
        if (state is ScheduleEvaluationState) {
          phases.add(state.evaluation?.phase);
        }
      });
      final client =
          clientFor(bloc, ControlledClient((_) async => response(503)));
      api.heldStatus = Completer<ScheduleStatus>();
      var heard = false;
      final pending = bloc.runScheduleChange(() => client.post(_complete),
          kind: ScheduleChangeKind.complete, affectedTileIds: ['t1'])
        ..then((_) {}, onError: (Object _) {}).whenComplete(() => heard = true);
      await wait(20);
      expect(heard, isFalse, reason: 'still checking the schedule');
      expect(phases, isNot(contains(ScheduleEvaluationPhase.uncertain)));

      api.heldStatus!.complete(api.status);
      api.heldStatus = null;
      await expectLater(pending, throwsA(isA<http.ClientException>()));
      expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
      await states.cancel();
      client.close();
      await bloc.close();
    });

    test(
        'a change already in the schedule when the outcome becomes unknown '
        'is only acknowledged', () async {
      final bloc = await make();
      final outcomes = <ScheduleChangeOutcome>[];
      final sub = bloc.outcomes.listen(outcomes.add);
      final phases = <ScheduleEvaluationPhase?>[];
      final states = bloc.stream.listen((state) {
        if (state is ScheduleEvaluationState) {
          phases.add(state.evaluation?.phase);
        }
      });
      final wire = Completer<http.StreamedResponse>();
      final client = clientFor(bloc, ControlledClient((_) => wire.future));
      final pending = bloc.runScheduleChange(() => client.post(_complete),
          kind: ScheduleChangeKind.complete,
          eventName: 'Gym',
          affectedTileIds: ['t1']);
      await flush();
      // A read while the write was in flight already shows its effect.
      api.status =
          ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
      bloc.revisions.observe(api.status);
      wire.complete(response(503));
      await expectLater(pending, throwsA(isA<http.ClientException>()));
      await flush();

      expect(phases, isNot(contains(ScheduleEvaluationPhase.uncertain)));
      expect(bloc.activeEvaluation, isNull);
      expect(outcomes.map((o) => o.kind),
          [ScheduleChangeOutcomeKind.acknowledged]);
      expect(bloc.latestOutcome?.kind, ScheduleChangeOutcomeKind.acknowledged);
      await sub.cancel();
      await states.cancel();
      client.close();
      await bloc.close();
    });

    test(
        'a change cut off while the app is in the background is checked '
        'when it returns, and told once', () async {
      final bloc = await make(
          config: const ScheduleEvaluationConfig(
              uncertaintyGrace: Duration(milliseconds: 40),
              reconcileFastInterval: Duration(seconds: 30)));
      final outcomes = <ScheduleChangeOutcome>[];
      final sub = bloc.outcomes.listen(outcomes.add);
      final phases = <ScheduleEvaluationPhase?>[];
      final states = bloc.stream.listen((state) {
        if (state is ScheduleEvaluationState) {
          phases.add(state.evaluation?.phase);
        }
      });
      final wire = Completer<http.StreamedResponse>();
      final client = clientFor(bloc, ControlledClient((_) => wire.future));
      var heard = false;
      final pending = bloc.runScheduleChange(() => client.post(_complete),
          kind: ScheduleChangeKind.complete, affectedTileIds: ['t1'])
        ..then((_) {}, onError: (Object _) {}).whenComplete(() => heard = true);
      await flush();

      // The user leaves the app; the system then cuts the connection.
      bloc.pauseReconciliation();
      wire.completeError(
          http.ClientException('Software caused connection abort'));
      await wait(120); // far longer than the check would take
      expect(heard, isFalse, reason: 'nothing decided while away');
      expect(phases, isNot(contains(ScheduleEvaluationPhase.uncertain)));
      expect(api.statusReads, 0, reason: 'no read while away');

      // Meanwhile the server applied it.
      api.status =
          ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});
      bloc.resumeReconciliation();
      await expectLater(pending, throwsA(isA<http.ClientException>()));
      await flush();

      expect(phases, isNot(contains(ScheduleEvaluationPhase.uncertain)));
      expect(outcomes.map((o) => o.kind),
          [ScheduleChangeOutcomeKind.acknowledged]);
      await sub.cancel();
      await states.cancel();
      client.close();
      await bloc.close();
    });

    test('the check before telling is bounded', () async {
      final bloc = await make(
          config: const ScheduleEvaluationConfig(
              uncertaintyGrace: Duration(milliseconds: 40),
              reconcileFastInterval: Duration(seconds: 30)));
      final client =
          clientFor(bloc, ControlledClient((_) async => response(503)));
      api.heldStatus = Completer<ScheduleStatus>(); // never answers
      final started = DateTime.now();
      await expectLater(
          bloc.runScheduleChange(() => client.post(_complete),
              kind: ScheduleChangeKind.complete, affectedTileIds: ['t1']),
          throwsA(isA<http.ClientException>()));
      expect(DateTime.now().difference(started).inMilliseconds, lessThan(1000));
      expect(bloc.activeEvaluation!.phase, ScheduleEvaluationPhase.uncertain);
      client.close();
      await bloc.close();
    });

    test(
        'a late confirmation arriving during the check is told as gone '
        'through, not as a failure', () async {
      final bloc = await make();
      final outcomes = <ScheduleChangeOutcome>[];
      final sub = bloc.outcomes.listen(outcomes.add);
      final late = Completer<http.StreamedResponse>();
      final client = clientFor(bloc, ControlledClient((_) => late.future),
          mutationTimeout: const Duration(milliseconds: 10));
      api.heldStatus = Completer<ScheduleStatus>();
      final pending = bloc.runScheduleChange(() => client.post(_complete),
          kind: ScheduleChangeKind.complete, affectedTileIds: ['t1']);
      await wait(30); // timed out; now checking the schedule
      late.complete(response());
      await wait(5);
      api.heldStatus!.complete(api.status);
      api.heldStatus = null;
      await expectLater(pending, throwsA(isA<TimeoutException>()));
      await flush();

      expect(bloc.activeEvaluation, isNull);
      expect(
          outcomes.map((o) => o.kind), [ScheduleChangeOutcomeKind.confirmed]);
      expect(bloc.latestOutcome?.kind, ScheduleChangeOutcomeKind.confirmed);
      await sub.cancel();
      client.close();
      await bloc.close();
    });

    testWidgets(
        'when the screen tells the outcome, the calendar does not repeat it',
        (tester) async {
      final bloc = _Scripted(null);
      final bus = ScheduleNoticeBus();
      final now = DateTime.now();
      final gym = ScheduleEvaluation(
          id: 'gym',
          kind: ScheduleChangeKind.complete,
          account: 'user',
          startedAt: now,
          expiresAt: now.add(const Duration(minutes: 3)),
          baseline: const ScheduleRevision('a', 'e'),
          baselineObservedAt: now,
          eventName: 'Gym',
          affectedEventCount: 1,
          affectedTileIds: const ['t1'],
          phase: ScheduleEvaluationPhase.uncertain);
      await tester.pumpWidget(RepositoryProvider<ScheduleNoticeBus>.value(
          value: bus,
          child: BlocProvider<ScheduleBloc>.value(
              value: bloc,
              child: MaterialApp(
                  locale: const Locale('en'),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: ScheduleChangeOutcomeNotices(
                      child: Scaffold(
                          body: Builder(
                              builder: (context) => TextButton(
                                  onPressed: () => showScheduleChangeFailure(
                                      context,
                                      kind: ScheduleChangeKind.complete,
                                      eventName: 'Gym'),
                                  child: const Text('Report')))))))));

      // The write's outcome is known when its screen reports the error.
      final outcome =
          ScheduleChangeOutcome(gym, ScheduleChangeOutcomeKind.acknowledged);
      bloc.latest = outcome;
      bloc.publish(outcome);
      await tester.tap(find.text('Report'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final acknowledged =
          l10n.scheduleChangeAcknowledged('${l10n.complete} · Gym');
      // The screen told it, in its own message...
      expect(
          find.descendant(
              of: find.byType(SnackBar), matching: find.text(acknowledged)),
          findsOneWidget);
      // ...so the calendar did not repeat it.
      expect(find.byKey(ScheduleInterruptionToast.toastKey), findsNothing);
      expect(find.text(acknowledged), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      bus.dispose();
      await tester.runAsync(bloc.close);
    });
  });

  group('screens', () {
    Widget app(ScheduleBloc bloc, Widget home) => BlocProvider.value(
        value: bloc,
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home));

    ScheduleEvaluation unconfirmedGym({String id = 'gym'}) {
      final now = DateTime.now();
      return ScheduleEvaluation(
          id: id,
          kind: ScheduleChangeKind.complete,
          account: 'user',
          startedAt: now,
          expiresAt: now.add(const Duration(minutes: 3)),
          baseline: const ScheduleRevision('a', 'e'),
          baselineObservedAt: now,
          eventName: 'Gym',
          affectedEventCount: 1,
          affectedTileIds: const ['t1'],
          phase: ScheduleEvaluationPhase.uncertain);
    }

    testWidgets('the uncertainty card can be dismissed', (tester) async {
      final bloc = _Scripted(unconfirmedGym());
      await tester.pumpWidget(app(
          bloc,
          Scaffold(
              body: ScheduleEvaluationFeedback(
                  state: ScheduleEvaluationState(
                      subEvents: const [],
                      timelines: const [],
                      lookupTimeline: Utility.todayTimeline(),
                      evaluationTime: DateTime.now(),
                      currentView: AuthorizedRouteTileListPage.Daily,
                      scheduleStatus: ScheduleStatus(),
                      evaluation: bloc.activeEvaluation)))));
      expect(find.text(l10n.scheduleChangeUncertain), findsOneWidget);
      expect(find.text(l10n.scheduleChangeRefresh), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.close));
      expect(bloc.dismissed, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(bloc.close);
    });

    testWidgets(
        'the screen that sent it hears "unconfirmed", never "failed", '
        'and gets no Retry', (tester) async {
      final bloc = _Scripted(unconfirmedGym());
      await tester.pumpWidget(app(
          bloc,
          Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showScheduleChangeFailure(context,
                          kind: ScheduleChangeKind.complete,
                          eventName: 'Gym',
                          onRetry: () {}),
                      child: const Text('Report'))))));
      await tester.tap(find.text('Report'));
      await tester.pump();
      expect(find.textContaining(l10n.scheduleChangeUncertain), findsOneWidget);
      expect(find.textContaining(l10n.scheduleChangeFailed), findsNothing);
      expect(find.text(l10n.addTileRetry), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(bloc.close);
    });

    testWidgets('outcomes are told to the user', (tester) async {
      final bloc = _Scripted(null);
      await tester.pumpWidget(app(
          bloc,
          const ScheduleChangeOutcomeNotices(
              child: Scaffold(body: SizedBox()))));
      var write = 0;
      for (final (kind, text) in [
        (
          ScheduleChangeOutcomeKind.acknowledged,
          l10n.scheduleChangeAcknowledged('${l10n.complete} · Gym')
        ),
        (
          ScheduleChangeOutcomeKind.confirmed,
          l10n.scheduleChangeWentThrough('${l10n.complete} · Gym')
        ),
        (
          ScheduleChangeOutcomeKind.failed,
          l10n.scheduleChangeFailedLate('${l10n.complete} · Gym')
        ),
        (
          ScheduleChangeOutcomeKind.unconfirmed,
          l10n.scheduleChangeUnconfirmed('${l10n.complete} · Gym')
        ),
      ]) {
        // Each write resolves once; one write per outcome.
        bloc.publish(
            ScheduleChangeOutcome(unconfirmedGym(id: 'gym${write++}'), kind));
        // After the moment the sending screen gets to tell it first, the
        // newest outcome replaces the one showing.
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget, reason: kind.name);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(bloc.close);
    });

    testWidgets('before repeating a change, the user is asked', (tester) async {
      final bloc = _Scripted(null);
      await tester.pumpWidget(app(
          bloc,
          const ScheduleChangeOutcomeNotices(
              child: Scaffold(body: SizedBox()))));
      expect(bloc.confirmReattempt, isNotNull);

      final declined = bloc.confirmReattempt!(unconfirmedGym());
      await tester.pumpAndSettle();
      expect(find.text(l10n.scheduleChangeReattemptTitle), findsOneWidget);
      expect(
          find.text(l10n.scheduleChangeReattemptBody('${l10n.complete} · Gym')),
          findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(await declined, isFalse);

      final confirmed = bloc.confirmReattempt!(unconfirmedGym());
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.scheduleChangeReattemptConfirm));
      await tester.pumpAndSettle();
      expect(await confirmed, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(bloc.confirmReattempt, isNull, reason: 'released on unmount');
      await tester.runAsync(bloc.close);
    });
  });
}

/// The second request of the repeat test answers normally.
var inner0 = 0;

/// A bloc whose evaluation and outcomes the test sets directly.
class _Scripted extends ScheduleBloc {
  _Scripted(this.current) : super(getContextCallBack: () => null);
  final ScheduleEvaluation? current;
  final StreamController<ScheduleChangeOutcome> _outcomes =
      StreamController<ScheduleChangeOutcome>.broadcast();
  int dismissed = 0;

  @override
  ScheduleEvaluation? get activeEvaluation => current;
  ScheduleChangeOutcome? latest;
  @override
  ScheduleChangeOutcome? get latestOutcome => latest;
  @override
  bool get scheduleChangesBlocked =>
      current?.phase == ScheduleEvaluationPhase.pending;
  @override
  Stream<ScheduleChangeOutcome> get outcomes => _outcomes.stream;
  @override
  void dismissUncertainty() => dismissed++;

  void publish(ScheduleChangeOutcome outcome) => _outcomes.add(outcome);

  @override
  Future<void> close() async {
    await _outcomes.close();
    return super.close();
  }
}
