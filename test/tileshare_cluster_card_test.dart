// TileShare redesign Step 9.8 (section 5.3): the cluster card. Broadcast, Class
// and Project read differently, and so do the owner and a recipient:
//   * owner  - who it went to, and "3 of 5 accepted" (RSVP status, never
//              progress, T13); a Project shows one segment per task;
//   * recipient - who it is from, my status, my task count, and - while a
//              Broadcast / Class invitation waits - inline Accept / Decline
//              (a Project is reviewed task by task, T20).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareMyStatus.dart';
import 'package:tiler_app/data/tileShareRsvpSummary.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clusterCard.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime.utc(2026, 10, 1, 9);

int _msFromNow(Duration d) => _now.add(d).millisecondsSinceEpoch;

TileShareClusterData _cluster(
  String id, {
  String? name,
  TileShareMode mode = TileShareMode.broadcast,
  int? endMs,
  List<String> contacts = const <String>[],
  String? creator,
  bool? completed,
}) {
  final c = tsCluster(id,
      name: name ?? 'Launch prep',
      mode: mode,
      endMs: endMs,
      contacts: contacts,
      completed: completed ?? false);
  if (creator != null) c.creator = UserProfile()..fullName = creator;
  return c;
}

ClusterListItem _owner(
  TileShareClusterData cluster, {
  TileShareRsvpSummary? rsvp,
  bool rsvpFailed = false,
}) =>
    ClusterListItem(
        cluster: cluster,
        createdByMe: true,
        mode: TileShareMode.fromCluster(cluster),
        rsvp: rsvp,
        rsvpFailed: rsvpFailed);

ClusterListItem _recipient(
  TileShareClusterData cluster, {
  MyClusterStatus? mine,
}) =>
    ClusterListItem(
        cluster: cluster,
        createdByMe: false,
        mode: TileShareMode.fromCluster(cluster),
        mine: mine);

MyClusterStatus _mine({int accepted = 0, int declined = 0, int pending = 0}) =>
    MyClusterStatus(
        taskCount: accepted + declined + pending,
        accepted: accepted,
        declined: declined,
        pending: pending);

TileShareRsvpSummary _rsvp(int accepted, int declined, int pending) =>
    TileShareRsvpSummary(
        total: accepted + declined + pending,
        accepted: accepted,
        declined: declined,
        pending: pending);

Widget _host(Widget child, {ThemeData? theme, double width = 400}) =>
    MaterialApp(
      theme: theme ?? TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, ClusterCard card,
    {ThemeData? theme, double width = 400}) async {
  await tester.pumpWidget(_host(card, theme: theme, width: width));
  await tester.pump();
}

ClusterCard _card(
  ClusterListItem item, {
  VoidCallback? onOpen,
  VoidCallback? onDelete,
  VoidCallback? onAccept,
  VoidCallback? onDecline,
  VoidCallback? onRetryRsvp,
}) =>
    ClusterCard(
      item: item,
      now: _now,
      onOpen: onOpen,
      onDelete: onDelete,
      onAccept: onAccept,
      onDecline: onDecline,
      onRetryRsvp: onRetryRsvp,
    );

