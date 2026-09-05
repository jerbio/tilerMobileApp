// Constructor refactor + rebuild hardening.
//
// Regression set for the old `DayGridWidget` (which took a `PeekDay` and
// accumulated tile widgets in state lists during `build`):
//   1. duplicate tiles on every rebuild / after tap-select,
//   2. no reaction to a new tile list (didUpdateWidget),
//   3. in-place sort mutating the caller's list,
//   4. unclamped initial scroll-jump (debug assertion),
//   5. forecast path (DayCast) no longer renders.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/dayCast.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({required Widget child, bool withScaffold = true}) {
    final body = withScaffold ? Scaffold(body: child) : child;
    return MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: body,
    );
  }

  SubCalendarEvent buildTile({
    required String id,
    required String name,
    required DateTime start,
    required DateTime end,
  }) {
    return SubCalendarEvent(
      id: id,
      name: name,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
    );
  }

  /// Grid in a fixed 400x600 viewport (so scroll math is deterministic).
  Widget gridViewport(List<SubCalendarEvent> tiles) {
    return SizedBox(
      width: 400,
      height: 600,
      child: DayGridWidget(tiles: tiles),
    );
  }

  group('DayGridWidget rebuild safety', () {
    testWidgets('tile count stays stable across rebuilds (no duplicates)',
        (tester) async {
      final tiles = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 9)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 11)),
        buildTile(
            id: 'c',
            name: 'Gamma',
            start: DateTime(2026, 5, 15, 12),
            end: DateTime(2026, 5, 15, 13)),
      ];

      // A setState-driven parent (the shape of the real host) — each
      // build hands the grid a fresh widget instance with the same data.
      late void Function() rebuildGrid;
      await tester.pumpWidget(
          buildTestApp(child: StatefulBuilder(builder: (context, setState) {
        rebuildGrid = () => setState(() {});
        return gridViewport(tiles);
      })));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TileGridWidget), findsNWidgets(3));

      // Rebuild #2: same data, fresh DayGridWidget instance.
      rebuildGrid();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TileGridWidget), findsNWidgets(3));

      // Rebuild #3: must still be exactly 3.
      rebuildGrid();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TileGridWidget), findsNWidgets(3));
    });

    testWidgets('tap-select opens the preview sheet without duplicating tiles',
        (tester) async {
      final tiles = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 9)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 11)),
        buildTile(
            id: 'c',
            name: 'Gamma',
            start: DateTime(2026, 5, 15, 12),
            end: DateTime(2026, 5, 15, 13)),
      ];

      await tester.pumpWidget(buildTestApp(child: gridViewport(tiles)));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Alpha' (it sits at the 8am scroll position).
      await tester.tap(find.text('Alpha'));
      await tester.pump(); // open the bottom sheet
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PreviewDetailsTileWidget), findsOneWidget);
      // The tap must NOT add a second 'Alpha' tile to the grid.
      // (Scope to the grid: the bottom sheet shows the tile name too.)
      final inGrid = find.descendant(
          of: find.byType(DayGridWidget), matching: find.text('Alpha'));
      expect(find.byType(TileGridWidget), findsNWidgets(3));
      expect(inGrid, findsOneWidget);

      // Tap a second tile — still no duplicates.
      await tester.tap(find.text('Beta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TileGridWidget), findsNWidgets(3));
    });
    testWidgets('didUpdateWidget: added tile renders, removed tile is gone',
        (tester) async {
      final a = buildTile(
          id: 'a',
          name: 'Alpha',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 15, 9));
      final b = buildTile(
          id: 'b',
          name: 'Beta',
          start: DateTime(2026, 5, 15, 10),
          end: DateTime(2026, 5, 15, 11));
      final c = buildTile(
          id: 'c',
          name: 'Gamma',
          start: DateTime(2026, 5, 15, 12),
          end: DateTime(2026, 5, 15, 13));

      // setState-driven parent: the grid element is UPDATED (didUpdateWidget)
      // when the tile list changes.
      List<SubCalendarEvent> tiles = [a, b];
      late void Function(List<SubCalendarEvent>) setTiles;
      await tester.pumpWidget(
          buildTestApp(child: StatefulBuilder(builder: (context, setState) {
        setTiles =
            (List<SubCalendarEvent> next) => setState(() => tiles = next);
        return gridViewport(tiles);
      })));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      // New list: B stays, C arrives, A is removed. With enter/exit
      // animations a removed tile fades out as a short-lived ghost before it
      // is dropped — it is no longer gone on the very next frame.
      setTiles([b, c]);
      await tester.pump();
      // C eases in (live) while A fades out (ghost). During the fade the
      // ghost is still present: 2 live tiles + 1 ghost = 3 TileGridWidgets.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget,
          reason: 'removed tile fades out as a ghost before being dropped');
      expect(find.byType(TileGridWidget), findsNWidgets(3));

      // Once the fade + drop timer elapse, the ghost is gone: exactly the 2
      // live tiles remain.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Alpha'), findsNothing);
      expect(find.byType(TileGridWidget), findsNWidgets(2));
    });

    testWidgets('build does not mutate the input list order', (tester) async {
      final a = buildTile(
          id: 'a',
          name: 'Alpha',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 15, 9));
      final b = buildTile(
          id: 'b',
          name: 'Beta',
          start: DateTime(2026, 5, 15, 10),
          end: DateTime(2026, 5, 15, 11));
      final c = buildTile(
          id: 'c',
          name: 'Gamma',
          start: DateTime(2026, 5, 15, 12),
          end: DateTime(2026, 5, 15, 13));

      // Deliberately out of time order.
      final input = <SubCalendarEvent>[c, a, b];
      final originalOrder = input.map((t) => t.id).toList();

      await tester.pumpWidget(buildTestApp(child: gridViewport(input)));
      await tester.pump(const Duration(milliseconds: 100));

      // Caller's list must be untouched after the builds.
      expect(input.map((t) => t.id).toList(), originalOrder);

      // Render order IS time-sorted: Alpha above Beta above Gamma.
      final alphaTop = tester.getTopLeft(find.text('Alpha')).dy;
      final betaTop = tester.getTopLeft(find.text('Beta')).dy;
      final gammaTop = tester.getTopLeft(find.text('Gamma')).dy;
      expect(alphaTop, lessThan(betaTop));
      expect(betaTop, lessThan(gammaTop));
    });
    testWidgets('initial scroll target is clamped to the scrollable range',
        (tester) async {
      // First tile at 20:00 → target = 20h * 80px = 1600px.
      // Content = 24h * 80px = 1920px; viewport = 600px → max 1320px.
      final lateTile = buildTile(
          id: 'late',
          name: 'Late',
          start: DateTime(2026, 5, 15, 20),
          end: DateTime(2026, 5, 15, 21));

      await tester.pumpWidget(buildTestApp(child: gridViewport([lateTile])));
      await tester.pump(const Duration(milliseconds: 100));

      final scrollable = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final controller = scrollable.controller!;
      expect(controller.hasClients, isTrue);
      expect(controller.position.hasContentDimensions, isTrue);
      // Must be clamped to the end of the range — never past it.
      expect(controller.position.pixels,
          lessThanOrEqualTo(controller.position.maxScrollExtent));
      expect(controller.position.pixels, 1320);
    });

    testWidgets('grid with no tiles renders the 24-hour gutter',
        (tester) async {
      await tester.pumpWidget(buildTestApp(child: gridViewport([])));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TileGridWidget), findsNothing);
      // 24 time labels (hour rows are plain Containers).
      expect(find.byType(TimeOfDayTimeCellWidget), findsNWidgets(24));
    });
  });

  group('DayCast forecast path', () {
    testWidgets('still renders the day grid after geolocation resolves',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // DayCast.initState awaits Geolocator; mock the channel so `source`
      // resolves without real permissions. (geolocator 13x uses the
      // baseflow channel; checkPermission returns the enum index —
      // 2 = LocationPermission.whileInUse.)
      final binding = tester.binding;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (call) async {
          switch (call.method) {
            case 'isLocationServiceEnabled':
              return true;
            case 'checkPermission':
            case 'requestPermission':
              return 2; // LocationPermission.whileInUse
            case 'getCurrentPosition':
              return <String, dynamic>{
                'latitude': 37.33,
                'longitude': -122.03,
                'accuracy': 10.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'timestamp': 0,
                'is_mocked': false,
              };
            default:
              return null;
          }
        },
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_maps_flutter'),
        (call) async {
          if (call.method == 'create') {
            return 1; // map view id
          }
          return null;
        },
      );

      final peekDay = PeekDay(
        startTime: DateTime(2026, 5, 15).millisecondsSinceEpoch,
        endTime: DateTime(2026, 5, 16).millisecondsSinceEpoch,
      );
      peekDay.subEvents = <SubCalendarEvent>[
        buildTile(
            id: 'a',
            name: 'Alpha',
            start: DateTime(2026, 5, 15, 8),
            end: DateTime(2026, 5, 15, 9)),
        buildTile(
            id: 'b',
            name: 'Beta',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 11)),
      ];

      await tester.pumpWidget(
          buildTestApp(child: DayCast(peekDay), withScaffold: false));
      // First frame: geolocation spinner.
      await tester.pump();
      // Flush the mocked geolocation + setState(source) + grid build.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.byType(DayGridWidget), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });
  });
}
