import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/sundial_geometry.dart';

void main() {
  group('percentArcSweep', () {
    test('returns 0 when pct is 0', () {
      expect(percentArcSweep(0.0), 0.0);
    });

    test('returns pi when pct is 1', () {
      expect(percentArcSweep(1.0), closeTo(math.pi, 1e-9));
    });

    test('returns pi/2 when pct is 0.5', () {
      expect(percentArcSweep(0.5), closeTo(math.pi / 2, 1e-9));
    });

    test('clamps negative pct to 0', () {
      expect(percentArcSweep(-0.25), 0.0);
    });

    test('clamps pct above 1 to pi', () {
      expect(percentArcSweep(1.7), closeTo(math.pi, 1e-9));
    });
  });

  group('compositionArcSweeps', () {
    test('returns zeroes when total is zero', () {
      final sweeps = compositionArcSweeps(tiles: 0, blocks: 0, nonViable: 0);
      expect(sweeps.tiles, 0.0);
      expect(sweeps.blocks, 0.0);
      expect(sweeps.nonViable, 0.0);
    });

    test('three equal counts split semicircle into thirds', () {
      final sweeps = compositionArcSweeps(tiles: 1, blocks: 1, nonViable: 1);
      expect(sweeps.tiles, closeTo(math.pi / 3, 1e-9));
      expect(sweeps.blocks, closeTo(math.pi / 3, 1e-9));
      expect(sweeps.nonViable, closeTo(math.pi / 3, 1e-9));
    });

    test('sweeps are proportional to counts', () {
      final sweeps = compositionArcSweeps(tiles: 4, blocks: 2, nonViable: 2);
      // 4:2:2 -> 50% / 25% / 25% of pi
      expect(sweeps.tiles, closeTo(math.pi / 2, 1e-9));
      expect(sweeps.blocks, closeTo(math.pi / 4, 1e-9));
      expect(sweeps.nonViable, closeTo(math.pi / 4, 1e-9));
    });

    test('sweeps sum to pi when total is positive', () {
      final sweeps = compositionArcSweeps(tiles: 7, blocks: 3, nonViable: 5);
      final sum = sweeps.tiles + sweeps.blocks + sweeps.nonViable;
      expect(sum, closeTo(math.pi, 1e-9));
    });

    test('negative counts are treated as zero', () {
      final sweeps = compositionArcSweeps(tiles: 2, blocks: -3, nonViable: 0);
      expect(sweeps.tiles, closeTo(math.pi, 1e-9));
      expect(sweeps.blocks, 0.0);
      expect(sweeps.nonViable, 0.0);
    });
  });
}
