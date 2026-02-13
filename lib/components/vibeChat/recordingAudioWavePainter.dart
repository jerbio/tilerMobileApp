import 'package:flutter/material.dart';
import 'dart:math' as math;

class recordingAudioWavePainter extends CustomPainter {
  final Animation<double> animation;
  final double amplitude;
  final Color color;

  recordingAudioWavePainter({
    required this.animation,
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = animation.value * math.pi * 2;

    for (int i = 0; i < 3; i++) {
      final layerOpacity = 0.15 + (i * 0.08);
      final phase = i * 0.5;
      final heightScale = 0.5 + (i * 0.3);

      _drawSymmetricWave(canvas, size, time, phase, layerOpacity, heightScale,);
    }

    _drawSymmetricWave(canvas, size, time, 0, 0.8, 1.0);

    for (int i = 0; i < 2; i++) {
      final layerOpacity = 0.4 + (i * 0.15);
      final phase = i * 0.6 + 1.0;
      final heightScale = 0.7 + (i * 0.3);

      _drawSymmetricWave(canvas, size, time, phase, layerOpacity, heightScale);
    }
  }

  void _drawSymmetricWave(Canvas canvas, Size size, double time, double phase,
      double opacity, double heightScale) {
    final centerY = size.height / 2;
    final width = size.width;
    final topPath = Path();
    final bottomPath = Path();

    topPath.moveTo(0, centerY);
    bottomPath.moveTo(0, centerY);

    for (double x = 0; x <= width;x++) {
      final percentAcrossScreen = x / width;

      final pulseScale = math.sin(time + percentAcrossScreen * math.pi * 2 + phase) *
          (0.3 + amplitude * 0.7);

      final blobShape = math.exp(-math.pow((percentAcrossScreen - 0.5) * 3, 2));

      final baseHeight = 0.15 + (amplitude * amplitude * 0.85);
      final height = pulseScale * baseHeight * size.height * 0.4 * blobShape * heightScale;
      topPath.lineTo(x, centerY - height);
      bottomPath.lineTo(x, centerY + height);
    }

    topPath.lineTo(width, centerY);
    bottomPath.lineTo(width, centerY);
    topPath.close();
    bottomPath.close();

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(recordingAudioWavePainter oldDelegate) {
    return true;
  }
}