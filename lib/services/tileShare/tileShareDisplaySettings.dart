import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tileShareLog.dart';

enum TiletteDensity { comfortable, compact, list }

abstract class TileShareDisplayPreferences {
  Future<TiletteDensity?> readDensity();
  Future<void> writeDensity(TiletteDensity density);
}

class StoredTileShareDisplayPreferences implements TileShareDisplayPreferences {
  static const key = 'tileShareDisplayDensity';
  const StoredTileShareDisplayPreferences();

  @override
  Future<TiletteDensity?> readDensity() async {
    final value = (await SharedPreferences.getInstance()).get(key);
    for (final density in TiletteDensity.values) {
      if (value == density.name) return density;
    }
    return null;
  }

  @override
  Future<void> writeDensity(TiletteDensity density) async {
    if (!await (await SharedPreferences.getInstance())
        .setString(key, density.name)) {
      throw StateError('Display preference was not saved');
    }
  }
}

/// Rendering updates immediately. Preference failures never block share work.
class TileShareDisplaySettings extends ChangeNotifier {
  final TileShareDisplayPreferences? _preferences;
  TiletteDensity _density;
  bool _scrolled = false;
  bool _loadingStarted = false;
  bool _disposed = false;
  int _revision = 0;
  Future<void> _writes = Future<void>.value();

  TileShareDisplaySettings({TileShareDisplayPreferences? preferences})
      : _preferences = preferences ?? const StoredTileShareDisplayPreferences(),
        _density = TiletteDensity.compact;

  TileShareDisplaySettings.memory(
      {TiletteDensity density = TiletteDensity.compact})
      : _preferences = null,
        _density = density;

  TiletteDensity get density => _density;
  bool get condensedSummary =>
      _scrolled || _density != TiletteDensity.comfortable;

  Future<void> load() async {
    if (_loadingStarted || _disposed) return;
    _loadingStarted = true;
    final revision = _revision;
    try {
      final saved = await _preferences?.readDensity();
      if (_disposed ||
          revision != _revision ||
          saved == null ||
          saved == _density) return;
      _density = saved;
      notifyListeners();
    } catch (error) {
      TileShareLog.d('TileShareDisplay',
          'reading preference failed: ${TileShareLog.describe(error)}');
    }
  }

  Future<void> setDensity(TiletteDensity density) {
    if (_disposed) return Future<void>.value();
    _revision++;
    if (_density != density) {
      _density = density;
      notifyListeners();
    }
    // Serialize writes so a slower earlier choice cannot overwrite a newer one.
    _writes = _writes.then((_) async {
      try {
        await _preferences?.writeDensity(density);
      } catch (error) {
        TileShareLog.d('TileShareDisplay',
            'saving preference failed: ${TileShareLog.describe(error)}');
      }
    });
    return _writes;
  }

  void updateScroll(double offset) {
    final next = offset > 120
        ? true
        : offset <= 0
            ? false
            : _scrolled;
    if (!_disposed && next != _scrolled) {
      _scrolled = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
