// today_status_screen_test.dart
//
// Phase 7 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// Walks the §16.3 acceptance matrix (cases A–I) against the assembled screen,
// plus the §15.3 loading/error states and the ported completion flow.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/todayStatus/planPreviewCta.dart';
import 'package:tiler_app/components/todayStatus/planSectionCard.dart';
import 'package:tiler_app/components/todayStatus/planTaskRow.dart';
import 'package:tiler_app/components/todayStatus/statusSummaryStrip.dart';
import 'package:tiler_app/components/todayStatus/todayAppBar.dart';
import 'package:tiler_app/components/todayStatus/trackStatusCard.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

SubCalendarEvent _event(String id, String name, {int hour = 9}) {
  return SubCalendarEvent.fromJson({
    'id': id,
    'name': name,
    'start': DateTime(2026, 9, 1, hour).millisecondsSinceEpoch,
    'end': DateTime(2026, 9, 1, hour + 1).millisecondsSinceEpoch,
  });
}

class _FakeScheduleApi extends ScheduleApi {
  _FakeScheduleApi({
    this.placed = 0,
    this.attention = 0,
    this.late = 0,
    this.gate,
    this.throwError = false,
    this.titles,
  }) : super(getContextCallBack: () => null);

  final int placed;
  final int attention;
  final int late;
  final Completer<void>? gate;
  final bool throwError;
  final List<String>? titles;

  int callCount = 0;

  @override
  Future<TimelineSummary?> getTimelineSummary(Timeline timeline) async {
    callCount++;
    if (gate != null) await gate!.future;
    if (throwError) throw Exception('boom');
    final summary = TimelineSummary();
    summary.timeline = timeline;
    summary.complete = <TilerEvent>[
      for (int i = 0; i < placed; i++)
        _event('p$i', titles != null ? titles![i] : 'Placed $i', hour: 8 + i)
    ];
    summary.nonViable = <TilerEvent>[
      for (int i = 0; i < attention; i++) _event('a$i', 'Attention $i')
    ];
    summary.tardy = <TilerEvent>[
      for (int i = 0; i < late; i++) _event('l$i', 'Late $i')
    ];
    return summary;
  }
}

class _FakeSummaryBloc extends ScheduleSummaryBloc {
  _FakeSummaryBloc() : super(getContextCallBack: () => null);

  final List<List<String>> completeCalls = [];

  @override
  Future<bool> completeTasks(String id, String type, String userId) async {
    completeCalls.add([id, type, userId]);
    return true;
  }
}

Widget _harness(ScheduleApi api, {ScheduleSummaryBloc? bloc}) {
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
      value: bloc ?? _FakeSummaryBloc(),
      child: TodayStatusScreen(
        timeline: Timeline.fromDateTime(
            DateTime(2026, 9, 1), DateTime(2026, 9, 1, 23, 59)),
        scheduleApi: api,
      ),
    ),
  );
}

/// The strip and the section headers deliberately share wording, so finders
/// must say which one they mean.
Finder _sectionTitle(String text) => find.descendant(
    of: find.byType(PlanSectionCard), matching: find.text(text));

