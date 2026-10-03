/// Turns on the redesigned TileShare screens as they are built (see
/// docs/tileshare-redesign-design.md). Off by default, so the released app keeps
/// today's screens until the redesign is complete.
///
/// Run with `--dart-define=TILESHARE_V2=true`.
const bool kTileShareV2 = bool.fromEnvironment('TILESHARE_V2');

/// Turns on the new one-scaffold detail (redesign Step 9.12) on its own, so the
/// hub can be tried with today's detail screens while the mode contents
/// (9.13-9.16) are built. Removed with the old screens in 9.17.
///
/// Run with `--dart-define=TILESHARE_DETAIL_V2=true`.
const bool kTileShareDetailV2 = bool.fromEnvironment('TILESHARE_DETAIL_V2');
