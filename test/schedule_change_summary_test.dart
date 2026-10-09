// "Plan updated" chip: when a change is worth reporting, how schedule states
// turn into summaries, and the chip, sheet and host on screen.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryChip.dart';
import 'package:tiler_app/components/tilelist/dailyView/scheduleChangeSummaryHost.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/scheduleChangeSummary.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

final DateTime _day = DateTime(2026, 10, 8);
int at(int h, int m, {int dayOffset = 0}) => _day
    .add(Duration(days: dayOffset, hours: h, minutes: m))
    .millisecondsSinceEpoch;

SubCalendarEvent tile(String id, String name, int start, int minutes,
    {int travel = 0}) {
  final t = SubCalendarEvent(
      id: id, name: name, start: start, end: start + minutes * 60000);
  t.travelTimeBefore = travel * 60000.0;
  return t;
}

final Timeline day = Timeline(at(0, 0), at(0, 0, dayOffset: 1));
final Timeline window =
    Timeline(at(0, 0, dayOffset: -3), at(0, 0, dayOffset: 4));

/// Sync, groceries, Vit.D, dinner, read: the storyboard's Thursday.
List<SubCalendarEvent> thursday(
        {int vitd = 0, int groc = 0, int grocTravel = 12}) =>
    [
      tile('sync', 'Team sync', at(16, 0), 45),
      tile('groc', 'Pick up groceries', groc == 0 ? at(17, 15) : groc, 40,
          travel: grocTravel),
      tile('vitd', 'Get some Vit.D', vitd == 0 ? at(18, 11) : vitd, 30,
          travel: 7),
      tile('dinner', 'Dinner', at(19, 0), 45),
      tile('read', 'Read 30 pages', at(20, 30), 30),
    ];

ScheduleStatus status(String id) =>
    ScheduleStatus.fromJson({'analysisId': id, 'evaluationId': id});

ScheduleLoadedState loaded(List<SubCalendarEvent> tiles, ScheduleStatus s) =>
    ScheduleLoadedState(
        subEvents: tiles,
        timelines: const [],
        lookupTimeline: window,
        scheduleStatus: s,
        previousLookupTimeline: window,
        currentView: AuthorizedRouteTileListPage.Daily);

const revise = ScheduleChangeAttribution(ScheduleChangeOrigin.tilerRevise);

ScheduleDelta moveVitD() => ScheduleDelta.compute(
    before: thursday(), after: thursday(vitd: at(19, 55)), day: day);

