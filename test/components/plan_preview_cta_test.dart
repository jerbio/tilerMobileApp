// plan_preview_cta_test.dart
//
// Phase 6 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// Covers the §5.6 / §6.6 CTA contract and the §15.3 preview loading/error
// states. The preview pipeline is not wired yet, so these also pin down that
// the button is inert beyond its callback.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/todayStatus/planPreviewCta.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

Widget _harness({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 390, child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('§5.6 appearance', () {
    testWidgets('uses the preview-first label', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      expect(find.text('Preview a better plan'), findsOneWidget);
      expect(find.text('Rework my day'), findsNothing);
    });

    testWidgets('is the §4.1 CTA height', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      expect(tester.getSize(find.byKey(PlanPreviewCta.buttonKey)).height,
          TodayStatusTokens.ctaHeight);
    });

    testWidgets('fills the available width', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      expect(tester.getSize(find.byKey(PlanPreviewCta.buttonKey)).width, 390);
    });

    testWidgets('paints with the shared brand color, not a spec hex',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      final Container button =
          tester.widget<Container>(find.byKey(PlanPreviewCta.buttonKey));
      expect((button.decoration as BoxDecoration).color,
          TodayStatusTokens.from(TileThemeData.lightTheme).brand);
    });

    testWidgets('the trailing chevron is decorative only (§6.6)',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      final Icon chevron =
          tester.widget<Icon>(find.byKey(PlanPreviewCta.chevronKey));
      expect(chevron.semanticLabel, isNull);
    });
  });

  group('interaction', () {
    testWidgets('invokes the callback once per tap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () => taps++),
      ));

      await tester.tap(find.byKey(PlanPreviewCta.buttonKey));
      expect(taps, 1);
    });

    testWidgets('ignores repeat taps while loading (§5.6)', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(loading: true, onPressed: () => taps++),
      ));

      await tester.tap(find.byKey(PlanPreviewCta.buttonKey));
      await tester.tap(find.byKey(PlanPreviewCta.buttonKey));
      expect(taps, 0);
    });

    testWidgets('is inert when disabled', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(enabled: false, onPressed: () => taps++),
      ));

      await tester.tap(find.byKey(PlanPreviewCta.buttonKey));
      expect(taps, 0);
    });
  });

  group('§15.3 loading and error states', () {
    testWidgets('keeps the label and shows progress while loading',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(loading: true, onPressed: () {}),
      ));

      expect(find.text('Preview a better plan'), findsOneWidget,
          reason: 'the label must be preserved, not swapped for a spinner');
      expect(find.byKey(PlanPreviewCta.progressKey), findsOneWidget);
    });

    testWidgets('announces the loading state to screen readers',
        (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(loading: true, onPressed: () {}),
      ));

      expect(find.bySemanticsLabel('Preparing preview…'), findsOneWidget);
    });

    testWidgets('announces itself as a button when idle', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      expect(find.bySemanticsLabel('Preview a better plan'), findsOneWidget);
    });

    testWidgets('shows a recoverable error above the button', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(
          onPressed: () {},
          errorText: "Preview couldn't be generated. Your plan is unchanged.",
        ),
      ));

      expect(
          find.text("Preview couldn't be generated. Your plan is unchanged."),
          findsOneWidget);
    });

    testWidgets('stays tappable after an error so the user can retry',
        (tester) async {
      int taps = 0;
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(
          onPressed: () => taps++,
          errorText: 'boom',
        ),
      ));

      await tester.tap(find.byKey(PlanPreviewCta.buttonKey));
      expect(taps, 1);
    });

    testWidgets('no error region when there is no error', (tester) async {
      await tester.pumpWidget(_harness(
        child: PlanPreviewCta(onPressed: () {}),
      ));

      expect(find.byKey(PlanPreviewCta.errorKey), findsNothing);
    });
  });
}
