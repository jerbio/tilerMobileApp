// procrastinate_duration_test.dart
//
// The two "defer" screens — ProcrastinateAll (defer everything) and
// TileProcrastinateRoute (defer one tile) — used to embed the raw package
// `DurationPicker` inside the old Cancel/Proceed template, so they were the
// last places in the app still wearing the pre-redesign duration look.
// Both now ARE the redesigned `AddTileDurationScreen`, titled "Defer":
//   1. ProcrastinateAll: committing a value calls `ScheduleApi.procrastinateAll`
//      with it exactly once and pops; Back calls nothing and pops.
//   2. TileProcrastinateRoute: committing calls
//      `SubCalendarEventApi.procrastinate(duration, tileId)` once, hands the
//      request to the caller's callback as `PlaybackOptions.Procrastinate`,
//      asks the ScheduleBloc to evaluate, and pops; a seeded duration opens
//      the picker on that value.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/procrastinateAll.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/tileProcrastinate.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final _l10n = lookupAppLocalizations(const Locale('en'));
final Finder _firstPreset = find.byKey(const ValueKey('durationPreset_0'));
final Duration _firstPresetValue = addTileDurationPresets.first;

/// The request is gated behind [release] so a test can observe the screen
/// while it is in flight. Ungated by default.
class FakeScheduleApi extends ScheduleApi {
  FakeScheduleApi({this.gated = false}) : super(getContextCallBack: () => null);
  final bool gated;
  final Completer<void> release = Completer<void>();
  final List<Duration> procrastinateAllCalls = [];

  @override
  Future procrastinateAll(Duration duration) async {
    procrastinateAllCalls.add(duration);
    if (gated) await release.future;
    return null;
  }
}

class FakeSubCalendarEventApi extends SubCalendarEventApi {
  FakeSubCalendarEventApi({this.gated = false})
      : super(getContextCallBack: () => null);
  final bool gated;
  final Completer<void> release = Completer<void>();
  final List<(Duration, String)> calls = [];

  @override
  Future<SubCalendarEvent> procrastinate(Duration duration, String id) async {
    calls.add((duration, id));
    if (gated) await release.future;
    return SubCalendarEvent();
  }
}

/// Records events without processing them — nothing reaches the network.
class RecordingScheduleBloc extends ScheduleBloc {
  RecordingScheduleBloc() : super(getContextCallBack: () => null);
  final List<ScheduleEvent> events = [];
  @override
  void add(ScheduleEvent event) => events.add(event);
}

class _HomePage extends StatelessWidget {
  const _HomePage();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}

/// Pushes [screen] over a home page the way the app does, so popping is
/// observable.
Future<void> _push(WidgetTester tester, Widget screen,
    {ScheduleBloc? scheduleBloc}) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  Widget app = MaterialApp(
    navigatorKey: navigatorKey,
    theme: TileThemeData.lightTheme,
    localizationsDelegates: _l10nDelegates,
    supportedLocales: const [Locale('en', '')],
    home: const _HomePage(),
  );
  if (scheduleBloc != null) {
    app = BlocProvider<ScheduleBloc>.value(value: scheduleBloc, child: app);
  }
  await tester.pumpWidget(app);
  navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => screen));
  await tester.pumpAndSettle();
}

