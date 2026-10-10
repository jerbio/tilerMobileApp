import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/animatedKeyedColumn.dart';

Widget _row(String id, [String? text]) =>
    SizedBox(key: ValueKey<String>(id), height: 50, child: Text(text ?? id));

Widget _host(List<String> ids, {Map<String, String> text = const {}}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedKeyedColumn(
            children: [for (final id in ids) _row(id, text[id])]),
      ),
    );

double _top(WidgetTester tester, String id) =>
    tester.getTopLeft(find.byKey(ValueKey<String>(id))).dy;

void main() {
  testWidgets('what is there at first shows at once, at full size',
      (tester) async {
    await tester.pumpWidget(_host(['a', 'b']));
    expect(tester.getSize(find.byType(AnimatedKeyedColumn)).height, 100);
    expect(_top(tester, 'b'), 50);
  });

  testWidgets('a child that leaves shrinks out where it was, then is gone',
      (tester) async {
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    await tester.pumpWidget(_host(['a', 'c']));
    expect(find.text('b'), findsOneWidget);
    expect(_top(tester, 'c'), 100);
    await tester.pump(AnimatedKeyedColumn.outDuration ~/ 2);
    expect(_top(tester, 'c'), inExclusiveRange(50, 100));
    await tester.pumpAndSettle();
    expect(find.text('b'), findsNothing);
    expect(_top(tester, 'c'), 50);
  });

  testWidgets('a child that arrives grows in from nothing', (tester) async {
    await tester.pumpWidget(_host(['a', 'c']));
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    expect(_top(tester, 'c'), 50);
    await tester.pumpAndSettle();
    expect(_top(tester, 'c'), 100);
  });

  testWidgets('a child back before it finished leaving stays', (tester) async {
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    await tester.pumpWidget(_host(['a', 'c']));
    await tester.pump(AnimatedKeyedColumn.outDuration ~/ 2);
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    await tester.pumpAndSettle();
    expect(find.text('b'), findsOneWidget);
    expect(_top(tester, 'c'), 100);
  });

  testWidgets('a reorder keeps one of each, in the new order', (tester) async {
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    await tester.pumpWidget(_host(['c', 'a', 'b']));
    await tester.pumpAndSettle();
    expect(find.text('c'), findsOneWidget);
    expect(_top(tester, 'c'), 0);
    expect(_top(tester, 'a'), 50);
    expect(_top(tester, 'b'), 100);
  });

  testWidgets('a child keeps its fresh widget without animating',
      (tester) async {
    await tester.pumpWidget(_host(['a']));
    await tester.pumpWidget(_host(['a'], text: {'a': 'a2'}));
    expect(find.text('a2'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
