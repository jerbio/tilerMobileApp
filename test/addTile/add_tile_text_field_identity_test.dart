// A text field's FocusNode must survive a rebuild (D56).
//
// Reported on a physical device: in the place editor, BACKSPACE deleted
// nothing, while select-all-then-delete worked.
//
// The cause was `focusNode: FocusNode()` written inline in `build`. The editor
// rebuilds on every keystroke — the name listener drives the collision warning
// — so each character produced a NEW node, detaching the field from its old
// one and discarding the selection and composing region the platform keyboard
// depends on. Backspace needs a caret; replacing the whole value does not,
// which is exactly why select-all still worked.
//
// It is invisible to ordinary widget tests: `enterText` sets the whole value,
// so every existing test passed throughout. These assert the INVARIANT instead
// — the same node and controller instance across rebuilds — because that is
// the property the keyboard actually relies on.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePlaceEditor.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

/// A source that never finds a collision, so the editor's own rebuilds are the
/// only thing under test.
class QuietSource implements AddTileLocationSource {
  @override
  Future<List<Location>> savedPlaces() async => const <Location>[];

  @override
  Future<List<Location>> search(String query) async => const <Location>[];

  @override
  Future<Location?> findByName(String name) async => null;
}

Future<void> pumpEditor(WidgetTester tester) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTilePlaceEditorScreen(source: QuietSource()),
  ));
  await tester.pumpAndSettle();
}

EditableText fieldAt(WidgetTester tester, String key) =>
    tester.widget<EditableText>(find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(EditableText),
    ));

void main() {
  group('The editor keeps its field identities across rebuilds', () {
    testWidgets('the name field keeps ONE FocusNode', (tester) async {
      await pumpEditor(tester);
      final FocusNode before = fieldAt(tester, 'placeNameField').focusNode;

      // Typing rebuilds the screen; the node must be the same instance after.
      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), 'wor');
      await tester.pumpAndSettle();

      expect(identical(fieldAt(tester, 'placeNameField').focusNode, before),
          isTrue,
          reason: 'a new FocusNode per rebuild discards the caret, which is '
              'what stopped backspace from deleting anything');
    });

    testWidgets('the address field keeps ONE FocusNode', (tester) async {
      await pumpEditor(tester);
      final FocusNode before = fieldAt(tester, 'placeAddressField').focusNode;

      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), 'work');
      await tester.pumpAndSettle();

      expect(identical(fieldAt(tester, 'placeAddressField').focusNode, before),
          isTrue,
          reason: 'a rebuild triggered by the OTHER field must not replace '
              'this one either');
    });

    testWidgets('the controllers survive too', (tester) async {
      // Same failure mode, one layer over: a controller rebuilt per keystroke
      // would reset the value rather than the caret.
      await pumpEditor(tester);
      final TextEditingController before =
          fieldAt(tester, 'placeNameField').controller;

      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), 'work');
      await tester.pumpAndSettle();

      expect(identical(fieldAt(tester, 'placeNameField').controller, before),
          isTrue);
    });

    testWidgets('a caret placed mid-text survives a rebuild', (tester) async {
      // The closest a widget test gets to the reported gesture: put the caret
      // somewhere other than the end, force a rebuild, and check it stayed.
      await pumpEditor(tester);
      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), 'work');
      await tester.pumpAndSettle();

      final TextEditingController controller =
          fieldAt(tester, 'placeNameField').controller;
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pumpAndSettle();

      expect(
          fieldAt(tester, 'placeNameField').controller.selection.baseOffset, 2,
          reason: 'the caret was reset by a rebuild, so a backspace would '
              'have had nothing to delete from');
    });
  });
}
