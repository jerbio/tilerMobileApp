// A row that announces itself as a button must be ACTIVATABLE as one (D62).
//
// Every tappable control in the form kit wraps its content in
// `Semantics(button: true, label: ...)` over an `ExcludeSemantics`, so the
// screen reader hears one clean label instead of the row's parts. But the
// tap lived on the excluded `InkWell`, so the node the reader exposed had NO
// tap action: a double-tap in TalkBack / VoiceOver reached nothing. Found by
// the Duration picker's Ends row test, which asked for the action and did
// not get it.
//
// These assert the property the assistive technology relies on — that
// performing the node's tap action invokes the handler — for each of the
// three wrappers.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/theme_data.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

Future<void> pumpControl(WidgetTester tester, Widget control) async {
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: control)),
  ));
  await tester.pumpAndSettle();
}

/// Activates [finder]'s semantics node the way a screen reader does.
void activate(WidgetTester tester, Finder finder) {
  final SemanticsNode node = tester.getSemantics(finder);
  tester.binding.pipelineOwner.semanticsOwner!
      .performAction(node.id, SemanticsAction.tap);
}

void main() {
  testWidgets('a field row announced as a button is activatable',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int taps = 0;
    await pumpControl(
      tester,
      AddTileFieldRow(
        key: const ValueKey('row'),
        icon: Icons.schedule,
        label: 'Starts',
        value: '2:00 PM',
        onTap: () => taps++,
      ),
    );

    expect(
        tester.getSemantics(find.byKey(const ValueKey('row'))),
        matchesSemantics(
            isButton: true, hasTapAction: true, label: 'Starts, 2:00 PM'));
    activate(tester, find.byKey(const ValueKey('row')));
    await tester.pump();
    expect(taps, 1, reason: 'the reader\'s double-tap must reach onTap');
    handle.dispose();
  });

  testWidgets('a read-only field row is neither a button nor tappable',
      (tester) async {
    // The other half of the contract: a derived value must not invite a
    // tap it cannot honour.
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpControl(
      tester,
      const AddTileFieldRow(
        key: ValueKey('row'),
        icon: Icons.outlined_flag,
        label: 'Ends',
        value: '4:00 PM',
      ),
    );

    expect(
        tester.getSemantics(find.byKey(const ValueKey('row'))),
        matchesSemantics(
            isButton: false, hasTapAction: false, label: 'Ends, 4:00 PM'));
    handle.dispose();
  });

  testWidgets('a nav row announced as a button is activatable', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int taps = 0;
    await pumpControl(
      tester,
      AddTileNavRow(
        key: const ValueKey('row'),
        icon: Icons.place_outlined,
        title: 'Location',
        subtitle: 'Not set',
        onTap: () => taps++,
      ),
    );

    expect(
        tester.getSemantics(find.byKey(const ValueKey('row'))),
        matchesSemantics(
            isButton: true, hasTapAction: true, label: 'Location, Not set'));
    activate(tester, find.byKey(const ValueKey('row')));
    await tester.pump();
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('the name-this-place button is activatable', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int taps = 0;
    await pumpControl(
      tester,
      NameLocationButton(key: const ValueKey('name'), onTap: () => taps++),
    );

    expect(tester.getSemantics(find.byKey(const ValueKey('name'))),
        matchesSemantics(isButton: true, hasTapAction: true));
    activate(tester, find.byKey(const ValueKey('name')));
    await tester.pump();
    expect(taps, 1);
    handle.dispose();
  });
}
