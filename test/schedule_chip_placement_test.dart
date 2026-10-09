// Schedule-change chips sit above the bottom navigation bar (the Daily page
// runs behind it) and clear of the floating add button.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/scheduleChipInsets.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/listMotion.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryChip.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryHost.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoff.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoffChip.dart';

const double bar = 100;

Widget app(Widget child, {double bottomPadding = 0}) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(padding: EdgeInsets.only(bottom: bottomPadding)),
          child: Scaffold(body: child),
        ),
      ),
    );

SubCalendarEvent tile(String id, DateTime start) => SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: start.add(const Duration(minutes: 30)).millisecondsSinceEpoch);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('list edge chips clear the bar and the add button',
      (tester) async {
    final motion = ListMotion(apply: (change) => change());
    final day = DateTime(2026, 10, 8);
    motion.handoffs.show([
      GridHandoff(HandoffDirection.later,
          [tile('a', day.add(const Duration(hours: 22)))]),
      GridHandoff(HandoffDirection.nextDay, [
        tile('b', day.add(const Duration(days: 1, hours: 9))),
        tile('c', day.add(const Duration(days: 3, hours: 9))),
      ]),
    ]);
    await tester.pumpWidget(app(ScheduleChipInsets(
      bottomBar: bar,
      child: ListMotionLayer(
        motion: motion,
        rowBuilder: (_) => const SizedBox(),
        scrollToTile: (_) {},
        child: const SizedBox.expand(),
      ),
    )));

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    for (final direction in [
      HandoffDirection.later,
      HandoffDirection.nextDay
    ]) {
      final chip = find.byKey(GridHandoffChip.keyFor(direction));
      expect(chip, findsOneWidget);
      expect(
          tester.getBottomLeft(chip).dy,
          lessThanOrEqualTo(
              size.height - bar - ScheduleChipInsets.edgeChipGap));
      expect(tester.getTopRight(chip).dx,
          lessThanOrEqualTo(size.width - ScheduleChipInsets.fabClearance));
    }
    // Several destinations share one chip.
    expect(find.text('2 Tiles moved to other days'), findsOneWidget);
    motion.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
        'the Plan updated chip is solid and readable (${dark ? "dark" : "light"})',
        (tester) async {
      final day = DateTime(2026, 10, 9);
      final summary = ScheduleChangeSummary.from(
          ScheduleDelta.compute(
              before: [tile('a', day.add(const Duration(hours: 9)))],
              after: [tile('a', day.add(const Duration(hours: 11)))],
              day:
                  Timeline.fromDateTime(day, day.add(const Duration(days: 1)))),
          const ScheduleChangeAttribution(ScheduleChangeOrigin.tilerRevise))!;
      await tester.pumpWidget(MaterialApp(
        theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: ScheduleChangeSummaryChip(
                summary: summary, onSeeChanges: () {})),
      ));
      final background = tester
          .widget<Material>(find.byKey(ScheduleChangeSummaryChip.chipKey))
          .color!;
      // Opaque: nothing behind the chip shows through.
      expect(background.a, 1.0);
      final title = tester.widget<Text>(find.text('Plan updated'));
      expect(contrast(title.style!.color!, background), greaterThan(4.5));
      final action = tester
          .widget<TextButton>(
              find.byKey(ScheduleChangeSummaryChip.seeChangesKey))
          .style!
          .foregroundColor!
          .resolve(<WidgetState>{})!;
      expect(contrast(action, background), greaterThan(4.5));
    });
  }

  testWidgets('the summary host shares the bar height it is given',
      (tester) async {
    double? seen;
    await tester.pumpWidget(app(
      BlocProvider<ScheduleBloc>(
        create: (_) => ScheduleBloc(getContextCallBack: () => null),
        child: ScheduleChangeSummaryHost(
          currentDate: DateTime(2026, 10, 8),
          child: Builder(builder: (context) {
            seen = ScheduleChipInsets.bottomBarOf(context);
            return const SizedBox.expand();
          }),
        ),
      ),
      bottomPadding: bar,
    ));
    expect(seen, bar);
  });
}

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
