import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_event.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/scheduleEvaluationFeedback.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeSurface.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/previewAddWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'schedule_evaluation_flow_test.dart' show FakeScheduleApi;

class _ShuffleApi extends FakeScheduleApi {
  int shuffles = 0;

  @override
  Future<void> shuffleSchedule() async {
    shuffles++;
    status = ScheduleStatus.fromJson(
        {'analysisId': 'shuffled', 'evaluationId': 'shuffled'});
  }
}

class _Forecast extends ForecastBloc {
  _Forecast() : super(getContextCallBack: () => null);
  int resets = 0;

  @override
  void add(ForecastEvent event) {
    if (event is ResetEvent) resets++;
    super.add(event);
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  for (final shuffle in [true, false]) {
    testWidgets(
        '${shuffle ? 'Shuffle' : 'Defer All'} explains a pending re-optimize on the open sheet',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _ShuffleApi();
      final bloc = ScheduleBloc(getContextCallBack: () => null)
        ..scheduleApi = api;
      final forecast = _Forecast();
      final bus = ScheduleNoticeBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(RepositoryProvider.value(
        value: bus,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ScheduleBloc>(create: (_) => bloc),
            BlocProvider<ForecastBloc>(create: (_) => forecast),
            BlocProvider(
                create: (_) =>
                    ScheduleSummaryBloc(getContextCallBack: () => null)),
            BlocProvider(
                create: (_) =>
                    SubCalendarTileBloc(getContextCallBack: () => null)),
            BlocProvider(create: (_) => UiDateManagerBloc()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            theme: TileThemeData.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ScheduleNoticeSurface.calendar(
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (sheetContext) => SizedBox(
                        height: MediaQuery.sizeOf(sheetContext).height,
                        child: PreviewAddWidget(),
                      ),
                    ),
                    child: const Text('Open actions'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: [],
          timelines: [],
          lookupTimeline: api.window,
          scheduleStatus: api.status));
      await tester.pump();
      final write = Completer<void>();
      final pending = bloc.runScheduleChange(() => write.future,
          kind: ScheduleChangeKind.revise);
      await tester.pump();
      final requestId = bloc.activeEvaluation!.id;

      await tester.tap(find.text('Open actions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final resets = forecast.resets;
      await tester.tap(find
          .text(shuffle ? l10n.previewTileShuffle : l10n.previewTileDeferAll));
      await tester.pump();

      final explanation = l10n.scheduleChangesBlockedBy(
          scheduleChangeLabel(l10n, bloc.activeEvaluation!));
      final toast = find.text(explanation);
      expect(toast.hitTestable(), findsOneWidget,
          reason: 'the notice must be visible above the modal sheet');
      expect(find.descendant(of: find.byType(BottomSheet), matching: toast),
          findsOneWidget);
      expect(find.byType(PreviewAddWidget), findsOneWidget);
      expect(bloc.activeEvaluation!.id, requestId);
      expect(bloc.activeEvaluation!.kind, ScheduleChangeKind.revise);
      expect(bloc.scheduleChangesBlocked, isTrue);
      expect(api.shuffles, 0);
      expect(forecast.resets, resets,
          reason: 'a blocked action must preserve the current draft');
      expect(tester.takeException(), isNull);

      write.complete();
      await pending;
      await tester.pump();
      expect(bloc.scheduleChangesBlocked, isFalse);
      await tester.pump(bus.interruptionFor);

      if (shuffle) {
        await tester.tap(find.text(l10n.previewTileShuffle));
        await tester.pumpAndSettle();
        expect(api.shuffles, 1);
        expect(find.byType(PreviewAddWidget), findsNothing);
        expect(forecast.resets, resets + 1);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
