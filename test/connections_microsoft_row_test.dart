import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/connetions.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

/// P4-2: the Microsoft connect row is live. Previously it rendered with
/// `isComingSoon: true` (a disabled "Coming soon" button); now it shows the
/// same "Configure" affordance as the Google row and its tap is wired to the
/// Microsoft connect flow. The Apple / Google Tasks / Slack rows stay
/// coming-soon (out of scope, tracker §8).
void main() {
  testWidgets('Microsoft connect row is live, the others stay coming soon',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true)
            .copyWith(
                extensions: <ThemeExtension<dynamic>>[TileThemeExtension.light]),
        home: const Connections(),
      ),
    );

    // The Microsoft row renders its live "Configure" button (not "Coming
    // soon") and the button is tappable.
    final Finder microsoftRow = find
        .ancestor(of: find.text('Microsoft'), matching: find.byType(ListTile))
        .first;
    expect(microsoftRow, findsOneWidget);

    final Finder microsoftAddButton = find
        .descendant(of: microsoftRow, matching: find.byType(TextButton))
        .first;
    expect(microsoftAddButton, findsOneWidget);
    final TextButton microsoftButton =
        tester.widget<TextButton>(microsoftAddButton);
    expect(microsoftButton.onPressed, isNotNull,
        reason: 'The Microsoft row button must be enabled (not coming soon)');
    expect(
        find.descendant(
            of: microsoftRow, matching: find.text('Configure')),
        findsOneWidget);
    expect(
        find.descendant(
            of: microsoftRow, matching: find.text('Coming soon')),
        findsNothing);

    // The Google row keeps its live button; Apple / Google Tasks / Slack
    // remain coming-soon (out of P4-2 scope).
    expect(find.text('Configure'), findsNWidgets(2));
    expect(find.text('Coming soon'), findsNWidgets(3));
  });
}