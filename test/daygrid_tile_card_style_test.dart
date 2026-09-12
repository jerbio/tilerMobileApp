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
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
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
      // 30 min at 80 px/h = 40 px: above the 16 px caption threshold, below
      // the 48 px time-range threshold (the compact tier).
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

  group('tile detail sheet (tap-out)', () {
    Widget sheetApp(ScheduleBloc bloc, DayGridController controller,
        List<SubCalendarEvent> tiles,
        {required DateTime? day, bool preview = false}) {
      // Providers ABOVE MaterialApp so the pushed EditTile route sees them.
      return MultiBlocProvider(
        providers: [
          BlocProvider<ScheduleBloc>.value(value: bloc),
          BlocProvider(
              create: (_) =>
                  SubCalendarTileBloc(getContextCallBack: () => null)),
        ],
        child: MaterialApp(
          theme: TileThemeData.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DayGridWidget(
              tiles: tiles,
              now: DateTime(2026, 5, 15, 14, 30),
              day: day,
              controller: controller,
              preview: preview,
            ),
          ),
        ),
      );
    }

    Future<void> openSheet(WidgetTester tester, String tileName) async {
      await tester.tap(find.text(tileName));
      // The sheet body carries a repeating animation, so settle by time.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PreviewDetailsTileWidget), findsOneWidget);
    }

    testWidgets(
        'on the live grid, tapping anywhere on the detail sheet opens EditTile',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tile = _tile('editable', dayStart.add(const Duration(hours: 4)),
          dayStart.add(const Duration(hours: 6)))
        ..thirdpartyType = TileSource.tiler;
      await tester.pumpWidget(sheetApp(bloc, controller, [tile], day: dayStart));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await openSheet(tester, 'editable');
      // No pencil: the sheet itself is the affordance.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      final target = find.byKey(TileGridWidgetState.sheetEditTargetKey);
      expect(target, findsOneWidget);

      // Tap the details body (not a dedicated button).
      await tester.tap(find.byType(PreviewDetailsTileWidget));
      await tester.pump(); // sheet pops + EditTile route pushes
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PreviewDetailsTileWidget), findsNothing,
          reason: 'the sheet closes before the edit flow opens');
      expect(find.byType(EditTile), findsOneWidget);
      final EditTile edit = tester.widget<EditTile>(find.byType(EditTile));
      expect(edit.tileId, 'editable');
      expect(edit.tileSource, TileSource.tiler);

      await tester.pump(const Duration(milliseconds: 300));
      await _closeBloc(tester, bloc);
    });

    testWidgets('the forecast peek (no day) sheet is NOT editable',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tile = _tile('forecast', dayStart.add(const Duration(hours: 4)),
          dayStart.add(const Duration(hours: 6)))
        ..thirdpartyType = TileSource.tiler;
      // DayCast builds the grid without `day` (read-only peek).
      await tester.pumpWidget(sheetApp(bloc, controller, [tile], day: null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await openSheet(tester, 'forecast');
      expect(find.byKey(TileGridWidgetState.sheetEditTargetKey), findsNothing);
      await tester.tap(find.byType(PreviewDetailsTileWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(EditTile), findsNothing);
      expect(find.byType(PreviewDetailsTileWidget), findsOneWidget,
          reason: 'a read-only sheet stays open');
      await _closeBloc(tester, bloc);
    });

    testWidgets('the TileCast preview sheet is NOT editable', (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      final tile = _tile('previewed', dayStart.add(const Duration(hours: 4)),
          dayStart.add(const Duration(hours: 6)))
        ..thirdpartyType = TileSource.tiler;
      await tester.pumpWidget(
          sheetApp(bloc, controller, [tile], day: dayStart, preview: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await openSheet(tester, 'previewed');
      expect(find.byKey(TileGridWidgetState.sheetEditTargetKey), findsNothing);
      await tester.tap(find.byType(PreviewDetailsTileWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(EditTile), findsNothing);
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
