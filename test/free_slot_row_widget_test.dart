import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/freeSlot.dart';
import 'package:tiler_app/components/tilelist/freeSlotRow.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Wraps [FreeSlotRow] in the app's localization + theme harness.
Widget _harness(FreeSlot slot, {bool preview = false}) {
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
      body: SizedBox(
        width: 400,
        child: FreeSlotRow(slot: slot, preview: preview),
      ),
    ),
  );
}

FreeSlot _liveSlot() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return FreeSlot(
    startMs: now - const Duration(minutes: 20).inMilliseconds,
    endMs: now + const Duration(minutes: 90).inMilliseconds,
    isLive: true,
  );
}

FreeSlot _upcomingSlot() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return FreeSlot(
    startMs: now + const Duration(hours: 2).inMilliseconds,
    endMs: now + const Duration(hours: 3).inMilliseconds,
    isLive: false,
  );
}

void main() {
  final footerFinder = find.byKey(const ValueKey('freeSlotLiveFooter'));

  testWidgets('live slot renders the countdown + scrubber footer',
      (tester) async {
    await tester.pumpWidget(_harness(_liveSlot()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(footerFinder, findsOneWidget);
    // The opportunity glyph and a depleting bar live inside the footer.
    expect(
      find.descendant(
        of: footerFinder,
        matching: find.byIcon(Icons.auto_awesome_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: footerFinder,
        matching: find.byType(FractionallySizedBox),
      ),
      findsOneWidget,
    );

    // Advance the periodic ticker; the row must survive a refresh tick.
    await tester.pump(const Duration(seconds: 1));
    expect(footerFinder, findsOneWidget);
  });

  testWidgets('non-live slot does not render the live footer', (tester) async {
    await tester.pumpWidget(_harness(_upcomingSlot()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(footerFinder, findsNothing);
  });
}
