// today_status_recovery_test.dart
//
// §8.1 row 4: when anything is late the screen enters the recovery state, and
// that section takes precedence over placed / attention rather than trailing
// them where it can fall below the fold.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/todayStatus/planSectionCard.dart';
import 'package:tiler_app/components/todayStatus/statusSummaryStrip.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/todayStatus/dayPlanViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

TilerEvent _event(String id, String name, {int hour = 9}) {
  return SubCalendarEvent.fromJson({
    'id': id,
    'name': name,
    'start': DateTime(2026, 9, 1, hour).millisecondsSinceEpoch,
    'end': DateTime(2026, 9, 1, hour + 1).millisecondsSinceEpoch,
  });
}

class _FakeScheduleApi extends ScheduleApi {
  _FakeScheduleApi({this.placed = 0, this.attention = 0, this.late = 0})
      : super(getContextCallBack: () => null);

  final int placed;
  final int attention;
  final int late;

  @override
  Future<TimelineSummary?> getTimelineSummary(Timeline timeline) async {
    final summary = TimelineSummary();
    summary.timeline = timeline;
    summary.complete = [
      for (int i = 0; i < placed; i++) _event('p$i', 'Placed $i', hour: 8)
    ];
    summary.nonViable = [
      for (int i = 0; i < attention; i++) _event('a$i', 'Attention $i')
    ];
    summary.tardy = [
      for (int i = 0; i < late; i++) _event('l$i', 'Late $i', hour: 17)
    ];
    return summary;
  }
}

class _FakeSummaryBloc extends ScheduleSummaryBloc {
  _FakeSummaryBloc() : super(getContextCallBack: () => null);
  @override
  Future<bool> completeTasks(String id, String type, String userId) async =>
      true;
}

Widget _harness(ScheduleApi api) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<ScheduleSummaryBloc>.value(
      value: _FakeSummaryBloc(),
      child: TodayStatusScreen(
        timeline: Timeline.fromDateTime(
            DateTime(2026, 9, 1), DateTime(2026, 9, 1, 23, 59)),
        scheduleApi: api,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('view model recovery precedence', () {
    test('late leads the content whenever anything is late', () {
      final summary = TimelineSummary();
      summary.complete = [_event('p', 'Placed')];
      summary.nonViable = [_event('a', 'Attention')];
      summary.tardy = [_event('l', 'Late')];

      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: Timeline.fromDateTime(
            DateTime(2026, 9, 1), DateTime(2026, 9, 1, 23, 59)),
        summary: summary,
      );

      expect(model.lateLeadsContent, isTrue);
      expect(model.attentionLeadsContent, isFalse,
          reason: 'late outranks attention for the leading slot');
    });

    test('nothing late means no recovery lead', () {
      final summary = TimelineSummary();
      summary.nonViable = [_event('a', 'Attention')];

      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: Timeline.fromDateTime(
            DateTime(2026, 9, 1), DateTime(2026, 9, 1, 23, 59)),
        summary: summary,
      );

      expect(model.lateLeadsContent, isFalse);
    });
  });

  group('screen ordering', () {
    testWidgets('the late card renders above placed and attention',
        (tester) async {
      await tester.pumpWidget(
          _harness(_FakeScheduleApi(placed: 2, attention: 2, late: 1)));
      await tester.pumpAndSettle();

      final double lateY = tester
          .getTopLeft(find.ancestor(
              of: find.text('Running late'),
              matching: find.byType(PlanSectionCard)))
          .dy;
      final double placedY = tester
          .getTopLeft(find.ancestor(
              of: find.text('Placed successfully'),
              matching: find.byType(PlanSectionCard)))
          .dy;
      final double attentionY = tester
          .getTopLeft(find.ancestor(
              of: find.text('Need attention'),
              matching: find.byType(PlanSectionCard)))
          .dy;

      expect(lateY, lessThan(attentionY));
      expect(lateY, lessThan(placedY));
    });

    testWidgets('the late card is visible without scrolling', (tester) async {
      await tester.pumpWidget(
          _harness(_FakeScheduleApi(placed: 6, attention: 6, late: 1)));
      await tester.pumpAndSettle();

      final Size screen =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
          tester
              .getTopLeft(find.descendant(
                  of: find.byType(PlanSectionCard),
                  matching: find.text('Running late')))
              .dy,
          lessThan(screen.height),
          reason: 'the most urgent state must not start below the fold');
    });
  });

  group('summary strip', () {
    testWidgets('reports a late metric when something is running late',
        (tester) async {
      await tester.pumpWidget(
          _harness(_FakeScheduleApi(placed: 2, attention: 1, late: 3)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
            of: find.byType(StatusSummaryStrip), matching: find.text('3')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: find.byType(StatusSummaryStrip),
            matching: find.text('Running late')),
        findsOneWidget,
      );
    });

    testWidgets('stays a two-column strip when nothing is late',
        (tester) async {
      await tester
          .pumpWidget(_harness(_FakeScheduleApi(placed: 2, attention: 1)));
      await tester.pumpAndSettle();

      expect(find.text('Running late'), findsNothing);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });
  });
}
