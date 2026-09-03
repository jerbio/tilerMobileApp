import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

/// Traffic alert widget shown inline with travel info
/// Displays warnings like "Traffic detected - rerouting suggested"
class TrafficAlertWidget extends StatelessWidget {
  final String message;
  final TrafficAlertType type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const TrafficAlertWidget({
    Key? key,
    required this.message,
    this.type = TrafficAlertType.warning,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  Color _accentColor(TileThemeExtension tileTheme) {
    switch (type) {
      case TrafficAlertType.warning:
        return tileTheme.statusAttention;
      case TrafficAlertType.severe:
        return tileTheme.statusDanger;
      case TrafficAlertType.info:
        return TileColors.travel;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case TrafficAlertType.warning:
        return Icons.warning_amber_rounded;
      case TrafficAlertType.severe:
        return Icons.error_outline;
      case TrafficAlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color accent = _accentColor(theme.extension<TileThemeExtension>()!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 16,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum TrafficAlertType {
  info,
  warning,
  severe,
}
