// Tapping a search result opens its edit flow WITHOUT dismissing the results
// (2026-09-19).
//
// The results list sits inside a GestureDetector whose tap hides the list;
// a card with no tap handler of its own let the tap fall through to it, so
// tapping a result closed the search instead of opening the tile. The card
// body is now a [SearchResultTapTarget]: an ink-responding surface that
// claims the tap (a child wins the gesture arena) and reports it.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tileUI/searchResultDestination.dart';

Future<void> pump(WidgetTester tester,
    {required VoidCallback? onOpen, required VoidCallback onDismiss}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: GestureDetector(
        onTap: onDismiss,
        child: Container(
          width: 400,
          height: 600,
          color: Colors.white,
          child: Column(children: [
            SearchResultTapTarget(
              key: const ValueKey('target'),
              onOpen: onOpen,
              child: const SizedBox(
                  height: 80, width: 300, child: Text('Dentist')),
            ),
          ]),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('a tap on the result opens it and does NOT reach the dismisser',
      (tester) async {
    int opened = 0;
    int dismissed = 0;
    await pump(tester, onOpen: () => opened++, onDismiss: () => dismissed++);
    await tester.tap(find.text('Dentist'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(dismissed, 0);
    // A tap on the empty area still dismisses, as before.
    await tester.tapAt(const Offset(200, 500));
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    expect(opened, 1);
  });

  testWidgets('the target responds with ink (a visible pressed state)',
      (tester) async {
    await pump(tester, onOpen: () {}, onDismiss: () {});
    final Finder ink = find.descendant(
        of: find.byKey(const ValueKey('target')),
        matching: find.byType(InkWell));
    expect(ink, findsOneWidget);
    expect(tester.widget<InkWell>(ink).onTap, isNotNull);
    // The splash is the theme's (Material 3 paints it with a shader, so the
    // primitive is not asserted); what matters is that nothing turned it
    // off, and that the ink has a Material of its own to paint on.
    final InkWell well = tester.widget<InkWell>(ink);
    expect(well.splashFactory, isNull, reason: 'inherits the theme splash');
    expect(Theme.of(tester.element(ink)).splashFactory,
        isNot(NoSplash.splashFactory));
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('target')),
            matching: find.byType(Material)),
        findsOneWidget);
    // And pressing does not throw or dismiss anything.
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(find.text('Dentist')));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a result that cannot open is inert, and the tap still stays put',
      (tester) async {
    int dismissed = 0;
    await pump(tester, onOpen: null, onDismiss: () => dismissed++);
    await tester.tap(find.text('Dentist'));
    await tester.pumpAndSettle();
    expect(dismissed, 0,
        reason: 'a dead row must not close the results either');
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  test('the search card body IS the tap target', () {
    final String code = File('lib/components/tileUI/eventNameSearch.dart')
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(code.contains('SearchResultTapTarget('), isTrue);
  });
}
