import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/ActionsList.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewSummary.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/chatApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

class _FakeChatApi extends ChatApi {
  _FakeChatApi(this.state);
  final PreviewState state;

  @override
  Future<List<VibeRequestPreview>> getVibeRequestPreviews(String id) async =>
      [VibeRequestPreview(id: 'preview_1', vibeRequestId: id, state: state)];

  @override
  Future<VibePreviewSummary?> getVibePreviewSummary(String previewId) async =>
      VibePreviewSummary(previewId: previewId, subCalendarEvents: const []);
}

/// Bloc that records dispatched events so tap behaviour can be asserted without
/// depending on asynchronous stream emissions.
class _RecordingBloc extends VibeChatBloc {
  _RecordingBloc()
      : super(
          scheduleBloc: ScheduleBloc(getContextCallBack: () => null),
          scheduleSummaryBloc:
              ScheduleSummaryBloc(getContextCallBack: () => null),
          getContextCallBack: () => null,
        );

  final List<VibeChatEvent> recorded = [];

  @override
  void add(VibeChatEvent event) {
    recorded.add(event);
    super.add(event);
  }
}

VibeAction _clickableAction() => VibeAction(
      id: 'action_1',
      descriptions: 'Add gym task',
      type: ActionType.addNewTask,
      status: ActionStatus.pending,
      entityId: 'entity_1',
    );

VibeChatBloc _makeBloc() {
  final bloc = VibeChatBloc(
    scheduleBloc: ScheduleBloc(getContextCallBack: () => null),
    scheduleSummaryBloc: ScheduleSummaryBloc(getContextCallBack: () => null),
    getContextCallBack: () => null,
  );
  bloc.chatApi = _FakeChatApi(PreviewState.ready);
  bloc.tileCastReadinessDelayOverride = (_) async {};
  bloc.tileCastReadinessMaxAttempts = 1;
  return bloc;
}

VibeChatState _stateWith(PreviewState state,
        {String requestId = 'req_1', bool isStale = false}) =>
    VibeChatState(
      step: VibeChatStep.loaded,
      tileCastStatusByRequest: {
        requestId: VibeRequestPreview(
            id: 'preview_1',
            vibeRequestId: requestId,
            state: state,
            isStale: isStale),
      },
    );

Widget _wrap(VibeChatBloc bloc, Widget child) {
  return BlocProvider.value(
    value: bloc,
    child: MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpList(WidgetTester t, VibeChatState state,
      {VibeChatBloc? bloc}) async {
    final b = bloc ?? _makeBloc();
    await t.pumpWidget(_wrap(
      b,
      ActionsList(
        actions: [_clickableAction()],
        requestId: 'req_1',
        state: state,
      ),
    ));
    await t.pump();
  }

  group('ActionsList readiness banner', () {
    testWidgets('shows preparing banner + spinner while processing', (t) async {
      await pumpList(t, _stateWith(PreviewState.processing));
      expect(find.byKey(const ValueKey('tilecast_readiness_banner')),
          findsOneWidget);
      expect(find.text('Preparing TileCast…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ready banner when ready', (t) async {
      await pumpList(t, _stateWith(PreviewState.ready));
      expect(find.text('Tap to view TileCast'), findsOneWidget);
    });

    testWidgets('shows outdated banner when invalidated', (t) async {
      await pumpList(t, _stateWith(PreviewState.invalidated));
      expect(find.text('Outdated — send a new message'), findsOneWidget);
    });

    testWidgets('shows unavailable banner when failed', (t) async {
      await pumpList(t, _stateWith(PreviewState.failed));
      expect(find.text('TileCast unavailable'), findsOneWidget);
    });

    double opacity(WidgetTester t) =>
        t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

    testWidgets('dims actions only while preparing', (t) async {
      await pumpList(t, _stateWith(PreviewState.processing));
      expect(opacity(t), lessThan(1.0));
    });

    testWidgets('does not dim actions when unavailable (failed)', (t) async {
      await pumpList(t, _stateWith(PreviewState.failed));
      expect(opacity(t), 1.0);
    });

    testWidgets('does not dim actions when outdated (invalidated)', (t) async {
      await pumpList(t, _stateWith(PreviewState.invalidated));
      expect(opacity(t), 1.0);
    });

    testWidgets('no banner when there are no clickable actions', (t) async {
      final bloc = _makeBloc();
      await t.pumpWidget(_wrap(
        bloc,
        ActionsList(
          actions: [
            VibeAction(
              id: 'a',
              descriptions: 'chatter',
              type: ActionType.conversationalAndNotSupported,
              status: ActionStatus.none,
            ),
            VibeAction(
              id: 'b',
              descriptions: 'done',
              type: ActionType.addNewTask,
              status: ActionStatus.executed,
            ),
          ],
          requestId: 'req_1',
          state: _stateWith(PreviewState.processing),
        ),
      ));
      await t.pump();
      expect(find.byKey(const ValueKey('tilecast_readiness_banner')),
          findsNothing);
    });
  });

  group('ActionsList stale note', () {
    testWidgets('shows stale note when the ready TileCast is stale',
        (t) async {
      await pumpList(
          t, _stateWith(PreviewState.ready, isStale: true));
      expect(find.byKey(const ValueKey('tilecast_stale_note')), findsOneWidget);
      expect(find.text('Your schedule changed — this TileCast may be out of date'),
          findsOneWidget);
      // Ready + stale must remain tappable (banner still says ready).
      expect(find.text('Tap to view TileCast'), findsOneWidget);
    });

    testWidgets('no stale note when the TileCast is not stale', (t) async {
      await pumpList(t, _stateWith(PreviewState.ready));
      expect(find.byKey(const ValueKey('tilecast_stale_note')), findsNothing);
    });

    testWidgets('stale TileCast still opens when tapped', (t) async {
      final bloc = _RecordingBloc()..chatApi = _FakeChatApi(PreviewState.ready);
      bloc.tileCastReadinessDelayOverride = (_) async {};
      bloc.tileCastReadinessMaxAttempts = 1;
      await pumpList(t, _stateWith(PreviewState.ready, isStale: true),
          bloc: bloc);

      await t.tap(find.text('Add gym task'));
      await t.pump();

      expect(bloc.recorded.whereType<LoadTileCastEvent>(), isNotEmpty);
    });
  });

  group('ActionsList tap gating', () {
    testWidgets('tapping while preparing does not open a preview', (t) async {
      final bloc = _RecordingBloc()..chatApi = _FakeChatApi(PreviewState.processing);
      bloc.tileCastReadinessDelayOverride = (_) async {};
      bloc.tileCastReadinessMaxAttempts = 1;
      await pumpList(t, _stateWith(PreviewState.processing), bloc: bloc);

      await t.tap(find.text('Add gym task'));
      await t.pump();

      expect(bloc.recorded.whereType<LoadTileCastEvent>(), isEmpty);
    });

    testWidgets('tapping when ready opens the preview', (t) async {
      final bloc = _RecordingBloc()..chatApi = _FakeChatApi(PreviewState.ready);
      bloc.tileCastReadinessDelayOverride = (_) async {};
      bloc.tileCastReadinessMaxAttempts = 1;
      await pumpList(t, _stateWith(PreviewState.ready), bloc: bloc);

      await t.tap(find.text('Add gym task'));
      await t.pump();

      final loadEvents =
          bloc.recorded.whereType<LoadTileCastEvent>().toList();
      expect(loadEvents, hasLength(1));
      expect(loadEvents.first.vibeRequestId, 'req_1');
      expect(loadEvents.first.actionId, 'action_1');
    });
  });
}
