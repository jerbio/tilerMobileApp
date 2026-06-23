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
import 'package:tiler_app/routes/authenticatedUser/preview/preview_day_digest.dart';
import 'package:tiler_app/theme/theme_data.dart';

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

  group('PreviewDayDigest', () {
    testWidgets('renders the no-tiles message when the day is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PreviewDayDigest(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          overrideTimelineSummary: TimelineSummary(),
          autoFetchSummary: false,
        ),
      ));
      await tester.pump();

      expect(find.text('You have nothing coming up for the rest of today.'),
          findsOneWidget);
    });

    testWidgets('renders sentence with all clauses when day is populated',
        (tester) async {
      final subs = <TilerEvent>[
        _buildSub(id: 't1', startMs: _todayAt(9), endMs: _todayAt(10)),
        _buildSub(id: 't2', startMs: _todayAt(11), endMs: _todayAt(12)),
        _buildSub(
            id: 'b1',
            startMs: _todayAt(14),
            endMs: _todayAt(15),
            isRigid: true),
      ];

      await tester.pumpWidget(_wrap(
        PreviewDayDigest(
          subEvents: subs,
          timeline: _todayTimeline(),
          overrideTimelineSummary: TimelineSummary(),
          autoFetchSummary: false,
        ),
      ));
      await tester.pump();

      final sentence =
          find.byKey(const ValueKey('preview-day-digest-sentence'));
      expect(sentence, findsOneWidget);
      final widget = tester.widget(sentence) as Text;
      final text = widget.textSpan!.toPlainText();
      expect(text, contains('Hello.'));
      expect(text, contains('Today has'));
      expect(text, contains('2 tiles'));
      expect(text, contains('1 blocks'));
      expect(text, contains('waiting.'));
    });

    testWidgets('hides icon chips when no chip metric is present',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PreviewDayDigest(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          overrideTimelineSummary: TimelineSummary(),
          autoFetchSummary: false,
        ),
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('preview-day-digest-chip-distance')),
          findsNothing);
      expect(find.byKey(const ValueKey('preview-day-digest-chip-locations')),
          findsNothing);
      expect(find.byKey(const ValueKey('preview-day-digest-chip-sleep')),
          findsNothing);
    });

    testWidgets('renders sleep chip when timeline summary has sleepDuration',
        (tester) async {
      final summary = TimelineSummary()
        ..sleepDuration = const Duration(hours: 7, minutes: 30);

      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewDayDigest(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
          overrideTimelineSummary: summary,
        ),
        bloc: bloc,
      ));
      await tester.pump();

      expect(find.byKey(const ValueKey('preview-day-digest-chip-sleep')),
          findsOneWidget);
    });

    testWidgets(
        'dispatches GetScheduleDaySummaryEvent on mount when bloc is initial',
        (tester) async {
      final bloc = _CapturingScheduleSummaryBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(
        PreviewDayDigest(
          subEvents: const <TilerEvent>[],
          timeline: _todayTimeline(),
        ),
        bloc: bloc,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        bloc.eventsAdded.whereType<GetScheduleDaySummaryEvent>(),
        isNotEmpty,
        reason:
            'PreviewDayDigest should request a day summary when the bloc starts in the initial state.',
      );
    });
  });
}

class _CapturingScheduleSummaryBloc extends ScheduleSummaryBloc {
  final List<ScheduleSummaryEvent> eventsAdded = [];

  _CapturingScheduleSummaryBloc({ScheduleSummaryState? seed})
      : super(getContextCallBack: () => null) {
    if (seed != null) {
      // ignore: invalid_use_of_visible_for_testing_member
      emit(seed);
    }
  }

  @override
  void add(ScheduleSummaryEvent event) {
    eventsAdded.add(event);
  }
}
