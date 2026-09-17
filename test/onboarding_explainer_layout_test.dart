import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/welcome/tilesVsBlocksExplainer.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onboardingExplainerRoute.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(640, 360),
    const Size(800, 1280)
  ]) {
    for (final language in ['en', 'es']) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final dark in [false, true]) {
          testWidgets('demo $size $language text=$scale dark=$dark',
              (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            await tester.runAsync(() async {
              final loader = FontLoader('Rubik');
              for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
                loader.addFont(rootBundle
                    .load('assets/fonts/Rubik/static/Rubik-$weight.ttf'));
              }
              await loader.load();
            });
            await tester.pumpWidget(MaterialApp(
              theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
              locale: Locale(language),
              supportedLocales: const [Locale('en'), Locale('es')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: OnboardingExplainerScreen(
                destinationBuilder: (_) => const Scaffold(body: Text('Done')),
              ),
            ));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final caption =
                find.byKey(const ValueKey<ExplainerBeat>(ExplainerBeat.replan));
            final paragraph = tester.renderObject<RenderParagraph>(caption);
            expect(paragraph.didExceedMaxLines, isFalse,
                reason:
                    'The dentist and tile explanation must remain readable.');
            final button = find.byType(ElevatedButton);
            await tester.ensureVisible(button);
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(find.text('Done'), findsOneWidget);
          });
        }
      }
    }
  }
}