void main() {
  group('ProcrastinateAll (defer everything)', () {
    testWidgets('is the redesigned picker titled "Defer"', (tester) async {
      final api = FakeScheduleApi();
      await _push(tester, ProcrastinateAll(scheduleApi: api));

      expect(find.byType(AddTileDurationScreen), findsOneWidget);
      expect(find.text(_l10n.defer), findsOneWidget,
          reason: 'The screen is about deferring, not a tile\'s duration.');
    });

    testWidgets('committing a value defers everything by it and pops',
        (tester) async {
      final api = FakeScheduleApi();
      await _push(tester, ProcrastinateAll(scheduleApi: api));

      await tester.tap(_firstPreset);
      await tester.pumpAndSettle();

      expect(api.procrastinateAllCalls, [_firstPresetValue]);
      expect(find.byType(AddTileDurationScreen), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Back defers nothing', (tester) async {
      final api = FakeScheduleApi();
      await _push(tester, ProcrastinateAll(scheduleApi: api));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(api.procrastinateAllCalls, isEmpty);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets(
        'while the request is in flight the picker shows progress, blocks '
        'a second commit, and only pops once the request resolves',
        (tester) async {
      final api = FakeScheduleApi(gated: true);
      await _push(tester, ProcrastinateAll(scheduleApi: api));

      await tester.tap(_firstPreset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(api.procrastinateAllCalls, hasLength(1));
      expect(find.byType(AddTileDurationScreen), findsOneWidget,
          reason: 'The screen stays up until the defer is confirmed.');
      // The redesign's pending treatment: the CTA carries the spinner and
      // the page shows the pending sweep — no dimmed overlay.
      expect(
        find.descendant(
            of: find.byKey(const ValueKey('durationDone')),
            matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
        reason: 'The Done button shows the in-flight state, like the Add '
            'Tile CTA while submitting.',
      );
      expect(find.byType(AddTilePendingSweep), findsOneWidget,
          reason: 'The page shows the pending sweep while waiting on the '
              'server.');

      // A second tap while busy must not send a second request.
      await tester.tap(find.byKey(const ValueKey('durationPreset_1')),
          warnIfMissed: false);
      await tester.pump();
      expect(api.procrastinateAllCalls, hasLength(1));

      api.release.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AddTileDurationScreen), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('TileProcrastinateRoute (defer one tile)', () {
    testWidgets(
        'is the redesigned picker titled "Defer", seeded with the given '
        'duration', (tester) async {
      final api = FakeSubCalendarEventApi();
      final bloc = RecordingScheduleBloc();
      addTearDown(bloc.close);
      await _push(
        tester,
        TileProcrastinateRoute(
          tileId: 'tile-1',
          duration: const Duration(hours: 2),
          subCalendarEventApi: api,
        ),
        scheduleBloc: bloc,
      );

      expect(find.byType(AddTileDurationScreen), findsOneWidget);
      expect(find.text(_l10n.defer), findsOneWidget);
      expect(
        tester
            .widget<AddTileDurationScreen>(find.byType(AddTileDurationScreen))
            .initialDuration,
        const Duration(hours: 2),
      );
    });

    testWidgets(
        'committing defers the tile, hands the request to the callback, '
        'asks the schedule to evaluate, and pops', (tester) async {
      final api = FakeSubCalendarEventApi();
      final bloc = RecordingScheduleBloc();
      addTearDown(bloc.close);
      PlaybackOptions? reported;
      await _push(
        tester,
        TileProcrastinateRoute(
          tileId: 'tile-1',
          subCalendarEventApi: api,
          callBack: (PlaybackOptions option, Future request) {
            reported = option;
          },
        ),
        scheduleBloc: bloc,
      );

      await tester.tap(_firstPreset);
      await tester.pumpAndSettle();

      expect(api.calls, [(_firstPresetValue, 'tile-1')]);
      expect(reported, PlaybackOptions.Procrastinate);
      expect(bloc.events.whereType<EvaluateSchedule>(), hasLength(1),
          reason: 'The schedule shows its evaluating state while the '
              'request is in flight.');
      expect(find.byType(AddTileDurationScreen), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows progress while the defer is in flight', (tester) async {
      final api = FakeSubCalendarEventApi(gated: true);
      final bloc = RecordingScheduleBloc();
      addTearDown(bloc.close);
      await _push(
        tester,
        TileProcrastinateRoute(tileId: 'tile-1', subCalendarEventApi: api),
        scheduleBloc: bloc,
      );

      await tester.tap(_firstPreset);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.descendant(
            of: find.byKey(const ValueKey('durationDone')),
            matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      expect(find.byType(AddTilePendingSweep), findsOneWidget);
      expect(find.byType(AddTileDurationScreen), findsOneWidget);

      api.release.complete();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
