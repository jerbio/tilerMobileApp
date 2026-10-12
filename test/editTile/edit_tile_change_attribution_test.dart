// Edits made from the Edit Tile / Tile detail screens are recorded as the
// change they are, so the day shows what they moved (the pushed tiles step
// into place, with the "Plan updated" chip) instead of treating the result
// as a background refresh.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileScheduleRefresher.dart';

ScheduleStatus status(String id) =>
    ScheduleStatus.fromJson({'analysisId': id, 'evaluationId': id});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScheduleBloc bloc;
  late BlocEditTileScheduleRefresher refresher;

  /// Serves an empty schedule at [revision], as the bloc would after a load.
  Future<void> serve(WidgetTester tester, String revision) async {
    bloc.add(ReloadLocalScheduleEvent(
        subEvents: const [],
        timelines: const [],
        lookupTimeline: Timeline(0, 1000),
        scheduleStatus: status(revision)));
    await tester.pump();
  }

  Future<void> setUpBlocs(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Created inside the test so their events run in its fake-async zone.
    bloc = ScheduleBloc(getContextCallBack: () => null);
    refresher = BlocEditTileScheduleRefresher(
      scheduleBloc: bloc,
      scheduleSummaryBloc: ScheduleSummaryBloc(getContextCallBack: () => null),
    );
    await serve(tester, 'r0');
  }

  testWidgets('a save is the change that produced the next revision',
      (tester) async {
    await setUpBlocs(tester);
    refresher.beginEvaluation(subjectId: 'tile-1');
    await serve(tester, 'r1');

    final attribution = bloc.attributionFor(status('r1'));
    expect(attribution.origin, ScheduleChangeOrigin.userEdit);
    expect(attribution.subjectId, 'tile-1');
  });

  testWidgets('a complete is recorded as a complete', (tester) async {
    await setUpBlocs(tester);
    refresher.beginEvaluation(
        origin: ScheduleChangeOrigin.userComplete, subjectId: 'tile-1');
    await serve(tester, 'r1');

    expect(bloc.attributionFor(status('r1')).origin,
        ScheduleChangeOrigin.userComplete);
  });

  testWidgets('a failed request withdraws the change', (tester) async {
    await setUpBlocs(tester);
    refresher.beginEvaluation(subjectId: 'tile-1');
    refresher.abandonEvaluation();
    await serve(tester, 'r1');

    expect(bloc.attributionFor(status('r1')).isRefresh, isTrue);
  });
}
