// Phase 0 / Step 0.3 — Verification that the reusable Add Tile widget-test
// harness itself works: repeatable rendering across the supported matrix
// (light/dark theme, narrow + large viewports, text scale 1.0/1.3, keyboard
// insets) with actionable failure context (route/viewport/theme in messages).
//
// Self-contained (framework-only) so the harness is proven before Phase 1
// widget tests depend on it. No app widgets are pumped here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'add_tile_widget_harness.dart';

void main() {
  const tag = Key('harness-subject');
  const action = Key('harness-action');

  Widget subject() => Container(
        key: tag,
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.all(8),
        child: const Text(
          'Subject',
          key: Key('harness-subject-text'),
          semanticsLabel: 'Subject',
        ),
      );

  group('AddTileWidgetHarness — matrix reproducibility (Step 0.3)', () {
    testWidgets('renders subject + semantics across light and dark themes',
        (tester) async {
      for (final theme in [AddTileTestTheme.light, AddTileTestTheme.dark]) {
        final harness = AddTileWidgetHarness(tester: tester, theme: theme);
        await harness.pump(subject());
        expect(
          find.text('Subject'),
          findsOneWidget,
          reason: 'Subject must render under theme=$theme '
              '(viewport=${harness.viewSize})',
        );
        expect(
          find.bySemanticsLabel('Subject'),
          findsWidgets,
          reason: 'Semantics label must be exposed under theme=$theme',
        );
        await tester.pumpAndSettle();
        tester.view.reset();
      }
    });

    testWidgets('renders at narrow and large viewports without overflow',
        (tester) async {
      for (final size in [
        AddTileTestMatrix.narrow,
        AddTileTestMatrix.largePhone,
        AddTileTestMatrix.standard,
      ]) {
        final harness = AddTileWidgetHarness(tester: tester, viewSize: size);
        await harness.pump(subject());
        expect(
          find.text('Subject'),
          findsOneWidget,
          reason: 'Subject must render at viewport=$size',
        );
        expect(tester.takeException(), isNull,
            reason: 'No overflow/exception at viewport=$size');
        await tester.pumpAndSettle();
        tester.view.reset();
      }
    });

    testWidgets('text scale 1.3 does not break rendering', (tester) async {
      final harness = AddTileWidgetHarness(
        tester: tester,
        textScale: AddTileTestMatrix.largeTextScale,
      );
      await harness.pump(subject());
      expect(
        find.text('Subject'),
        findsOneWidget,
        reason: 'Subject must render at large text scale 1.3',
      );
      final rect = tester.getRect(find.byKey(tag));
      expect(
        rect.height.isFinite && rect.height > 0,
        isTrue,
        reason: 'Scaled subject rect must be finite and non-zero',
      );
      await tester.pumpAndSettle();
      tester.view.reset();
    });

    testWidgets('action area stays above simulated keyboard inset',
        (tester) async {
      final harness = AddTileWidgetHarness(
        tester: tester,
        bottomInset: 320.0,
        viewSize: AddTileTestMatrix.largePhone,
      );
      final actionWidget = Container(
        key: action,
        height: 56,
        color: Colors.pink,
      );
      await harness.pump(subject(), actionArea: actionWidget);
      expect(
        find.byKey(action),
        findsOneWidget,
        reason: 'Persistent action area must render with keyboard inset',
      );
      expect(
        isCoveredByKeyboardBottom(
          tester,
          actionWidget,
          bottomHeight: 300,
        ),
        isFalse,
        reason: 'Persistent CTA must remain visible above the keyboard',
      );
      await tester.pumpAndSettle();
      tester.view.reset();
    });
  });
}
