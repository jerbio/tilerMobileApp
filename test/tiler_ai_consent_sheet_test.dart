// tiler_ai_consent_sheet_test.dart
//
// TDD stage 2 for the iOS AI data-sharing consent gate.
// Verifies the consent sheet discloses what data is shared and with whom
// (Google Gemini, OpenAI), exposes a privacy-policy link, and returns a
// boolean result: true only when the user taps the affirmative CTA, false when
// the sheet is dismissed via the close control (there is no decline button).
//
// See docs/ios-ai-consent-plan.md and docs/ios-ai-consent-tracker.md.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/vibeChat/tilerAiConsentSheet.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

Widget _harness({required void Function(bool) onResult}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await showTilerAiConsentSheet(context);
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TilerAiConsentSheet', () {
    testWidgets('discloses data, both providers and a privacy link',
        (tester) async {
      await tester.pumpWidget(_harness(onResult: (_) {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Names both third-party providers explicitly.
      expect(find.textContaining('Google Gemini'), findsWidgets);
      expect(find.textContaining('OpenAI'), findsWidgets);

      // Discloses what is sent and offers a privacy policy link + affirmative CTA.
      expect(find.text('What we send'), findsOneWidget);
      expect(find.text('Read our Privacy Policy'), findsOneWidget);
      expect(find.text('Continue to Tiler AI'), findsOneWidget);

      // Makes clear that tapping Continue is the act of granting permission.
      expect(
        find.textContaining('By continuing, you agree to share'),
        findsOneWidget,
      );
    });

    testWidgets('returns true when the affirmative CTA is tapped',
        (tester) async {
      bool? result;
      await tester.pumpWidget(_harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue to Tiler AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Tiler AI'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false when dismissed via the close control',
        (tester) async {
      bool? result;
      await tester.pumpWidget(_harness(onResult: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
