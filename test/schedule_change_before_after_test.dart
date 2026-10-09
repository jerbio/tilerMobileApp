// "What changed" sheet: the Before & after tab shows the whole day on each
// side (moved tiles joined, arrivals and departures marked), and long
// durations read in hours.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeBeforeAfter.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryChip.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

final DateTime _day = DateTime(2026, 10, 9); // a Friday
final Timeline day =
    Timeline.fromDateTime(_day, _day.add(const Duration(days: 1)));
int at(int h, int m, {int dayOffset = 0}) => _day
    .add(Duration(days: dayOffset, hours: h, minutes: m))
    .millisecondsSinceEpoch;

SubCalendarEvent tile(String id, String name, int start, int minutes) =>
    SubCalendarEvent(
        id: id, name: name, start: start, end: start + minutes * 60000);

const revise = ScheduleChangeAttribution(ScheduleChangeOrigin.tilerRevise);

ScheduleChangeSummary summarize(
        List<SubCalendarEvent> before, List<SubCalendarEvent> after) =>
    ScheduleChangeSummary.from(
        ScheduleDelta.compute(before: before, after: after, day: day), revise,
        before: before, after: after)!;

Future<void> openSheet(
    WidgetTester tester, ScheduleChangeSummary summary) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => ScheduleChangeSheet.show(context, summary),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The screenshot: one "work out" moves from 10:39 PM to 10:58 AM and the
  // next one comes in from Saturday into the 10:39 PM slot.
  final before = [
    tile('notes', 'Notes', at(9, 0), 30),
    tile('w1', 'work out', at(22, 39), 30),
    tile('w2', 'work out', at(22, 39, dayOffset: 1), 30),
  ];
  final after = [
    tile('notes', 'Notes', at(9, 0), 30),
    tile('w1', 'work out', at(10, 58), 30),
    tile('w2', 'work out', at(22, 39), 30),
  ];

  test('the summary carries the whole day before and after', () {
    final summary = summarize(before, after);
    expect(summary.beforeDay.map((t) => t.uniqueId), ['notes', 'w1']);
    expect(summary.afterDay.map((t) => t.uniqueId), ['notes', 'w1', 'w2']);
  });

  testWidgets('Before & after shows both days, with arrivals marked',
      (tester) async {
    await openSheet(tester, summarize(before, after));
    expect(find.byType(ScheduleChangeBeforeAfter), findsNothing);

    await tester.tap(find.byKey(ScheduleChangeSheet.beforeAfterTabKey));
    await tester.pumpAndSettle();
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);

    Finder row(String side, String id) =>
        find.byKey(ScheduleChangeBeforeAfter.rowKey(side, id));
    expect(row('before', 'notes'), findsOneWidget);
    expect(row('before', 'w1'), findsOneWidget);
    expect(row('before', 'w2'), findsNothing); // it was on Saturday
    expect(row('after', 'w1'), findsOneWidget);
    expect(row('after', 'w2'), findsOneWidget);

    // 'work out' is second on both sides (after Notes), so its rows line
    // up even though its time changed.
    expect(tester.getTopLeft(row('before', 'w1')).dy,
        tester.getTopLeft(row('after', 'w1')).dy);
    expect(
        find.descendant(
            of: row('after', 'w2'), matching: find.textContaining('← Sat')),
        findsOneWidget);
    expect(
        find.descendant(
            of: row('after', 'w1'), matching: find.text('10:58 AM')),
        findsOneWidget);
  });

  testWidgets('long durations read in hours', (tester) async {
    // 8:30 AM to 2:09 PM free (5h 39m), then 8:30 AM to 5:41 PM (9h 11m).
    final summary = summarize(
      [tile('a', 'A', at(8, 0), 30), tile('b', 'B', at(14, 9), 30)],
      [tile('a', 'A', at(8, 0), 30), tile('b', 'B', at(17, 41), 30)],
    );
    await openSheet(tester, summary);
    expect(find.text('5h 39m → 9h 11m'), findsOneWidget);
    expect(find.text('2:09 PM → 5:41 PM'), findsOneWidget);
  });
}
