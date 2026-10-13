// A schedule change keeps going when the screen that started it closes
// first (e.g. completing a tile from its sheet, which closes at once): the
// API calls made for it still find the schedule bloc.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tuple/tuple.dart';

class _FakeScheduleApi extends ScheduleApi {
  _FakeScheduleApi() : super(getContextCallBack: () => null);
  final status =
      ScheduleStatus.fromJson({'analysisId': 'a', 'evaluationId': 'e'});
  @override
  Future<ScheduleStatus> getScheduleStatus() async => status;
  @override
  Future<Tuple3<List<Timeline>, List<SubCalendarEvent>, ScheduleStatus>>
      getSubEvents(Timeline window) async => Tuple3([], [], status);
}

/// What `() => context` does once its State is unmounted.
Never closedScreen() => throw FlutterError(
    'This widget has been unmounted, so the State no longer has a context');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a closed screen means no schedule bloc, not an error', () {
    final api = SubCalendarEventApi(getContextCallBack: closedScreen);
    expect(api.scheduleLifecycle, isNull);
  });

  test('a call made for a change finds that change\'s bloc', () async {
    SharedPreferences.setMockInitialValues({});
    final bloc = ScheduleBloc(getContextCallBack: () => null)
      ..scheduleApi = _FakeScheduleApi();
    final api = SubCalendarEventApi(getContextCallBack: closedScreen);
    ScheduleBloc? seen;
    await bloc.runScheduleChange(() async {
      // The baseline read happened first; the sheet is long gone.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      seen = api.scheduleLifecycle;
      return true;
    }, kind: ScheduleChangeKind.complete);
    expect(seen, same(bloc));
    expect(bloc.activeEvaluation, isNull,
        reason: 'the change finished instead of failing');
    expect(ScheduleBloc.ofCurrentChange, isNull);
    await bloc.close();
  });
}
