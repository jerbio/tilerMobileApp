// Step 6.5 — the occurrences of a series, on Tile Detail.
//
// The legacy `TileDetail` carousel: an initial `ProximityToNow` page of 20,
// then `Id`-ordered pages before and after, single-flight, kept by the
// parent so an edit-and-return keeps the list (`SubEventPaging`, pinned in
// `test/sub_event_paging_test.dart`). Re-hosted as a kit section: one row
// per occurrence (day, time span, Done), sorted by start, with "Show
// earlier" / "Show later" rows while more may exist. A row opens the
// occurrence in Edit Tile (`EditTileRoute`); a returned tile reloads.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/subEventPaging.dart';

import '../addTile/l10n_fixture.dart';
import 'tile_detail_draft_test.dart' as fx;
import 'tile_detail_shell_test.dart' as shell;

Finder key(String k) => find.byKey(ValueKey(k));

Future<void> reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 160,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

/// An occurrence on Sep [day] 2026 at 14:00–15:30 local.
SubCalendarEvent occ(String id, int day,
        {bool isComplete = false, String thirdPartyType = 'tiler'}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': id,
      'name': 'Write report',
      'start': DateTime(2026, 9, day, 14, 0).millisecondsSinceEpoch,
      'end': DateTime(2026, 9, day, 15, 30).millisecondsSinceEpoch,
      'calendarEventStart': fx.start.millisecondsSinceEpoch,
      'calendarEventEnd': fx.end.millisecondsSinceEpoch,
      'thirdPartyType': thirdPartyType,
      'thirdPartyUserId': thirdPartyType == 'tiler' ? null : 'ext-user-3',
      'isComplete': isComplete,
      'isEnabled': true,
      'priority': 'medium',
    });

/// [count] occurrences with ids `s<from>`…, one per day from Sep 1.
List<SubCalendarEvent> page(int from, int count) => <SubCalendarEvent>[
      for (int i = 0; i < count; i++) occ('s${from + i}', 1 + (from + i) % 28),
    ];

shell.FakeOccurrences source({
  List<SubCalendarEvent>? initial,
  List<SubCalendarEvent>? after,
  List<SubCalendarEvent>? before,
}) =>
    shell.FakeOccurrences()
      ..initialPage = initial ?? <SubCalendarEvent>[]
      ..afterPage = after ?? <SubCalendarEvent>[]
      ..beforePage = before ?? <SubCalendarEvent>[];

