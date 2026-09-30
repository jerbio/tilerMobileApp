import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';

/// The colour family of a [TileShareStatusPill].
enum StatusPillTone { primary, warning, danger, success, info, neutral }

/// A short status label (redesign §5.6): a tinted pill with a coloured dot and
/// the text in the normal text colour, so it reads in light and dark themes
/// and never depends on colour alone.
class TileShareStatusPill extends StatelessWidget {
  final String label;
  final StatusPillTone tone;

  const TileShareStatusPill({
    super.key,
    required this.label,
    this.tone = StatusPillTone.neutral,
  });

  static Color colorOf(ColorScheme scheme, StatusPillTone tone) {
    switch (tone) {
      case StatusPillTone.primary:
        return scheme.primary;
      case StatusPillTone.warning:
        return TileColors.progressMedium;
      case StatusPillTone.danger:
        return scheme.error;
      case StatusPillTone.success:
        return TileColors.acceptedTileShare;
      case StatusPillTone.info:
        return scheme.tertiary;
      case StatusPillTone.neutral:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = colorOf(theme.colorScheme, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
              child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          )),
        ],
      ),
    );
  }
}
