//
// TileCast read-only day-grid preview: analyzer-clean and passing by exercising
// `DayGridWidget` in preview mode directly (the lightweight, tile-list-free
// path) instead of the heavier live `ScheduleBloc` / `VibeChatBloc` tile-list
// path.
//
// Preview parity under test:
//   * `DayGridPage.previewGridTiles` keeps non-viable tiles; the live
//     `DayGridPage.gridTiles` selector drops them.
//   * `DayGridWidget.tileMatchesAction` matches the selected action's entity id
//     to a tile id (the dotted-border highlight rule shared with the list).
//   * In preview mode the grid renders a non-viable tile, the selected action's
//     tile is visible without manual scrolling (grid tiles build eagerly and the
//     grid auto-scrolls it into view), and exactly one tile is raised to the
//     dotted-border (`DashedBorderPainter`) treatment when a selected action
//     exists -- zero when none is selected.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart'; // DashedBorderPainter
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart'; // gridTiles / previewGridTiles
import 'package:tiler_app/data/subCalendarEvent.dart'; // SubCalendarEvent / RsvpStatus
import 'package:tiler_app/data/tilerEvent.dart'; // TileSource
import 'package:tiler_app/l10n/app_localizations.dart'; // AppLocalizations
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart'; // DayGridWidget / tileMatchesAction
import 'package:tiler_app/theme/theme_data.dart'; // TileThemeData

/// Builds a deterministic tiler [SubCalendarEvent] fixture: a 09:00-11:00 tile
/// on 2026-09-05 with the given id, viability flag, source and (optional) RSVP.
/// Tiler tiles carry [TileSource.tiler] so [SubCalendarEvent.isFromTiler] is
/// true (the grid selectors' RSVP filters then don't apply).
/// [SubCalendarEvent.isViable] and `thirdpartyType` are mutable fields (not
/// constructor parameters), so they are set post-construction.
SubCalendarEvent _makeTile(
  String id, {
  bool viable = true,
  TileSource source = TileSource.tiler,
  RsvpStatus? rsvp,
}) {
  final tile = SubCalendarEvent(
    id: id,
    name: 'Tile $id',
    start: DateTime(2026, 9, 5, 9).millisecondsSinceEpoch,
    end: DateTime(2026, 9, 5, 11).millisecondsSinceEpoch,
    rsvp: rsvp,
  );
  tile.thirdpartyType = source;
  tile.isViable = viable;
  return tile;
}

void main() {
  group('tileMatchesAction (preview highlight rule)', () {
    test('matches when the tile id contains the action entity id', () {
      final tile = _makeTile('evt_42');
      expect(DayGridWidget.tileMatchesAction(tile, 'evt_42'), isTrue);
    });

    test('does not match a different entity id', () {
      final tile = _makeTile('evt_42');
      expect(DayGridWidget.tileMatchesAction(tile, 'evt_999'), isFalse);
    });

    test('does not match when no action is selected', () {
      final tile = _makeTile('evt_42');
      expect(DayGridWidget.tileMatchesAction(tile, null), isFalse);
    });
  });

  group('preview vs live grid tile selection', () {
    test('previewGridTiles keeps non-viable tiles', () {
      final tiles = <SubCalendarEvent>[
        _makeTile('evt_viable', viable: true),
        _makeTile('evt_nonviable', viable: false),
      ];
      expect(DayGridPage.previewGridTiles(tiles).length, 2);
    });

    test('gridTiles drops non-viable tiles', () {
      final tiles = <SubCalendarEvent>[
        _makeTile('evt_viable', viable: true),
        _makeTile('evt_nonviable', viable: false),
      ];
      expect(DayGridPage.gridTiles(tiles).length, 1);
    });

    test('previewGridTiles drops declined third-party tiles', () {
      final tiles = <SubCalendarEvent>[
        _makeTile('evt_ok', viable: true),
        _makeTile(
          'evt_google_declined',
          viable: true,
          source: TileSource.google,
          rsvp: RsvpStatus.declined,
        ),
      ];
      expect(DayGridPage.previewGridTiles(tiles).length, 1);
    });
  });

  group('DayGridWidget preview mode (read-only)', () {
    setUp(() {
      // `DayGridWidget.initState` restores the last settled zoom from
      // SharedPreferences for a grid-owned controller; mock it so the preview
      // harness needs no live prefs.
      SharedPreferences.setMockInitialValues({});
    });

    /// Pumps [DayGridWidget] in read-only preview mode with a fixed clock and
    /// day, the production [TileThemeData.lightTheme] (which registers
    /// [TileThemeExtension]) and the app's localization delegates. No
    /// `ScheduleBloc` / `VibeChatBloc` is required -- the preview grid path is
    /// tile-list-free and builds eagerly.
    Widget _harness(List<SubCalendarEvent> tiles, {String? selectedEntityId}) {
      final fixedNow = DateTime(2026, 9, 5, 12);
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: TileThemeData.lightTheme,
        home: Scaffold(
          body: DayGridWidget(
            key: const ValueKey<String>('daygrid_preview'),
            tiles: tiles,
            now: fixedNow,
            day: DateTime(2026, 9, 5),
            preview: true,
            selectedActionEntityId: selectedEntityId,
          ),
        ),
      );
    }

    testWidgets('renders the day grid and a tile in preview mode',
        (tester) async {
      await tester.pumpWidget(_harness([_makeTile('evt_42', viable: true)]));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('daygrid_preview')),
          findsOneWidget);
      expect(find.text('Tile evt_42'), findsOneWidget);
    });

    testWidgets(
        'keeps non-viable tiles visible in preview mode', (tester) async {
      await tester.pumpWidget(_harness([_makeTile('evt_42', viable: false)]));
      await tester.pumpAndSettle();
      expect(find.text('Tile evt_42'), findsOneWidget);
    });

    testWidgets(
        'raises exactly one tile to the dotted border for the selected action',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          [
            _makeTile('evt_1', viable: true),
            _makeTile('evt_42', viable: true),
            _makeTile('evt_2', viable: true),
          ],
          selectedEntityId: 'evt_42',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tile evt_42'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is DashedBorderPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'raises no tile to the dotted border without a selected action',
        (tester) async {
      await tester.pumpWidget(
        _harness([
          _makeTile('evt_1', viable: true),
          _makeTile('evt_42', viable: true),
        ]),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is DashedBorderPainter,
        ),
        findsNothing,
      );
    });
  });
}