import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_recovery_monitor.dart';
import 'package:tiler_app/components/scheduleReadFeedback.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tuple/tuple.dart';

typedef ReadData
    = Tuple3<List<Timeline>, List<SubCalendarEvent>, ScheduleStatus>;

class PendingRead {
  PendingRead(this.timeline);
  final Timeline timeline;
  final result = Completer<ReadData>();
  void succeed([List<SubCalendarEvent> tiles = const []]) =>
      result.complete(Tuple3([], tiles,
          ScheduleStatus.fromJson({'analysisId': 'a', 'evaluationId': 'e'})));
  void fail([Object? error]) =>
      result.completeError(error ?? StateError('offline'));
}

class ReadApi extends ScheduleApi {
  ReadApi() : super(getContextCallBack: () => null);
  final pending = <PendingRead>[];
  @override
  Future<ReadData> getSubEvents(Timeline range) {
    final read = PendingRead(range);
    pending.add(read);
    return read.result.future;
  }

  @override
  Future<ScheduleStatus> getScheduleStatus() async =>
      ScheduleStatus.fromJson({'analysisId': 'a', 'evaluationId': 'e'});
}

Future<void> flush() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final monday = DateTime(2026, 10, 26);
  final tuesday = DateTime(2026, 10, 27);
  final first = Timeline.fromDateTime(monday, tuesday);
  final second = Timeline.fromDateTime(tuesday, DateTime(2026, 10, 28));
  late ScheduleBloc bloc;
  late ReadApi api;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = ReadApi();
    bloc = ScheduleBloc(getContextCallBack: () => null)..scheduleApi = api;
  });
  tearDown(() async => bloc.close());

  test('cold failure has no successful coverage and is scoped to its day',
      () async {
    final done = bloc.refreshSchedule(timeline: first);
    await flush();
    expect(bloc.reads.state.loadingFor(monday), isTrue);
    api.pending.single.fail();
    expect(await done, ScheduleReadOutcome.failed);
    expect(bloc.reads.state.hasDataFor(monday), isFalse);
    expect(bloc.reads.state.failureFor(monday), isNotNull);
    expect(bloc.reads.state.failureFor(tuesday), isNull);
  });

  test('verified empty data survives failed refresh and local state changes',
      () async {
    final loaded = bloc.refreshSchedule(timeline: first);
    await flush();
    api.pending.last.succeed();
    await loaded;
    final failed = bloc.refreshSchedule(timeline: first);
    await flush();
    api.pending.last.fail();
    await failed;
    final error = bloc.reads.state.failureFor(monday);
    expect(bloc.reads.state.hasDataFor(monday), isTrue);
    expect((bloc.state as ScheduleLoadedState).subEvents, isEmpty);
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: [],
        timelines: [],
        lookupTimeline: first,
        scheduleStatus: ScheduleStatus()));
    await flush();
    expect(bloc.reads.state.failureFor(monday), error);
    final retried = bloc.retryRead(error!);
    await flush();
    expect(api.pending.last.timeline.isEquivalent(first), isTrue);
    expect(bloc.reads.state.failureFor(monday), error);
    api.pending.last.succeed();
    await retried;
    expect(bloc.reads.state.failureFor(monday), isNull);
  });

  test('equivalent retries share a request and await its outcome', () async {
    final one = bloc.refreshSchedule(timeline: first);
    final two = bloc.refreshSchedule(timeline: first);
    var completed = false;
    unawaited(two.then((_) => completed = true));
    await flush();
    expect(api.pending, hasLength(1));
    expect(completed, isFalse);
    api.pending.single.fail();
    expect(await one, ScheduleReadOutcome.failed);
    expect(await two, ScheduleReadOutcome.failed);
  });

  test('a visible-day refresh does not target an unrelated failed edge',
      () async {
    final loaded = bloc.refreshSchedule(timeline: first);
    await flush();
    api.pending.last.succeed();
    await loaded;
    final edge = bloc.refreshSchedule(timeline: second, eventId: 'future-edge');
    await flush();
    api.pending.last.fail();
    await edge;
    expect(bloc.readTimelineFor(monday).isEquivalent(first), isTrue);
    expect(bloc.readTimelineFor(tuesday).isEquivalent(second), isTrue);
    final retry = bloc.retryRead(bloc.reads.state.failureFor(tuesday)!);
    await flush();
    expect(api.pending.last.timeline.isEquivalent(second), isTrue);
    api.pending.last.succeed();
    await retry;
  });

  test('automatic callbacks cannot supersede a manual request', () async {
    final manual = bloc.refreshSchedule(timeline: second);
    await flush();
    final automatic = bloc.refreshSchedule(timeline: first, automatic: true);
    await flush();
    expect(api.pending, hasLength(1));
    expect(bloc.reads.state.requested!.isEquivalent(second), isTrue);
    api.pending.single.succeed();
    expect(await manual, ScheduleReadOutcome.succeeded);
    expect(await automatic, ScheduleReadOutcome.succeeded);
  });

  test('navigation supersedes immediately and ignores late older data',
      () async {
    final old = bloc.refreshSchedule(timeline: first);
    await flush();
    final latest = bloc.refreshSchedule(timeline: second);
    expect(await old, ScheduleReadOutcome.superseded);
    await flush();
    api.pending.last.succeed([SubCalendarEvent(id: 'new')]);
    await latest;
    api.pending.first.succeed([SubCalendarEvent(id: 'old')]);
    await flush();
    expect((bloc.state as ScheduleLoadedState).subEvents.single.id, 'new');
    expect(bloc.reads.state.hasDataFor(tuesday), isTrue);
    expect(bloc.reads.state.hasDataFor(monday), isFalse);
  });

  test('old failures stay scoped when navigating to a successful day',
      () async {
    final failed = bloc.refreshSchedule(timeline: first);
    await flush();
    api.pending.last.fail();
    await failed;
    final loaded = bloc.refreshSchedule(timeline: second);
    await flush();
    api.pending.last.succeed();
    await loaded;
    expect(bloc.reads.state.failureFor(monday), isNotNull);
    expect(bloc.reads.state.failureFor(tuesday), isNull);
    bloc.recoverScheduleReads();
    await flush();
    expect(api.pending.last.timeline.isEquivalent(second), isTrue);
    api.pending.last.succeed();
    await flush();
  });

  test('logout clears coverage and releases awaiters before old HTTP finishes',
      () async {
    final pending = bloc.refreshSchedule(timeline: first);
    await flush();
    bloc.add(LogOutScheduleEvent(() => null));
    expect(await pending, ScheduleReadOutcome.skipped);
    api.pending.single.succeed();
    await flush();
    expect(bloc.state, isA<ScheduleLoggedOutState>());
    expect(bloc.reads.state.coverage, isNull);
    expect(bloc.reads.state.failures, isEmpty);
  });

  test('deadline releases loading and late success cannot remove failure',
      () async {
    await bloc.close();
    bloc = ScheduleBloc(
        getContextCallBack: () => null,
        readTimeout: const Duration(milliseconds: 30))
      ..scheduleApi = api;
    final pending = bloc.refreshSchedule(timeline: first);
    await flush();
    expect(await pending, ScheduleReadOutcome.failed);
    expect(bloc.reads.state.failureFor(monday)!.error, isA<TimeoutException>());
    api.pending.single.succeed();
    await flush();
    expect(bloc.reads.state.hasDataFor(monday), isFalse);
    expect(bloc.reads.state.failureFor(monday), isNotNull);
  });

  test('authentication failure cannot become empty data or an automatic loop',
      () async {
    final pending = bloc.refreshSchedule(timeline: first);
    await flush();
    api.pending.single.fail(ScheduleAuthenticationRequired());
    await pending;
    bloc.recoverScheduleReads();
    await flush();
    expect(api.pending, hasLength(1));
    expect(bloc.reads.state.coverage, isNull);
  });

  test('resume and reconnect recover together, and pause suppresses retries',
      () async {
    await bloc.close();
    final changes = StreamController<List<ConnectivityResult>>();
    var connected = <ConnectivityResult>[ConnectivityResult.none];
    var now = DateTime(2026, 10, 27, 9);
    late ScheduleRecoveryMonitor monitor;
    bloc = ScheduleBloc(
        getContextCallBack: () => null,
        now: () => now,
        recoveryMonitorFactory: (recover, suspend) =>
            monitor = ScheduleRecoveryMonitor(
              onRecover: recover,
              onSuspend: suspend,
              connectivityChanges: changes.stream,
              checkConnectivity: () async => connected,
            ))
      ..scheduleApi = api;
    final initial = bloc.refreshSchedule(timeline: first);
    await flush();
    api.pending.last.fail();
    await initial;
    bloc.startRecoveryMonitoring();
    await flush();
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    connected = [ConnectivityResult.wifi];
    changes.add(connected);
    await flush();
    expect(api.pending, hasLength(1));
    now = now.add(const Duration(seconds: 3));
    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    changes.add(connected);
    await flush();
    expect(api.pending, hasLength(2));
    expect(api.pending.last.timeline.isEquivalent(first), isTrue);
    api.pending.last.succeed();
    await flush();
    expect(bloc.reads.state.failureFor(monday), isNull);
    expect(bloc.reads.state.hasDataFor(monday), isTrue);
    await bloc.close();
    await changes.close();
  });

  Widget host(DateTime day, Widget child) => BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ScheduleReadFeedback(date: day, child: child)),
      ));

  testWidgets('cold failure hides empty content; retry remains until result',
      (tester) async {
    await tester.pumpWidget(host(monday, const Text('No plans yet.')));
    await tester.runAsync(() async {
      final pending = bloc.refreshSchedule(timeline: first);
      await flush();
      api.pending.single.fail();
      await pending;
    });
    await tester.pump();
    expect(find.byKey(ScheduleReadFailureView.panelKey), findsOneWidget);
    expect(find.text('No plans yet.'), findsNothing);
    await tester.tap(find.byKey(ScheduleReadFailureView.retryKey));
    await tester.runAsync(flush);
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(ScheduleReadFailureView.retryKey))
            .onPressed,
        isNull);
    await tester.runAsync(() async {
      api.pending.last.succeed();
      await flush();
    });
    await tester.pump();
    expect(find.byKey(ScheduleReadFailureView.panelKey), findsNothing);
    expect(find.text('No plans yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('retained list stays mounted and keeps its scroll position',
      (tester) async {
    await tester.runAsync(() async {
      final loaded = bloc.refreshSchedule(timeline: first);
      await flush();
      api.pending.last.succeed();
      await loaded;
    });
    final scroll = ScrollController(initialScrollOffset: 180);
    await tester.pumpWidget(host(
        monday,
        ListView.builder(
          controller: scroll,
          itemExtent: 50,
          itemCount: 80,
          itemBuilder: (_, i) => Text('Event $i'),
        )));
    await tester.runAsync(() async {
      final failed = bloc.refreshSchedule(timeline: first);
      await flush();
      api.pending.last.fail();
      await failed;
    });
    await tester.pump();
    expect(find.byKey(ScheduleReadFailureView.bannerKey), findsOneWidget);
    expect(scroll.offset, 180);
    expect(find.byKey(ScheduleReadFailureView.panelKey), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });

  testWidgets('error panel supports large text in a short viewport',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bloc.reads.begin(first, 1);
    bloc.reads.fail(ScheduleReadFailure(first, 1, StateError('offline')));
    await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
              child: Scaffold(
                  body: ScheduleReadFeedback(
                      date: monday, child: const Text('No plans yet.')))),
        )));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(ScheduleReadFailureView.panelKey), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('refresh warning keeps content usable at large text sizes',
      (tester) async {
    tester.view.physicalSize = const Size(320, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bloc.reads.succeed(first, DateTime.now(), 1);
    bloc.reads.fail(ScheduleReadFailure(first, 2, StateError('offline')));
    await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
              child: Scaffold(
                  body: ScheduleReadFeedback(
                      date: monday,
                      child:
                          ListView(children: const [Text('Existing event')])))),
        )));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Existing event'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
