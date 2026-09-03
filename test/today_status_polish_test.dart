// today_status_polish_test.dart
//
// Design-review follow-up: pluralization, the temporal-attribute rule that
// stops "Today" repeating down the screen, and demoting the healthy placed
// section when the day has an exception.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/todayStatus/planSectionCard.dart';
import 'package:tiler_app/components/todayStatus/planTaskRow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

DateTime _todayAt(int hour) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour);
}

TilerEvent _event(String id, String name,
    {DateTime? start, int durationMinutes = 45}) {
  final DateTime begin = start ?? _todayAt(9);
  return SubCalendarEvent.fromJson({
    'id': id,
    'name': name,
    'start': begin.millisecondsSinceEpoch,
    'end': begin.add(Duration(minutes: durationMinutes)).millisecondsSinceEpoch,
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
      for (int i = 0; i < placed; i++)
        _event('p$i', 'Deep work $i', start: _todayAt(8 + i))
    ];
    summary.nonViable = [
      for (int i = 0; i < attention; i++)
        _event('a$i', 'Vitamin D $i',
            start: _todayAt(10 + i), durationMinutes: 30)
    ];
    summary.tardy = [
      for (int i = 0; i < late; i++)
        _event('l$i', 'School pickup $i', start: _todayAt(14 + i))
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

Widget _screen(ScheduleApi api) {
  final DateTime now = DateTime.now();
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
        timeline: Timeline.fromDateTime(DateTime(now.year, now.month, now.day),
            DateTime(now.year, now.month, now.day, 23, 59)),
        scheduleApi: api,
      ),
    ),
  );
}

Widget _card(Widget child) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 390, child: child))),
  );
}

PlanItemViewModel _item({
  required String id,
  required String title,
  required PlanItemStatus status,
  DateTime? start,
  DateTime? displayDate,
  int? durationMinutes,
}) {
  return PlanItemViewModel(
    id: id,
    title: title,
    status: status,
    source: _event(id, title),
    scheduledStart: start,
    displayDate: displayDate,
    durationMinutes: durationMinutes,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pluralization', () {
    testWidgets('a single tile reads "1 tile", not "1 tiles"', (tester) async {
      await tester.pumpWidget(_screen(_FakeScheduleApi(placed: 1)));
      await tester.pumpAndSettle();

      expect(find.text('1 tile'), findsOneWidget);
      expect(find.text('1 tiles'), findsNothing);
    });

    testWidgets('the strip label agrees with its count', (tester) async {
      await tester.pumpWidget(_screen(_FakeScheduleApi(placed: 1)));
      await tester.pumpAndSettle();

      expect(find.text('Tile completed'), findsOneWidget);
      expect(find.text('Tiles completed'), findsNothing);
    });

    testWidgets('plural form is used beyond one', (tester) async {
      await tester.pumpWidget(_screen(_FakeScheduleApi(placed: 3)));
      await tester.pumpAndSettle();

      expect(find.text('3 tiles'), findsOneWidget);
      expect(find.text('Tiles completed'), findsOneWidget);
    });
  });

  group('temporal attribute rules', () {
    testWidgets('late rows lead with the scheduled time, not "Today"',
        (tester) async {
      await tester.pumpWidget(_card(PlanSectionCard(
        status: PlanItemStatus.late,
        items: [
          _item(
              id: 'l',
              title: 'School pickup',
              status: PlanItemStatus.late,
              start: _todayAt(14),
              displayDate: _todayAt(14)),
        ],
      )));

      expect(find.text('Today'), findsNothing);
      expect(find.textContaining('2:00'), findsOneWidget);
    });

    testWidgets('attention rows lead with how long the tile needs',
        (tester) async {
      await tester.pumpWidget(_card(PlanSectionCard(
        status: PlanItemStatus.needsAttention,
        items: [
          _item(
              id: 'a',
              title: 'Get some Vitamin D',
              status: PlanItemStatus.needsAttention,
              start: _todayAt(10),
              displayDate: _todayAt(10),
              durationMinutes: 30),
        ],
      )));

      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('placed rows still name a date when it is not today',
        (tester) async {
      final DateTime future = DateTime.now().add(const Duration(days: 4));
      await tester.pumpWidget(_card(PlanSectionCard(
        status: PlanItemStatus.placed,
        items: [
          _item(
              id: 'p',
              title: 'Deep Work',
              status: PlanItemStatus.placed,
              start: future,
              displayDate: future),
        ],
      )));

      expect(find.byType(PlanTaskRow), findsOneWidget);
      expect(find.text('Today'), findsNothing);
    });
  });

  group('exception owns the screen', () {
    testWidgets('placed collapses when something needs attention',
        (tester) async {
      await tester
          .pumpWidget(_screen(_FakeScheduleApi(placed: 2, attention: 2)));
      await tester.pumpAndSettle();

      expect(find.text('Placed successfully'), findsOneWidget);
      expect(find.text('Deep work 0'), findsNothing,
          reason: 'the healthy section should start collapsed');
      expect(find.text('Vitamin D 0'), findsOneWidget);
    });

    testWidgets('placed stays expanded on a healthy day', (tester) async {
      await tester.pumpWidget(_screen(_FakeScheduleApi(placed: 2)));
      await tester.pumpAndSettle();

      expect(find.text('Deep work 0'), findsOneWidget);
    });

    testWidgets('the user can still expand a collapsed placed section',
        (tester) async {
      await tester
          .pumpWidget(_screen(_FakeScheduleApi(placed: 2, attention: 1)));
      await tester.pumpAndSettle();

      final Finder placedCard = find.ancestor(
          of: find.text('Placed successfully'),
          matching: find.byType(PlanSectionCard));
      await tester.tap(find.descendant(
          of: placedCard, matching: find.byKey(PlanSectionCard.chevronKey)));
      await tester.pumpAndSettle();

      expect(find.text('Deep work 0'), findsOneWidget);
    });
  });
}
