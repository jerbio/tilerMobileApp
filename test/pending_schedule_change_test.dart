// Screens that save a schedule change record it with PendingScheduleChange
// so the revision it produces shows as that change, not a background
// refresh.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/pending_schedule_change.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';

ScheduleStatus status(String id) =>
    ScheduleStatus.fromJson({'analysisId': id, 'evaluationId': id});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A context under [bloc] (or under nothing when null).
  Future<BuildContext> contextUnder(
      WidgetTester tester, ScheduleBloc? bloc) async {
    late BuildContext captured;
    final probe = Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    });
    await tester.pumpWidget(bloc == null
        ? probe
        : BlocProvider<ScheduleBloc>.value(value: bloc, child: probe));
    return captured;
  }

  testWidgets('the next revision is the recorded change', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final bloc = ScheduleBloc(getContextCallBack: () => null);
    final change = PendingScheduleChange.begin(
        await contextUnder(tester, bloc), ScheduleChangeOrigin.userComplete,
        subjectId: 'tile-1');
    expect(change, isNotNull);

    final attribution = bloc.attributionFor(status('r1'));
    expect(attribution.origin, ScheduleChangeOrigin.userComplete);
    expect(attribution.subjectId, 'tile-1');
  });

  testWidgets('the subject can be named after the request', (tester) async {
    final bloc = ScheduleBloc(getContextCallBack: () => null);
    final change = PendingScheduleChange.begin(
        await contextUnder(tester, bloc), ScheduleChangeOrigin.userAdd)!;
    // The screen is gone by the time the server replies: still fine.
    await tester.pumpWidget(const SizedBox());
    change.attachSubject('new-1');

    final attribution = bloc.attributionFor(status('r1'));
    expect(attribution.origin, ScheduleChangeOrigin.userAdd);
    expect(attribution.subjectId, 'new-1');
  });

  testWidgets('a failed request leaves nothing recorded', (tester) async {
    final bloc = ScheduleBloc(getContextCallBack: () => null);
    PendingScheduleChange.begin(
            await contextUnder(tester, bloc), ScheduleChangeOrigin.userEdit)!
        .abandon();
    expect(bloc.attributionFor(status('r1')).isRefresh, isTrue);
  });

  testWidgets('without a schedule bloc nothing is recorded', (tester) async {
    expect(
        PendingScheduleChange.begin(
            await contextUnder(tester, null), ScheduleChangeOrigin.userEdit),
        isNull);
  });
}
