/// Turns on the redesigned TileShare screens as they are built (see
/// docs/tileshare-redesign-design.md). Off by default, so the released app keeps
/// today's screens until the redesign is complete.
///
/// Run with `--dart-define=TILESHARE_V2=true`.
const bool kTileShareV2 = bool.fromEnvironment('TILESHARE_V2');
