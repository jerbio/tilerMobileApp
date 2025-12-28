import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Circular completion indicator showing percentage progress
class CompletionIndicator extends StatelessWidget {
  final int percentage;
  final double size;
  final double strokeWidth;

  const CompletionIndicator({
    Key? key,
    required this.percentage,
    this.size = 45,
    this.strokeWidth = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: strokeWidth,
            backgroundColor: colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 70
                  ? TileColors.completedTeal
                  : percentage >= 40
                      ? TileColors.progressMedium
                      : colorScheme.primary,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
