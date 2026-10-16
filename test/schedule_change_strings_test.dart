import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final keys = english.keys.where((key) =>
      key.startsWith('scheduleChange') ||
      key.startsWith('scheduleUpdate') ||
      key == 'durationDaysHoursShort' ||
      key == 'durationDaysShort');
  for (final locale in ['de', 'el', 'es', 'fr', 'it', 'ja', 'nl', 'pt']) {
    test('$locale explicitly defines schedule strings and their placeholders',
        () {
      final translated =
          jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in keys) {
        expect(translated.containsKey(key), isTrue,
            reason: '$locale is missing $key');
        expect(translated[key], isA<String>(), reason: '$locale $key');
        expect((translated[key] as String).trim(), isNotEmpty,
            reason: '$locale $key');
        final metadata = english['@$key'] as Map<String, dynamic>?;
        final placeholders = metadata?['placeholders'] as Map<String, dynamic>?;
        for (final name in placeholders?.keys ?? <String>[]) {
          expect(
              RegExp('\\{$name(?:\\s*[,}])')
                  .hasMatch(translated[key] as String),
              isTrue,
              reason: '$locale $key lost placeholder $name');
        }
      }
    });
  }
}
