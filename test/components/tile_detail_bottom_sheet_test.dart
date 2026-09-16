import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileDetailBottomSheet.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

/// Build a [SubCalendarEvent] with an explicit time range. When [active] is
/// true the range straddles the current time (so `isCurrentTimeWithin` is
/// true and the time scrub should render); otherwise it is a future event.
SubCalendarEvent _event(
    {bool active = false,
    String? name = 'Test Event',
    String? address}) {
  final now = DateTime.now();
  final start = active
      ? now.subtract(const Duration(minutes: 30))
      : now.add(const Duration(hours: 5));
  final end = start.add(const Duration(hours: 1));
  final event = SubCalendarEvent(
    id: 'evt-1',
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    address: address,
  );
  event.isTardy = active;
  return event;
}

/// Wrap [child] in a [MaterialApp] carrying the app's localization delegates
/// (the duration badge and other strings require `AppLocalizations`).
Widget _harness(Widget child) {
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

/// The pushed EditTile route reads the schedule providers, so the tap-out
/// tests provide one above the MaterialApp (like the grid's sheet tests).
class _NoopScheduleBloc extends ScheduleBloc {
  _NoopScheduleBloc() : super(getContextCallBack: () => null);
}

void main() {
  group('compact list tile (EnhancedTileCard compact: true)', () {
    testWidgets('renders at the fixed compact height with name + time only',
        (tester) async {
      final event = _event();
      await tester.pumpWidget(_harness(
        Center(child: EnhancedTileCard(subEvent: event, compact: true)),
      ));
      await tester.pump();

      final size = tester
          .getSize(find.byKey(const ValueKey('enhancedTileCardCompactOpacity')));
      // height = compactListTileHeight + vertical margin (4 * 2).
      expect(size.height, TileDimensions.compactListTileHeight + 8);

      // Name is shown (single line).
      expect(find.text('Test Event'), findsOneWidget);
      // The full-detail PlayBack controls are NOT in the compact card.
      expect(find.byType(PlayBack), findsNothing);
    });

    testWidgets('tapping the compact tile invokes the onTileTap handler',
        (tester) async {
      final event = _event();
      int tapCount = 0;
      SubCalendarEvent? tappedEvent;
      await tester.pumpWidget(_harness(Builder(
        builder: (c) {
          return Center(
            child: EnhancedTileCard(
              subEvent: event,
              compact: true,
              onTileTap: () {
                tapCount++;
                tappedEvent = event;
              },
            ),
          );
        },
      )));
      await tester.pump();

      // The compact card does not carry the full-detail controls inline...
      expect(find.byType(PlayBack), findsNothing);

      // ...but tapping it routes through onTileTap (the caller wires this to
      // open the detail bottom sheet).
      await tester.tap(
          find.byKey(const ValueKey('enhancedTileCardCompactOpacity')));
      await tester.pump();

      expect(tapCount, 1);
      expect(tappedEvent, same(event));
    });

    testWidgets('shows an inline time scrub on the currently-active tile',
        (tester) async {
      final event = _event(active: true);
      await tester.pumpWidget(_harness(
        Center(child: EnhancedTileCard(subEvent: event, compact: true)),
      ));
      await tester.pump(); // frame 1: scrub initState's post-frame callback
      await tester.pump(); // frame 2: that setState renders the scrub

      // The active tile is taller than a plain compact tile (header + scrub).
      final size = tester
          .getSize(find.byKey(const ValueKey('enhancedTileCardCompactOpacity')));
      expect(size.height, TileDimensions.compactListTileHeightActive + 8);

      // ...and carries an inline time-scrub strip so it's easy to spot...
      expect(find.byType(TimeScrubWidget), findsOneWidget);
      // ...while the full PlayBack controls stay in the detail sheet.
      expect(find.byType(PlayBack), findsNothing);

      // Tear down: unmount to dispose the scrub's repeating controller/timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('keeps the inline scrub flush with the tile name',
        (tester) async {
      final event = _event(active: true);
      await tester.pumpWidget(_harness(
        Center(child: EnhancedTileCard(subEvent: event, compact: true)),
      ));
      await tester.pump(); // frame 1: scrub post-frame callback
      await tester.pump(); // frame 2: render the scrub strip

      final nameLeft = tester.getTopLeft(find.text('Test Event')).dx;
      final trackLeft = tester
          .getTopLeft(find.byKey(const ValueKey('timeScrubTrack')))
          .dx;

      // The scrub's leading edge is flush with the name's leading edge.
      expect(trackLeft, closeTo(nameLeft, 1.0));

      // Tear down: unmount to dispose the scrub's repeating controller/timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets(
        'keeps the inline scrub flush with the location badge on the right',
        (tester) async {
      final event = _event(active: true, address: '123 Main St');
      await tester.pumpWidget(_harness(
        Center(child: EnhancedTileCard(subEvent: event, compact: true)),
      ));
      await tester.pump(); // frame 1: scrub post-frame callback
      await tester.pump(); // frame 2: render the scrub strip

      final trackRight = tester
          .getTopRight(find.byKey(const ValueKey('timeScrubTrack')))
          .dx;
      final badgeRight = tester
          .getTopRight(
            find.byKey(const ValueKey('compactTileLocationButton')),
          )
          .dx;

      // The scrub's trailing edge lines up with the badge's trailing edge
      // (both anchored to the tile's right edge).
      expect(trackRight, closeTo(badgeRight, 1.0));

      // Tear down: unmount to dispose the scrub's repeating controller/timer.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets(
        'shows a tappable location/video button right of the name only when a '
        'location is present', (tester) async {
      // With a location => the button is present and sits to the right of,
      // and on the same row as, the name.
      await tester.pumpWidget(_harness(
        Center(
          child:
              EnhancedTileCard(subEvent: _event(address: '123 Main St'), compact: true),
        ),
      ));
      await tester.pump();

      final nameRect = tester.getRect(find.text('Test Event'));
      final buttonFinder =
          find.byKey(const ValueKey('compactTileLocationButton'));
      expect(buttonFinder, findsOneWidget);
      final btnRect = tester.getRect(buttonFinder);

      expect(btnRect.left, greaterThan(nameRect.left));
      expect(btnRect.center.dy, closeTo(nameRect.center.dy, 2.0));

      // The badge is labeled (location text + open-in-new glyph), like the
      // bottom sheet's location badge.
      expect(find.text('123 Main St'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);

      // Without a location => no button.
      await tester.pumpWidget(_harness(
        Center(child: EnhancedTileCard(subEvent: _event(), compact: true)),
      ));
      await tester.pump();
      expect(buttonFinder, findsNothing);
    });
  });

  group('tile detail bottom sheet (conditional time scrub)', () {
    testWidgets('renders the time scrub only when the tile is active',
        (tester) async {
      // Active event (straddles "now") => time scrub present.
      await tester.pumpWidget(
          _harness(TileDetailBottomSheet(subEvent: _event(active: true))));
      await tester.pump(); // frame 1: TimeScrub initState schedules a post-frame
      await tester.pump(); // frame 2: that post-frame setState renders
      expect(find.byType(PlayBack), findsOneWidget);
      expect(find.byType(TimeScrubWidget), findsOneWidget);

      // Future event (not active) => no time scrub.
      await tester.pumpWidget(
          _harness(TileDetailBottomSheet(subEvent: _event(active: false))));
      await tester.pump();
      expect(find.byType(PlayBack), findsOneWidget);
      expect(find.byType(TimeScrubWidget), findsNothing);

      // Tear down (disposes the scrub's timer) and drain any scheduled frame.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('tile detail bottom sheet (tap-out, list parity with the grid)', () {
    Widget _sheetHarness(Widget child) {
      final scheduleBloc = _NoopScheduleBloc();
      final tileBloc = SubCalendarTileBloc(getContextCallBack: () => null);
      addTearDown(() async {
        await scheduleBloc.close();
        await tileBloc.close();
      });
      return MultiBlocProvider(
        providers: [
          BlocProvider<ScheduleBloc>.value(value: scheduleBloc),
          BlocProvider(create: (_) => tileBloc),
        ],
        child: _harness(child),
      );
    }

    Future<void> _openSheet(WidgetTester tester, SubCalendarEvent event,
        {bool preview = false}) async {
      await tester.pumpWidget(_sheetHarness(Builder(
        builder: (c) => Center(
          child: ElevatedButton(
            onPressed: () =>
                showTileDetailBottomSheet(c, event, preview: preview),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // sheet slide-in
      expect(find.byType(TileDetailBottomSheet), findsOneWidget);
    }

    testWidgets('tapping the sheet opens EditTile and closes the sheet',
        (tester) async {
      final event = _event(); // Tiler tile, id 'evt-1'
      await _openSheet(tester, event);

      // The whole body is the affordance — no dedicated button.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      final target = find.byKey(TileDetailBottomSheet.sheetEditTargetKey);
      expect(target, findsOneWidget);

      // Tap the sheet body away from the inner controls (top-left corner).
      final topLeft = tester.getTopLeft(target);
      debugPrint(
          'TDS: target size=${tester.getSize(target)} topLeft=$topLeft');
      await tester.tapAt(topLeft + const Offset(6, 6));
      await tester.pump(); // sheet pops + EditTile route pushes
      await tester.pump(const Duration(milliseconds: 400));
      debugPrint('TDS: sheet present='
          '${find.byType(TileDetailBottomSheet).evaluate().length}, edit='
          '${find.byType(EditTile).evaluate().length}');

      expect(find.byType(TileDetailBottomSheet), findsNothing,
          reason: 'the sheet closes before the edit flow opens');
      expect(find.byType(EditTile), findsOneWidget);
      final EditTile edit = tester.widget<EditTile>(find.byType(EditTile));
      expect(edit.tileId, 'evt-1');
    });

    testWidgets('a third-party tile resolves the edit id from thirdpartyId',
        (tester) async {
      final event = _event()
        ..thirdpartyType = TileSource.google
        ..thirdpartyId = 'gp-42';
      await _openSheet(tester, event);

      final target = find.byKey(TileDetailBottomSheet.sheetEditTargetKey);
      final topLeft = tester.getTopLeft(target);
      await tester.tapAt(topLeft + const Offset(6, 6));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EditTile), findsOneWidget);
      final EditTile edit = tester.widget<EditTile>(find.byType(EditTile));
      expect(edit.tileId, 'gp-42');
      expect(edit.tileSource, TileSource.google);
    });

    testWidgets('the TileCast preview sheet is NOT editable', (tester) async {
      await _openSheet(tester, _event(), preview: true);

      expect(find.byKey(TileDetailBottomSheet.sheetEditTargetKey), findsNothing);
      final topLeft = tester.getTopLeft(find.byType(TileDetailBottomSheet));
      await tester.tapAt(topLeft + const Offset(6, 6));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EditTile), findsNothing);
      expect(find.byType(TileDetailBottomSheet), findsOneWidget,
          reason: 'a read-only sheet stays open');
    });
  });
}