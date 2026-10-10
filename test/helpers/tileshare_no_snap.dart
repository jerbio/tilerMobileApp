// The TileShare no-snap checks (redesign T11, mirroring the day grid's
// §16.2 contract), shared by every harness that hosts a TileShare surface.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The largest one-frame move that is not a snap (§16.2).
const double snapTolerancePx = 4;

/// Where every visible row whose key starts with [prefix] is, by key.
Map<String, Rect> keyedRects(WidgetTester tester, String prefix) {
  final Map<String, Rect> rects = <String, Rect>{};
  final double screenHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  for (final Element e in find
      .byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith(prefix))
      .evaluate()) {
    final RenderObject? box = e.renderObject;
    if (box is! RenderBox || !box.hasSize || !box.attached) continue;
    final Rect r = box.localToGlobal(Offset.zero) & box.size;
    // Only what is on screen counts.
    if (r.bottom <= 0 || r.top >= screenHeight) continue;
    rects[(e.widget.key as ValueKey<String>).value] = r;
  }
  return rects;
}

/// At t = 0 nothing has jumped: every row that is still there has moved
/// less than the snap tolerance (or not at all, unless [mayAnimate]).
void expectNoJump(Map<String, Rect> before, Map<String, Rect> after,
    {bool mayAnimate = false, String what = 'row'}) {
  expect(before, isNotEmpty, reason: 'nothing measured');
  for (final MapEntry<String, Rect> e in before.entries) {
    final Rect? b = after[e.key];
    if (b == null) continue; // left: its exit animates
    final Rect a = e.value;
    final double delta = [
      (a.left - b.left).abs(),
      (a.top - b.top).abs(),
      (a.width - b.width).abs(),
      (a.height - b.height).abs(),
    ].reduce((x, y) => x > y ? x : y);
    expect(delta, lessThan(mayAnimate ? snapTolerancePx : 0.5),
        reason: '$what "${e.key}" jumped ${delta.toStringAsFixed(1)} px '
            'in one frame');
  }
}

/// After t = 0, every row that has to move gets there over several frames:
/// no single frame carries more than half of its move. (A move put off by
/// one frame and then made all at once is still a snap.)
Future<void> expectGlides(
    WidgetTester tester, Map<String, Rect> Function() measure,
    {String what = 'row'}) async {
  final Map<String, Rect> start = measure();
  final Map<String, Rect> last = Map<String, Rect>.of(start);
  final Map<String, double> biggestStep = <String, double>{};
  for (var frame = 0; frame < 40; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    final Map<String, Rect> now = measure();
    for (final MapEntry<String, Rect> e in now.entries) {
      final Rect? was = last[e.key];
      if (was != null) {
        final double step = (e.value.top - was.top).abs();
        if (step > (biggestStep[e.key] ?? 0)) biggestStep[e.key] = step;
      }
      last[e.key] = e.value;
    }
  }
  for (final MapEntry<String, Rect> e in start.entries) {
    final Rect? end = last[e.key];
    if (end == null) continue;
    final double moved = (end.top - e.value.top).abs();
    if (moved < snapTolerancePx) continue;
    expect(biggestStep[e.key] ?? 0, lessThanOrEqualTo(moved / 2),
        reason: '$what "${e.key}" made most of its ${moved.toStringAsFixed(1)}'
            ' px move in one frame');
  }
}
