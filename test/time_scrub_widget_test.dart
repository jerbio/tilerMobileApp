// Widget-level regression guards for TimeScrubWidget.
//
// The proportion/width math is unit tested separately in
// time_scrub_geometry_test.dart. These tests lock in the widget's behavior:
//   * a current (interfering) occurrence renders the scrub track with a
//     pulsing ball (ScaleTransition) and no elapsed/starts-in text row,
//   * a past occurrence falls back to the "elapsed ... ago" text row,
//   * a future occurrence falls back to the "starts in ..." text row,
//   * the widget adapts to narrow and wide parents without overflowing.
//
// NOTE: the pulse animation repeats forever and the ball glides toward the end
// of the occurrence over its remaining duration, so these tests must never call
// pumpAndSettle — they pump fixed durations instead.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

const int _minute = 60 * 1000;
const int _hour = 60 * _minute;

final Finder _pulse = find.byKey(const ValueKey('timeScrubPulse'));

Timeline _timeline(int startMs, int endMs) => Timeline(startMs, endMs);

Widget _host({required double width, required Widget child}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

Future<void> _pumpScrub(
  WidgetTester tester, {
  required double width,
  required Timeline timeline,
}) async {
  await tester.pumpWidget(
    _host(width: width, child: TimeScrubWidget(timeline: timeline)),
  );
  // First frame + let the post-frame callback (animate-to-end) run, then a
  // short pump for the animation to begin. Never settle: pulse repeats forever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('TimeScrubWidget rendering modes', () {
    testWidgets('current occurrence shows the scrub track with a pulsing ball',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await tester.pumpScrubCurrent(now);

      // A current occurrence must NOT drop to the elapsed/future text rows.
      expect(find.byIcon(Icons.check_circle_outline_outlined), findsNothing);
      expect(find.byIcon(Icons.timelapse), findsNothing);
      // The moving ball pulses via the keyed ScaleTransition.
      expect(_pulse, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('past occurrence falls back to the elapsed text row',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _pumpScrub(
        tester,
        width: 320,
        timeline: _timeline(now - 2 * _hour, now - _hour),
      );

      expect(find.byIcon(Icons.check_circle_outline_outlined), findsOneWidget);
      expect(_pulse, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('future occurrence falls back to the starts-in text row',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _pumpScrub(
        tester,
        width: 320,
        timeline: _timeline(now + _hour, now + 2 * _hour),
      );

      expect(find.byIcon(Icons.timelapse), findsOneWidget);
      expect(_pulse, findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('TimeScrubWidget responsiveness', () {
    testWidgets('adapts to a narrow parent without overflowing',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _pumpScrub(
        tester,
        width: 150,
        timeline: _timeline(now - 30 * _minute, now + 30 * _minute),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(TimeScrubWidget), findsOneWidget);
    });

    testWidgets('adapts to a wide parent without overflowing', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _pumpScrub(
        tester,
        width: 500,
        timeline: _timeline(now - 30 * _minute, now + 30 * _minute),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(TimeScrubWidget), findsOneWidget);
    });
  });

  group('TimeScrubWidget orientation change', () {
    testWidgets(
        're-anchors the ball to the correct proportion after a width change',
        (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // ~50% elapsed occurrence so the correct ball position is unambiguous.
      final timeline = _timeline(now - 30 * _minute, now + 30 * _minute);

      // Narrow (portrait-like) layout first, then let the glide begin.
      await tester.pumpWidget(
        _host(width: 220, child: TimeScrubWidget(timeline: timeline)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Widen (landscape-like). The scrubber must snap the ball to its true
      // proportional position for the NEW track width instead of keeping the
      // stale absolute pixel offset from the narrow layout. We read the
      // anchor frame directly (no extra pump) before the glide resumes.
      await tester.pumpWidget(
        _host(width: 760, child: TimeScrubWidget(timeline: timeline)),
      );

      final ballPos = tester.widget<AnimatedPositioned>(
        find.ancestor(of: _pulse, matching: find.byType(AnimatedPositioned)),
      );

      // New track width = (760 - 20).clamp(120, 600) = 600; travel = 600 - 10.
      // On the re-anchor frame the ball snaps (duration 0) to its true ~50%
      // position (~295). The pre-fix behavior kept animating toward the end
      // target (590) with a non-zero duration from a stale start.
      expect(ballPos.duration, Duration.zero);
      expect(ballPos.left, isNotNull);
      expect(ballPos.left!, closeTo(295, 45));
      expect(tester.takeException(), isNull);
    });
  });
}

extension _CurrentScrub on WidgetTester {
  Future<void> pumpScrubCurrent(int now) async {
    await _pumpScrub(
      this,
      width: 320,
      timeline: _timeline(now - 30 * _minute, now + 30 * _minute),
    );
  }
}
