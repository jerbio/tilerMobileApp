// TileShare redesign Step 9.16d (T27): the task screen's header shows the
// task's notes as markdown, as every note in the app is shown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tiletteDetailScreen.dart';

import 'helpers/tileshare_fixtures.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('the notes are rendered, not shown as raw markdown',
      (tester) async {
    await tester.pumpWidget(_app(TiletteHeader(
        tilette:
            tsDesignatedTile('d1', note: '- [ ] Pull the **Q3** numbers'))));
    expect(find.byType(MarkdownNoteView), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
  });

  testWidgets('no notes, no note', (tester) async {
    await tester.pumpWidget(_app(
        TiletteHeader(tilette: tsDesignatedTile('d1', endMs: 1791000000000))));
    expect(find.byType(MarkdownNoteView), findsNothing);
  });
}
