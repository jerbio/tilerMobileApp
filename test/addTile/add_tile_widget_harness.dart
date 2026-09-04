// Phase 0 / Step 0.3 — Reusable Add Tile widget-test harness.
//
// Centralizes the theme / viewport / text-scale / keyboard-inset / action-area
// / semantics setup so every later widget test (shell, forms, pickers) runs
// against one consistent, repeatable matrix instead of ad-hoc `MaterialApp`
// scaffolding. This is the harness the plan's §10.2/§10.4 matrix depends on.
//
// Intentionally thin and framework-only (no app widgets imported) so it is
// stable across the whole redesign.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Viewports / scales for the §10.4 responsive + a11y matrix.
class AddTileTestMatrix {
  AddTileTestMatrix._();

  /// ~320px logical width (narrow / small phone).
  static const Size narrow = Size(320, 640);

  /// Representative large-phone width.
  static const Size largePhone = Size(414, 896);

  /// Default widget-test viewport.
  static const Size standard = Size(800, 600);

  /// Baseline text scale.
  static const double baseTextScale = 1.0;

  /// Large-text scale from the matrix.
  static const double largeTextScale = 1.3;

  static const double _pixelRatio = 3.0;

  /// Physical size for a logical [size] at the harness pixel ratio.
  static Size physicalSizeOf(Size size) =>
      Size(size.width * _pixelRatio, size.height * _pixelRatio);
}

enum AddTileTestTheme { light, dark }

/// Reusable harness for Add Tile widget tests.
///
/// Wrap a [child] in the app's localization + theme with a controllable
/// viewport, text scale, and simulated keyboard bottom inset. Pass
/// [actionArea] to [pump] to model the persistent, keyboard-safe bottom CTA
/// slot so layout tests can assert a control stays visible above the keyboard
/// (§6.3, §10.2).
class AddTileWidgetHarness {
  const AddTileWidgetHarness({
    required this.tester,
    this.theme = AddTileTestTheme.light,
    this.viewSize = AddTileTestMatrix.standard,
    this.textScale = AddTileTestMatrix.baseTextScale,
    this.bottomInset = 0.0,
    this.locale,
    this.routes,
  });

  final WidgetTester tester;
  final AddTileTestTheme theme;
  final Size viewSize;
  final double textScale;
  final double bottomInset;
  final Locale? locale;
  final Map<String, WidgetBuilder>? routes;

  ThemeData get themeData => theme == AddTileTestTheme.light
      ? TileThemeData.lightTheme
      : TileThemeData.darkTheme;

  /// Pump [child] inside the harness. `actionArea` is placed in the
  /// Scaffold's persistent footer, which sits ABOVE the simulated keyboard
  /// inset — the analog of the persistent CTA that must never be hidden.
  Future<void> pump(
    Widget child, {
    Widget? actionArea,
    Map<String, WidgetBuilder>? overrideRoutes,
  }) async {
    final effectiveLocale = locale ?? const Locale('en');
    final scaffold = Scaffold(
      body: child,
      bottomNavigationBar: bottomInset > 0
          ? SizedBox(
              height: bottomInset,
              child: const _KeyboardSpacer(),
            )
          : null,
      persistentFooterButtons: actionArea != null ? [actionArea] : null,
    );

    tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
    addTearDown(tester.view.reset);
    final home = _TextScaleOverride(scale: textScale, child: scaffold);

    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        debugShowCheckedModeBanner: false,
        locale: effectiveLocale,
        localeResolutionCallback:
            (Locale? requested, Iterable<Locale> supported) => supported.first,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: overrideRoutes ?? routes ?? const <String, WidgetBuilder>{},
        home: home,
      ),
    );
  }
}

class _KeyboardSpacer extends StatelessWidget {
  const _KeyboardSpacer();
  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black26);
}

/// Applies a [MediaQuery] text scale factor to the subtree. Version-
/// independent way to exercise the §10.4 large-text matrix without relying on
/// a specific `TestFlutterView` setter.
class _TextScaleOverride extends StatelessWidget {
  const _TextScaleOverride({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Semantics / accessibility helpers
// ---------------------------------------------------------------------------

/// Find a [Semantics] node by its label text.
Finder semanticsLabel(String label) => find.bySemanticsLabel(label);

/// True when [widget]'s rect lies within [bottomHeight] logical pixels of
/// the bottom of the viewport — i.e. it would be covered by a keyboard of
/// that height.
bool isCoveredByKeyboardBottom(
  WidgetTester tester,
  Widget widget, {
  double bottomHeight = 320.0,
}) {
  final rect = tester.getRect(find.byWidget(widget));
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  return rect.bottom > (logicalSize.height - bottomHeight);
}

/// Convenience: a minimal [TextFormField] usable as a harness subject.
TextFormField harnessTextField({
  Key? key,
  required String label,
  String? hint,
}) {
  return TextFormField(
    key: key,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}