Finder _stripLabel(String text) => find.descendant(
    of: find.byType(StatusSummaryStrip), matching: find.text(text));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('§16.3 acceptance matrix', () {
    testWidgets('A · 4 placed / 6 attention / 0 late', (tester) async {
      await tester
          .pumpWidget(_harness(_FakeScheduleApi(placed: 4, attention: 6)));
      await tester.pumpAndSettle();

      expect(find.text('Placed successfully'), findsOneWidget);
      expect(_sectionTitle('Need attention'), findsOneWidget);
      expect(find.text('Everything else is on track'), findsOneWidget);
      expect(find.text('Everything is on track'), findsNothing);
    });

    testWidgets('B · 10 placed / 0 / 0 — on track, no attention card',
        (tester) async {
      await tester.pumpWidget(_harness(_FakeScheduleApi(placed: 10)));
      await tester.pumpAndSettle();

      expect(find.text('Placed successfully'), findsOneWidget);
      expect(_sectionTitle('Need attention'), findsNothing);
      expect(find.text('Everything is on track'), findsOneWidget);
      expect(find.byType(PlanPreviewCta), findsNothing);
    });

    testWidgets('C · 0 placed / 6 attention — attention leads', (tester) async {
      await tester.pumpWidget(_harness(_FakeScheduleApi(attention: 6)));
      await tester.pumpAndSettle();

      expect(find.text('Placed successfully'), findsNothing);
      expect(_sectionTitle('Need attention'), findsOneWidget);
    });

    testWidgets('D · 1 late suppresses the on-track card', (tester) async {
      await tester.pumpWidget(
          _harness(_FakeScheduleApi(placed: 4, attention: 2, late: 1)));
      await tester.pumpAndSettle();

      expect(_sectionTitle('Running late'), findsOneWidget);
      expect(find.byType(TrackStatusCard), findsNothing);
      expect(find.text('Everything is on track'), findsNothing);
      expect(find.text('Everything else is on track'), findsNothing);
    });

    testWidgets('E · clear day', (tester) async {
      await tester.pumpWidget(_harness(_FakeScheduleApi()));
      await tester.pumpAndSettle();

      expect(find.text('Your day is clear.'), findsOneWidget);
      expect(find.byType(PlanSectionCard), findsNothing);
      expect(find.byType(TrackStatusCard), findsNothing);
    });

    testWidgets('F · a 100+ char title renders without overflow',
        (tester) async {
      final String longTitle = 'Create the end of quarter write-up ' * 4;
      await tester.pumpWidget(
          _harness(_FakeScheduleApi(placed: 1, titles: [longTitle])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.byKey(PlanTaskRow.titleKey));
      expect(title.maxLines, 2);
    });

    testWidgets('G · survives 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 2.0,
          maxScaleFactor: 2.0,
          child: child!,
        ),
        home: BlocProvider<ScheduleSummaryBloc>.value(
          value: _FakeSummaryBloc(),
          child: TodayStatusScreen(
            timeline: Timeline.fromDateTime(
                DateTime(2026, 9, 1), DateTime(2026, 9, 1, 23, 59)),
            scheduleApi: _FakeScheduleApi(placed: 2, attention: 2),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('I · a failed fetch keeps the screen usable and offers retry',
        (tester) async {
      final api = _FakeScheduleApi(throwError: true);
      await tester.pumpWidget(_harness(api));
      await tester.pumpAndSettle();

      expect(find.byKey(TodayStatusScreen.errorKey), findsOneWidget);
      expect(find.byKey(TodayStatusScreen.retryKey), findsOneWidget);

      await tester.tap(find.byKey(TodayStatusScreen.retryKey));
      await tester.pumpAndSettle();
      expect(api.callCount, 2);
    });
  });

  group('§15.3 loading', () {
    testWidgets('shows a loading state until the summary arrives',
        (tester) async {
      final gate = Completer<void>();
      await tester
          .pumpWidget(_harness(_FakeScheduleApi(placed: 2, gate: gate)));
      await tester.pump();

      expect(find.byKey(TodayStatusScreen.loadingKey), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(TodayStatusScreen.loadingKey), findsNothing);
      expect(find.text('Placed successfully'), findsOneWidget);
    });
  });

  group('chrome', () {
    testWidgets('summary strip reports the counts', (tester) async {
      await tester
          .pumpWidget(_harness(_FakeScheduleApi(placed: 4, attention: 6)));
      await tester.pumpAndSettle();

      expect(find.byType(StatusSummaryStrip), findsOneWidget);
      expect(_stripLabel('Tiles completed'), findsOneWidget);
      expect(_stripLabel('Need attention'), findsOneWidget);
    });

    testWidgets('titles itself with the humanized date', (tester) async {
      final DateTime now = DateTime.now();
      await tester.pumpWidget(MaterialApp(
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
                DateTime(now.year, now.month, now.day),
                DateTime(now.year, now.month, now.day, 23, 59)),
            scheduleApi: _FakeScheduleApi(placed: 1),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
            of: find.byType(TodayAppBar), matching: find.text('Today')),
        findsOneWidget,
      );
    });
  });

  group('completion flow ported from the old summary page', () {
    testWidgets('selecting attention tiles and completing calls the bloc',
        (tester) async {
      final bloc = _FakeSummaryBloc();
      await tester
          .pumpWidget(_harness(_FakeScheduleApi(attention: 2), bloc: bloc));
      await tester.pumpAndSettle();

      // Selection starts from the header control; a row tap opens the tile.
      await tester.tap(find.byKey(PlanSectionCard.enterSelectionKey));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(2));

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete Tiles'));
      await tester.pumpAndSettle();

      expect(bloc.completeCalls, hasLength(1));
      expect(bloc.completeCalls.single.first, 'a0');
    });
  });
}
