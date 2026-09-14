import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileTheme = theme.extension<TileThemeExtension>()!;

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
                  ? tileTheme.statusSuccess
                  : percentage >= 40
                      ? tileTheme.statusAttention
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
