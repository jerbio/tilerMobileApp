// TileShare redesign Step 9.1 (docs/tileshare-redesign-design.md, T2 / O9):
// the cluster `Mode` — broadcast / class / project.
//   * the backend request key is `Mode` (PascalCase, like the other request
//     fields); values are lower-case strings;
//   * the response key is read as `mode` or `Mode`, values case-insensitive;
//   * the client resolves the mode from the backend value when present, else
//     from the legacy `isMultiTilette` flag — and a missing value NEVER
//     yields Class (the legacy flag cannot express it).
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/tileShareClusterModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';

TileShareClusterData _cluster([Map<String, dynamic> extra = const {}]) =>
    TileShareClusterData.fromJson({'id': 'c1', 'name': 'Launch Prep', ...extra});

void main() {
  group('TileShareMode.tryParse / wire', () {
    test('parses the three backend values, any casing, trimmed', () {
      expect(TileShareMode.tryParse('broadcast'), TileShareMode.broadcast);
      expect(TileShareMode.tryParse('Broadcast'), TileShareMode.broadcast);
      expect(TileShareMode.tryParse(' CLASS '), TileShareMode.class_);
      expect(TileShareMode.tryParse('class'), TileShareMode.class_);
      expect(TileShareMode.tryParse('Project'), TileShareMode.project);
    });

    test('anything else is null, never a guess or a throw', () {
      for (final Object? raw in <Object?>[null, '', '  ', 'garbage', 'plan', 42, true]) {
        expect(TileShareMode.tryParse(raw), isNull, reason: '$raw');
      }
    });

    test('wire names are the lower-case backend values', () {
      expect(TileShareMode.broadcast.wire, 'broadcast');
      expect(TileShareMode.class_.wire, 'class');
      expect(TileShareMode.project.wire, 'project');
    });
  });

  group('TileShareMode.fromCluster', () {
    test('the backend mode wins over the legacy flag', () {
      expect(
          TileShareMode.fromCluster(
              _cluster({'mode': 'class', 'isMultiTilette': false})),
          TileShareMode.class_);
      expect(
          TileShareMode.fromCluster(
              _cluster({'mode': 'broadcast', 'isMultiTilette': true})),
          TileShareMode.broadcast);
      expect(
          TileShareMode.fromCluster(
              _cluster({'mode': 'project', 'isMultiTilette': false})),
          TileShareMode.project);
    });

    test('legacy fallback: single → broadcast, multi → project', () {
      expect(TileShareMode.fromCluster(_cluster({'isMultiTilette': false})),
          TileShareMode.broadcast);
      expect(TileShareMode.fromCluster(_cluster({'isMultiTilette': true})),
          TileShareMode.project);
      expect(TileShareMode.fromCluster(_cluster()), TileShareMode.broadcast,
          reason: 'no signal at all → the simplest mode');
    });

    test('a missing or unknown mode never yields class', () {
      for (final extra in <Map<String, dynamic>>[
        {},
        {'mode': 'garbage'},
        {'mode': null},
        {'isMultiTilette': true},
        {'isMultiTilette': false},
      ]) {
        expect(TileShareMode.fromCluster(_cluster(extra)),
            isNot(TileShareMode.class_),
            reason: '$extra');
      }
    });
  });

  group('TileShareClusterData.fromJson reads the mode', () {
    test('key `mode` or `Mode`, values in any casing', () {
      expect(_cluster({'mode': 'class'}).mode, TileShareMode.class_);
      expect(_cluster({'Mode': 'Project'}).mode, TileShareMode.project);
      expect(_cluster({'mode': 'BROADCAST'}).mode, TileShareMode.broadcast);
    });

    test('absent / unknown → null (the resolver falls back)', () {
      expect(_cluster().mode, isNull);
      expect(_cluster({'mode': 'garbage'}).mode, isNull);
      expect(_cluster({'mode': 7}).mode, isNull);
    });
  });

  group('TileShareClusterModel carries `Mode` on the request', () {
    test('serialises under the PascalCase key `Mode`', () {
      final model = TileShareClusterModel()
        ..Name = 'Launch Prep'
        ..Mode = 'class';
      expect(model.toJson()['Mode'], 'class');
      expect(TileShareClusterModel.fromJson(model.toJson()).Mode, 'class');
    });

    test('toTemplateClusterModel sends Mode only when the mode is explicit',
        () {
      final explicit = _cluster()..mode = TileShareMode.class_;
      expect(explicit.toTemplateClusterModel().Mode, 'class');

      final legacy = _cluster()..isMultiTilette = true;
      expect(legacy.toTemplateClusterModel().Mode, isNull,
          reason: 'legacy create flows keep their exact payload');
    });
  });
}
