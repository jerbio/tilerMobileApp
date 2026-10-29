// Each schedule change is named for what it is. Shuffle tries a new
// arrangement (not "Optimizing schedule" / "Re-optimize"). The timeline
// built after onboarding is its own kind (not a revise the user never
// asked for). A buzz that follows something else is named for that.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

import 'schedule_evaluation_flow_test.dart' show FakeScheduleApi, flush;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('Shuffle says it is trying a new arrangement, and is called Shuffle',
      () {
    expect(scheduleChangeActionTitle(l10n, ScheduleChangeKind.shuffle),
        'Trying a new arrangement…');
    expect(scheduleChangeCommand(l10n, ScheduleChangeKind.shuffle), 'Shuffle');
  });

  test('the first timeline after onboarding has its own words', () {
    expect(scheduleChangeActionTitle(l10n, ScheduleChangeKind.setup),
        'Building your initial timeline…');
    expect(scheduleChangeCommand(l10n, ScheduleChangeKind.setup),
        'Initial timeline');
    expect(scheduleChangeActionTitle(l10n, ScheduleChangeKind.setup),
        isNot(l10n.revisingSchedule));
  });

  testWidgets('the setup card has its own glyph, not the revise one',
      (tester) async {
    final now = DateTime(2026, 10, 28, 9);
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
                        evaluation: ScheduleEvaluation(
                            id: 'setup',
                            kind: ScheduleChangeKind.setup,
                            account: 'user',
                            startedAt: now,
                            expiresAt: now.add(const Duration(minutes: 3)),
                            baseline: const ScheduleRevision('a', 'e'),
                            baselineObservedAt: now)))))));
    expect(find.text('Building your initial timeline…'), findsOneWidget);
    final glyph = tester
        .widget<Icon>(
            find.byKey(const ValueKey('scheduleEvaluationActionIcon')))
        .icon;
    expect(glyph, isNot(Icons.autorenew));
    expect(glyph, isNot(Icons.shuffle));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });

  group('buzzSchedule', () {
    late ScheduleBloc bloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final api = FakeScheduleApi();
      bloc = ScheduleBloc(getContextCallBack: () => null)..scheduleApi = api;
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: const [],
          timelines: const [],
          lookupTimeline: api.window,
          scheduleStatus: api.status));
      await flush();
    });
    tearDown(() => bloc.close());

    Future<ScheduleChangeKind?> admittedKindOf(
        Future Function(ScheduleApi api) buzz) async {
      final api = ScheduleApi(getContextCallBack: () => bloc);
      // No sign-in in tests, so the request itself fails after admission;
      // the admitted change is what matters here.
      await buzz(api).then((_) {}, onError: (Object _) {});
      await flush();
      api.dispose();
      return bloc.activeEvaluation?.kind;
    }

    test('is admitted as the kind its caller names', () async {
      expect(
          await admittedKindOf(
              (api) => api.buzzSchedule(kind: ScheduleChangeKind.setup)),
          ScheduleChangeKind.setup);
    });

    test('without a kind it is still a revise', () async {
      expect(await admittedKindOf((api) => api.buzzSchedule()),
          ScheduleChangeKind.revise);
    });
  });
}
