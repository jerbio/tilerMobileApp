// TileShare redesign Step 9.9 (T7): the hub remembers which segment the user
// was last on, so a user with nothing to attend to returns where they were.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/services/tileShare/tileShareHubPreferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing stored is no answer (the caller picks the default)', () async {
    expect(await const StoredTileShareHubPreferences().lastSegment(), isNull);
  });

  test('a stored segment comes back', () async {
    const prefs = StoredTileShareHubPreferences();
    await prefs.setLastSegment(HubSegment.clusters);
    expect(await prefs.lastSegment(), HubSegment.clusters);
    await prefs.setLastSegment(HubSegment.attention);
    expect(await prefs.lastSegment(), HubSegment.attention);
  });

  test('a value it does not know, or of the wrong type, is no answer',
      () async {
    SharedPreferences.setMockInitialValues({'tileShareHubSegment': 'gone'});
    expect(await const StoredTileShareHubPreferences().lastSegment(), isNull);
    SharedPreferences.setMockInitialValues({'tileShareHubSegment': 7});
    expect(await const StoredTileShareHubPreferences().lastSegment(), isNull);
  });
}
