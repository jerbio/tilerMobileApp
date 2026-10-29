// Starting a schedule change while another is in progress explains which
// change is still running.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class _BusyScheduleBloc extends ScheduleBloc {
  _BusyScheduleBloc(this.busyWith) : super(getContextCallBack: () => null);
  final ScheduleEvaluation? busyWith;

  @override
  bool get scheduleChangesBlocked => true;

  @override
  ScheduleEvaluation? get activeEvaluation => busyWith;
}

ScheduleEvaluation evaluation(ScheduleChangeKind kind,
    {String? name, int count = 0}) {
  final now = DateTime(2026, 10, 11, 9);
  return ScheduleEvaluation(
      id: 'busy',
      kind: kind,
      account: 'user',
      startedAt: now,
      expiresAt: now.add(const Duration(minutes: 3)),
      baseline: const ScheduleRevision('a', 'e'),
      baselineObservedAt: now,
      eventName: name,
      affectedEventCount: count,
      phase: ScheduleEvaluationPhase.pending);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('the label names the action and what it acts on', () {
    expect(
        scheduleChangeLabel(
            l10n, evaluation(ScheduleChangeKind.complete, name: 'Gym')),
        'Completing · Gym');
    expect(scheduleChangeLabel(l10n, evaluation(ScheduleChangeKind.shuffle)),
        '${l10n.scheduleChangeShuffling} · ${l10n.scheduleChangeTargetSchedule}');
    expect(
        scheduleChangeLabel(
            l10n, evaluation(ScheduleChangeKind.defer, count: 4)),
        '${l10n.procrastinating} · 4 events');
  });

  Future<String> blockedMessage(
      WidgetTester tester, ScheduleEvaluation? busyWith) async {
    SharedPreferences.setMockInitialValues({});
    final bloc = _BusyScheduleBloc(busyWith);
    late bool allowed;
    await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
        value: bloc,
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Builder(builder: (context) {
              return TextButton(
                  onPressed: () => allowed = scheduleChangesAllowed(context),
                  child: const Text('go'));
            })))));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(allowed, isFalse);
    final text = tester
        .widget<Text>(find.descendant(
            of: find.byType(SnackBar), matching: find.byType(Text)))
        .data!;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
    return text;
  }

  testWidgets('a blocked change says which change is still running',
      (tester) async {
    expect(
        await blockedMessage(
            tester, evaluation(ScheduleChangeKind.complete, name: 'Gym')),
        'Finish the current schedule change (Completing · Gym) '
        'before starting another.');
  });

  testWidgets('with nothing known about it, the plain message shows',
      (tester) async {
    expect(await blockedMessage(tester, null), l10n.scheduleChangesBlocked);
  });
}
