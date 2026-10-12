import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/operationFeedback.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

import 'editTile/edit_tile_shell_test.dart' as editor;
import 'schedule_changes_blocked_message_test.dart' show evaluation;

class _Schedule extends ScheduleBloc {
  _Schedule() : super(getContextCallBack: () => null);
  ScheduleEvaluation? current;
  bool unconfirmed = false;

  @override
  ScheduleEvaluation? get activeEvaluation => current;
  @override
  bool get scheduleChangesBlocked => current?.blocksChanges ?? false;
  @override
  bool get lastChangeUnconfirmed => unconfirmed;

  void show(ScheduleEvaluation value) {
    current = value;
    emit(ScheduleEvaluationState(
        subEvents: [],
        timelines: [],
        lookupTimeline: Utility.todayTimeline(),
        evaluationTime: value.startedAt,
        currentView: AuthorizedRouteTileListPage.Daily,
        scheduleStatus: ScheduleStatus(),
        evaluation: value));
  }

  void settle() {
    current = null;
    emit(ScheduleInitialState(currentView: AuthorizedRouteTileListPage.Daily));
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  late _Schedule bloc;
  late ScheduleNoticeBus bus;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bloc = _Schedule();
    bus = ScheduleNoticeBus();
  });
  tearDown(() async {
    bus.dispose();
    await bloc.close();
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepositoryProvider.value(
        value: bus,
        child: BlocProvider<ScheduleBloc>.value(
            value: bloc,
            child: MaterialApp(
                locale: const Locale('en'),
                theme: TileThemeData.lightTheme,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: child))));
    await tester.pump();
  }

  for (final action in ['complete', 'startNow', 'defer', 'delete']) {
    testWidgets('editor $action names the running change without submitting',
        (tester) async {
      bloc.show(evaluation(ScheduleChangeKind.complete, name: 'Gym'));
      final submission = editor.FakeSubmission();
      await mount(
          tester,
          EditTileRedesignScreen(
              tileId: 'sub-1',
              loader: editor.FakeLoader(
                  EditTileLoadResult.success(editor.loaded(), [])),
              submission: submission));
      expect(find.text('Gym'), findsOneWidget,
          reason: 'progress stays visible above the editor');
      final button = find.byKey(ValueKey('editAction_$action'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(bus.interruption?.message, contains('Completing · Gym'));
      expect(submission.actions, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(l10n.editTileActionFailed), findsNothing);
      await tester.pump(bus.interruptionFor);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final phase in ScheduleEvaluationPhase.values) {
    testWidgets('failure feedback distinguishes $phase and controls Retry',
        (tester) async {
      bloc.current =
          evaluation(ScheduleChangeKind.complete, name: 'Gym').withPhase(phase);
      await mount(
          tester,
          Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showScheduleChangeFailure(context,
                          kind: ScheduleChangeKind.delete,
                          eventName: 'Lunch',
                          onRetry: () {}),
                      child: const Text('Report')))));
      await tester.tap(find.text('Report'));
      await tester.pump();
      final message = tester
          .widget<Text>(find
              .descendant(
                  of: find.byType(SnackBar), matching: find.byType(Text))
              .first)
          .data!;
      if (phase == ScheduleEvaluationPhase.pending) {
        expect(message, contains('Completing · Gym'));
        expect(message, isNot(contains('failed')));
        expect(find.text(l10n.addTileRetry), findsNothing);
      } else if (phase == ScheduleEvaluationPhase.uncertain) {
        expect(message, contains(l10n.scheduleChangeUncertainBody));
        expect(message, contains('Completing · Gym'));
        expect(message, isNot(contains('failed')));
        expect(find.text(l10n.addTileRetry), findsNothing);
      } else {
        expect(message, l10n.operationFailed('${l10n.delete} · Lunch'));
        expect(find.text(l10n.addTileRetry), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('an action rechecks admission after its confirmation dialog',
      (tester) async {
    final submission = editor.FakeSubmission();
    await mount(
        tester,
        EditTileRedesignScreen(
            tileId: 'sub-1',
            loader: editor.FakeLoader(
                EditTileLoadResult.success(editor.loaded(), [])),
            submission: submission));
    final button = find.byKey(const ValueKey('editAction_complete'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    bloc.show(evaluation(ScheduleChangeKind.complete, name: 'Gym'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('editActionConfirm')));
    await tester.pump();
    expect(submission.actions, isEmpty);
    expect(bus.interruption?.message, contains('Completing · Gym'));
    await tester.pump(bus.interruptionFor);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('editor draft survives pending, uncertain, and settled feedback',
      (tester) async {
    await mount(
        tester,
        EditTileRedesignScreen(
            tileId: 'sub-1',
            loader: editor.FakeLoader(
                EditTileLoadResult.success(editor.loaded(), [])),
            submission: editor.FakeSubmission()));
    final field = find.byKey(const ValueKey('editTitleField'));
    await tester.enterText(field, 'Keep this draft');
    final draft = tester
        .state<EditTileRedesignScreenState>(find.byType(EditTileRedesignScreen))
        .draft;
    bloc.show(evaluation(ScheduleChangeKind.complete, name: 'Gym'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    bloc.show(bloc.current!.withPhase(ScheduleEvaluationPhase.uncertain));
    await tester.pump();
    expect(find.text(l10n.scheduleChangeRefresh), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    bloc.settle();
    await tester.pump();
    expect(find.byType(ScheduleEvaluationFeedback), findsNothing);
    expect(
        tester
            .state<EditTileRedesignScreenState>(
                find.byType(EditTileRedesignScreen))
            .draft,
        same(draft));
    expect(draft!.name, 'Keep this draft');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an expired unconfirmed change does not offer replay',
      (tester) async {
    bloc.unconfirmed = true;
    await mount(
        tester,
        Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showScheduleChangeFailure(context,
                        kind: ScheduleChangeKind.add, onRetry: () {}),
                    child: const Text('Report')))));
    await tester.tap(find.text('Report'));
    await tester.pump();
    expect(find.text(l10n.scheduleChangeHoldEnded), findsOneWidget);
    expect(find.text(l10n.addTileRetry), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('operation feedback replaces generic errors, keeps useful explanations',
      () {
    for (final error in [
      Exception('private request details'),
      TilerError(Message: l10n.errorOccurred),
      TilerError(Message: l10n.responseHandlingError),
      TilerError(Message: l10n.failedToSendRequest),
    ]) {
      expect(
          operationFailureMessage(l10n,
              fallback: l10n.chatSendFailed, error: error),
          l10n.chatSendFailed);
    }
    expect(
        operationFailureMessage(l10n,
            fallback: l10n.operationFailed(l10n.accountInfo),
            error: TilerError(Message: 'An email address is required.')),
        contains('An email address is required.'));
  });
}
