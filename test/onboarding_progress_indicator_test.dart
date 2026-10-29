import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/onBoarding/onBoardingProgressIndicator.dart';

void main() {
  for (final currentPage in [0, 1]) {
    testWidgets('two-page flow shows steps 1 and 2 on page $currentPage',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OnBoardingProgressIndicator(
            totalPages: 2,
            currentPage: currentPage,
          ),
        ),
      ));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));

      final colorScheme =
          Theme.of(tester.element(find.byType(OnBoardingProgressIndicator)))
              .colorScheme;
      for (var step = 0; step < 2; step++) {
        final circle = tester.widget<Container>(find
            .ancestor(
                of: find.text('${step + 1}'), matching: find.byType(Container))
            .first);
        expect((circle.decoration! as BoxDecoration).color,
            step <= currentPage ? colorScheme.primary : Colors.transparent);
      }
    });
  }

  for (final scenario in [
    (totalPages: 1, currentPage: 0, labels: ['1']),
    (totalPages: 3, currentPage: 0, labels: ['1', '2', '3']),
    (totalPages: 4, currentPage: 3, labels: ['1', '2', '3', '4']),
    (totalPages: 10, currentPage: 0, labels: ['1', '2', '3', '4']),
    (totalPages: 10, currentPage: 4, labels: ['5', '6', '7', '8']),
    (totalPages: 10, currentPage: 9, labels: ['7', '8', '9', '10']),
  ]) {
    testWidgets(
        '${scenario.totalPages}-page flow on page ${scenario.currentPage} '
        'shows ${scenario.labels.join(', ')}', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OnBoardingProgressIndicator(
            totalPages: scenario.totalPages,
            currentPage: scenario.currentPage,
          ),
        ),
      ));

      expect(
          tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
          scenario.labels);
    });
  }
}
