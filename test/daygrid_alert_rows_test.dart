// DayGridAlertRows — the grid-mode conflict / pending-RSVP rows, laid out
// in-flow above the grid (C21). One row per alert kind, each opening the
// same modal the list's banners do; nothing when the day is clean.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/dayGridAlertRows.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

SubCalendarEvent _tile({
  required String id,
  required DateTime start,
  required DateTime end,
  RsvpStatus? rsvp,
}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    rsvp: rsvp,
  );
  tile.isViable = true;
  return tile;
}

final DateTime _day = DateTime(2027, 1, 15);

List<TilerEvent> _conflictTiles() => [
      _tile(id: 'c1', start: _day.add(const Duration(hours: 9)),
          end: _day.add(const Duration(hours: 11))),
      _tile(id: 'c2', start: _day.add(const Duration(hours: 10)),
          end: _day.add(const Duration(hours: 12))),
    ];

List<TilerEvent> _rsvpTiles() => [
      _tile(
          id: 'r1',
          start: _day.add(const Duration(hours: 14)),
          end: _day.add(const Duration(hours: 15)),
          rsvp: RsvpStatus.needsAction),
    ];

Widget _app(List<TilerEvent> tiles) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(children: [DayGridAlertRows(tiles: tiles)]),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders nothing on a clean day', (tester) async {
    await tester.pumpWidget(_app(const []));
    await tester.pump();
    expect(find.byKey(DayGridAlertRows.conflictRowKey), findsNothing);
    expect(find.byKey(DayGridAlertRows.rsvpRowKey), findsNothing);
  });

  testWidgets('conflict row only when there are conflicts', (tester) async {
    await tester.pumpWidget(_app(_conflictTiles()));
    await tester.pump();
    expect(find.byKey(DayGridAlertRows.conflictRowKey), findsOneWidget);
    expect(find.byKey(DayGridAlertRows.rsvpRowKey), findsNothing);
    expect(find.text('2 conflicts'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('RSVP row only when there are pending RSVPs', (tester) async {
    await tester.pumpWidget(_app(_rsvpTiles()));
    await tester.pump();
    expect(find.byKey(DayGridAlertRows.rsvpRowKey), findsOneWidget);
    expect(find.byKey(DayGridAlertRows.conflictRowKey), findsNothing);
    expect(find.text('1 RSVP'), findsOneWidget);
    expect(find.text('Respond'), findsOneWidget);
  });

  testWidgets('both rows when both alert kinds are present', (tester) async {
    await tester.pumpWidget(_app([..._conflictTiles(), ..._rsvpTiles()]));
    await tester.pump();
    expect(find.byKey(DayGridAlertRows.conflictRowKey), findsOneWidget);
    expect(find.byKey(DayGridAlertRows.rsvpRowKey), findsOneWidget);
  });

  testWidgets('tapping the conflict row opens the conflict cards sheet',
      (tester) async {
    await tester.pumpWidget(_app(_conflictTiles()));
    await tester.pump();
    await tester.tap(find.byKey(DayGridAlertRows.conflictRowKey));
    await tester.pumpAndSettle();
    expect(find.text('2 Conflicting Tiles'), findsOneWidget);
  });

  testWidgets('tapping the RSVP row opens the pending-RSVP sheet',
      (tester) async {
    await tester.pumpWidget(_app(_rsvpTiles()));
    await tester.pump();
    await tester.tap(find.byKey(DayGridAlertRows.rsvpRowKey));
    await tester.pumpAndSettle();
    expect(find.text('Pending Responses'), findsOneWidget);
  });
}