void main() {
  group('the header', () {
    testWidgets('shows the title, and a stand-in when there is none',
        (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1', name: 'Launch prep'))));
      expect(find.text('Launch prep'), findsOneWidget);

      await _pump(tester, _card(_owner(_cluster('c2', name: '  '))));
      expect(find.text('Untitled share'), findsOneWidget);
    });

    testWidgets('names the mode for each of the three modes', (tester) async {
      for (final entry in {
        TileShareMode.broadcast: 'Broadcast',
        TileShareMode.class_: 'Class',
        TileShareMode.project: 'Project',
      }.entries) {
        await _pump(tester, _card(_owner(_cluster('c1', mode: entry.key))));
        expect(find.textContaining(entry.value), findsOneWidget,
            reason: entry.value);
      }
    });

    testWidgets('tapping the card opens it', (tester) async {
      var opened = 0;
      await _pump(tester,
          _card(_owner(_cluster('c1')), onOpen: () => opened++));
      await tester.tap(find.text('Launch prep'));
      expect(opened, 1);
    });
  });

  group('the role line', () {
    testWidgets('the owner sees it is theirs', (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1'))));
      expect(find.textContaining('Created by you'), findsOneWidget);
    });

    testWidgets('a recipient sees who it is from, or a plain fallback',
        (tester) async {
      await _pump(tester,
          _card(_recipient(_cluster('c1', creator: 'Sarah Kim'))));
      expect(find.textContaining('From Sarah Kim'), findsOneWidget);

      await _pump(tester, _card(_recipient(_cluster('c2'))));
      expect(find.textContaining('Shared with you'), findsOneWidget);
    });
  });

  group('the deadline chip', () {
    testWidgets('shows the date when it is not close', (tester) async {
      await _pump(
          tester,
          _card(_owner(
              _cluster('c1', endMs: _msFromNow(const Duration(days: 9))))));
      expect(find.byKey(const Key('cluster_due_c1')), findsOneWidget);
      expect(find.byKey(const Key('cluster_due_urgent_c1')), findsNothing);
      expect(find.textContaining('Due '), findsOneWidget);
    });

    testWidgets('is marked urgent inside 48 hours', (tester) async {
      await _pump(
          tester,
          _card(_owner(
              _cluster('c1', endMs: _msFromNow(const Duration(hours: 30))))));
      expect(find.byKey(const Key('cluster_due_urgent_c1')), findsOneWidget);
    });

    testWidgets('says overdue once it has passed', (tester) async {
      await _pump(
          tester,
          _card(_owner(
              _cluster('c1', endMs: _msFromNow(const Duration(hours: -5))))));
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.byKey(const Key('cluster_due_urgent_c1')), findsOneWidget);
    });

    testWidgets('is absent with no deadline, or when it is completed',
        (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1'))));
      expect(find.byKey(const Key('cluster_due_c1')), findsNothing);
      expect(find.byKey(const Key('cluster_due_urgent_c1')), findsNothing);

      await _pump(
          tester,
          _card(_owner(_cluster('c2',
              endMs: _msFromNow(const Duration(hours: 5)), completed: true))));
      expect(find.byKey(const Key('cluster_due_c2')), findsNothing);
      expect(find.byKey(const Key('cluster_due_urgent_c2')), findsNothing);
    });
  });

  group('the owner\'s card', () {
    testWidgets('Broadcast: who it went to and "3 of 5 accepted"',
        (tester) async {
      await _pump(
          tester,
          _card(_owner(
              _cluster('c1', contacts: ['ann@x.com', 'bob@x.com']),
              rsvp: _rsvp(3, 1, 1))));
      expect(find.text('3 of 5 accepted'), findsOneWidget);
      expect(find.byKey(const Key('cluster_avatars_c1')), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('Class counts people', (tester) async {
      await _pump(
          tester,
          _card(_owner(_cluster('c1', mode: TileShareMode.class_),
              rsvp: _rsvp(3, 0, 2))));
      expect(find.text('3 of 5 people accepted'), findsOneWidget);
    });

    testWidgets('Project counts tasks and draws one segment per task',
        (tester) async {
      await _pump(
          tester,
          _card(_owner(_cluster('c1', mode: TileShareMode.project),
              rsvp: _rsvp(3, 0, 1))));
      expect(find.text('3 of 4 tasks accepted'), findsOneWidget);
      final segments = find.descendant(
          of: find.byKey(const Key('cluster_segments_c1')),
          matching: find.byType(DecoratedBox));
      expect(segments, findsNWidgets(4));
    });

    testWidgets('a single person / task is singular', (tester) async {
      await _pump(
          tester,
          _card(_owner(_cluster('c1', mode: TileShareMode.class_),
              rsvp: _rsvp(1, 0, 0))));
      expect(find.text('1 of 1 person accepted'), findsOneWidget);
      await _pump(
          tester,
          _card(_owner(_cluster('c2', mode: TileShareMode.project),
              rsvp: _rsvp(0, 0, 1))));
      expect(find.text('0 of 1 task accepted'), findsOneWidget);
    });

    testWidgets('nobody counted (no tilettes or no roster) is no line, not '
        '"0 of 0 accepted"', (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1'), rsvp: _rsvp(0, 0, 0))));
      expect(find.byKey(const Key('cluster_rsvp_c1')), findsNothing);
      expect(find.textContaining('accepted'), findsNothing);

      await _pump(
          tester,
          _card(_owner(_cluster('c2', mode: TileShareMode.project),
              rsvp: _rsvp(0, 0, 0))));
      expect(find.byKey(const Key('cluster_segments_c2')), findsNothing);
    });

    testWidgets('says nothing about responses until they are known',
        (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1'))));
      expect(find.byKey(const Key('cluster_rsvp_c1')), findsNothing);
      expect(find.textContaining('accepted'), findsNothing);
      expect(find.text('Responses unavailable'), findsNothing);
    });

    testWidgets('when counting failed the card still shows, with a way to '
        'retry', (tester) async {
      var retried = 0;
      await _pump(
          tester,
          _card(_owner(_cluster('c1'), rsvpFailed: true),
              onRetryRsvp: () => retried++));
      expect(find.text('Launch prep'), findsOneWidget);
      expect(find.text('Responses unavailable'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('no progress figure anywhere on the card (T13)',
        (tester) async {
      await _pump(
          tester, _card(_owner(_cluster('c1'), rsvp: _rsvp(2, 0, 1))));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('more people than fit are summarised as +N', (tester) async {
      await _pump(
          tester,
          _card(_owner(_cluster('c1', contacts: [
            for (var i = 0; i < 7; i++) 'p$i@x.com',
          ]))));
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('P'), findsNWidgets(4));
    });

    testWidgets('a truncated contact list without a known count shows an '
        'ellipsis chip', (tester) async {
      final cluster = _cluster('c1', contacts: ['a@x.com']);
      cluster.isMoreContact = true;
      await _pump(tester, _card(_owner(cluster)));
      expect(find.text('…'), findsOneWidget);
    });

    testWidgets('no avatars at all when there are no contacts',
        (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1'))));
      expect(find.byKey(const Key('cluster_avatars_c1')), findsNothing);
    });
  });

  group('the recipient\'s card', () {
    testWidgets('shows my status, per answer', (tester) async {
      for (final entry in {
        _mine(accepted: 2): 'You accepted',
        _mine(declined: 1): 'You declined',
        _mine(pending: 1): 'Needs your answer',
        _mine(accepted: 1, pending: 1): 'Needs your answer',
        _mine(accepted: 1, declined: 1): 'Partly answered',
      }.entries) {
        await _pump(tester,
            _card(_recipient(_cluster('c1'), mine: entry.key)));
        expect(find.text(entry.value), findsOneWidget, reason: entry.value);
      }
    });

    testWidgets('a partly answered cluster with nothing pending says so, '
        'and one still pending asks for an answer', (tester) async {
      await _pump(tester,
          _card(_recipient(_cluster('c1'), mine: _mine(accepted: 1, pending: 1))));
      expect(find.text('Needs your answer'), findsOneWidget);
      expect(find.text('Partly answered'), findsNothing);
    });

    testWidgets('no status pill while my answer is unknown', (tester) async {
      await _pump(tester, _card(_recipient(_cluster('c1'))));
      expect(find.byKey(const Key('cluster_mine_c1')), findsNothing);
    });

    testWidgets('names how many tasks I hold (Class and Project)',
        (tester) async {
      await _pump(
          tester,
          _card(_recipient(_cluster('c1', mode: TileShareMode.class_),
              mine: _mine(accepted: 3))));
      expect(find.text('3 tasks'), findsOneWidget);
      await _pump(
          tester,
          _card(_recipient(_cluster('c2', mode: TileShareMode.broadcast),
              mine: _mine(accepted: 1))));
      expect(find.text('1 task'), findsNothing,
          reason: 'a Broadcast is one task; naming it adds nothing');
    });

    testWidgets('a pending Broadcast offers Accept / Decline inline',
        (tester) async {
      var accepted = 0, declined = 0;
      await _pump(
          tester,
          _card(_recipient(_cluster('c1'), mine: _mine(pending: 1)),
              onAccept: () => accepted++, onDecline: () => declined++));
      await tester.tap(find.byKey(const Key('cluster_accept_c1')));
      await tester.tap(find.byKey(const Key('cluster_decline_c1')));
      expect([accepted, declined], [1, 1]);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('a pending Class offers Accept all / Decline all',
        (tester) async {
      await _pump(
          tester,
          _card(
              _recipient(_cluster('c1', mode: TileShareMode.class_),
                  mine: _mine(pending: 3)),
              onAccept: () {},
              onDecline: () {}));
      expect(find.text('Accept all'), findsOneWidget);
      expect(find.text('Decline all'), findsOneWidget);
    });

    testWidgets('a pending Project never offers Accept all; it says how many '
        'tasks need a response (T20)', (tester) async {
      await _pump(
          tester,
          _card(
              _recipient(_cluster('c1', mode: TileShareMode.project),
                  mine: _mine(pending: 2)),
              onAccept: () {},
              onDecline: () {}));
      expect(find.byKey(const Key('cluster_accept_c1')), findsNothing);
      expect(find.byKey(const Key('cluster_decline_c1')), findsNothing);
      expect(find.text('2 tasks need your response'), findsOneWidget);
    });

    testWidgets('no buttons once answered, or when no handlers are given',
        (tester) async {
      await _pump(
          tester,
          _card(_recipient(_cluster('c1'), mine: _mine(accepted: 1)),
              onAccept: () {}, onDecline: () {}));
      expect(find.byKey(const Key('cluster_accept_c1')), findsNothing);

      await _pump(tester,
          _card(_recipient(_cluster('c2'), mine: _mine(pending: 1))));
      expect(find.byKey(const Key('cluster_accept_c2')), findsNothing);
    });

    testWidgets('a recipient has no delete menu', (tester) async {
      await _pump(
          tester,
          _card(_recipient(_cluster('c1'), mine: _mine(pending: 1)),
              onDelete: () {}));
      expect(find.byKey(const Key('cluster_menu_c1')), findsNothing);
    });
  });

  group('delete (owner only)', () {
    testWidgets('the overflow menu offers Delete and reports it',
        (tester) async {
      var deleted = 0;
      await _pump(
          tester, _card(_owner(_cluster('c1')), onDelete: () => deleted++));
      await tester.tap(find.byKey(const Key('cluster_menu_c1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(deleted, 1);
    });

    testWidgets('no menu without a handler', (tester) async {
      await _pump(tester, _card(_owner(_cluster('c1'))));
      expect(find.byKey(const Key('cluster_menu_c1')), findsNothing);
    });

    testWidgets('dismissing the menu deletes nothing', (tester) async {
      var deleted = 0;
      await _pump(
          tester, _card(_owner(_cluster('c1')), onDelete: () => deleted++));
      await tester.tap(find.byKey(const Key('cluster_menu_c1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(deleted, 0);
    });
  });

  group('looks right', () {
    for (final theme in {
      'light': TileThemeData.lightTheme,
      'dark': TileThemeData.darkTheme
    }.entries) {
      testWidgets('every variant lays out in the ${theme.key} theme at a '
          'narrow width, without overflow', (tester) async {
        final variants = <ClusterListItem>[
          _owner(
              _cluster('a',
                  name: 'A very long cluster name that has to wrap or clip '
                      'rather than push the badge off the card',
                  contacts: ['ann@x.com', 'bob@x.com', 'cy@x.com', 'di@x.com', 'ed@x.com'],
                  endMs: _msFromNow(const Duration(hours: 3))),
              rsvp: _rsvp(3, 1, 1)),
          _owner(_cluster('b', mode: TileShareMode.project), rsvp: _rsvp(3, 1, 8)),
          _owner(_cluster('c'), rsvpFailed: true),
          _recipient(_cluster('d', mode: TileShareMode.class_, creator: 'Sarah Kim'),
              mine: _mine(pending: 4)),
          _recipient(_cluster('e', mode: TileShareMode.project),
              mine: _mine(accepted: 1, pending: 3)),
          _recipient(_cluster('f'), mine: _mine(declined: 1)),
        ];
        for (final item in variants) {
          await _pump(
              tester,
              _card(item,
                  onOpen: () {},
                  onDelete: item.createdByMe ? () {} : null,
                  onAccept: () {},
                  onDecline: () {},
                  onRetryRsvp: () {}),
              theme: theme.value,
              width: 320);
          expect(tester.takeException(), isNull, reason: item.toString());
        }
      });
    }
  });
}
