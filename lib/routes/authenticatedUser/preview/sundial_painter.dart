import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/sundial_geometry.dart';

/// Renders the semi-circle "sundial" progress arc used by the preview card.
///
/// In percent mode it draws a background arc and a foreground arc whose
/// sweep is proportional to [progress] (0..1). In composition mode it
/// draws three coloured sweeps proportional to the [tilesCount],
/// [blocksCount], and [nonViableCount] inputs.
class SundialPainter extends CustomPainter {
  /// 0..1 completion fraction. Required for percent mode, ignored for
  /// composition mode.
  final double progress;

  /// When true, paints the three-sweep composition arc instead of the
  /// percent arc.
  final bool isCompositionMode;

  final int tilesCount;
  final int blocksCount;
  final int nonViableCount;

  final Color trackColor;
  final Color progressColor;
  final Color tilesColor;
  final Color blocksColor;
  final Color nonViableColor;

  final double strokeWidth;

  SundialPainter({
    this.progress = 0.0,
    this.isCompositionMode = false,
    this.tilesCount = 0,
    this.blocksCount = 0,
    this.nonViableCount = 0,
    required this.trackColor,
    required this.progressColor,
    required this.tilesColor,
    required this.blocksColor,
    required this.nonViableColor,
    this.strokeWidth = 18.0,
  });

  /// Angular inset (radians) applied at each end of the half-circle.
  /// Set to 0 so the arc ends sit flush with the diameter line, matching
  /// the Figma comp.
  static const double _endInset = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Effective sweep range after subtracting the inset at both ends.
    final usableSweep = math.pi - 2 * _endInset;
    final scale = usableSweep / math.pi;
    final arcStart = math.pi + _endInset;

    // Background half-circle (with the end gap baked in).
    canvas.drawArc(
      rect,
      arcStart,
      usableSweep,
      false,
      Paint.from(basePaint)..color = trackColor,
    );

    if (isCompositionMode) {
      final sweeps = compositionArcSweeps(
        tiles: tilesCount,
        blocks: blocksCount,
        nonViable: nonViableCount,
      );
      var start = arcStart;
      if (sweeps.tiles > 0) {
        final s = sweeps.tiles * scale;
        canvas.drawArc(
            rect, start, s, false, Paint.from(basePaint)..color = tilesColor);
        start += s;
      }
      if (sweeps.blocks > 0) {
        final s = sweeps.blocks * scale;
        canvas.drawArc(
            rect, start, s, false, Paint.from(basePaint)..color = blocksColor);
        start += s;
      }
      if (sweeps.nonViable > 0) {
        final s = sweeps.nonViable * scale;
        canvas.drawArc(rect, start, s, false,
            Paint.from(basePaint)..color = nonViableColor);
      }
    } else {
      final sweep = percentArcSweep(progress) * scale;
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          arcStart,
          sweep,
          false,
          Paint.from(basePaint)..color = progressColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SundialPainter old) {
    return progress != old.progress ||
        isCompositionMode != old.isCompositionMode ||
        tilesCount != old.tilesCount ||
        blocksCount != old.blocksCount ||
        nonViableCount != old.nonViableCount ||
        trackColor != old.trackColor ||
        progressColor != old.progressColor ||
        tilesColor != old.tilesColor ||
        blocksColor != old.blocksColor ||
        nonViableColor != old.nonViableColor ||
        strokeWidth != old.strokeWidth;
  }
}
