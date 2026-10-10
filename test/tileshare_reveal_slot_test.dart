import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/revealSlot.dart';

const Key _below = Key('below');

Widget _host(Widget? banner) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RevealSlot(child: banner),
            const SizedBox(key: _below, height: 20),
          ],
        ),
      ),
    );

Widget _banner([String text = 'Offline']) =>
    SizedBox(key: const Key('banner'), height: 60, child: Text(text));

double _belowTop(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_below)).dy;

void main() {
  testWidgets('empty, it takes no space', (tester) async {
    await tester.pumpWidget(_host(null));
    expect(_belowTop(tester), 0);
  });

  testWidgets('what is there at first is simply shown', (tester) async {
    await tester.pumpWidget(_host(_banner()));
    expect(_belowTop(tester), 60);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('what arrives grows in; what is below slides down',
      (tester) async {
    await tester.pumpWidget(_host(null));
    await tester.pumpWidget(_host(_banner()));
    expect(_belowTop(tester), 0);
    await tester.pump(RevealSlot.duration ~/ 2);
    expect(_belowTop(tester), inExclusiveRange(0, 60));
    await tester.pumpAndSettle();
    expect(_belowTop(tester), 60);
  });

  testWidgets('what leaves is still shown while it shrinks out, then gone',
      (tester) async {
    await tester.pumpWidget(_host(_banner()));
    await tester.pumpWidget(_host(null));
    await tester.pump(RevealSlot.duration ~/ 2);
    expect(find.text('Offline'), findsOneWidget);
    expect(_belowTop(tester), inExclusiveRange(0, 60));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsNothing);
    expect(_belowTop(tester), 0);
  });

  testWidgets('a change with the same key updates in place', (tester) async {
    await tester.pumpWidget(_host(_banner()));
    await tester.pumpWidget(_host(_banner('Still offline')));
    expect(find.text('Still offline'), findsOneWidget);
    expect(find.text('Offline'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
