// P8 (A): blocks vs tiles are told apart by a small lock glyph on the
// block's caption — grid card (caption tiers) and compact list card —
// matching the full list card's existing `lock_outline`; the filter's
// `Blocks` segment carries the same glyph so the control doubles as the
// legend. Both kinds share the same solid accent bar (a dashed tile bar was
// tried and rejected: stacked rounded cards with segmented edges scallop).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tileUI/tileAccentBar.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

class _RecordingScheduleBloc extends ScheduleBloc {
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);
  @override
  void add(ScheduleEvent event) {
    if (event is GetScheduleEvent) return;
    super.add(event);
  }
}

final DateTime _day = DateTime(2027, 1, 15);

SubCalendarEvent _tile(String id, {required bool rigid, int hours = 1}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: _day.add(const Duration(hours: 9)).millisecondsSinceEpoch,
    end: _day.add(Duration(hours: 9 + hours)).millisecondsSinceEpoch,
  );
  tile.isViable = true;
  tile.isRigid = rigid;
  return tile;
}

Widget _material(Widget child) => MaterialApp(
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

/// The accent bar inside the card for [id].
TileAccentBar _barOf(WidgetTester tester, Finder card) =>
    tester.widget<TileAccentBar>(
        find.descendant(of: card, matching: find.byType(TileAccentBar)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TileAccentBar', () {
    testWidgets('one solid bar for both kinds', (tester) async {
      await tester.pumpWidget(_material(const SizedBox(
          height: 40, child: TileAccentBar(key: Key('b'), color: Colors.red))));
      expect(
          find.descendant(
              of: find.byKey(const Key('b')), matching: find.byType(CustomPaint)),
          findsNothing);
      expect(tester.getSize(find.byKey(const Key('b'))).width,
          TileAccentBar.width);
    });
  });

  group('grid card', () {
    testWidgets('block → lock on the caption; tile → none; holds zoomed out',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(BlocProvider<ScheduleBloc>.value(
        value: bloc,
        child: _material(DayGridWidget(
          tiles: [
            _tile('block', rigid: true),
            _tile('tile', rigid: false),
          ],
          now: DateTime(2026, 5, 15, 14, 30),
          day: _day,
          controller: controller,
        )),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      Finder card(String id) => find.byWidgetPredicate(
          (w) => w is TileGridWidget && w.tilerEvent.id == id);
      Finder lockIn(Finder card) => find.descendant(
          of: card, matching: find.byIcon(Icons.lock_outline));
      expect(_barOf(tester, card('block')), isNotNull);
      expect(_barOf(tester, card('tile')), isNotNull);
      // A: the block's caption carries the lock; the tile's does not. It
      // sits on the LEFT, right after the time range (not at the far edge).
      expect(lockIn(card('block')), findsOneWidget);
      expect(lockIn(card('tile')), findsNothing);
      final Rect timeRange = tester.getRect(find.descendant(
          of: card('block'), matching: find.textContaining('\u2013')));
      final Rect lock = tester.getRect(lockIn(card('block')));
      expect(lock.left, greaterThanOrEqualTo(timeRange.right));
      expect(lock.left - timeRange.right, lessThan(12));
      expect((lock.center.dy - timeRange.center.dy).abs(), lessThan(4));

      // Zoomed far out (40 px/h -> the compact caption tier, since the
      // 20px pixel floor keeps a caption on every tile): the lock shrinks
      // to the compact size rather than disappearing.
      controller.setPxPerHour(40);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(lockIn(card('block')), findsOneWidget);
      expect(tester.widget<Icon>(lockIn(card('block'))).size, 11);
      await tester.runAsync(() => bloc.close());
    });
  });

  group('compact list card', () {
    testWidgets('block → lock on the caption; tile → none', (tester) async {
      await tester.pumpWidget(_material(SingleChildScrollView(
        child: Column(children: [
          EnhancedTileCard(
              key: const Key('block'),
              subEvent: _tile('block', rigid: true),
              compact: true),
          EnhancedTileCard(
              key: const Key('tile'),
              subEvent: _tile('tile', rigid: false),
              compact: true),
        ]),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_barOf(tester, find.byKey(const Key('block'))), isNotNull);
      expect(_barOf(tester, find.byKey(const Key('tile'))), isNotNull);
      final Finder blockLock = find.descendant(
          of: find.byKey(const Key('block')),
          matching: find.byIcon(Icons.lock_outline));
      expect(blockLock, findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('tile')),
              matching: find.byIcon(Icons.lock_outline)),
          findsNothing);
      // Left, right after the time range (the card's first line).
      final Rect timeRange = tester.getRect(find.descendant(
          of: find.byKey(const Key('block')),
          matching: find.textContaining('-')));
      final Rect lock = tester.getRect(blockLock);
      expect(lock.left, greaterThanOrEqualTo(timeRange.right));
      expect(lock.left - timeRange.right, lessThan(12));
    });
  });
}
