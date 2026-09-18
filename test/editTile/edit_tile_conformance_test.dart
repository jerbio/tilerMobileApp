// Step 3.6 — mockup conformance, gaps G1, G4, G6 (plan §4.4).
//
// G2 (repeat detail), G3 (location row) and G5 (callouts) belong to the
// calendar event since D19 and are pinned by the Tile Detail tests. D18
// (Notes as a plain row) was taken on its default.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRedesignScreen.dart'
    show TileDetailDeleted;

import '../addTile/l10n_fixture.dart';
import 'edit_tile_phase2_test.dart' as p2;
import 'edit_tile_shell_test.dart' as shell;

Finder key(String k) => find.byKey(ValueKey(k));

String? openedSeriesId;

/// What the (fake) Tile details pops with.
Object? seriesResult;

Future<void> open(WidgetTester tester,
    {bool withSeries = true, String? note, Location? location}) async {
  openedSeriesId = null;
  seriesResult = null;
  await shell.pumpEdit(
    tester,
    tile: p2.tile(
      calendarEvent: withSeries ? p2.series() : null,
      note: note,
      location: location,
    ),
    openSeries: (_, String calendarEventId) async {
      openedSeriesId = calendarEventId;
      return seriesResult;
    },
  );
}

Future<void> reveal(WidgetTester tester, Finder f) => p2.reveal(tester, f);

void main() {
  group('G1 header: close and menu', () {
    testWidgets('a ✕ closes, asking first when dirty; no back arrow',
        (tester) async {
      await open(tester);
      expect(key('editTileClose'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      await tester.enterText(shell.titleField, 'Edited');
      await tester.pump();
      await tester.tap(key('editTileClose'));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.editTileDiscardTitle), findsOneWidget);
    });

    testWidgets(
        'the top-right button IS Tile details: one tap, no menu (2026-09-16)',
        (tester) async {
      await open(tester);
      expect(key('editTileMenu'), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(key('editTileDetails'), findsOneWidget);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester.getSemantics(key('editTileDetails')),
          matchesSemantics(
              isButton: true,
              hasTapAction: true,
              hasFocusAction: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
              // A native IconButton names itself through its tooltip.
              tooltip: testL10n.editTileMenuTileDetails),
          reason: 'a glyph needs its name for assistive tech');
      h.dispose();
    });

    testWidgets('Tile details opens the series and reloads on return',
        (tester) async {
      await open(tester);
      await tester.tap(key('editTileDetails'));
      await tester.pumpAndSettle();
      expect(openedSeriesId, 'cal-1');
      expect(shell.loader.calls, 2,
          reason: 'the series screen may have changed what this tile shows');
    });

    testWidgets(
        'a series deleted from Tile details pops Edit Tile too, without '
        'reloading the occurrence that no longer exists (2026-09-17)',
        (tester) async {
      await open(tester);
      seriesResult = const TileDetailDeleted(null);
      await tester.tap(key('editTileDetails'));
      await tester.pumpAndSettle();
      expect(shell.loader.calls, 1, reason: 'no reload of a deleted tile');
      expect(find.byType(EditTileRedesignScreen), findsNothing,
          reason: 'the occurrence is gone with its series');
    });

    testWidgets('no series → no Tile details button', (tester) async {
      await open(tester, withSeries: false);
      expect(key('editTileDetails'), findsNothing);
    });
  });

  group('G4 progress chevron', () {
    testWidgets('opens the series', (tester) async {
      await open(tester);
      await reveal(tester, key('editProgress'));
      await tester.tap(key('editProgress'));
      await tester.pumpAndSettle();
      expect(openedSeriesId, 'cal-1');
    });
  });

  group('G6 notes row (D18)', () {
    testWidgets('a plain row with the preview; tapping opens the notes page',
        (tester) async {
      await open(tester, note: 'bring the charts');
      await reveal(tester, key('editNotesRow'));
      expect(find.byType(NotePreviewTile), findsNothing,
          reason: 'the inline tile and its double frame are gone');
      expect(find.text('bring the charts'), findsWidgets);
      await tester.tap(key('editNotesRow'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteFullPage), findsOneWidget);
    });

    testWidgets('a long note is capped at three lines, not rendered whole',
        (tester) async {
      // Seen on device 2026-09-15: the row grew with the note. The full
      // text lives on the notes page; the row is a preview.
      final String long = List<String>.generate(
              12, (int i) => 'Paragraph $i of a very long note that goes on.')
          .join(String.fromCharCode(10));
      await open(tester, note: long);
      await reveal(tester, key('editNotesRow'));
      final Text preview = tester.widget<Text>(
          find.descendant(of: key('editNotesRow'), matching: find.text(long)));
      expect(preview.maxLines, 3);
      expect(preview.overflow, TextOverflow.ellipsis);
      final double rowHeight = tester.getSize(key('editNotesRow')).height;
      expect(rowHeight, lessThan(120), reason: '~title + 3 lines');
    });

    testWidgets('no note reads Not set', (tester) async {
      await open(tester);
      await reveal(tester, key('editNotesRow'));
      expect(
          find.descendant(
              of: key('editNotesRow'),
              matching: find.text(testL10n.addTileValueNotSet)),
          findsOneWidget);
    });
  });

  group('Accessibility and width', () {
    testWidgets('every new control is a button (D62)', (tester) async {
      await open(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      // The ⋯ is a PopupMenuButton: its tap lives on the inner IconButton
      // node, so it is checked through its descendant below.
      for (final String k in <String>[
        'editTileDetails',
        'editTileClose',
        'editNotesRow',
      ]) {
        await reveal(tester, key(k));
        expect(
            tester
                .getSemantics(key(k))
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
            reason: k);
      }
      h.dispose();
    });
  });
}
