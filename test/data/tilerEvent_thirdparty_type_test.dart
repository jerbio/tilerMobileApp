import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// S5-1 (Red) / S5-2 (Green) — the search wire contract (Gate A) emits the
/// canonical `thirdpartyType` spelling; the legacy mobile wire used
/// `thirdPartyType`. The parser must accept BOTH (canonical first) so the
/// schedule payload, the legacy name-search payload, and the search envelope
/// all map to the same field.
void main() {
  Map<String, dynamic> baseJson({String? typeKey, String? typeValue}) {
    final json = <String, dynamic>{
      'id': 'user_0_event',
      'name': 'Dentist',
      'start': 1700000000000,
      'end': 1700003600000,
    };
    if (typeKey != null && typeValue != null) {
      json[typeKey] = typeValue;
    }
    return json;
  }

  group('TilerEvent.fromJson thirdpartyType wire-name compat (S5-1/S5-2)', () {
    test('parses the canonical `thirdpartyType` spelling', () {
      final event = TilerEvent.fromJson(
          baseJson(typeKey: 'thirdpartyType', typeValue: 'google'));
      expect(event.thirdpartyType, TileSource.google);
    });

    test('parses the legacy `thirdPartyType` spelling', () {
      final event = TilerEvent.fromJson(
          baseJson(typeKey: 'thirdPartyType', typeValue: 'outlook'));
      expect(event.thirdpartyType, TileSource.outlook);
    });

    test('canonical spelling wins when both keys are present', () {
      final json = baseJson(typeKey: 'thirdpartyType', typeValue: 'google');
      json['thirdPartyType'] = 'outlook';
      final event = TilerEvent.fromJson(json);
      expect(event.thirdpartyType, TileSource.google);
    });

    test('unknown provider value maps to null (never throws)', () {
      final event = TilerEvent.fromJson(
          baseJson(typeKey: 'thirdpartyType', typeValue: 'bogus'));
      expect(event.thirdpartyType, isNull);
    });

    test('absent key leaves thirdpartyType null', () {
      final event = TilerEvent.fromJson(baseJson(typeKey: null));
      expect(event.thirdpartyType, isNull);
    });

    test('tiler-native rows parse to TileSource.tiler on either spelling',
          () {
      final canonical = TilerEvent.fromJson(
          baseJson(typeKey: 'thirdpartyType', typeValue: 'tiler'));
      final legacy = TilerEvent.fromJson(
          baseJson(typeKey: 'thirdPartyType', typeValue: 'tiler'));
      expect(canonical.thirdpartyType, TileSource.tiler);
      expect(legacy.thirdpartyType, TileSource.tiler);
    });
  });
}