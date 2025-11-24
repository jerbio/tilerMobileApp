import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class AnalysisCheckState extends StatelessWidget {
  const AnalysisCheckState({
    super.key,
    this.isPass = false,
    this.isWarning = false,
    this.isConflict = false,
    required this.height,
  });

  final bool isPass;
  final bool isWarning;
  final bool isConflict;
  final double height;
  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    if (isPass) {
      return Container(
        width: height / (height / 24),
        height: height / (height / 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / (height / 8)),
            color: TileColors.forecastAnalysisCheck,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/check.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
        ),
      );
    } else if (isWarning) {
      return Container(
        width: height / (height / 24),
        height: height / (height / 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / (height / 8)),
            color: TileColors.forecastAnalysisWarning
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/exclamation.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
        ),
      );
    } else if (isConflict) {
      return Container(
        width: height / (height / 24),
        height: height / (height / 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / (height / 8)),
            color:  TileColors.forecastAnalysisConflict
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/exclamation.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
        ),
      );
    }
    return Container(
      width: height / (height / 24),
      height: height / (height / 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / (height / 8)),
        color:colorScheme.onSurface.withValues(alpha: 0.05),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/clock.svg',
          height: height / (height / 10),
          width: height / (height / 10),
        ),
      ),
    );
  }
}
