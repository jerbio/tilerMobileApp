// Tests for TimeScrubGeometry — the pure proportion/width math behind the
// timeline scrubber.
//
// These lock in the behavior that:
//   * progress is clamped to [0, 1] and is proportional to elapsed time,
//   * the moving ball and the "used up" fill share the SAME track so their
//     edges stay visually aligned (regression guard for the disproportionate
//     fill bug where ball and fill used different denominators),
//   * geometry is derived from a caller-supplied track width so the scrubber
//     can be made responsive instead of a hardcoded 280px.

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tileUI/timeScrubGeometry.dart';

const int _minute = 60 * 1000;
const int _hour = 60 * _minute;

// A fixed reference instant so tests are deterministic.
int _t(int msOffsetFromStart, {int start = 0}) => start + msOffsetFromStart;

void main() {
  group('TimeScrubGeometry.progress', () {
    test('is 0 at the start instant', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 0);
      expect(geo.progress, 0.0);
    });

    test('is 1 at the end instant', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: _hour);
      expect(geo.progress, 1.0);
    });

    test('is 0.5 halfway through', () {
      final geo =
          TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 30 * _minute);
      expect(geo.progress, closeTo(0.5, 1e-9));
    });

    test('clamps to 0 before the start', () {
      final geo = TimeScrubGeometry(startMs: _hour, endMs: 2 * _hour, nowMs: 0);
      expect(geo.progress, 0.0);
    });

    test('clamps to 1 after the end', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 5 * _hour);
      expect(geo.progress, 1.0);
    });

    test('degenerate (end <= start) reports fully elapsed', () {
      final geo = TimeScrubGeometry(startMs: _hour, endMs: _hour, nowMs: _hour);
      expect(geo.progress, 1.0);
    });
  });

  group('TimeScrubGeometry.isActive', () {
    test('true when now is within [start, end]', () {
      final geo =
          TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 10 * _minute);
      expect(geo.isActive, isTrue);
    });

    test('true on the exact boundaries', () {
      expect(TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 0).isActive,
          isTrue);
      expect(TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: _hour).isActive,
          isTrue);
    });

    test('false before start and after end', () {
      expect(
          TimeScrubGeometry(startMs: _hour, endMs: 2 * _hour, nowMs: 0)
              .isActive,
          isFalse);
      expect(
          TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 2 * _hour)
              .isActive,
          isFalse);
    });
  });

  group('TimeScrubGeometry ball/fill along a track', () {
    const double track = 280;
    const double ball = 10;

    test('ball sits at 0 at the start', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 0);
      expect(geo.ballLeft(track, ball), 0.0);
    });

    test('ball sits at (track - ball) at the end', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: _hour);
      expect(geo.ballLeft(track, ball), track - ball);
    });

    test('fill and ball stay aligned: fill ends at the ball center', () {
      // Sample several progress points; the fill edge must equal the ball's
      // center (ballLeft + ball/2), clamped to the track. This is the core
      // regression guard against the mismatched-denominator bug.
      for (final nowMs in <int>[
        0,
        15 * _minute,
        30 * _minute,
        45 * _minute,
        _hour
      ]) {
        final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: nowMs);
        final expectedFill =
            (geo.ballLeft(track, ball) + ball / 2).clamp(0.0, track);
        expect(geo.fillWidth(track, ball), closeTo(expectedFill, 1e-9),
            reason: 'fill must track the ball center at now=$nowMs');
      }
    });

    test('fill never exceeds the track width', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: 5 * _hour);
      expect(geo.fillWidth(track, ball), lessThanOrEqualTo(track));
    });

    test('geometry scales with the supplied track width (responsive)', () {
      final geo = TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: _hour);
      // Narrow device track.
      expect(geo.ballLeft(120, ball), 120 - ball);
      // Wide device track.
      expect(geo.ballLeft(500, ball), 500 - ball);
    });

    test('ball travel is monotonic in progress', () {
      double previous = -1;
      for (int i = 0; i <= 60; i++) {
        final geo =
            TimeScrubGeometry(startMs: 0, endMs: _hour, nowMs: i * _minute);
        final left = geo.ballLeft(track, ball);
        expect(left, greaterThanOrEqualTo(previous));
        previous = left;
      }
    });
  });
}
