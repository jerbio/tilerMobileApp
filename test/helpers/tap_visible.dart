import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mobile cards may continue below the viewport; scroll to their real actions.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 180,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}
