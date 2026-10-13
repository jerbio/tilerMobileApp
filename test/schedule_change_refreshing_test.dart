// After the server confirms a change, the card says "Updating your
// schedule…" until the refreshed schedule is shown, so the calendar never
// looks finished while it still shows the old schedule. It holds nothing
// back and always ends: with the new schedule, a failed read, or a timeout.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';
import 'package:tiler_app/services/changeFlash.dart';
import 'package:tiler_app/util.dart';

import 'schedule_evaluation_flow_test.dart'
    show FakeScheduleApi, ControlledClient, response, flush;

final _complete = Uri.https('example.test', 'api/Schedule/Event/Complete');
final _changed =
    ScheduleStatus.fromJson({'analysisId': 'new', 'evaluationId': 'new'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));
  late FakeScheduleApi api;
  final gym = SubCalendarEvent(id: 't1', name: 'Gym');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeScheduleApi()..tiles = [gym];
  });

  Future<ScheduleBloc> make(
      {ScheduleEvaluationConfig config = const ScheduleEvaluationConfig(),
      ScheduleChangeTimings? timings}) async {
    final bloc = ScheduleBloc(
        getContextCallBack: () => null,
        evaluationConfig: config,
        timings: timings)
      ..scheduleApi = api;
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [gym],
        timelines: [],
        lookupTimeline: api.window,
        scheduleStatus: api.status));
    await flush();
    return bloc;
  }

  /// Completes Gym; the server confirms it while the refresh read is held.
  Future<RetryHttpClient> confirmedComplete(ScheduleBloc bloc) async {
    api.heldRead = Completer<void>();
    final client = RetryHttpClient(
        scheduleLifecycle: () => bloc,
        innerClient: ControlledClient((_) async => response()));
    await bloc.runScheduleChange(() => client.post(_complete),
        kind: ScheduleChangeKind.complete,
        eventName: 'Gym',
        affectedTileIds: ['t1']);
    await flush();
    return client;
  }

  ScheduleRevision revisionOf(ScheduleState state) =>
      ScheduleRevision.fromStatus(
          ScheduleState.generatePriorScheduleState(state).scheduleStatus);

  test(
      'after the answer the card says it is updating, without holding '
      'anything back', () async {
    final bloc = await make();
    final client = await confirmedComplete(bloc);

    final state = bloc.state;
    expect(state, isA<ScheduleEvaluationState>());
    final card = (state as ScheduleEvaluationState).evaluation!;
    expect(card.phase, ScheduleEvaluationPhase.refreshing);
    expect(card.kind, ScheduleChangeKind.complete);
    expect(card.eventName, 'Gym');
    expect(bloc.activeEvaluation, isNull, reason: 'the write is settled');
    expect(bloc.scheduleChangesBlocked, isFalse);

    api.heldRead!.complete();
    await flush();
    client.close();
    await bloc.close();
  });

  test('the card leaves in the same update that brings the refreshed schedule',
      () async {
    final bloc = await make();
    final states = <ScheduleState>[];
    final sub = bloc.stream.listen(states.add);
    final client = await confirmedComplete(bloc);

    api.status = _changed;
    api.tiles = [SubCalendarEvent(id: 't2', name: 'Lunch')];
    api.heldRead!.complete();
    await flush();
    await flush();

    final refreshed = states.firstWhere(
        (s) => revisionOf(s) == const ScheduleRevision('new', 'new'));
    expect(refreshed, isNot(isA<ScheduleEvaluationState>()),
        reason: 'no frame shows the new schedule under an updating card');
    expect(bloc.state, isNot(isA<ScheduleEvaluationState>()));
    await sub.cancel();
    client.close();
    await bloc.close();
  });

  test('a new change can start while updating, and takes the card', () async {
    final bloc = await make();
    final client = await confirmedComplete(bloc);
    final next = Completer<void>();
    final pending = bloc.runScheduleChange(() => next.future,
        kind: ScheduleChangeKind.delete, eventName: 'Lunch');
    await flush();
    final card = (bloc.state as ScheduleEvaluationState).evaluation!;
    expect(card.kind, ScheduleChangeKind.delete);
    expect(card.phase, ScheduleEvaluationPhase.pending);
    next.complete();
    await pending;
    api.heldRead!.complete();
    await flush();
    client.close();
    await bloc.close();
  });

  test('a failed refresh read still ends the updating card', () async {
    final bloc = await make();
    final client = await confirmedComplete(bloc);
    api.readError = StateError('server down');
    api.heldRead!.complete();
    await flush();
    await flush();
    expect(bloc.state, isNot(isA<ScheduleEvaluationState>()));
    client.close();
    await bloc.close();
  });

  test(
      'a newer read takes over the update without the card blinking out, '
      'and no timer is kept', () async {
    final bloc = await make();
    final client = await confirmedComplete(bloc);
    // Another read starts (a view change, a pull to refresh) and replaces
    // the first.
    bloc.add(GetScheduleEvent(forceRefresh: true, emitOnlyLoadedStated: true));
    await flush();
    expect((bloc.state as ScheduleEvaluationState).evaluation!.phase,
        ScheduleEvaluationPhase.refreshing);

    api.status = _changed;
    api.heldRead!.complete();
    await flush();
    await flush();
    expect(bloc.state, isNot(isA<ScheduleEvaluationState>()));
    expect(revisionOf(bloc.state), const ScheduleRevision('new', 'new'));
    client.close();
    await bloc.close();
  });

  test('the timing shows when the card left', () async {
    final reports = <Map<String, Object?>>[];
    final bloc = await make(
        timings: ScheduleChangeTimings(
            onNextFrame: (frame) => scheduleMicrotask(frame),
            report: reports.add));
    final client = await confirmedComplete(bloc);
    api.status = _changed;
    api.heldRead!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final marks = reports.single['marks'] as Map;
    expect(marks['cardCleared'], isNotNull);
    expect(marks['cardCleared'], greaterThanOrEqualTo(marks['settled'] as int));
    expect(marks['cardCleared'], lessThanOrEqualTo(marks['applied'] as int));
    client.close();
    await bloc.close();
  });

  testWidgets('the updating card names the change and shows progress',
      (tester) async {
    final now = DateTime.now();
    final refreshing = ScheduleEvaluation(
        id: 'r1',
        kind: ScheduleChangeKind.complete,
        account: 'user',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 3)),
        baseline: const ScheduleRevision('a', 'e'),
        baselineObservedAt: now,
        eventName: 'Gym',
        affectedEventCount: 1,
        phase: ScheduleEvaluationPhase.refreshing);
    final bloc = ScheduleBloc(getContextCallBack: () => null);
    await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
        value: bloc,
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                body: ScheduleEvaluationFeedback(
                    state: ScheduleEvaluationState(
                        subEvents: const [],
                        timelines: const [],
                        lookupTimeline: Utility.todayTimeline(),
                        evaluationTime: now,
                        currentView: AuthorizedRouteTileListPage.Daily,
                        scheduleStatus: ScheduleStatus(),
                        evaluation: refreshing))))));
    expect(find.text(l10n.scheduleChangeRefreshing), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.scheduleChangeFailed), findsNothing);
    expect(find.text(l10n.scheduleChangeRefresh), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });

  group('the switch from processing to updating is visible', () {
    ScheduleEvaluation completeGym(ScheduleEvaluationPhase phase) {
      final now = DateTime(2026, 10, 13, 9);
      return ScheduleEvaluation(
          id: 'r1',
          kind: ScheduleChangeKind.complete,
          account: 'user',
          startedAt: now,
          expiresAt: now.add(const Duration(minutes: 3)),
          baseline: const ScheduleRevision('a', 'e'),
          baselineObservedAt: now,
          eventName: 'Gym',
          affectedEventCount: 1,
          phase: phase);
    }

    Widget card(ScheduleEvaluation evaluation, {ThemeData? theme}) =>
        MaterialApp(
            theme: theme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                body: ScheduleEvaluationFeedback(
                    state: ScheduleEvaluationState(
                        subEvents: const [],
                        timelines: const [],
                        lookupTimeline: Utility.todayTimeline(),
                        evaluationTime: evaluation.startedAt,
                        currentView: AuthorizedRouteTileListPage.Daily,
                        scheduleStatus: ScheduleStatus(),
                        evaluation: evaluation))));

    final glyph = find.byKey(const ValueKey('scheduleEvaluationActionIcon'));
    final badge = find.byKey(const ValueKey('scheduleEvaluationBadge'));
    Color badgeColor(WidgetTester tester) =>
        ((tester.widget<Container>(badge).decoration as BoxDecoration).color)!;

    for (final brightness in Brightness.values) {
      testWidgets(
          'processing shows the action on the brand colour; updating shows '
          'a sync glyph in the accent (${brightness.name})', (tester) async {
        final bloc = ScheduleBloc(getContextCallBack: () => null);
        final theme = ThemeData(brightness: brightness, useMaterial3: true);
        final scheme = theme.colorScheme;

        await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
            value: bloc,
            child: card(completeGym(ScheduleEvaluationPhase.pending),
                theme: theme)));
        expect(tester.widget<Icon>(glyph).icon, Icons.check_circle_outline);
        expect(badgeColor(tester), scheme.primaryContainer);

        await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
            value: bloc,
            child: card(completeGym(ScheduleEvaluationPhase.refreshing),
                theme: theme)));
        // One frame starts the 400 ms switch; the outgoing badge leaves a
        // frame after it ends.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump();
        final accent = ChangeFlash.moved.color(scheme);
        expect(tester.widget<Icon>(glyph).icon, Icons.sync);
        expect(tester.widget<Icon>(glyph).color, accent);
        expect(badgeColor(tester), accent.withValues(alpha: 0.16));
        final spinner = tester.widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator));
        expect(spinner.color, accent);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(bloc.close);
      });
    }

    testWidgets('the glyph cross-fades rather than swapping in place',
        (tester) async {
      final bloc = ScheduleBloc(getContextCallBack: () => null);
      await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
          value: bloc,
          child: card(completeGym(ScheduleEvaluationPhase.pending))));
      await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
          value: bloc,
          child: card(completeGym(ScheduleEvaluationPhase.refreshing))));
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-way, the outgoing and incoming glyphs are both on screen.
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(bloc.close);
    });
  });

  test('the card speaks of the timeline, in each language\'s own term', () {
    expect(lookupAppLocalizations(const Locale('en')).scheduleChangeRefreshing,
        'Updating your timeline…');
    const term = {
      'de': 'Zeitleiste',
      'el': 'χρονολ',
      'es': 'línea de tiempo',
      'fr': 'chronologie',
      'it': 'linea temporale',
      'ja': 'タイムライン',
      'nl': 'ijdlijn',
      'pt': 'linha temporal',
    };
    for (final entry in term.entries) {
      expect(lookupAppLocalizations(Locale(entry.key)).scheduleChangeRefreshing,
          contains(entry.value),
          reason: entry.key);
    }
  });

  testWidgets(
      'midway through the switch everything is easing, nothing has snapped',
      (tester) async {
    final bloc = ScheduleBloc(getContextCallBack: () => null);
    final theme = ThemeData(useMaterial3: true);
    final scheme = theme.colorScheme;
    final accent = ChangeFlash.moved.color(scheme);
    final now = DateTime(2026, 10, 13, 9);
    ScheduleEvaluation gym(ScheduleEvaluationPhase phase) => ScheduleEvaluation(
        id: 'r1',
        kind: ScheduleChangeKind.complete,
        account: 'user',
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 3)),
        baseline: const ScheduleRevision('a', 'e'),
        baselineObservedAt: now,
        eventName: 'Gym',
        affectedEventCount: 1,
        phase: phase);
    Widget card(ScheduleEvaluationPhase phase) =>
        BlocProvider<ScheduleBloc>.value(
            value: bloc,
            child: MaterialApp(
                theme: theme,
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                    body: ScheduleEvaluationFeedback(
                        state: ScheduleEvaluationState(
                            subEvents: const [],
                            timelines: const [],
                            lookupTimeline: Utility.todayTimeline(),
                            evaluationTime: now,
                            currentView: AuthorizedRouteTileListPage.Daily,
                            scheduleStatus: ScheduleStatus(),
                            evaluation: gym(phase))))));

    await tester.pumpWidget(card(ScheduleEvaluationPhase.pending));
    await tester.pumpWidget(card(ScheduleEvaluationPhase.refreshing));
    await tester.pump(); // starts the 400 ms switch
    await tester.pump(const Duration(milliseconds: 200));

    // The sync glyph grows and turns into place.
    final incoming = find.byIcon(Icons.sync);
    final scale = tester
        .widget<ScaleTransition>(find
            .ancestor(of: incoming, matching: find.byType(ScaleTransition))
            .first)
        .scale
        .value;
    expect(scale, inExclusiveRange(0.0, 1.0));
    final turns = tester
        .widget<RotationTransition>(find
            .ancestor(of: incoming, matching: find.byType(RotationTransition))
            .first)
        .turns
        .value;
    expect(turns, isNot(0.0));
    // The title cross-fades: both are on screen.
    expect(find.text(l10n.completing), findsOneWidget);
    expect(find.text(l10n.scheduleChangeRefreshing), findsOneWidget);
    // The spinner's colour is between the two.
    final midway = tester
        .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator))
        .color;
    expect(midway, isNot(scheme.primary));
    expect(midway, isNot(accent));

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.completing), findsNothing);
    expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .color,
        accent);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });
}
