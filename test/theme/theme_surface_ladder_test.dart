// theme_surface_ladder_test.dart
//
// Phase 9 (universal theme alignment): the dark surface ladder must get
// lighter as elevation increases. It previously inverted — the page background
// (#23272C) was lighter than cards (#1E2227), so cards sank instead of lifting
// and §16.1's "card edges remain visible" could not hold.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/theme/theme_data.dart';

double _luminance(Color c) => c.computeLuminance();

void main() {
  group('dark surface ladder', () {
    test('each elevation step is lighter than the one below it', () {
      final ColorScheme dark = TileThemeData.darkTheme.colorScheme;

      final List<(String, Color)> ladder = [
        ('surface', dark.surface),
        ('surfaceContainerLowest', dark.surfaceContainerLowest),
        ('surfaceContainerLow', dark.surfaceContainerLow),
        ('surfaceContainer', dark.surfaceContainer),
        ('surfaceContainerHigh', dark.surfaceContainerHigh),
        ('surfaceContainerHighest', dark.surfaceContainerHighest),
      ];

      for (int i = 1; i < ladder.length; i++) {
        expect(
          _luminance(ladder[i].$2),
          greaterThan(_luminance(ladder[i - 1].$2)),
          reason: '${ladder[i].$1} must be lighter than ${ladder[i - 1].$1}',
        );
      }
    });

    test('cards separate from the page background', () {
      final ColorScheme dark = TileThemeData.darkTheme.colorScheme;

      expect(_luminance(dark.surfaceContainerLowest),
          greaterThan(_luminance(dark.surface)),
          reason: 'a card must lift off the page, not sink into it');
    });

    test('the page background avoids pure black', () {
      final ColorScheme dark = TileThemeData.darkTheme.colorScheme;

      expect(_luminance(dark.surface), greaterThan(0),
          reason: '§6.1: avoid pure black except system chrome');
    });

    test('primary text stays legible on the darker background', () {
      final ColorScheme dark = TileThemeData.darkTheme.colorScheme;
      final double bg = _luminance(dark.surface);
      final double fg = _luminance(dark.onSurface);
      final double contrast = (fg + 0.05) / (bg + 0.05);

      expect(contrast, greaterThanOrEqualTo(4.5),
          reason: '§10 requires >= 4.5:1 for normal text');
    });
  });

  group('light surface ladder', () {
    test('cards separate from the page background', () {
      final ColorScheme light = TileThemeData.lightTheme.colorScheme;

      expect(_luminance(light.surfaceContainerLowest),
          greaterThan(_luminance(light.surface)),
          reason: '§16.1: light theme needs page/card distinction');
    });

    test('primary text stays legible', () {
      final ColorScheme light = TileThemeData.lightTheme.colorScheme;
      final double bg = _luminance(light.surface);
      final double fg = _luminance(light.onSurface);
      final double contrast = (bg + 0.05) / (fg + 0.05);

      expect(contrast, greaterThanOrEqualTo(4.5));
    });
  });
}