void main() {
  group('ScheduleChangeSummary.from', () {
    test('background refreshes never get a chip', () {
      expect(
          ScheduleChangeSummary.from(
              moveVitD(), ScheduleChangeAttribution.refresh),
          isNull);
    });

    test('a re-optimize that changed the day gets one', () {
      final summary = ScheduleChangeSummary.from(moveVitD(), revise)!;
      expect(summary.movedCount, 1);
      expect(summary.isDayCleared, isFalse);
    });

    test('nothing changed: no chip', () {
      final delta = ScheduleDelta.compute(
          before: thursday(), after: thursday(), day: day);
      expect(ScheduleChangeSummary.from(delta, revise), isNull);
    });

    test('a drag that only moved the dragged Tile gets none', () {
      const drag = ScheduleChangeAttribution(ScheduleChangeOrigin.userDrag,
          subjectId: 'vitd');
      expect(ScheduleChangeSummary.from(moveVitD(), drag), isNull);
    });

    test('a drag that pushed other Tiles gets one', () {
      const drag = ScheduleChangeAttribution(ScheduleChangeOrigin.userDrag,
          subjectId: 'groc');
      final delta = ScheduleDelta.compute(
          before: thursday(),
          after: thursday(groc: at(17, 33), vitd: at(18, 20)),
          day: day);
      expect(ScheduleChangeSummary.from(delta, drag)!.movedCount, 2);
    });

    test('counts by kind and orders rows by time', () {
      final after = [
        ...thursday(vitd: at(19, 55))
            .where((t) => t.uniqueId != 'read' && t.uniqueId != 'sync'),
        tile('sync', 'Team sync', at(16, 0, dayOffset: 1), 45),
        tile('gym', 'Gym', at(21, 0), 60),
      ];
      final summary = ScheduleChangeSummary.from(
          ScheduleDelta.compute(
              before: thursday(),
              after: after,
              day: day,
              beforeWindow: window,
              afterWindow: window),
          revise)!;
      expect(summary.movedCount, 1);
      expect(summary.movedToOtherDaysCount, 1);
      expect(summary.removedCount, 1);
      expect(summary.addedCount, 1);
      expect(summary.orderedChanges.map((c) => c.id),
          ['sync', 'vitd', 'read', 'gym']);
    });

    test('a cleared day is flagged', () {
      final gone = [
        for (final t in thursday())
          tile(t.uniqueId, t.name!,
              t.start! + const Duration(days: 1).inMilliseconds, 30)
      ];
      final summary = ScheduleChangeSummary.from(
          ScheduleDelta.compute(before: thursday(), after: gone, day: day),
          revise)!;
      expect(summary.isDayCleared, isTrue);
      expect(summary.movedToOtherDaysCount, 5);
    });
  });

  group('ScheduleChangeWatcher', () {
    ScheduleChangeSummary? feed(ScheduleChangeWatcher w, ScheduleState state,
            [ScheduleChangeAttribution attribution = revise]) =>
        w.observe(state, day: day, attribute: (_) => attribution);

    test('the first state only seeds the snapshot', () {
      final w = ScheduleChangeWatcher();
      expect(feed(w, loaded(thursday(), status('r0'))), isNull);
    });

    test('a new revision with a change produces a summary', () {
      final w = ScheduleChangeWatcher()
        ..observe(loaded(thursday(), status('r0')),
            day: day, attribute: (_) => revise);
      final summary =
          feed(w, loaded(thursday(vitd: at(19, 55)), status('r1')))!;
      expect(summary.movedCount, 1);
    });

    test('the same revision again never produces one', () {
      final w = ScheduleChangeWatcher();
      feed(w, loaded(thursday(), status('r0')));
      // Same revision, different Tiles: e.g. more days were loaded.
      expect(feed(w, loaded(thursday(vitd: at(19, 55)), status('r0'))), isNull);
    });

    test('failed and unknown states are ignored and keep the snapshot', () {
      final w = ScheduleChangeWatcher();
      feed(w, loaded(thursday(), status('r0')));
      expect(
          feed(
              w,
              FailedScheduleLoadedState(
                  subEvents: const <SubCalendarEvent>[],
                  timelines: const <Timeline>[],
                  lookupTimeline: window,
                  evaluationTime: DateTime(2026),
                  scheduleStatus: status('r9'),
                  currentView: AuthorizedRouteTileListPage.Daily)),
          isNull);
      expect(feed(w, loaded(const [], ScheduleStatus())), isNull);
      // Diffed against the last good snapshot, not the empty failure.
      final summary =
          feed(w, loaded(thursday(vitd: at(19, 55)), status('r1')))!;
      expect(summary.movedCount, 1);
      expect(summary.removedCount, 0);
    });

    test('a refresh is diffed but not reported', () {
      final w = ScheduleChangeWatcher();
      feed(w, loaded(thursday(), status('r0')));
      expect(
          feed(w, loaded(thursday(vitd: at(19, 55)), status('r1')),
              ScheduleChangeAttribution.refresh),
          isNull);
    });
  });

  Widget app(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('chip and sheet', () {
    testWidgets('the chip summarises; See changes lists the diff',
        (tester) async {
      final summary = ScheduleChangeSummary.from(
          ScheduleDelta.compute(
              before: thursday(),
              after:
                  thursday(groc: at(17, 33), vitd: at(18, 20), grocTravel: 30),
              day: day),
          revise)!;
      await tester.pumpWidget(app(Builder(
          builder: (context) => ScheduleChangeSummaryChip(
              summary: summary,
              onSeeChanges: () =>
                  ScheduleChangeSheet.show(context, summary)))));

      expect(find.text('Plan updated'), findsOneWidget);
      expect(
          find.text('2 Tiles moved · 1 travel time updated'), findsOneWidget);

      await tester.tap(find.byKey(ScheduleChangeSummaryChip.seeChangesKey));
      await tester.pumpAndSettle();
      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('5:15 PM → 5:33 PM'), findsOneWidget);
      expect(find.text('6:11 PM → 6:20 PM'), findsOneWidget);
      expect(find.text('Travel to Pick up groceries'), findsOneWidget);
      expect(find.text('12 min → 30 min'), findsOneWidget);
      expect(find.text('Free time'), findsOneWidget);
    });

    testWidgets('free time gained shows on the chip', (tester) async {
      // Vit.D leaves early evening: gaps join, and the 7 min drive into it
      // no longer eats into free time before dinner.
      final summary = ScheduleChangeSummary.from(
          ScheduleDelta.compute(
              before: thursday(), after: thursday(vitd: at(22, 0)), day: day),
          revise)!;
      expect(summary.freeMinutesGained, greaterThan(0));
      await tester.pumpWidget(app(
          ScheduleChangeSummaryChip(summary: summary, onSeeChanges: () {})));
      expect(
          find.text('1 Tile moved · '
              '+${summary.freeMinutesGained} min free'),
          findsOneWidget);
    });
  });

  group('ScheduleChangeSummaryHost', () {
    late ScheduleBloc bloc;

    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// The bloc must be created inside the widget test so its events run in
    /// the test's fake-async zone and are delivered by `pump`.
    void createBloc() => bloc = ScheduleBloc(getContextCallBack: () => null);

    Future<void> reload(WidgetTester tester, List<SubCalendarEvent> tiles,
        ScheduleStatus s) async {
      bloc.add(ReloadLocalScheduleEvent(
          subEvents: tiles,
          timelines: const [],
          lookupTimeline: window,
          scheduleStatus: s));
      await tester.pump();
      await tester.pump();
    }

    Widget host({DateTime? date}) => app(BlocProvider<ScheduleBloc>.value(
        value: bloc,
        child: ScheduleChangeSummaryHost(
            currentDate: date ?? _day,
            visibleFor: const Duration(seconds: 6),
            child: const SizedBox.expand())));

    testWidgets('shows after a re-optimize and hides on its own',
        (tester) async {
      createBloc();
      await tester.pumpWidget(host());
      await reload(tester, thursday(), status('r0'));
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsNothing);

      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      await reload(tester, thursday(vitd: at(19, 55)), status('r1'));
      // While the change plays (Detailed), a banner names it...
      expect(find.byKey(ScheduleChangeMovingBanner.bannerKey), findsOneWidget);
      expect(find.text('1 Tile moving'), findsOneWidget);
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsNothing);
      // ...then the chip takes over once it has played.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(ScheduleChangeMovingBanner.bannerKey), findsNothing);
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsNothing);
    });

    testWidgets('a background refresh shows nothing', (tester) async {
      createBloc();
      await tester.pumpWidget(host());
      await reload(tester, thursday(), status('r0'));
      await reload(tester, thursday(vitd: at(19, 55)), status('r1'));
      await tester.pumpAndSettle();
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsNothing);
    });

    testWidgets('changing day hides the chip', (tester) async {
      createBloc();
      await tester.pumpWidget(host());
      await reload(tester, thursday(), status('r0'));
      bloc.beginChange(ScheduleChangeOrigin.tilerRevise);
      await reload(tester, thursday(vitd: at(19, 55)), status('r1'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsOneWidget);

      await tester.pumpWidget(host(date: _day.add(const Duration(days: 1))));
      await tester.pumpAndSettle();
      expect(find.byKey(ScheduleChangeSummaryChip.chipKey), findsNothing);
    });
  });
}
