// DayGridAlerts — the grid-mode alert detectors + conflict modal (P6: the
// chip strip is retired; the scroll header's banner rows consume these).
// The detectors mirror the list-mode ones (ConflictGroup.detectGroups /
// ExtendedTilesBanner.detectExtendedTiles / pending-RSVP split) on the same
// input, and the conflict modal renders the stacked conflict cards.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/pendingRsvpBanner.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridAlerts.dart';
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

/// - c1/c2 overlap -> one conflict group of 2 tiles,
/// - ext1 spans 20h (>=16h) -> extended,
/// - rsvp1 is a third-party pending-RSVP tile with a future end date.
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

  group('DayGridAlerts detector mirror', () {
    test('grid detectors mirror the list-mode detectors on the same input',
        () {
      final tiles = _alertFixture();
      expect(
        DayGridAlerts.detectExtendedTiles(tiles),
        ExtendedTilesBanner.detectExtendedTiles(tiles),
      );
      expect(
        DayGridAlerts.detectPendingRsvpTiles(tiles),
        PendingRsvpBanner.detectPendingRsvpTiles(tiles),
      );
      // Conflicts mirror the list-mode input rules +
      // ConflictGroup.detectGroups: the >=16h tile is dropped from the
      // conflict input, the pending-RSVP tile is hidden, and the two
      // overlapping tiles form one group.
      final conflicts = DayGridAlerts.detectConflicts(tiles);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.tiles.map((t) => t.id).toSet(), {'c1', 'c2'});
    });
  });

  group('DayGridAlerts.showConflictModal', () {
    testWidgets('renders the stacked conflict cards sheet', (tester) async {
      final conflicts = DayGridAlerts.detectConflicts(_alertFixture());
      await tester.pumpWidget(MaterialApp(
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
            builder: (context) => TextButton(
              onPressed: () =>
                  DayGridAlerts.showConflictModal(context, conflicts),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(StackedConflictCards), findsOneWidget);
      expect(find.text('2 Conflicting Tiles'), findsOneWidget);
      expect(find.text('ConflictA'), findsOneWidget);
      expect(find.text('ConflictB'), findsOneWidget);

      await tester.tap(find.text('Tap to expand'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Total overlap:'), findsOneWidget);
    });
  });
}
