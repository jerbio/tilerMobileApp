// Step 4.3b — the Color picker.
//
// The behaviours worth pinning are the ones that differ from the legacy
// `/PickColor` route:
//   * Automatic is a real, choosable, reversible answer — the legacy result
//     slot could only ever hold a colour, so once set there was no way back;
//   * a confirmed Automatic is distinguishable from backing out, which is
//     why the screen returns a `ColorChoice` and not a `Color?`;
//   * a preset tap COMMITS, matching Priority and Location (D18);
//   * the custom wheel is the one control that confirms, because it fires on
//     every drag and cannot commit on change.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

ColorChoice? _choice;

Future<void> pumpColor(
  WidgetTester tester, {
  Color? initial,
  Size viewSize = AddTileTestMatrix.standard,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  _choice = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileColorScreen(
      initialColor: initial,
      onSelected: (c) => _choice = c,
    ),
  ));
  await tester.pumpAndSettle();
}

/// Reads a row's assistive-tech selected state. Selection must not be carried
/// by colour alone here of all screens — the control is MADE of colours.
bool rowIsSelected(WidgetTester tester, String key) {
  final Semantics semantics = tester.widget<Semantics>(
    find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Semantics),
        )
        .first,
  );
  return semantics.properties.selected ?? false;
}

void main() {
  group('Colour choice model', () {
    test('a confirmed Automatic is distinguishable from a dismissal', () {
      // Both carry a null colour; only `made` tells them apart. A `Color?`
      // return could not express this, which is why the legacy route had no
      // way back to Automatic.
      const automatic = ColorChoice.automatic();
      const dismissed = ColorChoice.none();

      expect(automatic.color, isNull);
      expect(dismissed.color, isNull);
      expect(automatic.made, isTrue);
      expect(dismissed.made, isFalse);
      expect(automatic, isNot(dismissed));
    });

    test('a chosen colour round-trips', () {
      const chosen = ColorChoice.chosen(Color(0xFF336699));
      expect(chosen.made, isTrue);
      expect(chosen.color, const Color(0xFF336699));
    });

    test('summaries name the state, never the colour', () {
      // Colour names are a translation and perception problem, and the row
      // shows the actual swatch alongside.
      expect(colorChoiceSummary(testL10n, null), 'Automatic');
      expect(colorChoiceSummary(testL10n, addTileColorPresets.first), 'Custom');
    });

    test('Automatic is selected exactly when no colour is set', () {
      expect(colorIsSelected(null, null), isTrue);
      expect(colorIsSelected(addTileColorPresets.first, null), isFalse);
      expect(
        colorIsSelected(addTileColorPresets.first, addTileColorPresets.first),
        isTrue,
      );
      expect(
        colorIsSelected(addTileColorPresets.first, addTileColorPresets[1]),
        isFalse,
      );
    });
  });

  group('Colour picker — selection', () {
    testWidgets('Automatic reads as selected when no colour is set',
        (tester) async {
      await pumpColor(tester);
      expect(rowIsSelected(tester, 'colorAutomatic'), isTrue);
    });

    testWidgets('Automatic is reachable again once a colour is set',
        (tester) async {
      // The regression the legacy route could not avoid: a colour, once
      // chosen, was permanent for the life of the draft.
      await pumpColor(tester, initial: addTileColorPresets[2]);
      expect(rowIsSelected(tester, 'colorAutomatic'), isFalse);

      await tester.tap(find.byKey(const ValueKey('colorAutomatic')));
      await tester.pumpAndSettle();

      expect(_choice, isNotNull);
      expect(_choice!.made, isTrue);
      expect(_choice!.color, isNull, reason: 'null colour means Automatic');
    });

    testWidgets('tapping a preset commits it immediately', (tester) async {
      await pumpColor(tester);
      await tester.tap(find.byKey(const ValueKey('colorPreset_3')));
      await tester.pumpAndSettle();

      expect(_choice, isNotNull);
      expect(_choice!.made, isTrue);
      expect(_choice!.color, addTileColorPresets[3]);
    });

    testWidgets('the current colour reads as the selected preset',
        (tester) async {
      await pumpColor(tester, initial: addTileColorPresets[5]);
      expect(rowIsSelected(tester, 'colorPreset_5'), isTrue);
      expect(rowIsSelected(tester, 'colorPreset_4'), isFalse);
    });

    testWidgets('every preset is offered and separately addressable',
        (tester) async {
      await pumpColor(tester);
      for (int i = 0; i < addTileColorPresets.length; i++) {
        expect(find.byKey(ValueKey('colorPreset_$i')), findsOneWidget);
      }
    });
  });

  group('Colour picker — the custom wheel', () {
    testWidgets('there is no confirm button until the wheel is open',
        (tester) async {
      // Every other control commits on tap; a standing Done would imply the
      // presets need confirming too.
      await pumpColor(tester);
      expect(find.byKey(const ValueKey('colorCustomDone')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('colorCustomRow')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('colorCustomDone')), findsOneWidget);
    });

    testWidgets('opening the wheel is not itself a choice', (tester) async {
      await pumpColor(tester);
      await tester.tap(find.byKey(const ValueKey('colorCustomRow')));
      await tester.pumpAndSettle();

      expect(_choice, isNull,
          reason: 'the draft must not change just because the wheel opened');
    });

    testWidgets('Done commits the wheel colour', (tester) async {
      await pumpColor(tester, initial: addTileColorPresets[1]);
      await tester.tap(find.byKey(const ValueKey('colorCustomRow')));
      await tester.pumpAndSettle();

      // The wheel is tall, so Done sits below the fold on the test viewport.
      final done = find.byKey(const ValueKey('colorCustomDone'));
      await tester.ensureVisible(done);
      await tester.pumpAndSettle();
      await tester.tap(done);
      await tester.pumpAndSettle();

      expect(_choice, isNotNull);
      expect(_choice!.made, isTrue);
      expect(_choice!.color, addTileColorPresets[1],
          reason: 'the wheel opens on the colour already in effect');
    });

    testWidgets('the wheel opens on the colour already in effect',
        (tester) async {
      await pumpColor(tester, initial: addTileColorPresets[6]);
      await tester.tap(find.byKey(const ValueKey('colorCustomRow')));
      await tester.pumpAndSettle();

      // The row previews what Done would commit.
      final ColorDot dot = tester.widget<ColorDot>(find.descendant(
        of: find.byKey(const ValueKey('colorCustomRow')),
        matching: find.byType(ColorDot),
      ));
      expect(dot.color, addTileColorPresets[6]);
    });
  });

  group('Colour picker — navigation (D12)', () {
    testWidgets('backing out returns nothing', (tester) async {
      // Pushed for real so the pop path, not the injected callback, is what
      // gets exercised.
      ColorChoice? popped;
      bool returned = false;
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        locale: const Locale('en'),
        localeResolutionCallback: _resolve,
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<ColorChoice>(
                  MaterialPageRoute<ColorChoice>(
                    builder: (_) => const AddTileColorScreen(),
                  ),
                );
                returned = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget,
          reason: 'D12: secondary screens go Back, not Close');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(popped, isNull,
          reason: 'a dismissal must not read as choosing Automatic');
    });
  });
}
