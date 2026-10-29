import 'package:flutter/material.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';

/// The sharing mode as a small tinted icon tile (redesign §5.5): Broadcast,
/// Class or Project. An unknown mode (the server did not say, and it has not
/// been looked up yet) shows a neutral share glyph.
class TileShareModeBadge extends StatelessWidget {
  final TileShareMode? mode;
  final double size;

  const TileShareModeBadge({super.key, required this.mode, this.size = 40});

  static IconData iconOf(TileShareMode? mode) {
    switch (mode) {
      case TileShareMode.broadcast:
        return Icons.campaign_outlined;
      case TileShareMode.class_:
        return Icons.groups_2_outlined;
      case TileShareMode.project:
        return Icons.view_kanban_outlined;
      case null:
        return Icons.share_outlined;
    }
  }

  /// The localized name; `null` for an unknown mode.
  static String? labelOf(AppLocalizations l10n, TileShareMode? mode) {
    switch (mode) {
      case TileShareMode.broadcast:
        return l10n.tileShareModeBroadcast;
      case TileShareMode.class_:
        return l10n.tileShareModeClass;
      case TileShareMode.project:
        return l10n.tileShareModeProject;
      case null:
        return null;
    }
  }

  /// Class and Project keep distinct mode colours in both themes.
  static Color colorOf(ColorScheme scheme, TileShareMode? mode) {
    switch (mode) {
      case TileShareMode.broadcast:
        return scheme.primary;
      case TileShareMode.class_:
        return scheme.tertiary;
      case TileShareMode.project:
        return TileColors.responseTileShare;
      case null:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tone = colorOf(scheme, mode);
    final String? label = labelOf(AppLocalizations.of(context)!, mode);
    final Widget tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(iconOf(mode), color: tone, size: size * 0.55),
    );
    return label == null
        ? ExcludeSemantics(child: tile)
        : Semantics(label: label, child: ExcludeSemantics(child: tile));
  }
}
