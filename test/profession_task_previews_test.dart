import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/professionTaskPreviews.dart';

Widget _app(
        {MediaQueryData media = const MediaQueryData(), VoidCallback? onTap}) =>
    MaterialApp(
      home: MediaQuery(
        data: media,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ProfessionTaskPreviews(
                previews: List.generate(4, (index) => 'Example $index'),
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    height: 64,
                    child: TextButton(
                      key: ValueKey('choice_$index'),
                      onPressed: onTap ?? () {},
                      child: Text('Profession $index'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

Finder get _examples => find.byWidgetPredicate((widget) =>
    widget is Text && (widget.data?.startsWith('Example ') ?? false));

Future<void> _advance(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
      'previews overlap, linger for three seconds, and rotate without moving rows',
      (tester) async {
    await tester.pumpWidget(_app());
    final before = tester.getTopLeft(find.byKey(const ValueKey('choice_3')));
    await _advance(tester, 600);
    expect(_examples, findsOneWidget);
    final firstExample = tester.widget<Text>(_examples).data!;

    await _advance(tester, 2900);
    expect(find.text(firstExample), findsOneWidget,
        reason: 'The first preview must remain through its three-second hold.');
    expect(_examples, findsNWidgets(2),
        reason: 'A second profession starts while the first preview lingers.');
    await _advance(tester, 400);
    expect(find.text(firstExample), findsNothing);
    expect(_examples, findsOneWidget);

    final seen = <String>{firstExample};
    for (var step = 0; step < 20; step++) {
      await _advance(tester, 700);
      final texts = tester.widgetList<Text>(_examples).toList();
      expect(texts.length, lessThanOrEqualTo(2));
      seen.addAll(texts.map((text) => text.data!));
    }
    expect(seen, hasLength(4),
        reason: 'Every visible profession gets a preview.');
    expect(tester.getTopLeft(find.byKey(const ValueKey('choice_3'))), before);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview bubbles do not intercept taps on profession choices',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
    final text = tester.widget<Text>(_examples).data!;
    final index = int.parse(text.split(' ').last);
    await tester.tap(find.byKey(ValueKey('choice_$index')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('reduced motion shows choices without rotating previews',
      (tester) async {
    await tester.pumpWidget(_app(
      media: const MediaQueryData(disableAnimations: true),
    ));
    await tester.pump(const Duration(seconds: 12));
    expect(_examples, findsNothing);
    expect(find.text('Profession 0'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('typing pauses previews; closing the keyboard resumes them',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
    expect(_examples, findsOneWidget);

    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 8));
    expect(_examples, findsNothing);

    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
    expect(_examples, findsOneWidget);
  });
}
