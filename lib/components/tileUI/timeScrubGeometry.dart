/// Pure, widget-free geometry for the timeline scrubber.
///
/// Extracted from [TimeScrubWidget] so the proportion/width math can be unit
/// tested deterministically (without wall-clock time or pumping animations),
/// and so the scrubber can be made responsive by deriving all positions from a
/// caller-supplied track width instead of a hardcoded pixel constant.
///
/// The moving ball and the "used up" fill are both derived from the SAME track
/// so their edges stay visually aligned. The fill is defined to end at the
/// ball's center, which keeps the progress indication consistent regardless of
/// track width or ball size.
class TimeScrubGeometry {
  /// Occurrence start, in epoch milliseconds.
  final int startMs;

  /// Occurrence end, in epoch milliseconds.
  final int endMs;

  /// The instant to render progress for, in epoch milliseconds.
  final int nowMs;

  const TimeScrubGeometry({
    required this.startMs,
    required this.endMs,
    required this.nowMs,
  });

  /// Fraction of the occurrence that has elapsed, clamped to `[0, 1]`.
  ///
  /// A degenerate occurrence (`endMs <= startMs`) is treated as fully elapsed.
  double get progress {
    final int total = endMs - startMs;
    if (total <= 0) return 1.0;
    final double raw = (nowMs - startMs) / total;
    return raw.clamp(0.0, 1.0);
  }

  /// Whether [nowMs] falls within `[startMs, endMs]` (inclusive).
  bool get isActive => nowMs >= startMs && nowMs <= endMs;

  /// Left offset of the moving ball along a track of [trackWidth], accounting
  /// for the ball's own [ballDiameter] so it never overflows the track end.
  double ballLeft(double trackWidth, double ballDiameter) {
    final double travel =
        (trackWidth - ballDiameter).clamp(0.0, double.infinity);
    return progress * travel;
  }

  /// Width of the "used up" fill along a track of [trackWidth].
  ///
  /// The fill ends at the ball's center ([ballLeft] + half the ball) so the
  /// fill edge and the ball stay visually aligned. Clamped to the track.
  double fillWidth(double trackWidth, double ballDiameter) {
    final double center = ballLeft(trackWidth, ballDiameter) + ballDiameter / 2;
    return center.clamp(0.0, trackWidth);
  }
}
