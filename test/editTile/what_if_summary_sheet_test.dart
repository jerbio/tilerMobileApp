// WhatIfSummarySheet — the edit-tile "what this change affects" sheet:
// pinned title + count, tiles tiered by day with start–end times, capped at
// three dated days, and a distinct treatment for high-priority tiles.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/whatIfSummaryModel.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/whatIfSummarySheet.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

SubCalendarEvent _tile(
  String name, {
  DateTime? start,
  Duration duration = const Duration(hours: 1),
  String priority = 'medium',
}) {
  return SubCalendarEvent.fromJson(<String, dynamic>{
    'id': name,
    'name': name,
    'thirdPartyType': 'tiler',
    'priority': priority,
    if (start != null) 'start': start.millisecondsSinceEpoch,
    if (start != null) 'end': start.add(duration).millisecondsSinceEpoch,
  });
}

Widget _app(WhatIfSummary summary) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 500,
          child: WhatIfSummarySheet(summary: summary),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Anchored on today so the day headers read Today / Tomorrow.
  final DateTime day1 = Utility.currentTime().dayDate;
  final DateTime day2 = day1.add(const Duration(days: 1));
  final DateTime day3 = day1.add(const Duration(days: 2));
  final DateTime day4 = day1.add(const Duration(days: 3));

  testWidgets('pins the title + affected count above the list',
      (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [
        for (int i = 0; i < 12; i++)
          _tile('t$i', start: day1.add(Duration(hours: 6 + i))),
      ],
      overflow: const [],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();

    final Rect title = tester.getRect(find.byKey(WhatIfSummarySheet.titleKey));
    expect(find.text('12 tiles affected'), findsOneWidget);
    final Finder list = find.byType(ListView);
    expect(list, findsOneWidget);
    // The list starts below the header, so the header cannot scroll away.
    expect(tester.getRect(list).top, greaterThanOrEqualTo(title.bottom));

    final Rect before = tester.getRect(find.byKey(WhatIfSummarySheet.titleKey));
    await tester.drag(list, const Offset(0, -160));
    await tester.pump();
    expect(tester.getRect(find.byKey(WhatIfSummarySheet.titleKey)), before,
        reason: 'the title is pinned while the list scrolls');
  });

  testWidgets('tiers the tiles by day, with a header per day', (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [
        _tile('today tile', start: day1.add(const Duration(hours: 9))),
        _tile('tomorrow tile', start: day2.add(const Duration(hours: 9))),
      ],
      overflow: const [],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('TOMORROW'), findsOneWidget);
    // Day 1's header and rows come before day 2's.
    final double d1 =
        tester.getRect(find.byKey(WhatIfSummarySheet.dayHeaderKey(0))).top;
    final double d2 =
        tester.getRect(find.byKey(WhatIfSummarySheet.dayHeaderKey(1))).top;
    expect(d1, lessThan(d2));
    expect(tester.getRect(find.byKey(WhatIfSummarySheet.rowKey('today tile'))).top,
        inExclusiveRange(d1, d2));
  });

  testWidgets('every row shows its start–end time and impact',
      (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [
        _tile('Gym',
            start: day1.add(const Duration(hours: 9)),
            duration: const Duration(minutes: 45)),
      ],
      overflow: const [],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();
    expect(find.textContaining('9:00 AM – 9:45 AM'), findsOneWidget);
    expect(find.textContaining('Late'), findsOneWidget);
  });

  testWidgets('caps at three days and surfaces the rest as a count',
      (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [
        for (final d in [day1, day2, day3, day4])
          _tile('t${d.day}', start: d.add(const Duration(hours: 9))),
      ],
      overflow: const [],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();

    expect(find.byKey(WhatIfSummarySheet.dayHeaderKey(2)), findsOneWidget);
    expect(find.byKey(WhatIfSummarySheet.dayHeaderKey(3)), findsNothing);
    expect(find.byKey(WhatIfSummarySheet.moreDaysKey), findsOneWidget);
    expect(find.text('1 more day affected'), findsOneWidget);
    expect(find.byKey(WhatIfSummarySheet.rowKey('t${day4.day}')), findsNothing);
  });

  testWidgets('tapping "N more days" extends the list to every day',
      (tester) async {
    final DateTime day5 = day1.add(const Duration(days: 4));
    final summary = WhatIfSummary.from(
      tardy: [
        for (final d in [day1, day2, day3, day4, day5])
          _tile('t${d.day}', start: d.add(const Duration(hours: 9))),
      ],
      overflow: const [],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();

    // Collapsed: 3 days, the rest behind the line. The count is of ALL
    // affected tiles, not just the visible tiers.
    expect(find.text('5 tiles affected'), findsOneWidget);
    expect(find.text('2 more days affected'), findsOneWidget);
    expect(find.byKey(WhatIfSummarySheet.rowKey('t${day4.day}')), findsNothing);

    await tester.tap(find.byKey(WhatIfSummarySheet.moreDaysKey));
    await tester.pump();

    // Expanded: the line is gone and the remaining days are listed.
    expect(find.byKey(WhatIfSummarySheet.moreDaysKey), findsNothing);
    for (final DateTime d in [day1, day2, day3, day4, day5]) {
      await tester.scrollUntilVisible(
          find.byKey(WhatIfSummarySheet.rowKey('t${d.day}')), 80,
          scrollable: find.byType(Scrollable).first);
      expect(find.byKey(WhatIfSummarySheet.rowKey('t${d.day}')),
          findsOneWidget);
    }
    expect(find.byKey(WhatIfSummarySheet.dayHeaderKey(4)), findsOneWidget);
  });

  testWidgets('the undated group stays last after expanding', (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [
        for (final d in [day1, day2, day3, day4])
          _tile('t${d.day}', start: d.add(const Duration(hours: 9))),
      ],
      overflow: [_tile('nowhere')],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();
    await tester.tap(find.byKey(WhatIfSummarySheet.moreDaysKey));
    await tester.pump();

    await tester.scrollUntilVisible(
        find.byKey(WhatIfSummarySheet.rowKey('nowhere')), 80,
        scrollable: find.byType(Scrollable).first);
    expect(tester.getRect(find.byKey(WhatIfSummarySheet.rowKey('nowhere'))).top,
        greaterThan(tester
            .getRect(find.byKey(WhatIfSummarySheet.rowKey('t${day4.day}')))
            .top));
  });

  testWidgets('high-priority tiles get their own treatment', (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [
        _tile('normal', start: day1.add(const Duration(hours: 8))),
        _tile('urgent',
            start: day1.add(const Duration(hours: 17)), priority: 'high'),
      ],
      overflow: const [],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();

    // The priority chip marks it, and it leads its day.
    expect(find.text('High'), findsOneWidget);
    expect(tester.getRect(find.byKey(WhatIfSummarySheet.rowKey('urgent'))).top,
        lessThan(
            tester.getRect(find.byKey(WhatIfSummarySheet.rowKey('normal'))).top));
    // Its row carries a tinted surface; an ordinary row does not.
    BoxDecoration decorationOf(String id) => tester
        .widget<Container>(find.byKey(WhatIfSummarySheet.rowKey(id)))
        .decoration! as BoxDecoration;
    expect(decorationOf('urgent').color, isNot(Colors.transparent));
    expect(decorationOf('normal').color, Colors.transparent);
  });

  testWidgets('unplaceable overflow tiles get their own trailing group',
      (tester) async {
    final summary = WhatIfSummary.from(
      tardy: [_tile('placed', start: day1.add(const Duration(hours: 9)))],
      overflow: [_tile('nowhere')],
    );
    await tester.pumpWidget(_app(summary));
    await tester.pump();

    expect(find.text('NO SLOT FOUND'), findsOneWidget);
    expect(find.byKey(WhatIfSummarySheet.rowKey('nowhere')), findsOneWidget);
    // Listed after the dated group.
    expect(tester.getRect(find.byKey(WhatIfSummarySheet.rowKey('nowhere'))).top,
        greaterThan(tester
            .getRect(find.byKey(WhatIfSummarySheet.rowKey('placed')))
            .top));
    // An unplaced row shows its impact without a time range.
    expect(find.text('Overflow'), findsOneWidget);
  });
}
