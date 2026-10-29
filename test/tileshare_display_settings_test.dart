import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/services/tileShare/tileShareDisplaySettings.dart';

class _Preferences implements TileShareDisplayPreferences {
  final read = Completer<TiletteDensity?>();
  final firstWrite = Completer<void>();
  final writes = <TiletteDensity>[];
  bool holdFirstWrite = false;
  bool failWrite = false;

  @override
  Future<TiletteDensity?> readDensity() => read.future;

  @override
  Future<void> writeDensity(TiletteDensity value) async {
    writes.add(value);
    if (holdFirstWrite && writes.length == 1) await firstWrite.future;
    if (failWrite) throw StateError('preferences unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Compact is the default and unsupported stored values fall back safely',
      () async {
    for (final value in [null, 'future-mode', 42]) {
      SharedPreferences.setMockInitialValues({
        if (value != null) StoredTileShareDisplayPreferences.key: value,
      });
      final settings = TileShareDisplaySettings();
      addTearDown(settings.dispose);
      await settings.load();
      expect(settings.density, TiletteDensity.compact);
    }
  });

  test('a later settings instance restores the saved choice', () async {
    final first = TileShareDisplaySettings();
    addTearDown(first.dispose);
    await first.load();
    await first.setDensity(TiletteDensity.list);
    final reopened = TileShareDisplaySettings();
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.density, TiletteDensity.list);
  });

  test('a late preference read cannot overwrite a choice already made',
      () async {
    final preferences = _Preferences();
    final settings = TileShareDisplaySettings(preferences: preferences);
    addTearDown(settings.dispose);
    final loading = settings.load();
    await settings.setDensity(TiletteDensity.list);
    preferences.read.complete(TiletteDensity.comfortable);
    await loading;
    expect(settings.density, TiletteDensity.list);
  });

  test('rapid choices save in order even when the first write is slow',
      () async {
    final preferences = _Preferences()..holdFirstWrite = true;
    final settings = TileShareDisplaySettings(preferences: preferences);
    addTearDown(settings.dispose);
    final first = settings.setDensity(TiletteDensity.comfortable);
    final last = settings.setDensity(TiletteDensity.list);
    expect(settings.density, TiletteDensity.list);
    await Future<void>.delayed(Duration.zero);
    expect(preferences.writes, [TiletteDensity.comfortable]);
    preferences.firstWrite.complete();
    await Future.wait([first, last]);
    expect(
        preferences.writes, [TiletteDensity.comfortable, TiletteDensity.list]);
  });

  test('preference failures keep the current view usable', () async {
    final preferences = _Preferences()..failWrite = true;
    final settings = TileShareDisplaySettings(preferences: preferences);
    addTearDown(settings.dispose);
    final loading = settings.load();
    preferences.read.completeError(StateError('preferences unavailable'));
    await loading;
    await settings.setDensity(TiletteDensity.list);
    expect(settings.density, TiletteDensity.list);
  });

  test(
      'leaving a share while preferences load does not notify a disposed controller',
      () async {
    final preferences = _Preferences();
    final settings = TileShareDisplaySettings(preferences: preferences);
    final loading = settings.load();
    settings.dispose();
    preferences.read.complete(TiletteDensity.comfortable);
    await loading;
  });
}
