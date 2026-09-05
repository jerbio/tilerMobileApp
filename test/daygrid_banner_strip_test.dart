// The compact alert banner strip above the
// grid reuses the list-mode detectors (ConflictGroup.detectGroups /
// ExtendedTilesBanner.detectExtendedTiles / pending-RSVP split) and
// surfaces them as a single condensed chip row: it shows conflict /
// extended / RSVP counts from fixture tiles, is hidden when the day is
// clean, and each chip tap opens the right modal.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/pendingRsvpBanner.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridBannerStrip.dart';
import 'package:tiler_app/theme/theme_data.dart';

SubCalendarEvent _tile({
  required String id,
  required String name,
  required DateTime start,
  required DateTime end,
  RsvpStatus? rsvp,
}) {
  final tile = SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    rsvp: rsvp,
  );
  tile.isViable = true;
  return tile;
}

Widget _buildApp(List<TilerEvent> tiles) {
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
      // The strip is natural-height; a plain max-height Column pins it to
      // the top of the bounded body (SizedBox.expand in a Column would
      // lay out at infinite height).
      body: Column(children: [
        DayGridBannerStrip(tiles: tiles),
      ]),
    ),
  );
}

/// Fixture exercising all three detectors at once:
/// - c1/c2 overlap -> one conflict group of 2 tiles,
/// - ext1 spans 20h (>=16h) -> extended,
/// - rsvp1 is a third-party pending-RSVP tile with a future end date,
///   so the detector's not-yet-ended filter keeps it.
List<TilerEvent> _alertFixture() {
  return <TilerEvent>[
    _tile(
      id: 'c1',
      name: 'ConflictA',
      start: DateTime(2026, 5, 15, 9),
      end: DateTime(2026, 5, 15, 11),
    ),
    _tile(
      id: 'c2',
      name: 'ConflictB',
      start: DateTime(2026, 5, 15, 10),
      end: DateTime(2026, 5, 15, 12),
    ),
    _tile(
      id: 'ext1',
      name: 'AllDayWork',
      start: DateTime(2026, 5, 15, 0),
      end: DateTime(2026, 5, 15, 20),
    ),
    _tile(
      id: 'rsvp1',
      name: 'PendingMeeting',
      start: DateTime(2027, 1, 15, 9),
      end: DateTime(2027, 1, 15, 10),
      rsvp: RsvpStatus.needsAction,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayGrid banner strip', () {
    testWidgets(
        'shows conflict / extended / RSVP counts from fixture tiles',
        (tester) async {
      await tester.pumpWidget(_buildApp(_alertFixture()));
      await tester.pump();

      expect(find.byType(CombinedAlertsBanner), findsOneWidget);
      // Conflict chip: the 2 overlapping tiles.
      expect(find.text('2 Conflicts'), findsOneWidget);
      // Extended chip: the single >=16h tile.
      expect(find.text('1 All-Day'), findsOneWidget);
      // RSVP chip: the single pending tile.
      expect(find.text('1 RSVP'), findsOneWidget);
    });

    testWidgets('is hidden when the day is clean', (tester) async {
      await tester.pumpWidget(_buildApp(<TilerEvent>[
        _tile(
          id: 'a',
          name: 'Lunch',
          start: DateTime(2026, 5, 15, 12),
          end: DateTime(2026, 5, 15, 13),
        ),
      ]));
      await tester.pump();

      expect(find.byType(CombinedAlertsBanner), findsNothing);
      expect(find.byType(DayGridBannerStrip), findsOneWidget);
    });

    testWidgets('conflict chip opens the stacked-conflict-cards modal',
        (tester) async {
      await tester.pumpWidget(_buildApp(_alertFixture()));
      await tester.pump();

      await tester.tap(find.text('2 Conflicts'));
      await tester.pumpAndSettle();

      // Grid-mode conflict modal: stacked cards + the conflict title
      // (list mode renders the cards inline; the chip is a no-op there).
      expect(find.byType(StackedConflictCards), findsOneWidget);
      expect(find.text('2 Conflicting Tiles'), findsOneWidget);
      // The stacked cards already carry both conflicting tiles...
      expect(find.text('ConflictA'), findsOneWidget);
      expect(find.text('ConflictB'), findsOneWidget);

      // ...and the tap-to-expand hint opens the expanded card list.
      await tester.tap(find.text('Tap to expand'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Total overlap:'), findsOneWidget);
    });

    testWidgets('extended chip opens the extended-tiles modal',
        (tester) async {
      await tester.pumpWidget(_buildApp(_alertFixture()));
      await tester.pump();

      await tester.tap(find.text('1 All-Day'));
      await tester.pumpAndSettle();

      expect(find.byType(ExtendedTilesModal), findsOneWidget);
      expect(find.text('AllDayWork'), findsOneWidget);
    });

    testWidgets('rsvp chip opens the pending-rsvp modal', (tester) async {
      await tester.pumpWidget(_buildApp(_alertFixture()));
      await tester.pump();

      await tester.tap(find.text('1 RSVP'));
      await tester.pumpAndSettle();

      expect(find.byType(PendingRsvpModal), findsOneWidget);
      expect(find.text('PendingMeeting'), findsOneWidget);
    });
  });

  group('DayGridBannerStrip detector mirror', () {
    test('grid detectors mirror the list-mode detectors on the same input',
        () {
      final tiles = _alertFixture();
      // Extended + pending-RSVP detectors are the list-mode ones verbatim.
      expect(
        DayGridBannerStrip.detectExtendedTiles(tiles),
        ExtendedTilesBanner.detectExtendedTiles(tiles),
      );
      expect(
        DayGridBannerStrip.detectPendingRsvpTiles(tiles),
        PendingRsvpBanner.detectPendingRsvpTiles(tiles),
      );
      // Conflicts mirror the list-mode input rules +
      // ConflictGroup.detectGroups: the >=16h tile is dropped from the
      // conflict input, the pending-RSVP tile is hidden, and the two
      // overlapping tiles form one group.
      final conflicts = DayGridBannerStrip.detectConflicts(tiles);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.tiles.map((t) => t.id).toSet(), {'c1', 'c2'});
    });
  });
}