import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/preview_sundial_card.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// JSON-driven SubCalendarEvent factory, mirrors the helper used by
/// day_preview_metrics_test.dart. Lets us set private flags
/// (`isRigid`, `isComplete`, `isViable`) that have no public setter.
SubCalendarEvent _buildSub({
  required String id,
  required int startMs,
  required int endMs,
  bool isRigid = false,
  bool isComplete = false,
  bool isEnabled = true,
  bool isViable = true,
}) {
  return SubCalendarEvent.fromJson({
    'id': id,
    'start': startMs,
    'end': endMs,
    'isRigid': isRigid,
    'isComplete': isComplete,
    'isEnabled': isEnabled,
    'isViable': isViable,
  });
}

/// Today's UTC day window so subEvent times line up against
/// `Utility.todayTimeline()` inside the widget.
Timeline _todayTimeline() {
  final now = DateTime.now();
  final begin = DateTime(now.year, now.month, now.day);
  final end = begin.add(const Duration(days: 1));
  return Timeline(begin.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}

int _todayAt(int hour, [int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute)
      .millisecondsSinceEpoch;
}

Widget _wrap(Widget child, {ScheduleSummaryBloc? bloc}) {
  final body = bloc == null
      ? child
      : BlocProvider<ScheduleSummaryBloc>.value(value: bloc, child: child);
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: SizedBox(width: 360, child: body))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreviewSundialCard', () {
    testWidgets(
        'renders the "Today" label and distribution counts in empty state',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PreviewSundialCard(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          overrideTimelineSummary: TimelineSummary(),
          autoFetchSummary: false,
        ),
      ));
      await tester.pump();

      // "Today" only appears inside the arc center label in empty state
      // — the redundant header label was dropped in v2 of the redesign.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('0 · 0 · 0'), findsOneWidget);
    });

    testWidgets('chevron has null onTap in v1', (tester) async {
      await tester.pumpWidget(_wrap(
        PreviewSundialCard(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          overrideTimelineSummary: TimelineSummary(),
          autoFetchSummary: false,
        ),
      ));
      await tester.pump();

      final inkWell = tester.widget<InkWell>(
        find.byKey(const ValueKey('preview-sundial-chevron')),
      );
      expect(inkWell.onTap, isNull);
    });

    testWidgets('hides icon chips when no chip metric is present',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PreviewSundialCard(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          overrideTimelineSummary: TimelineSummary(),
          autoFetchSummary: false,
        ),
      ));
      await tester.pump();

      // Chips moved to PreviewDayDigest; sundial card no longer renders them.
      expect(find.byKey(const ValueKey('preview-sundial-chip-distance')),
          findsNothing);
      expect(find.byKey(const ValueKey('preview-sundial-chip-locations')),
          findsNothing);
      expect(find.byKey(const ValueKey('preview-sundial-chip-sleep')),
          findsNothing);
    });

    testWidgets(
        'dispatches GetScheduleDaySummaryEvent on mount when bloc is initial',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewSundialCard(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
        ),
        bloc: bloc,
      ));
      await tester.pump();
      // Allow postFrameCallback to flush.
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        bloc.eventsAdded.whereType<GetScheduleDaySummaryEvent>(),
        isNotEmpty,
        reason:
            'PreviewSundialCard should request a day summary when the bloc starts in the initial state.',
      );
    });

    testWidgets(
        'does NOT dispatch GetScheduleDaySummaryEvent when bloc already loaded',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc(
        seed: ScheduleDaySummaryLoaded(
          dayData: const <TimelineSummary>[],
          timeline: _todayTimeline(),
          elapsedTiles: const [],
        ),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewSundialCard(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
        ),
        bloc: bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(bloc.eventsAdded.whereType<GetScheduleDaySummaryEvent>(), isEmpty);
    });
  });
}

/// Test double — captures any events added to the bloc instead of
/// invoking the real handlers (which would hit the network).
class _CapturingScheduleSummaryBloc extends ScheduleSummaryBloc {
  final List<ScheduleSummaryEvent> eventsAdded = [];

  _CapturingScheduleSummaryBloc({ScheduleSummaryState? seed})
      : super(getContextCallBack: () => null) {
    if (seed != null) {
      // Emit the seed state so consumers don't observe ScheduleSummaryInitial.
      // ignore: invalid_use_of_visible_for_testing_member
      emit(seed);
    }
  }

  @override
  void add(ScheduleSummaryEvent event) {
    eventsAdded.add(event);
    // Deliberately do NOT call super.add — we don't want the real bloc
    // handlers (which call into ScheduleApi) to run inside widget tests.
  }
}
