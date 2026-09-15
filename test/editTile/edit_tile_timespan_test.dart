// Starts and Ends on ONE line, each with its own time AND date control
// (requested 2026-09-14, revised 2026-09-15 — D24, the web layout).
//
// Add Block's two-up row stacks below 380pt, which is every phone once the
// card padding is taken off — so it never actually shows two-up on a
// phone. The edit screen's span row is built for the phone: two compact
// cells (label; a time chip; a date chip; no icon chip) that stay side by
// side down to 320pt and only stack when the width or text scale makes a
// cell unreadable. The cells keep the keys `editStartRow` / `editEndRow`;
// the chips inside are `editStartTime` / `editStartDate` / `editEndTime` /
// `editEndDate`.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../addTile/add_tile_widget_harness.dart';
import 'edit_tile_phase2_test.dart' as p2;
import 'edit_tile_shell_test.dart' as shell;

Finder key(String k) => find.byKey(ValueKey(k));

bool sideBySide(WidgetTester tester, Finder a, Finder b) {
  final Rect ra = tester.getRect(a);
  final Rect rb = tester.getRect(b);
  return (ra.top - rb.top).abs() < 1 && ra.right <= rb.left + 1;
}

bool above(WidgetTester tester, Finder a, Finder b) =>
    tester.getRect(a).bottom <= tester.getRect(b).top + 1;

bool hasTap(WidgetTester tester, Finder f) =>
    tester.getSemantics(f).getSemanticsData().hasAction(SemanticsAction.tap);

void main() {
  testWidgets('Starts and Ends share a line at phone width, for every tile',
      (tester) async {
    for (final bool rigid in <bool>[false, true]) {
      await shell.pumpEdit(tester,
          tile: p2.tile(isRigid: rigid), viewSize: AddTileTestMatrix.narrow);
      expect(sideBySide(tester, shell.startRow, shell.endRow), isTrue,
          reason: 'rigid=$rigid: the two cells must sit on the same line, '
              'start on the left');
      expect(key('editSpanRow'), findsOneWidget);
      expect(key('editDateRow'), findsNothing,
          reason: 'no separate Date row (D24 supersedes D23)');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('each cell stacks a time chip over a date chip (D24)',
      (tester) async {
    await shell.pumpEdit(tester, tile: p2.tile());
    expect(above(tester, shell.startTime, shell.startDate), isTrue);
    expect(above(tester, shell.endTime, shell.endDate), isTrue);
    expect(find.descendant(of: shell.startRow, matching: shell.startTime),
        findsOneWidget);
    expect(find.descendant(of: shell.endRow, matching: shell.endDate),
        findsOneWidget);
  });

  testWidgets('each cell shows its clock and its date', (tester) async {
    await shell.pumpEdit(tester, tile: p2.tile());
    List<String> textsIn(Finder f) => tester
        .widgetList<Text>(find.descendant(of: f, matching: find.byType(Text)))
        .map((Text t) => t.data ?? '')
        .toList();
    expect(
        textsIn(shell.startTime).any((String s) => s.contains('2:00')), isTrue);
    expect(
        textsIn(shell.startDate).any((String s) => s.contains('Sep')), isTrue);
    expect(
        textsIn(shell.endTime).any((String s) => s.contains('3:30')), isTrue);
    expect(textsIn(shell.endDate).any((String s) => s.contains('Sep')), isTrue,
        reason: 'the end date is always shown, as on the web');
  });

  testWidgets('all four chips are buttons that open their own picker',
      (tester) async {
    await shell.pumpEdit(tester, tile: p2.tile());
    final SemanticsHandle h = tester.ensureSemantics();
    for (final Finder f in <Finder>[
      shell.startTime,
      shell.startDate,
      shell.endTime,
      shell.endDate
    ]) {
      expect(hasTap(tester, f), isTrue, reason: '$f');
    }
    h.dispose();
    shell.pickedTimeAnswer = const TimeOfDay(hour: 17, minute: 0);
    await tester.tap(shell.endTime);
    await tester.pumpAndSettle();
    expect(shell.draftOf(tester).endTime, DateTime(2026, 9, 12, 17, 0));
    expect(shell.pickedDateSeed, isNull, reason: 'a time chip asks for time');

    shell.pickedDateAnswer = DateTime(2026, 9, 20);
    await tester.tap(shell.endDate);
    await tester.pumpAndSettle();
    expect(shell.draftOf(tester).endTime, DateTime(2026, 9, 20, 17, 0));
    expect(shell.draftOf(tester).startTime, DateTime(2026, 9, 12, 14, 0),
        reason: 'the end moves alone');
  });

  testWidgets('locked tiles keep the line but lose the taps', (tester) async {
    await shell.pumpEdit(tester, tile: p2.tile(isComplete: true));
    final SemanticsHandle h = tester.ensureSemantics();
    for (final Finder f in <Finder>[
      shell.startTime,
      shell.startDate,
      shell.endTime,
      shell.endDate
    ]) {
      expect(hasTap(tester, f), isFalse, reason: '$f');
    }
    h.dispose();
    expect(sideBySide(tester, shell.startRow, shell.endRow), isTrue);
  });

  testWidgets('large text at 320pt does not overflow (stacking is allowed)',
      (tester) async {
    await shell.pumpEdit(tester,
        tile: p2.tile(),
        viewSize: AddTileTestMatrix.narrow,
        textScale: AddTileTestMatrix.largeTextScale);
    expect(tester.takeException(), isNull);
    expect(shell.startRow, findsOneWidget);
    expect(shell.endRow, findsOneWidget);
  });
}
