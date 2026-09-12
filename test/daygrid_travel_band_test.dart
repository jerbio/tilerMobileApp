// DayGrid travel/return bands: pure geometry (TravelBand.bandsForTile),
// DayGrid integration (keys, below-tiles ordering, fromTile, dayKey prefix,
// geometry) and tap-to-directions gating (valid destination -> onTap present;
// missing/default/home-return -> suppressed and non-intercepting).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/travelBandWidget.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  /// Pump a [DayGridWidget] in a fixed 400x600 viewport with a deterministic
  /// clock (avoids the live now-line timer and keeps the "is today" check
  /// stable for tiles on 2026-05-15).
  Future<void> pumpGrid(
    WidgetTester tester, {
    required List<SubCalendarEvent> tiles,
    DayGridController? controller,
    String? dayKey,
  }) async {
    await tester.pumpWidget(buildTestApp(
      child: SizedBox(
        width: 400,
        height: 600,
        child: DayGridWidget(
          tiles: tiles,
          controller: controller,
          dayKey: dayKey,
          now: DateTime(2026, 5, 15, 12, 0),
        ),
      ),
    ));
    // Let any one-shot animations settle.
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// A minimal grid tile. [id] doubles as the tile's [TilerEvent.uniqueId]
  /// (a plain `SubCalendarEvent` with no third-party id).
  SubCalendarEvent makeTile({
    required String id,
    required DateTime start,
    required DateTime end,
    double? travelTimeBefore,
    double? travelTimeAfter,
    TravelDetail? travelDetail,
    Location? location,
  }) {
    return SubCalendarEvent(
      id: id,
      name: id,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
    )
      ..travelTimeBefore = travelTimeBefore
      ..travelTimeAfter = travelTimeAfter
      ..travelDetail = travelDetail
      ..location = location;
  }

  /// A real, non-default (lat/long) location -> directions offered.
  Location realLocation() =>
      Location.fromLatitudeAndLongitude(latitude: 37.7, longitude: -122.4);

  /// The app default location (isDefault == true) -> no directions.
  Location defaultLocation() => Location.fromDefault();

  Finder bandFinder(String id, TravelBandKind kind) =>
      find.byKey(ValueKey<String>('daygrid_band_${id}_$kind'));

  /// The band's own [GestureDetector] -- the widget carrying the `onTap`
  /// gating (it is a child of the [TravelBandWidget], not an ancestor).
  Finder bandGestureDetector(String id, TravelBandKind kind) => find
      .descendant(
          of: bandFinder(id, kind), matching: find.byType(GestureDetector))
      .first;

  /// Pump a standalone [TravelBandWidget] with fixed geometry, decoupled from
  /// the DayGrid layout, so the expanded / icon thresholds are exact.
  TravelBandWidget bandWidget({
    required SubCalendarEvent tile,
    required TravelBandKind kind,
    required double height,
    double top = 0,
    double left = 40,
    double width = 300,
    SubCalendarEvent? fromTile,
  }) {
    return TravelBandWidget(
      key: ValueKey<String>('band_${kind.name}_${height.toInt()}'),
      tile: tile,
      kind: kind,
      top: top,
      height: height,
      left: left,
      width: width,
      fromTile: fromTile,
      animate: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Pure geometry: TravelBand.bandsForTile
  // ---------------------------------------------------------------------------

  group('TravelBand.bandsForTile', () {
    final dayStart = DateTime(2026, 5, 15);
    const msPerMin = 60 * 1000.0;

    test('pre band sits above the tile top with height(travelTimeBefore)', () {
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * msPerMin,
      );
      final bands = TravelBand.bandsForTile(
          tile: tile, dayStart: dayStart, pxPerHour: 80);

      expect(bands, hasLength(1));
      expect(bands[0].kind, TravelBandKind.pre);
      expect(bands[0].top, 760, reason: 'tile top (10h*80) minus 30m (40px)');
      expect(bands[0].height, 40);
    });

    test('post band sits below the tile bottom with height(travelTimeAfter)',
        () {
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeAfter: 30 * msPerMin,
      );
      final bands = TravelBand.bandsForTile(
          tile: tile, dayStart: dayStart, pxPerHour: 80);

      expect(bands, hasLength(1));
      expect(bands[0].kind, TravelBandKind.post);
      expect(bands[0].top, 880, reason: 'tile bottom (11h*80)');
      expect(bands[0].height, 40);
    });

    test('pre and post bands are both emitted, pre first', () {
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * msPerMin,
        travelTimeAfter: 45 * msPerMin,
      );
      final bands = TravelBand.bandsForTile(
          tile: tile, dayStart: dayStart, pxPerHour: 80);

      expect(bands, hasLength(2));
      expect(bands[0].kind, TravelBandKind.pre);
      expect(bands[1].kind, TravelBandKind.post);
      expect(bands[0].top, 760);
      expect(bands[0].height, 40);
      expect(bands[1].top, 880);
      expect(bands[1].height, 60);
    });

    test('post band crossing midnight clamps its bottom to the day end', () {
      // Ends 23:00 with 90m of return travel -> would run to 00:30 next day.
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 22, 0),
        end: DateTime(2026, 5, 15, 23, 0),
        travelTimeAfter: 90 * msPerMin,
      );
      final bands = TravelBand.bandsForTile(
          tile: tile, dayStart: dayStart, pxPerHour: 80);

      expect(bands, hasLength(1));
      final band = bands[0];
      expect(band.kind, TravelBandKind.post);
      expect(band.top, 1840, reason: '23h * 80');
      expect(band.height, 80,
          reason:
              '1h visible before midnight (the remainder belongs to the next day)');
    });

    test('pre band crossing midnight clamps its top to the day start', () {
      // Starts 01:00 with 3h of pre-travel -> would run to 22:00 previous day.
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 1, 0),
        end: DateTime(2026, 5, 15, 2, 0),
        travelTimeBefore: 3 * 60 * msPerMin,
      );
      final bands = TravelBand.bandsForTile(
          tile: tile, dayStart: dayStart, pxPerHour: 80);

      expect(bands, hasLength(1));
      final band = bands[0];
      expect(band.kind, TravelBandKind.pre);
      expect(band.top, 0, reason: 'clipped at midnight');
      expect(band.height, 80, reason: '1h * 80');
    });

    test('no bands when travel times are zero or null', () {
      expect(
          TravelBand.bandsForTile(
            tile: makeTile(
                id: 'a',
                start: DateTime(2026, 5, 15, 9),
                end: DateTime(2026, 5, 15, 10)),
            dayStart: dayStart,
            pxPerHour: 80,
          ),
          isEmpty);

      expect(
          TravelBand.bandsForTile(
            tile: makeTile(
              id: 'b',
              start: DateTime(2026, 5, 15, 9),
              end: DateTime(2026, 5, 15, 10),
              travelTimeBefore: 0,
              travelTimeAfter: 0,
            ),
            dayStart: dayStart,
            pxPerHour: 80,
          ),
          isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // DayGrid integration
  // ---------------------------------------------------------------------------

  group('DayGrid renders travel bands', () {
    testWidgets('valid tiles render their bands with the expected keys',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
        travelTimeAfter: 30 * 60 * 1000,
      );

      await pumpGrid(tester, tiles: [tile], controller: controller);

      expect(bandFinder('t1', TravelBandKind.pre), findsOneWidget);
      expect(bandFinder('t1', TravelBandKind.post), findsOneWidget);
    });

    testWidgets(
        'bands are positioned by their geometry (top/left/width/height)',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
      );

      await pumpGrid(tester, tiles: [tile], controller: controller);

      // Read the band's root AnimatedPositioned (mirrors the layout test's
      // approach of reading the tile's Positioned directly).
      final ap = tester.widget<AnimatedPositioned>(find.descendant(
          of: bandFinder('t1', TravelBandKind.pre),
          matching: find.byType(AnimatedPositioned)));

      const gutter = TileDimensions.timeOfDayCellWidth;
      expect(ap.top, 760);
      expect(ap.height, 40);
      // The gutter segment sits left of the tile column (left - gutterSpan)
      // and spans gutterSpan + column width.
      expect(ap.left, (gutter + 4) - TravelBandWidget.gutterSpan);
      expect(ap.width, (400 - gutter - 8) + TravelBandWidget.gutterSpan);
    });

    testWidgets('a dayKey prefixes the band key (tile keys do the same)',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
      );

      await pumpGrid(tester,
          tiles: [tile], controller: controller, dayKey: '2026-05-15');

      // With a dayKey the band key carries it, and the tile key does too.
      expect(
          find.byKey(const ValueKey<String>(
              'daygrid_band_day_2026-05-15_t1_TravelBandKind.pre')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('daygrid_tile_day_2026-05-15_t1')),
          findsOneWidget);
      // The bare (un-prefixed) key is absent while the prefix is in effect.
      expect(bandFinder('t1', TravelBandKind.pre), findsNothing);
    });

    testWidgets('bands render below the tile widgets in the grid Stack',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final tile = makeTile(
        id: 't1',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
      );

      await pumpGrid(tester, tiles: [tile], controller: controller);

      // Locate the body Stack: the one directly containing both the band and
      // the tile widgets (later children paint on top in a Stack).
      const bandKey = ValueKey<String>('daygrid_band_t1_TravelBandKind.pre');
      Stack? bodyStack;
      for (final stack in tester.widgetList<Stack>(find.byType(Stack))) {
        final hasBand = stack.children
            .any((w) => w is TravelBandWidget && w.key == bandKey);
        final hasTile = stack.children.any((w) => w is TileGridWidget);
        if (hasBand && hasTile) {
          bodyStack = stack;
          break;
        }
      }
      expect(bodyStack, isNotNull);

      final bandIndex = bodyStack!.children
          .indexWhere((w) => w is TravelBandWidget && w.key == bandKey);
      final tileIndex =
          bodyStack.children.indexWhere((w) => w is TileGridWidget);

      expect(bandIndex, isNonNegative);
      expect(tileIndex, isNonNegative);
      expect(bandIndex, lessThan(tileIndex),
          reason: 'bands must paint below the tiles so tiles stay tappable');
    });

    testWidgets('fromTile is passed only to the pre band (previous tile)',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final first = makeTile(
        id: 'a',
        start: DateTime(2026, 5, 15, 8, 0),
        end: DateTime(2026, 5, 15, 9, 0),
        travelTimeBefore: 30 * 60 * 1000,
      );
      final second = makeTile(
        id: 'b',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
        travelTimeAfter: 30 * 60 * 1000,
      );

      await pumpGrid(tester, tiles: [first, second], controller: controller);

      // The day's first tile has no previous tile -> fromTile is null.
      expect(
          tester
              .widget<TravelBandWidget>(bandFinder('a', TravelBandKind.pre))
              .fromTile,
          isNull);

      // The second tile's pre band points at the previous tile...
      expect(
          tester
              .widget<TravelBandWidget>(bandFinder('b', TravelBandKind.pre))
              .fromTile
              ?.id,
          'a');

      // ...and its post band carries no from tile.
      expect(
          tester
              .widget<TravelBandWidget>(bandFinder('b', TravelBandKind.post))
              .fromTile,
          isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Tap-to-directions gating
  // ---------------------------------------------------------------------------

  group('TravelBand tap gating', () {
    testWidgets('onTap is present when the destination is valid',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final tile = makeTile(
        id: 't',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
        location: realLocation(),
      );

      await pumpGrid(tester, tiles: [tile], controller: controller);

      final gesture = tester.widget<GestureDetector>(
          bandGestureDetector('t', TravelBandKind.pre));
      expect(gesture.onTap, isNotNull,
          reason: 'valid destination -> directions offered');
    });

    testWidgets('onTap is suppressed when there is no valid destination',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      // No destination anywhere.
      final missing = makeTile(
        id: 'm',
        start: DateTime(2026, 5, 15, 9, 0),
        end: DateTime(2026, 5, 15, 10, 0),
        travelTimeBefore: 30 * 60 * 1000,
      );
      // Default destination.
      final def = makeTile(
        id: 'd',
        start: DateTime(2026, 5, 15, 11, 0),
        end: DateTime(2026, 5, 15, 12, 0),
        travelTimeBefore: 30 * 60 * 1000,
        location: defaultLocation(),
      );

      await pumpGrid(tester, tiles: [missing, def], controller: controller);

      expect(
          tester
              .widget<GestureDetector>(
                  bandGestureDetector('m', TravelBandKind.pre))
              .onTap,
          isNull,
          reason: 'no destination -> no directions');
      expect(
          tester
              .widget<GestureDetector>(
                  bandGestureDetector('d', TravelBandKind.pre))
              .onTap,
          isNull,
          reason: 'default destination -> no directions');
    });

    testWidgets('a home-return post band suppresses onTap', (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      // A valid (non-null, non-default) home destination -- so it would be
      // tappable except for the home-return suppression.
      final home = Location.fromDefault()
        ..description = Location.homeLocationNickName
        ..isNull = false
        ..isDefault = false;
      final tile = makeTile(
        id: 'h',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeAfter: 30 * 60 * 1000,
        travelDetail: TravelDetail(
          after: TravelData(endLocation: home),
        ),
        location: realLocation(),
      );

      await pumpGrid(tester, tiles: [tile], controller: controller);

      final gesture = tester.widget<GestureDetector>(
          bandGestureDetector('h', TravelBandKind.post));
      expect(gesture.onTap, isNull,
          reason: 'home return -> no directions (ReturnConnector rule)');
    });

    testWidgets('a non-tappable band is not a directions target',
        (tester) async {
      final controller = DayGridController()..setPxPerHour(80);
      addTearDown(controller.dispose);
      final tile = makeTile(
        id: 'n',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeBefore: 30 * 60 * 1000,
      );

      await pumpGrid(tester, tiles: [tile], controller: controller);

      final gesture = tester.widget<GestureDetector>(
          bandGestureDetector('n', TravelBandKind.pre));
      expect(gesture.onTap, isNull,
          reason: 'no destination -> the band offers no directions');

      // Tapping the band region must not crash and must not report an
      // unhandled exception (there is no destination to launch).
      await tester.tap(bandFinder('n', TravelBandKind.pre),
          warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Zoom-aware expansion / icon / color thresholds
  // ---------------------------------------------------------------------------

  group('TravelBand expansion thresholds', () {
    // The band's root is an AnimatedPositioned, so it must live inside a
    // Stack to lay out. Wrap each standalone pump accordingly.
    Future<void> pumpBand(WidgetTester tester, TravelBandWidget band) async {
      await tester.pumpWidget(buildTestApp(
        child: SizedBox(
          width: 400,
          height: 600,
          child: Stack(children: [band]),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
    }

    SubCalendarEvent bandTile({String id = 't1'}) => makeTile(
          id: id,
          start: DateTime(2026, 5, 15, 10, 0),
          end: DateTime(2026, 5, 15, 11, 0),
          travelTimeBefore: 30 * 60 * 1000,
        );

    testWidgets('the full card (with the window line) only appears at height >= 56px',
        (tester) async {
      // Below the compact threshold: gutter tier -> no Text inside the band.
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 11,
          ));
      expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('band_pre_11')),
            matching: find.byType(Text),
          ),
          findsNothing);

      // Just below the full threshold: the compact card (title only).
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 55,
          ));
      expect(find.text('Travel • 30 min'), findsOneWidget);
      expect(find.textContaining('–'), findsNothing,
          reason: 'the window line is the full tier only');

      // At the threshold: the full card (title + window Texts) is shown.
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 56,
          ));
      expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('band_pre_56')),
            matching: find.byType(Text),
          ),
          findsWidgets);
    });

    testWidgets(
        'the travel-medium icon is always visible (min-height clamp)',
        (tester) async {
      // Below the icon threshold: the band's effective height is clamped
      // to 18px so the icon is still rendered (the band extends into the
      // gutter space above the tile for pre-bands).
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 17,
          ));
      expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('band_pre_17')),
            matching: find.byType(Icon),
          ),
          findsOneWidget);

      // At the threshold: the 14px gutter icon is rendered (not expanded,
      // so there is exactly one icon).
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 18,
          ));
      expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('band_pre_18')),
            matching: find.byType(Icon),
          ),
          findsOneWidget);
    });

    testWidgets(
        'at >= 56px the band is a full-column card (title + window), not a gutter icon',
        (tester) async {
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 56,
            left: 40,
            width: 300,
          ));
      final card = find.byKey(TravelBandWidget.cardKey);
      expect(card, findsOneWidget);
      // The card spans exactly the tile column (left..left+width): it is
      // drawn beneath the tiles and never enters the overlap layout.
      final Rect rect = tester.getRect(card);
      expect(rect.left, closeTo(40, 0.5));
      expect(rect.width, closeTo(300, 0.5));
      expect(rect.height, closeTo(56, 0.5));
      // Title + travel window (pre band: 09:30 -> 10:00).
      expect(find.text('Travel • 30 min'), findsOneWidget);
      expect(find.text('9:30 – 10:00 AM'), findsOneWidget);
      // The gutter hairline/icon tier is replaced, not stacked: the only
      // travel-medium icon is the one inside the card.
      final icons = tester
          .widgetList<Icon>(find.descendant(
            of: find.byKey(const ValueKey<String>('band_pre_56')),
            matching: find.byType(Icon),
          ))
          .toList();
      expect(icons.where((i) => i.icon != Icons.navigation_outlined),
          hasLength(1));
      expect(
          tester.getRect(find.byWidget(
              icons.firstWhere((i) => i.icon != Icons.navigation_outlined))),
          predicate<Rect>((r) => r.left >= 40, 'icon sits inside the column'));
    });

    testWidgets(
        'a compact single-line card from 12px real height; gutter icon below it',
        (tester) async {
      // 12px real (rendered at the 18px minimum): compact card in the column.
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 12,
            left: 40,
            width: 300,
          ));
      final card = find.byKey(TravelBandWidget.cardKey);
      expect(card, findsOneWidget);
      expect(tester.getRect(card).left, closeTo(40, 0.5));
      expect(tester.getRect(card).height, closeTo(18, 0.5));
      expect(find.text('Travel • 30 min'), findsOneWidget);

      // Below it: no card, the gutter icon only.
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 11,
          ));
      expect(find.byKey(TravelBandWidget.cardKey), findsNothing);
      final icon = tester.getRect(find.descendant(
        of: find.byKey(const ValueKey<String>('band_pre_11')),
        matching: find.byType(Icon),
      ));
      expect(icon.left, lessThan(40), reason: 'gutter icon sits left of the column');
    });

    testWidgets('a post band card shows the window after the tile',
        (tester) async {
      final tile = makeTile(
        id: 'p',
        start: DateTime(2026, 5, 15, 10, 0),
        end: DateTime(2026, 5, 15, 11, 0),
        travelTimeAfter: 24 * 60 * 1000,
      );
      await pumpBand(
          tester,
          bandWidget(tile: tile, kind: TravelBandKind.post, height: 60));
      expect(find.text('Travel • 24 min'), findsOneWidget);
      expect(find.text('11:00 – 11:24 AM'), findsOneWidget);
    });

    testWidgets('the band color follows the tardy rule', (tester) async {
      // Not tardy -> TileColors.travel.
      await pumpBand(
          tester,
          bandWidget(
            tile: bandTile(),
            kind: TravelBandKind.pre,
            height: 40,
          ));
      final normalIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey<String>('band_pre_40')),
        matching: find.byType(Icon),
      ));
      expect(normalIcon.color, TileColors.travel);

      // Tardy -> TileColors.late.
      final tardy = bandTile();
      tardy.isTardy = true;
      await pumpBand(
          tester,
          bandWidget(
            tile: tardy,
            kind: TravelBandKind.pre,
            height: 40,
          ));
      final tardyIcon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey<String>('band_pre_40')),
        matching: find.byType(Icon),
      ));
      expect(tardyIcon.color, TileColors.late);
    });
  });
}
