// DayGrid tile-card restyle (P6 Step 16.1 — pure paint).
//
// Covers:
//   * `TileCardStyle.from` — the pastel card palette derives from the tile
//     color (tinted background over `surface`, full-color accent bar) and
//     the theme (title / subtitle text colors).
//   * `TileCardStyle.compactTimeRange` — "4:00 AM" + "5:00 AM" renders as
//     "4:00 – 5:00 AM" (shared period collapsed); mixed periods and 24h
//     strings are left intact.
//   * C24: the grid tile card renders NO glyph even when the tile has an
//     address — location/meeting details belong to the tap-out bottom sheet.
//   * `SubCalendarEvent.isAllDay` — unit fix regression (ms vs µs); feeds the
//     pinned card's "All day" label.
//   * `TileGridWidgetState.tileTimeRangeVisible` — the second (time-range)
//     line needs more height than the name caption alone.
//   * Widget level: a tall tile renders name + time range + accent bar; a
//     tile between the caption and time-range thresholds renders the name
//     only; no glyph on a tile with an address; hour guide lines and gutter
//     labels use the neutral outline / variant tokens, not `primary`.
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
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileCardStyle.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records `ScheduleBloc` events WITHOUT running the [GetScheduleEvent]
/// handler (no API calls in tests). Same idiom as the adaptive suite.
class _RecordingScheduleBloc extends ScheduleBloc {
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    if (event is GetScheduleEvent) {
      return;
    }
    super.add(event);
  }
}

SubCalendarEvent _tile(String id, DateTime start, DateTime end,
    {String? address, Color? color}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    address: address,
  );
  tile.isViable = true;
  if (color != null) {
    tile.color = color;
  }
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
    throw StateError(
      'bloc.close() stalled after $pumps fake-zone drains; '
      'isClosed=${bloc.isClosed}',
    );
  });
}

Widget _buildApp({
  required ScheduleBloc bloc,
  required DayGridController controller,
  required List<SubCalendarEvent> tiles,
  DateTime? day,
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
          day: day,
          controller: controller,
        ),
      ),
    ),
  );
}

/// The tile card for [tileId].
Finder _tileCard(String tileId) => find.byWidgetPredicate(
      (w) => w is TileGridWidget && w.tilerEvent.id == tileId,
    );

