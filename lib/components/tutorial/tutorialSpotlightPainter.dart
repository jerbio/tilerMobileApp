import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';

/// Custom painter that draws a semi-transparent overlay with a
/// spotlight cutout around the target widget area.
class TutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double padding;
  final SpotlightShape shape;
  final double animationValue;

  TutorialSpotlightPainter({
    this.targetRect,
    this.padding = 8.0,
    this.shape = SpotlightShape.roundedRect,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7 * animationValue)
      ..style = PaintingStyle.fill;

    // Draw full-screen overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      // Create the cutout path
      final paddedRect = targetRect!.inflate(padding);
      Path cutoutPath;

      if (shape == SpotlightShape.circle) {
        final center = paddedRect.center;
        final radius = paddedRect.longestSide / 2;
        cutoutPath = Path()
          ..addOval(Rect.fromCircle(center: center, radius: radius));
      } else {
        cutoutPath = Path()
          ..addRRect(RRect.fromRectAndRadius(
            paddedRect,
            Radius.circular(12.0),
          ));
      }

      // Combine: overlay minus cutout
      final combinedPath = Path.combine(
        PathOperation.difference,
        overlayPath,
        cutoutPath,
      );
      canvas.drawPath(combinedPath, overlayPaint);

      // Draw a subtle pulse border around the cutout
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6 * animationValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      if (shape == SpotlightShape.circle) {
        final center = paddedRect.center;
        final radius = paddedRect.longestSide / 2;
        canvas.drawCircle(center, radius, borderPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(paddedRect, Radius.circular(12.0)),
          borderPaint,
        );
      }
    } else {
      // No target — just draw the full overlay
      canvas.drawPath(overlayPath, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.shape != shape;
  }
}
