import 'dart:math' as math;

/// Sweep angle in radians for the percent arc, given a 0..1 completion
/// fraction. The full background arc spans `pi` (a half circle).
double percentArcSweep(double pct) {
  final clamped = pct.clamp(0.0, 1.0);
  return clamped * math.pi;
}

/// Proportional sweep angles for the empty-state composition arc.
/// Each sweep is in radians; the three sweeps sum to `pi` when at least
/// one count is positive, and to `0` when all counts are zero / negative.
class CompositionArcSweeps {
  final double tiles;
  final double blocks;
  final double nonViable;

  const CompositionArcSweeps({
    required this.tiles,
    required this.blocks,
    required this.nonViable,
  });
}

CompositionArcSweeps compositionArcSweeps({
  required int tiles,
  required int blocks,
  required int nonViable,
}) {
  final t = tiles < 0 ? 0 : tiles;
  final b = blocks < 0 ? 0 : blocks;
  final n = nonViable < 0 ? 0 : nonViable;
  final total = t + b + n;
  if (total == 0) {
    return const CompositionArcSweeps(
      tiles: 0,
      blocks: 0,
      nonViable: 0,
    );
  }
  return CompositionArcSweeps(
    tiles: math.pi * t / total,
    blocks: math.pi * b / total,
    nonViable: math.pi * n / total,
  );
}
