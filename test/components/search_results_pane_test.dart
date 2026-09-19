// The search results pane keeps its header — the result count and the
// provider filter chips — pinned while the results scroll (2026-09-19).
//
// Before, the header was the first item INSIDE the results ListView, so a
// few rows in the filters were gone and changing provider meant scrolling
// back to the top.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tileUI/searchResultsPane.dart';

Future<void> pump(WidgetTester tester,
    {int rows = 30, VoidCallback? onDismiss}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 600,
        child: SearchResultsPane(
          key: const ValueKey('pane'),
          header: const SizedBox(
              key: ValueKey('header'), height: 60, child: Text('Filters')),
          results: [
            for (int i = 0; i < rows; i++)
              SizedBox(
                  key: ValueKey('row_$i'), height: 90, child: Text('Row $i')),
          ],
          onDismiss: onDismiss ?? () {},
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('the header stays put while the results scroll', (tester) async {
    await pump(tester);
    final Rect headerBefore =
        tester.getRect(find.byKey(const ValueKey('header')));
    final Rect row0Before = tester.getRect(find.byKey(const ValueKey('row_0')));
    expect(headerBefore.bottom, lessThanOrEqualTo(row0Before.top),
        reason: 'the header sits above the first result');

    await tester.drag(
        find.byKey(const ValueKey('row_0')), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('header'))), headerBefore,
        reason: 'pinned');
    expect(find.byKey(const ValueKey('row_0')), findsNothing,
        reason: 'the first result scrolled out under the header');
    expect(find.byKey(const ValueKey('row_6')), findsOneWidget);
  });

  testWidgets('the header is not part of the scrollable', (tester) async {
    await pump(tester);
    expect(
        find.descendant(
            of: find.byType(Scrollable),
            matching: find.byKey(const ValueKey('header'))),
        findsNothing);
    expect(
        find.descendant(
            of: find.byType(Scrollable),
            matching: find.byKey(const ValueKey('row_0'))),
        findsOneWidget);
  });

  testWidgets('a tap on empty space below a short list still dismisses',
      (tester) async {
    int dismissed = 0;
    await pump(tester, rows: 1, onDismiss: () => dismissed++);
    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    expect(dismissed, 1);
  });

  test('the search widget renders its results through the pane', () {
    final String code = File('lib/components/tileUI/eventNameSearch.dart')
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(code.contains('SearchResultsPane('), isTrue);
    expect(code.contains('ListView(children: widgets)'), isFalse,
        reason: 'the header must not be an item of the list');
  });
}