/// The `Icon` widgets rendered INSIDE a tile card, so gutter / now-line
/// icons never leak into the count.
Finder _tileIcons(String tileId) =>
    find.descendant(of: _tileCard(tileId), matching: find.byType(Icon));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final dayStart = DateTime(2027, 1, 15);
  final scheme = TileThemeData.lightTheme.colorScheme;

  group('TileCardStyle.from (pure palette math)', () {
    test('background is the tile color tinted over surface, not the raw color',
        () {
      const tileColor = Color(0xFFFFC107);
      final style = TileCardStyle.from(tileColor, scheme);
      expect(
        style.background,
        Color.alphaBlend(
          tileColor.withValues(alpha: TileCardStyle.tintAlpha),
          scheme.surface,
        ),
      );
      expect(style.background, isNot(tileColor));
      // Opaque so side-by-side overlap columns never see through each other.
      expect(style.background.a, 1.0);
    });

    test('accent bar keeps the full tile color; text uses theme tokens', () {
      const tileColor = Color(0xFF2196F3);
      final style = TileCardStyle.from(tileColor, scheme);
      expect(style.accent, tileColor);
      expect(style.title, scheme.onSurface);
      expect(style.subtitle, scheme.onSurfaceVariant);
    });
  });

  group('TileCardStyle.compactTimeRange', () {
    test('collapses a shared AM/PM period onto the end time', () {
      expect(TileCardStyle.compactTimeRange('4:00 AM', '5:00 AM'),
          '4:00 – 5:00 AM');
    });
    test('keeps both periods when they differ', () {
      expect(TileCardStyle.compactTimeRange('11:00 AM', '12:30 PM'),
          '11:00 AM – 12:30 PM');
    });
    test('leaves 24h strings (no period token) intact', () {
      expect(TileCardStyle.compactTimeRange('16:00', '17:00'),
          '16:00 – 17:00');
    });
  });

  group('SubCalendarEvent.isAllDay (pinned card label source)', () {
    test('longer than the 16h active day is all day; exactly 16h is not', () {
      // Regression: the fallback used to compare ms against µs and was
      // effectively never true.
      expect(
          _tile('d', dayStart, dayStart.add(const Duration(hours: 24)))
              .isAllDay,
          isTrue);
      expect(
          _tile('e', dayStart, dayStart.add(const Duration(hours: 16)))
              .isAllDay,
          isFalse);
    });

    testWidgets('an all-day tile shows the "All day" trailing label',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DayGridPinnedHeader(tiles: [
            _tile('Labor Day', dayStart,
                dayStart.add(const Duration(hours: 24))),
          ]),
        ),
      ));
      await tester.pump();
      expect(find.text('Labor Day'), findsOneWidget);
      expect(find.text('All day'), findsOneWidget);
      expect(find.byKey(const Key('daygrid_pinned_card')), findsOneWidget);
    });
  });

  group('TileGridWidgetState.tileTimeRangeVisible', () {
    test('needs more height than the caption-only threshold', () {
      expect(TileGridWidgetState.timeRangeTileHeight,
          greaterThan(TileGridWidgetState.collapsedTileHeight));
      expect(
          TileGridWidgetState.tileTimeRangeVisible(
              TileGridWidgetState.timeRangeTileHeight - 1),
          isFalse);
      expect(
          TileGridWidgetState.tileTimeRangeVisible(
              TileGridWidgetState.timeRangeTileHeight),
          isTrue);
    });
  });

  group('tile card rendering', () {
    testWidgets('a tall tile renders name, time range and the accent bar',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tiles = [
        _tile('tall', dayStart.add(const Duration(hours: 4)),
            dayStart.add(const Duration(hours: 6))),
      ];
      await tester.pumpWidget(
          _buildApp(bloc: bloc, controller: controller, tiles: tiles));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('tall'), findsOneWidget);
      expect(find.text('4:00 – 6:00 AM'), findsOneWidget);
      expect(find.byKey(const Key('daygrid_tile_accent')), findsOneWidget);
      await _closeBloc(tester, bloc);
    });

    testWidgets(
        'a tile between the caption and time-range thresholds renders the name only',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      // 30 min at 80 px/h = 40 px: above the 32 px caption threshold, below
      // the time-range threshold.
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tiles = [
        _tile('short', dayStart.add(const Duration(hours: 4)),
            dayStart.add(const Duration(hours: 4, minutes: 30))),
      ];
      await tester.pumpWidget(
          _buildApp(bloc: bloc, controller: controller, tiles: tiles));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('short'), findsOneWidget);
      expect(find.textContaining('–'), findsNothing);
      await _closeBloc(tester, bloc);
    });

    testWidgets('no glyph on the card, even with an address (C24)',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tiles = [
        _tile('meeting', dayStart.add(const Duration(hours: 4)),
            dayStart.add(const Duration(hours: 5)),
            address: 'https://meet.google.com/abc'),
        _tile('plain', dayStart.add(const Duration(hours: 6)),
            dayStart.add(const Duration(hours: 7))),
      ];
      await tester.pumpWidget(
          _buildApp(bloc: bloc, controller: controller, tiles: tiles));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(_tileIcons('meeting'), findsNothing);
      expect(_tileIcons('plain'), findsNothing);
      await _closeBloc(tester, bloc);
    });
  });

  group('gutter restyle', () {
    testWidgets(
        'hour guide lines and labels use neutral tokens, not primary',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(
          bloc: bloc,
          controller: controller,
          tiles: [
            _tile('t', dayStart.add(const Duration(hours: 4)),
                dayStart.add(const Duration(hours: 5))),
          ]));
      await tester.pump();

      final lineContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(TileTimeCellWidget).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (lineContainer.decoration as BoxDecoration).border
          as Border;
      expect(border.top.color, scheme.outlineVariant);
      expect(border.top.color, isNot(scheme.primary));

      final label = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(TimeOfDayTimeCellWidget).first,
              matching: find.byType(Text),
            )
            .first,
      );
      expect(label.style?.color, scheme.onSurfaceVariant);
      await _closeBloc(tester, bloc);
    });
  });
}
