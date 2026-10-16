import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/tileProcrastinate.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';

import 'schedule_changes_blocked_message_test.dart' show evaluation;
import 'procrastinate_duration_test.dart' show FakeSubCalendarEventApi;
import 'schedule_evaluation_flow_test.dart' show ControlledClient, response;
import 'package:tiler_app/services/api/retryHttpClient.dart';

class _BusyBloc extends ScheduleBloc {
  _BusyBloc() : super(getContextCallBack: () => null);
  bool busy = true;
  @override
  bool get scheduleChangesBlocked => busy;
  @override
  ScheduleEvaluation? get activeEvaluation =>
      busy ? evaluation(ScheduleChangeKind.complete, name: 'Gym') : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _BusyBloc bloc;
  late ScheduleNoticeBus bus;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bloc = _BusyBloc();
    bus = ScheduleNoticeBus();
  });
  tearDown(() async {
    bus.dispose();
    await bloc.close();
  });

  Future<void> mount(WidgetTester tester, Widget child) =>
      tester.pumpWidget(RepositoryProvider<ScheduleNoticeBus>.value(
          value: bus,
          child: BlocProvider<ScheduleBloc>.value(
              value: bloc,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: child,
              ))));

  void expectNotice() =>
      expect(bus.interruption!.message, contains('Completing · Gym'));

  testWidgets('blocked tile defer keeps the picker and sends nothing',
      (tester) async {
    final api = FakeSubCalendarEventApi();
    await mount(tester,
        TileProcrastinateRoute(tileId: 'tile', subCalendarEventApi: api));
    await tester.tap(find.byKey(const ValueKey('durationPreset_0')));
    await tester.pump();
    expectNotice();
    expect(api.calls, isEmpty);
    expect(find.byType(AddTileDurationScreen), findsOneWidget);
    await tester.pump(bus.interruptionFor);
  });

  testWidgets('blocked notification complete publishes the running change',
      (tester) async {
    late BuildContext context;
    await mount(tester, Scaffold(body: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final service = LocalNotificationService();
    await service.completeTile(context, SubCalendarEvent(id: 'tile'));
    await tester.pump();
    expectNotice();
    expect(bloc.state, isA<ScheduleInitialState>());
    service.userApi.dispose();
    await tester.pump(bus.interruptionFor);
  });

  testWidgets(
      'blocked integration connect throws and shows the notice without HTTP',
      (tester) async {
    late BuildContext context;
    await mount(tester, Scaffold(body: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    final wire = ControlledClient((_) async => response());
    final api = IntegrationApi(getContextCallBack: () => context);
    api.httpClient.close();
    api.httpClient = RetryHttpClient(innerClient: wire);
    addTearDown(api.dispose);
    await expectLater(api.startCalendarConnect(provider: 'google'),
        throwsA(isA<ScheduleChangeBlocked>()));
    await tester.pump();
    expectNotice();
    expect(wire.requests, isEmpty);
    await tester.pump(bus.interruptionFor);
  });

  for (final remainsRelevant in [true, false]) {
    testWidgets(
        'background blocked notice waits for resume; relevant=$remainsRelevant',
        (tester) async {
      late BuildContext context;
      await mount(tester, Scaffold(body: Builder(builder: (value) {
        context = value;
        return const SizedBox();
      })));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(scheduleChangesAllowed(context), isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(bus.interruption, isNull);
      if (!remainsRelevant) bloc.busy = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      if (remainsRelevant) {
        expectNotice();
      } else {
        expect(bus.interruption, isNull);
      }
      await tester.pump(bus.interruptionFor);
    });
  }
}
