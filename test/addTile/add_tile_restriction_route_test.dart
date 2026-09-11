// Opening "Custom Restrictions" must not crash (D57).
//
// Reported on device: tapping it inside the restriction profile screen threw.
//
// `TimeRestrictionRouteState.build` constructed `_PreloadedRestrictionsRoute()`
// with NO params, so `widget.params` was always null inside it — and the
// button wrote to it through a `!`. Two consequences, one visible:
//
//   * the null check threw, which is what the user hit;
//   * even without the throw, the seeded profile never reached the custom
//     editor and the edited one never came back, because both travel in that
//     same argument map.
//
// This is the screen the Preferred time "Custom" chip opens (D31/D34), so the
// redesign routes users straight into it. The defect is in the legacy screen
// and predates the redesign.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/customTimeRestrictions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/timeRestrictionRoute.dart';
import 'package:tiler_app/theme/theme_data.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

/// The arguments the custom editor was pushed with, recorded by the harness.
Object? customRouteArguments;

Future<void> pumpRestrictionRoute(
  WidgetTester tester, {
  Map<String, dynamic>? arguments,
}) async {
  customRouteArguments = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // One Navigator, dispatching by name — a nested Navigator would swallow
    // the push and never resolve '/CustomRestrictionsRoute'.
    onGenerateRoute: (RouteSettings settings) {
      if (settings.name == '/CustomRestrictionsRoute') {
        customRouteArguments = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => CustomTimeRestrictionRoute(),
          settings: settings,
        );
      }
      return MaterialPageRoute<void>(
        builder: (_) => TimeRestrictionRoute(),
        settings: RouteSettings(
          name: '/TimeRestrictionRoute',
          arguments: arguments,
        ),
      );
    },
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('The restriction route passes its arguments inward', () {
    testWidgets('opening Custom Restrictions does not throw', (tester) async {
      // The reported crash. Pushed WITH arguments, which is how the redesign's
      // advanced-restriction adapter opens it.
      await pumpRestrictionRoute(tester, arguments: <String, dynamic>{
        'routeRestrictionProfile': null,
        'stackRouteHistory': <String?>[null],
      });

      final Finder custom = find.byType(ElevatedButton);
      expect(custom, findsWidgets, reason: 'precondition: the button renders');

      await tester.tap(custom.last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('it survives being pushed with NO arguments', (tester) async {
      // A caller with nowhere to put a result is a caller with nowhere to put
      // a result — not a crash. This is the exact shape that threw.
      await pumpRestrictionRoute(tester);

      final Finder custom = find.byType(ElevatedButton);
      expect(custom, findsWidgets);

      await tester.tap(custom.last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the caller map reaches the custom editor', (tester) async {
      // Not just "did not crash". The seeded profile and the edited one both
      // travel in this map, so if it does not arrive the editor silently
      // starts blank and its result goes nowhere — which is what happened
      // while the inner widget was built with no params at all (D57).
      final Map<String, dynamic> arguments = <String, dynamic>{
        'routeRestrictionProfile': null,
        'stackRouteHistory': <String?>[null],
      };
      await pumpRestrictionRoute(tester, arguments: arguments);

      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(customRouteArguments, same(arguments),
          reason: 'the editor must receive the SAME map, since that is how '
              'its result travels back to the caller');
      expect((customRouteArguments as Map).containsKey('restrictionProfile'),
          isTrue,
          reason: 'the profile slot must be seeded before the push');
    });

    testWidgets('the custom editor is actually reached', (tester) async {
      // Not just "did not throw": the point of the button is to navigate.
      await pumpRestrictionRoute(tester, arguments: <String, dynamic>{
        'stackRouteHistory': <String?>[null],
      });

      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(find.byType(CustomTimeRestrictionRoute), findsOneWidget);
    });
  });
}
