/// How a tile is emphasised while a schedule change plays in steps.
enum TileMotionEmphasis {
  none,

  /// Raised with a shadow: this tile is about to move or is moving.
  lifted,

  /// Slightly faded so the moving tiles stand out.
  receded,
}