void main() {
  group('Listing', () {
    testWidgets('the initial page is fetched once and listed by start',
        (tester) async {
      await shell.pumpDetail(tester,
          occurrencesSource: source(initial: <SubCalendarEvent>[
            occ('s2', 14),
            occ('s1', 12),
            occ('s3', 16, isComplete: true),
          ]));
      expect(shell.occurrences.calls, <String>['initial:cal-1']);
      await reveal(tester, key('detailOccurrence_s3'));
      expect(find.text(testL10n.tileDetailSectionOccurrences), findsOneWidget);
      final double y1 = tester.getRect(key('detailOccurrence_s1')).top;
      final double y2 = tester.getRect(key('detailOccurrence_s2')).top;
      final double y3 = tester.getRect(key('detailOccurrence_s3')).top;
      expect(y1 < y2 && y2 < y3, isTrue, reason: 'by start, not arrival');
      expect(
          find.descendant(
              of: key('detailOccurrence_s1'),
              matching: find.textContaining('Sep 12')),
          findsOneWidget);
      expect(
          find.descendant(
              of: key('detailOccurrence_s1'),
              matching: find.textContaining('2:00')),
          findsOneWidget,
          reason: 'the time span');
      expect(
          find.descendant(
              of: key('detailOccurrence_s3'),
              matching: find.textContaining(testL10n.tileDetailOccurrenceDone)),
          findsOneWidget);
      expect(
          find.descendant(
              of: key('detailOccurrence_s1'),
              matching: find.textContaining(testL10n.tileDetailOccurrenceDone)),
          findsNothing);
    });

    testWidgets('while the page loads, a placeholder; none → an empty line',
        (tester) async {
      final shell.FakeOccurrences src = source()
        ..initialGate = Completer<List<SubCalendarEvent>>();
      await shell.pumpDetail(tester, occurrencesSource: src);
      // The sweep never settles: scroll without pumpAndSettle.
      await tester.scrollUntilVisible(key('detailOccurrencesLoading'), 160,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(key('detailOccurrencesLoading'), findsOneWidget);
      src.initialGate!.complete(<SubCalendarEvent>[]);
      await tester.pumpAndSettle();
      expect(key('detailOccurrencesLoading'), findsNothing);
      expect(find.text(testL10n.tileDetailOccurrencesEmpty), findsOneWidget);
    });

    testWidgets('a failed page says so and Retry fetches again',
        (tester) async {
      final shell.FakeOccurrences src = source(initial: page(0, 3))
        ..failWith = StateError('socket');
      await shell.pumpDetail(tester, occurrencesSource: src);
      await reveal(tester, key('detailOccurrencesRetry'));
      expect(find.text(testL10n.tileDetailOccurrencesFailed), findsOneWidget);
      src.failWith = null;
      await tester.tap(key('detailOccurrencesRetry'));
      await tester.pumpAndSettle();
      expect(src.calls, <String>['initial:cal-1', 'initial:cal-1']);
      expect(key('detailOccurrence_s0'), findsOneWidget);
    });

    testWidgets('a series with no thirdPartyType lists its occurrences',
        (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(thirdPartyType: null),
          occurrencesSource: source(initial: page(0, 2)));
      expect(shell.occurrences.calls, <String>['initial:cal-1']);
      await reveal(tester, key('detailOccurrence_s1'));
      expect(key('detailModeBanner'), findsNothing);
    });

    testWidgets('a provider series has no occurrences section', (tester) async {
      await shell.pumpDetail(tester,
          event: fx.loaded(thirdPartyType: 'google'),
          occurrencesSource: source(initial: page(0, 2)));
      expect(shell.occurrences.calls, isEmpty);
      expect(find.text(testL10n.tileDetailSectionOccurrences), findsNothing);
    });
  });

  group('Paging', () {
    testWidgets(
        'a full page offers Show later; it appends the next page '
        'after the last id and hides once exhausted', (tester) async {
      await shell.pumpDetail(tester,
          occurrencesSource:
              source(initial: page(0, kSubEventBatchSize), after: page(20, 2)));
      await reveal(tester, key('detailOccurrencesLater'));
      await tester.tap(key('detailOccurrencesLater'));
      await tester.pumpAndSettle();
      expect(shell.occurrences.calls.last, 'after:s19');
      await reveal(tester, key('detailOccurrence_s21'));
      expect(key('detailOccurrence_s21'), findsOneWidget);
      expect(key('detailOccurrencesLater'), findsNothing,
          reason: 'a short page means no more');
    });

    testWidgets('Show earlier prepends before the first id', (tester) async {
      await shell.pumpDetail(tester,
          occurrencesSource: source(
              initial: page(20, kSubEventBatchSize), before: page(18, 2)));
      await reveal(tester, key('detailOccurrencesEarlier'));
      await tester.tap(key('detailOccurrencesEarlier'));
      await tester.pumpAndSettle();
      expect(shell.occurrences.calls.last, 'before:s20');
      await reveal(tester, key('detailOccurrence_s18'));
      expect(key('detailOccurrence_s18'), findsOneWidget);
    });

    testWidgets('a short initial page offers neither direction',
        (tester) async {
      await shell.pumpDetail(tester,
          occurrencesSource: source(initial: page(0, 3)));
      await reveal(tester, key('detailOccurrence_s2'));
      expect(key('detailOccurrencesLater'), findsNothing);
      expect(key('detailOccurrencesEarlier'), findsNothing);
    });

    testWidgets('a failed follow-up page closes that direction quietly',
        (tester) async {
      final shell.FakeOccurrences src =
          source(initial: page(0, kSubEventBatchSize));
      await shell.pumpDetail(tester, occurrencesSource: src);
      await reveal(tester, key('detailOccurrencesLater'));
      src.failWith = StateError('socket');
      await tester.tap(key('detailOccurrencesLater'));
      await tester.pumpAndSettle();
      expect(key('detailOccurrencesLater'), findsNothing);
      expect(key('detailOccurrence_s19'), findsOneWidget,
          reason: 'what was listed stays');
      expect(find.text(testL10n.tileDetailOccurrencesFailed), findsNothing);
    });
  });

  group('Opening an occurrence', () {
    testWidgets('a row opens it in Edit Tile with its identity',
        (tester) async {
      await shell.pumpDetail(tester,
          occurrencesSource: source(initial: page(0, 2)));
      await reveal(tester, key('detailOccurrence_s1'));
      await tester.tap(key('detailOccurrence_s1'));
      await tester.pumpAndSettle();
      expect(shell.openedOccurrences, <String>['s1:tiler:']);
    });

    testWidgets('a returned tile reloads the list; nothing returned keeps it',
        (tester) async {
      final shell.FakeOccurrences src = source(initial: page(0, 2));
      await shell.pumpDetail(tester, occurrencesSource: src);
      await reveal(tester, key('detailOccurrence_s1'));
      shell.openOccurrenceAnswer = null;
      await tester.tap(key('detailOccurrence_s1'));
      await tester.pumpAndSettle();
      expect(src.calls, <String>['initial:cal-1']);
      shell.openOccurrenceAnswer = occ('s1', 12);
      await tester.tap(key('detailOccurrence_s1'));
      await tester.pumpAndSettle();
      expect(src.calls, <String>['initial:cal-1', 'initial:cal-1']);
    });

    testWidgets('rows are buttons', (tester) async {
      await shell.pumpDetail(tester,
          occurrencesSource: source(initial: page(0, 1)));
      await reveal(tester, key('detailOccurrence_s0'));
      final SemanticsHandle h = tester.ensureSemantics();
      expect(tester.getSemantics(key('detailOccurrence_s0')),
          matchesSemantics(isButton: true, hasTapAction: true));
      h.dispose();
    });
  });
}
