// DayGrid scroll host: a freshly mounted grid (a carousel day page sliding
// into view) must PAINT its first frame already at its initial auto-scroll
// target (the first tile hour), not at 12 AM and then jump post-frame — the
// ScrollController is created with that `initialScrollOffset`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

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

void _setSurface(WidgetTester tester) {
  final originalPhysicalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(1080, 2160); // logical 540 x 1080.
  addTearDown(() {
    tester.view.devicePixelRatio = originalDpr;
    tester.view.physicalSize = originalPhysicalSize;
  });
}

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
    throw StateError('bloc.close() stalled after $pumps drains');
  });
}

Widget _buildApp({
  required ScheduleBloc bloc,
  required DayGridController controller,
  required List<SubCalendarEvent> tiles,
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
        body: DayGridWidget(
          tiles: tiles,
          now: DateTime(2026, 5, 15, 14, 30),
          day: DateTime(2027, 1, 15),
          dayKey: 'd',
          controller: controller,
        ),
      ),
    ),
  );
}

ScrollController _scrollControllerOf(WidgetTester tester) => tester
    .widget<CustomScrollView>(find.byType(CustomScrollView))
    .controller!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final day = DateTime(2027, 1, 15);

  group('DayGrid initial scroll lands on the FIRST frame (no post-frame jump)',
      () {
    testWidgets(
        'the scroll controller is created at the first-tile-hour offset',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController(); // 80 px/h
      addTearDown(controller.dispose);
      // A carousel day page sliding into view mounts fresh: its first
      // painted frame must already be at 9 AM (720 px), not at 12 AM.
      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: [
          _tile('nine', day.add(const Duration(hours: 9)),
              day.add(const Duration(hours: 10))),
        ],
      ));

      final scrollController = _scrollControllerOf(tester);
      expect(scrollController.initialScrollOffset, 720.0,
          reason: 'the initial offset is baked into the controller, so the '
              'very first layout is at the target — no visible jump');
      expect(scrollController.position.pixels, 720.0);
      await _closeBloc(tester, bloc);
    });
  });
}
