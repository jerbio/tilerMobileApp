/// How a tile is emphasised while a schedule change plays in steps.
enum TileMotionEmphasis {
  none,

  /// Raised with a shadow: this tile is about to move or is moving.
  lifted,

  /// Slightly faded so the moving tiles stand out.
  receded,

  /// Sliding out of view above: shrinks up into the edge chip that takes
  /// its place.
  departingUp,

  /// Sliding out of view below: shrinks down into the edge chip.
  departingDown,
}

extension TileMotionEmphasisShape on TileMotionEmphasis {
  bool get isDeparting =>
      this == TileMotionEmphasis.departingUp ||
      this == TileMotionEmphasis.departingDown;
}
