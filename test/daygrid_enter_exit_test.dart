// Added/removed slide-in / fade-out.
//
// A tile that is newly added slides in from a corner (fade + scale 0.86 -> 1,
// ~200ms); a tile that is removed fades out in place (a "ghost") before being
// dropped. Both are gated off while the controller is zooming/dragging and by
// `MediaQuery.disableAnimations`, and batched adds are staggered (<= 50ms each,
// capped ~400ms). The enter/exit opacity + scale targets are read off the
// `AnimatedOpacity` / `AnimatedScale` widgets that wrap each tile body (the
// `AnimatedPositioned` root is unchanged, so position tests elsewhere are
// unaffected).
//
// Like the position-transition test, `now` is fixed to a different day
// no now-line renders and the minute timer stays off (no pending-timer
// failures), so we can drive the animation with fixed-duration pumps.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  final DateTime day = DateTime(2026, 5, 15);
  // A clock on a different day than the grid day: no now-line, timer stays off.
  final DateTime now = DateTime(2026, 5, 16, 9);

  SubCalendarEvent alpha() => buildTile(
        id: 'a',
        name: 'Alpha',
        start: day.add(const Duration(hours: 8)),
        end: day.add(const Duration(hours: 9)),
      );
  SubCalendarEvent beta() => buildTile(
        id: 'b',
        name: 'Beta',
        start: day.add(const Duration(hours: 10)),
        end: day.add(const Duration(hours: 11)),
      );
  SubCalendarEvent gamma() => buildTile(
        id: 'c',
        name: 'Gamma',
        start: day.add(const Duration(hours: 11)),
        end: day.add(const Duration(hours: 12)),
      );

  Widget grid(
    List<SubCalendarEvent> tiles, {
    DayGridController? controller,
  }) {
    return SizedBox(
      width: 400,
      height: 600,
      child: DayGridWidget(
        tiles: tiles,
        controller: controller,
        dayKey: 'd1',
        now: now,
      ),
    );
  }

  /// Pumps the grid inside a persistent `StatefulBuilder` and returns a
  /// `rebuild` callback that re-renders with the (mutated) current tiles. The
  /// same element tree survives across rebuilds so element reuse (and the
  /// add/remove diff in `didUpdateWidget`) is observable.
  Future<void Function()> pumpGrid(
    WidgetTester tester,
    List<SubCalendarEvent> Function() tileSource, {
    DayGridController? controller,
    Widget Function(BuildContext, Widget)? wrap,
  }) async {
    late void Function() rebuild;
    await tester.pumpWidget(
      buildTestApp(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = () => setState(() {});
            final body = grid(tileSource(), controller: controller);
            return wrap?.call(context, body) ?? body;
          },
        ),
      ),
    );
    // Let the grid's post-frame initial-scroll callback run before measuring.
    await tester.pump();
    await tester.pump();
    return rebuild;
  }

  Finder opacityOf(String name) => find.ancestor(
      of: find.text(name), matching: find.byType(AnimatedOpacity));
  Finder scaleOf(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(AnimatedScale));

  group('DayGridWidget add/remove enter/exit', () {
    testWidgets('a newly-added tile slides in from a corner',
        (tester) async {
      List<SubCalendarEvent> tiles = [alpha()];
      final rebuild = await pumpGrid(tester, () => tiles);
      expect(find.text('Beta'), findsNothing);

      // Add Beta -> it mounts hidden (opacity 0, scale 0.86).
      tiles = [alpha(), beta()];
      rebuild();
      await tester.pump();
      expect(find.text('Beta'), findsOneWidget);
      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 0.0,
          reason: 'should start hidden');
      expect(tester.widget<AnimatedScale>(scaleOf('Beta')).scale,
          closeTo(0.86, 0.01),
          reason: 'should start from a corner scale');

      // Settle -> fully revealed (opacity 1, scale 1).
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 1.0);
      expect(
          tester.widget<AnimatedScale>(scaleOf('Beta')).scale,
          closeTo(1.0, 0.01));
    });

    testWidgets('a new tile appears immediately while zooming',
        (tester) async {
      final controller = DayGridController()..mode = DayGridMode.zooming;
      List<SubCalendarEvent> tiles = [alpha()];
      final rebuild = await pumpGrid(tester, () => tiles,
          controller: controller);

      tiles = [alpha(), beta()];
      rebuild();
      await tester.pump();

      // Not idle -> no hidden phase: fully visible from the first frame.
      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 1.0);
      expect(tester.widget<AnimatedScale>(scaleOf('Beta')).scale,
          closeTo(1.0, 0.01));
    });

    testWidgets('a new tile appears immediately under reduced motion',
        (tester) async {
      List<SubCalendarEvent> tiles = [alpha()];
      final rebuild = await pumpGrid(
        tester,
        () => tiles,
        wrap: (context, body) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: body,
        ),
      );

      tiles = [alpha(), beta()];
      rebuild();
      await tester.pump();

      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 1.0);
      expect(tester.widget<AnimatedScale>(scaleOf('Beta')).scale,
          closeTo(1.0, 0.01));
    });

    testWidgets('a batch of new tiles is staggered', (tester) async {
      List<SubCalendarEvent> tiles = [alpha()];
      final rebuild = await pumpGrid(tester, () => tiles);

      // Add two tiles in one frame: Beta (idx 0, delay 0) and
      // Gamma (idx 1, delay 40ms).
      tiles = [alpha(), beta(), gamma()];
      rebuild();
      await tester.pump();
      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 0.0);
      expect(tester.widget<AnimatedOpacity>(opacityOf('Gamma')).opacity, 0.0);

      // ~20ms in: Beta's 0ms delay has fired (revealed), Gamma's 40ms has not.
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 1.0,
          reason: 'first tile should reveal first');
      expect(tester.widget<AnimatedOpacity>(opacityOf('Gamma')).opacity, 0.0,
          reason: 'second tile should still be hidden');

      // Settle: both revealed.
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<AnimatedOpacity>(opacityOf('Gamma')).opacity, 1.0);
    });

    testWidgets('a removed tile fades out as a ghost, then is dropped',
        (tester) async {
      List<SubCalendarEvent> tiles = [alpha(), beta()];
      final rebuild = await pumpGrid(tester, () => tiles);
      expect(find.text('Beta'), findsOneWidget);

      // Remove Beta -> a ghost lingers at its spot (opacity target 1 first).
      tiles = [alpha()];
      rebuild();
      await tester.pump();
      expect(find.text('Beta'), findsOneWidget,
          reason: 'ghost should linger for the fade');
      expect(find.text('Alpha'), findsOneWidget);

      // The ghost begins fading (opacity target drops to 0).
      await tester.pump();
      expect(find.text('Beta'), findsOneWidget);
      expect(tester.widget<AnimatedOpacity>(opacityOf('Beta')).opacity, 0.0,
          reason: 'ghost opacity target should drop to 0');

      // After the fade + drop timer, the ghost is gone.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Beta'), findsNothing,
          reason: 'ghost should be dropped after the fade');
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('a removed tile drops immediately while zooming',
        (tester) async {
      final controller = DayGridController()..mode = DayGridMode.zooming;
      List<SubCalendarEvent> tiles = [alpha(), beta()];
      final rebuild = await pumpGrid(tester, () => tiles,
          controller: controller);
      expect(find.text('Beta'), findsOneWidget);

      // Not idle -> no ghost: the tile is removed outright.
      tiles = [alpha()];
      rebuild();
      await tester.pump();
      expect(find.text('Beta'), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
    });
  });
}