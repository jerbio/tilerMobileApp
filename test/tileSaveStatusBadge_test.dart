// Overlay-only drag-commit save badge — `TileSaveStatus`.
//
// The badge is a small `Positioned` chip inside a `Stack` that the tile body
// is wrapped in ONLY when the status is non-idle. Because the body is the
// top-left, non-positioned child of the Stack, the tile's size, caption,
// overlap layout and drag hit-testing are untouched — the badge is purely
// visual. `saving` shows a spinner (a Ticker that must be gone at teardown),
// `saved` a check, `error` a warning, and `idle` renders nothing.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

SubCalendarEvent _tile(String id, DateTime start, DateTime end) {
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  t.isViable = true;
  t.thirdpartyType = TileSource.tiler;
  t.split = 1;
  return t;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 360,
        height: 800,
        // `TileGridWidget` is a GridPositionableWidget whose root is an
        // AnimatedPositioned (a Positioned), so it must sit directly inside
        // a Stack (the same containment the real DayGrid provides).
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // An opaque full-area backdrop so the tile's origin is a stable,
            // non-anchored point in the Stack.
            Positioned(
              left: 0,
              top: 0,
              width: 360,
              height: 800,
              child: const ColoredBox(color: Colors.white),
            ),
            // The tile: its own AnimatedPositioned places it at
            // (left, top) within this Stack.
            child,
          ],
        ),
      ),
    ),
  );
}

TileGridWidget _grid(TileSaveStatus status) {
  return TileGridWidget(
    key: const Key('tile'),
    tilerEvent:
        _tile('a', DateTime(2027, 1, 15, 9), DateTime(2027, 1, 15, 10)),
    pxPerHour: 80,
    dayStart: DateTime(2027, 1, 15),
    left: 40,
    saveStatus: status,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A fixed anchor in the caption: the top-left of the tile's name text.
  // The badge is an overlay, so this must NOT move between statuses.
  Offset _captionTopLeft(WidgetTester tester) =>
      tester.getTopLeft(find.text('a'));

  group('TileSaveStatus badge (overlay-only)', () {
    testWidgets('idle renders no badge, no spinner', (tester) async {
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.idle)));
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('saving renders a spinner badge', (tester) async {
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.saving)));
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(); // let the spinner's Ticker settle.
    });

    testWidgets('saved renders a check badge, no spinner', (tester) async {
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.saved)));
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('error renders a warning badge, no spinner', (tester) async {
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.error)));
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('badge is overlay-only: the caption never shifts',
        (tester) async {
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.idle)));
      final baseline = _captionTopLeft(tester);

      for (final status in TileSaveStatus.values) {
        await tester.pumpWidget(_wrap(_grid(status)));
        await tester.pump();
        expect(_captionTopLeft(tester), baseline,
            reason: 'the caption must not move for $status');
      }

      // Back to idle: the badge is gone and the caption is still put.
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.idle)));
      await tester.pump();
      expect(find.byKey(const Key('daygrid_tile_save_badge')), findsNothing);
      expect(_captionTopLeft(tester), baseline);
    });

    testWidgets('the spinner is disposed (no active Ticker at teardown)',
        (tester) async {
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.saving)));
      await tester.pump(); // the Ticker is running.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Replace with a static badge — the spinner's Ticker must stop.
      await tester.pumpWidget(_wrap(_grid(TileSaveStatus.saved)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // A couple of settled frames: no pending ticker should remain.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}