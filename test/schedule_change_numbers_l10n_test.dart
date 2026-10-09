// Numbers in schedule-change text follow the user's language: counts use
// the locale's number format, and every duration uses the app's one short
// duration format, so units never mix within a language.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

AppLocalizations l10nFor(String locale) =>
    lookupAppLocalizations(Locale(locale));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('counts use the locale number format', () {
    test('thousands are grouped the local way', () {
      expect(l10nFor('en').scheduleChangeTilesMoved(1234),
          '1,234 Tiles moved');
      expect(l10nFor('de').scheduleChangeTilesMoved(1234),
          '1.234 Kacheln verschoben');
      expect(l10nFor('fr').scheduleChangeTilesMoving(1234),
          contains('1 234'));
    });

    test('plural forms still follow the language', () {
      expect(l10nFor('en').scheduleChangeTilesMoved(1), '1 Tile moved');
      expect(l10nFor('pt').scheduleChangeTilesRemoved(2), '2 blocos removidos');
      expect(l10nFor('ja').scheduleChangeTilesMovedLater(3),
          '3件のタイルを後ろに移動');
    });
  });

  group('durations use one style per language', () {
    Future<Map<String, String>> render(
        WidgetTester tester, String locale, List<Duration> values) async {
      final out = <String, String>{};
      await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          for (final value in values) {
            out['${value.inMinutes}'] = value.toHumanLocalized(context);
          }
          out['free'] = AppLocalizations.of(context)!.scheduleChangeFreeGained(
              const Duration(minutes: 16).toHumanLocalized(context));
          return const SizedBox();
        }),
      ));
      return out;
    }

    const values = [Duration(minutes: 45), Duration(minutes: 339)];

    testWidgets('German', (tester) async {
      final out = await render(tester, 'de', values);
      expect(out['45'], '45 min');
      expect(out['339'], '5 Std 39 min');
      expect(out['free'], '+16 min frei');
    });

    testWidgets('Japanese uses 時間 for hours', (tester) async {
      final out = await render(tester, 'ja', values);
      expect(out['45'], '45分');
      expect(out['339'], '5時間39分');
      expect(out['free'], '空き時間 +16分');
    });

    testWidgets('Greek', (tester) async {
      final out = await render(tester, 'el', values);
      expect(out['339'], '5ω 39λ');
      expect(out['free'], '+16λ ελεύθερα');
    });

    testWidgets('Spanish', (tester) async {
      final out = await render(tester, 'es', values);
      expect(out['339'], '5h 39m');
      expect(out['free'], '+16m libres');
    });
  });
}
