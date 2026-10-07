// TileShare redesign Step 9.9 (T1), 9.17: the pushed /TileShare route is the
// hub - the old Activity / Outbound / Inbound tabs are retired.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareRoute.dart';
import 'package:tiler_app/theme/theme_data.dart';

Widget _app(Widget home) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('the route is the hub and none of the old tabs', (tester) async {
    await tester.pumpWidget(_app(TileShareRoute(
      hubBuilder: (_) => const Text('hub-stub'),
    )));
    await tester.pump();
    expect(find.text('hub-stub'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
  });
}
