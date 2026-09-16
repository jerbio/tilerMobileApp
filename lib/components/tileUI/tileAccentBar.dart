import 'package:flutter/material.dart';

/// The left accent bar of a tile card, shared by the grid card and the
/// compact list card so both keep the same footprint and colour language.
///
/// Blocks (rigid) vs tiles (flexible) are told apart by the lock glyph on
/// the block's caption (P8/A) — a dashed bar for tiles was tried and
/// rejected: a stack of rounded cards with segmented edges scallops.
class TileAccentBar extends StatelessWidget {
  /// Bar width (px).
  static const double width = 4;

  final Color color;

  const TileAccentBar({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: ColoredBox(color: color));
  }
}
