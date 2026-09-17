// Pull-to-refresh dispatches
// GetScheduleEvent(forceRefresh: true) through ScheduleBloc (same wiring
// as EnhancedTileBatch); the live now-line renders only for the
// current day, sits at the injected clock's position, and its minute
// timer is cancelled on dispose (no pending timers).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records every event added to [ScheduleBloc] WITHOUT running the
/// [GetScheduleEvent] handler (no API calls in tests). The dispatch is
/// what's under test, not the fetch.
class _RecordingScheduleBloc extends ScheduleBloc {
  final List<ScheduleEvent> events = <ScheduleEvent>[];

  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    events.add(event);
    if (event is GetScheduleEvent) {
      return;
    }
    super.add(event);
  }
}

const _nowLineKey = Key('daygrid_now_line');
const _nowBubbleKey = Key('daygrid_now_bubble');

SubCalendarEvent _tile(String id, DateTime start, DateTime end) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  tile.isViable = true;
  return tile;
}

Widget _buildApp({
  required ScheduleBloc bloc,
  required List<SubCalendarEvent> tiles,
  DateTime? now,
}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<ScheduleBloc>(
      create: (_) => bloc,
      child: Scaffold(
        body: DayGridWidget(tiles: tiles, now: now),
      ),
    ),
  );
}

/// Closes [bloc] from the real async zone, draining the FakeAsync
/// microtask queue while the done-delivery cascade is in flight.
///
/// `bloc.close()` cascades a done event through the stream subscriptions
/// created while the bloc was alive (one per `on<E>` handler, plus the
/// provider's state-stream subscription). Those subscriptions live in the
/// FakeAsync test zone, so the done-delivery/cancellation work gets
/// parked in the fake microtask queue. Awaiting the cascade from inside
/// the fake zone deadlocks (the suspended body can never drain its own
/// queue); awaiting it in a single [WidgetTester.runAsync] deadlocks the
/// other way (the framework flushes the fake queue only after the
/// runAsync task has completed). So: start the close in the real zone
/// and pump the fake zone from inside the same runAsync callback — pump
/// is guarded, but the callback runs inside the test body's async scope,
/// so the nested guarded call is legal. Each pump drains the parked
/// done-delivery microtasks until the cascade completes.
Future<void> _closeBloc(WidgetTester tester, ScheduleBloc bloc) async {
  await tester.runAsync(() async {
    final closeFuture = bloc.close();
    int pumps = 0;
    for (; pumps < 20; pumps++) {
      try {
        await closeFuture.timeout(const Duration(milliseconds: 50));
        return;
      } on TimeoutException {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    throw StateError(
      'bloc.close() stalled after $pumps fake-zone drains; '
      'isClosed=${bloc.isClosed}',
    );
  });
}

/// Unmounts the tree (so the BlocProvider drops its subscription and
/// closes the bloc) and then closes [bloc] explicitly via [_closeBloc].
Future<void> _teardown(WidgetTester tester, ScheduleBloc bloc) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await _closeBloc(tester, bloc);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayGrid pull-to-refresh', () {
    testWidgets(
        'pull gesture dispatches GetScheduleEvent(forceRefresh: true)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      // A tile starting at 00:00 keeps the initial scroll at the very top,
      // where a downward overscroll (pull) triggers the RefreshIndicator.
      final tiles = <SubCalendarEvent>[
        _tile('top', DateTime(2026, 5, 15, 0, 0), DateTime(2026, 5, 15, 1, 0)),
      ];
      await tester.pumpWidget(_buildApp(bloc: bloc, tiles: tiles));
      await tester.pump(); // post-frame: initial scroll lands at 0.

      await tester.drag(find.byType(DayGridWidget), const Offset(0, 300));
      await tester.pump(); // release: indicator fires onRefresh.
      await tester.pump(const Duration(milliseconds: 400));

      final dispatches = bloc.events.whereType<GetScheduleEvent>().toList();
      expect(dispatches, isNotEmpty, reason: 'pull must dispatch an event');
      expect(dispatches.first.forceRefresh, isTrue);
      await _teardown(tester, bloc);
    });
  });

  group('DayGrid now-line', () {
    final injectedNow = DateTime(2026, 5, 15, 14, 30);

    testWidgets('renders only for the current day', (tester) async {
      final bloc = _RecordingScheduleBloc();
      // Grid day == injected clock date -> now-line + bubble visible.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: <SubCalendarEvent>[
          _tile('a', DateTime(2026, 5, 15, 8), DateTime(2026, 5, 15, 9)),
        ],
        now: injectedNow,
      ));
      await tester.pump();
      expect(find.byKey(_nowLineKey), findsOneWidget);
      expect(find.byKey(_nowBubbleKey), findsOneWidget);

      // Grid day != injected clock date -> no now-line.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: <SubCalendarEvent>[
          _tile('b', DateTime(2026, 5, 16, 8), DateTime(2026, 5, 16, 9)),
        ],
        now: injectedNow,
      ));
      await tester.pump();
      expect(find.byKey(_nowLineKey), findsNothing);
      expect(find.byKey(_nowBubbleKey), findsNothing);
      await _teardown(tester, bloc);
    });

    testWidgets('sits at the injected clock position', (tester) async {
      final bloc = _RecordingScheduleBloc();
      // Default controller: 80 px/h.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        tiles: <SubCalendarEvent>[
          _tile('a', DateTime(2026, 5, 15, 8), DateTime(2026, 5, 15, 9)),
        ],
        now: injectedNow,
      ));
      await tester.pump();

      final line = tester.widget<Positioned>(find.byKey(_nowLineKey));
      final expectedTop = (14 + 30 / 60.0) * 80.0; // 1160.0
      expect(line.top, moreOrLessEquals(expectedTop, epsilon: 0.001));
      await _teardown(tester, bloc);
    });

    testWidgets('minute timer is cancelled on dispose', (tester) async {
      final bloc = _RecordingScheduleBloc();
      // No `now` override -> the live minute timer runs.
      final today = DateTime.now();
      final tiles = <SubCalendarEvent>[
        _tile(
          'a',
          DateTime(today.year, today.month, today.day, 8),
          DateTime(today.year, today.month, today.day, 9),
        ),
      ];
      await tester.pumpWidget(_buildApp(bloc: bloc, tiles: tiles));
      await tester.pump();

      // Unmount the grid.
      await tester.pumpWidget(const SizedBox.shrink());
      // A leaked periodic timer would fire here and fail the test
      // (pending timer / setState on an unmounted State).
      await tester.pump(const Duration(minutes: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _closeBloc(tester, bloc);
    });
  });
}