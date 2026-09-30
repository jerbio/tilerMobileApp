import 'package:shared_preferences/shared_preferences.dart';

/// The two segments of the TileShare hub (redesign T6).
enum HubSegment { attention, clusters }

/// Remembers the segment the user was last on. An interface so the hub can be
/// tested without the platform.
abstract class TileShareHubPreferences {
  /// `null` when nothing (valid) is stored.
  Future<HubSegment?> lastSegment();

  Future<void> setLastSegment(HubSegment segment);
}

/// The [SharedPreferences] implementation; never throws on absent or corrupt
/// values.
class StoredTileShareHubPreferences implements TileShareHubPreferences {
  static const String _key = 'tileShareHubSegment';

  const StoredTileShareHubPreferences();

  @override
  Future<HubSegment?> lastSegment() async {
    final prefs = await SharedPreferences.getInstance();
    final Object? stored = prefs.get(_key);
    if (stored is! String) return null;
    for (final HubSegment segment in HubSegment.values) {
      if (segment.name == stored) return segment;
    }
    return null;
  }

  @override
  Future<void> setLastSegment(HubSegment segment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, segment.name);
  }
}
