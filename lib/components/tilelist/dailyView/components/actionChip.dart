import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

/// A single action chip button with icon and label
class TilerActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool preview;

  const TilerActionChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.preview = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;

    return   ColorFiltered(
      colorFilter: ColorFilter.mode(
        preview
            ? tileThemeExtension.vibeChatPreviewDisableColor.withValues(alpha: 0.6)
            : Colors.transparent,
        BlendMode.srcATop,
      ),
      child: GestureDetector(
        onTap:preview?null: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
