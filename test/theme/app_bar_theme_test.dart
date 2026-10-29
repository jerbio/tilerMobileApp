import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/theme/theme_data.dart';

double _contrast(Color text, Color background) {
  final a = text.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  testWidgets(
      'shared headers remain transparent and readable when the theme changes and content scrolls',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Settings', key: Key('header_title')),
            leading: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close, key: Key('header_leading'))),
            actions: [
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz, key: Key('header_action')))
            ],
          ),
          body: ListView(
              controller: controller, children: const [SizedBox(height: 1800)]),
        ),
      ));
      await tester.pumpAndSettle();

      Color foreground(Key key) =>
          IconTheme.of(tester.element(find.byKey(key))).color!;
      final title = DefaultTextStyle.of(
              tester.element(find.byKey(const Key('header_title'))))
          .style;
      for (final color in [
        title.color!,
        foreground(const Key('header_leading')),
        foreground(const Key('header_action'))
      ]) {
        expect(_contrast(color, theme.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.brightness}: header content must remain legible');
      }

      final barMaterial = find
          .descendant(of: find.byType(AppBar), matching: find.byType(Material))
          .first;
      expect(tester.widget<Material>(barMaterial).color, Colors.transparent);
      controller.jumpTo(160);
      await tester.pumpAndSettle();
      final scrolledBar = tester.widget<Material>(barMaterial);
      expect(scrolledBar.color, Colors.transparent);
      expect(scrolledBar.elevation, 0,
          reason: 'scrolling must not add a coloured or raised header');

      final overlay = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(find.descendant(
              of: find.byType(AppBar),
              matching: find.byWidgetPredicate(
                  (w) => w is AnnotatedRegion<SystemUiOverlayStyle>)))
          .value;
      expect(
          overlay.statusBarIconBrightness,
          theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark);
      expect(tester.takeException(), isNull);
      controller.jumpTo(0);
    }
  });
}
