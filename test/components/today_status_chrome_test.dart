// today_status_chrome_test.dart
//
// Phase 5 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// Covers the §5.5 track status card copy rules, the §5.2 / §6.2 app bar, and
// the §6.3 summary strip.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/todayStatus/statusSummaryStrip.dart';
import 'package:tiler_app/components/todayStatus/todayAppBar.dart';
import 'package:tiler_app/components/todayStatus/trackStatusCard.dart';
import 'package:tiler_app/data/todayStatus/dayPlanViewModel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

Widget _harness({required Widget child, ThemeData? theme, Widget? appBar}) {
  return MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: appBar as PreferredSizeWidget?,
      body: SizedBox(width: 390, child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackStatusCard §5.5', () {
    testWidgets('says "Everything is on track" when nothing needs attention',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const TrackStatusCard(copy: TrackStatusCopy.everythingOnTrack),
      ));

      expect(find.text('Everything is on track'), findsOneWidget);
      expect(find.text('Everything else is on track'), findsNothing);
    });

    testWidgets('says "Everything else is on track" when attention remains',
        (tester) async {
      await tester.pumpWidget(_harness(
        child:
            const TrackStatusCard(copy: TrackStatusCopy.everythingElseOnTrack),
      ));

      expect(find.text('Everything else is on track'), findsOneWidget);
      expect(find.text('Everything is on track'), findsNothing);
    });

    testWidgets('carries the non-masking subcopy', (tester) async {
      await tester.pumpWidget(_harness(
        child: const TrackStatusCard(copy: TrackStatusCopy.everythingOnTrack),
      ));

      expect(find.text('No scheduled tiles are running late.'), findsOneWidget);
    });

    testWidgets('pairs the status with an icon, never color alone (§10)',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const TrackStatusCard(copy: TrackStatusCopy.everythingOnTrack),
      ));

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('is at least the §5.5 minimum height', (tester) async {
      await tester.pumpWidget(_harness(
        child: const TrackStatusCard(copy: TrackStatusCopy.everythingOnTrack),
      ));

      expect(tester.getSize(find.byType(TrackStatusCard)).height,
          greaterThanOrEqualTo(80));
    });
  });

  group('TodayAppBar §5.2', () {
    testWidgets('titles itself with the humanized date', (tester) async {
      await tester.pumpWidget(_harness(
        appBar: TodayAppBar(date: DateTime.now()),
        child: const SizedBox.shrink(),
      ));

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows the actual day when viewing another date',
        (tester) async {
      await tester.pumpWidget(_harness(
        appBar: TodayAppBar(date: DateTime.now().add(const Duration(days: 1))),
        child: const SizedBox.shrink(),
      ));

      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('close control invokes the callback', (tester) async {
      int closed = 0;
      await tester.pumpWidget(_harness(
        appBar: TodayAppBar(date: DateTime.now(), onClose: () => closed++),
        child: const SizedBox.shrink(),
      ));

      await tester.tap(find.byKey(TodayAppBar.closeKey));
      expect(closed, 1);
    });

    testWidgets('close control meets the minimum touch target', (tester) async {
      await tester.pumpWidget(_harness(
        appBar: TodayAppBar(date: DateTime.now(), onClose: () {}),
        child: const SizedBox.shrink(),
      ));

      final Size size = tester.getSize(find.byKey(TodayAppBar.closeKey));
      expect(
          size.width, greaterThanOrEqualTo(TodayStatusTokens.minTouchTarget));
      expect(
          size.height, greaterThanOrEqualTo(TodayStatusTokens.minTouchTarget));
    });

    testWidgets('is the §5.2 height', (tester) async {
      expect(TodayAppBar(date: DateTime.now()).preferredSize.height, 56);
    });
  });

  group('StatusSummaryStrip §6.3', () {
    testWidgets('reports both metrics with their labels', (tester) async {
      await tester.pumpWidget(_harness(
        child: const StatusSummaryStrip(placedCount: 4, attentionCount: 6),
      ));

      expect(find.text('4'), findsOneWidget);
      expect(find.text('Tiles completed'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Need attention'), findsOneWidget);
    });

    testWidgets('shows a zero count rather than hiding one side',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: const StatusSummaryStrip(placedCount: 0, attentionCount: 6),
      ));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Tiles completed'), findsOneWidget);
    });

    testWidgets('separates the two regions with a divider', (tester) async {
      await tester.pumpWidget(_harness(
        child: const StatusSummaryStrip(placedCount: 4, attentionCount: 6),
      ));

      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('is non-interactive by default', (tester) async {
      await tester.pumpWidget(_harness(
        child: const StatusSummaryStrip(placedCount: 4, attentionCount: 6),
      ));

      expect(
          find.descendant(
              of: find.byType(StatusSummaryStrip),
              matching: find.byType(InkWell)),
          findsNothing);
    });

    testWidgets('renders in dark theme from shared tokens', (tester) async {
      await tester.pumpWidget(_harness(
        theme: TileThemeData.darkTheme,
        child: const StatusSummaryStrip(placedCount: 1, attentionCount: 2),
      ));

      final Container card =
          tester.widget<Container>(find.byKey(StatusSummaryStrip.cardKey));
      expect((card.decoration as BoxDecoration).color,
          TodayStatusTokens.from(TileThemeData.darkTheme).surface);
    });
  });
}
