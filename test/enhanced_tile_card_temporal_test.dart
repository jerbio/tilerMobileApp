import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveTileTemporalState (pure)', () {
    const now = 1000000;

    test('past when the occurrence has already ended', () {
      expect(
        resolveTileTemporalState(startMs: 100, endMs: 500, nowMs: now),
        TileTemporalState.past,
      );
    });

    test('past at the exact end boundary (endMs == nowMs)', () {
      expect(
        resolveTileTemporalState(startMs: 100, endMs: now, nowMs: now),
        TileTemporalState.past,
      );
    });

    test('future when the occurrence has not started yet', () {
      expect(
        resolveTileTemporalState(
            startMs: now + 100, endMs: now + 500, nowMs: now),
        TileTemporalState.future,
      );
    });

    test('active when now is within the span', () {
      expect(
        resolveTileTemporalState(
            startMs: now - 100, endMs: now + 100, nowMs: now),
        TileTemporalState.active,
      );
    });

    test('active at the exact start boundary (startMs == nowMs)', () {
      expect(
        resolveTileTemporalState(startMs: now, endMs: now + 100, nowMs: now),
        TileTemporalState.active,
      );
    });

    test('active (unbounded) when start and end are both null', () {
      expect(
        resolveTileTemporalState(startMs: null, endMs: null, nowMs: now),
        TileTemporalState.active,
      );
    });

    test('future when only start is set and is ahead of now', () {
      expect(
        resolveTileTemporalState(startMs: now + 1, endMs: null, nowMs: now),
        TileTemporalState.future,
      );
    });
  });

  Widget harness(SubCalendarEvent subEvent) {
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
        body: SingleChildScrollView(
          child: EnhancedTileCard(subEvent: subEvent),
        ),
      ),
    );
  }

  SubCalendarEvent tile({
    required Duration startFromNow,
    required Duration endFromNow,
  }) {
    final now = DateTime.now();
    return SubCalendarEvent(
      id: 'tile-1',
      name: 'Sample tile',
      start: now.add(startFromNow).millisecondsSinceEpoch,
      end: now.add(endFromNow).millisecondsSinceEpoch,
    );
  }

  Opacity cardOpacity(WidgetTester tester) => tester.widget<Opacity>(
      find.byKey(const ValueKey('enhancedTileCardOpacity')));

  group('EnhancedTileCard temporal styling', () {
    testWidgets('past tile is muted (opacity 0.6) with no active accent',
        (tester) async {
      final past = tile(
        startFromNow: const Duration(hours: -2),
        endFromNow: const Duration(hours: -1),
      );
      await tester.pumpWidget(harness(past));
      await tester.pump();

      expect(cardOpacity(tester).opacity, 0.6);
      expect(find.byKey(const ValueKey('enhancedTileActiveAccent')),
          findsNothing);
    });

    testWidgets('future tile is full opacity with no active accent',
        (tester) async {
      final future = tile(
        startFromNow: const Duration(hours: 1),
        endFromNow: const Duration(hours: 2),
      );
      await tester.pumpWidget(harness(future));
      await tester.pump();

      expect(cardOpacity(tester).opacity, 1.0);
      expect(find.byKey(const ValueKey('enhancedTileActiveAccent')),
          findsNothing);
    });

    testWidgets('active tile is full opacity and shows the top accent bar',
        (tester) async {
      final active = tile(
        startFromNow: const Duration(minutes: -30),
        endFromNow: const Duration(minutes: 30),
      );
      await tester.pumpWidget(harness(active));
      await tester.pump();

      expect(cardOpacity(tester).opacity, 1.0);
      expect(find.byKey(const ValueKey('enhancedTileActiveAccent')),
          findsOneWidget);
    });
  });
}
