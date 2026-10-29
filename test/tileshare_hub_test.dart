// TileShare redesign Step 9.9 (T1, T6, T7, T8): the hub - a slim bar (back,
// title, Activity, create) over two segments, Attention and Clusters.
//   * the opening segment follows T7: Attention when it has something, else
//     the one the user was last on; a choice made by hand is never overridden;
//   * the Attention badge counts what needs attention;
//   * each segment keeps its scroll offset, and Clusters is only built (and
//     loaded) once it is visited;
//   * a Clusters row answers through the Attention cubit, with the same Undo,
//     and the list reloads once the answer is sent;
//   * coming back from a screen reloads what it may have changed.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/hub/tileShareHub.dart';
import 'package:tiler_app/services/tileShare/tileShareHubPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _FakePrefs implements TileShareHubPreferences {
  HubSegment? stored;
  final List<HubSegment> writes = [];
  Completer<void>? gate;

  _FakePrefs([this.stored]);

  @override
  Future<HubSegment?> lastSegment() async {
    if (gate != null) await gate!.future;
    return stored;
  }

  @override
  Future<void> setLastSegment(HubSegment segment) async {
    writes.add(segment);
    stored = segment;
  }
}

class _ManualTimer implements Timer {
  final void Function() callback;
  bool _active = true;
  _ManualTimer(this.callback);
  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }

  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => 0;
}

class _Rig {
  final FakeTileShareAttentionSources attention;
  final FakeTileShareAssignmentsSource assignments;
  final FakeTileShareClustersSource clusters;
  final _FakePrefs prefs;
  final List<_ManualTimer> timers = [];
  late final TileShareAttentionCubit attentionCubit;
  late final TileShareClustersCubit clustersCubit;

  final List<String> openedAttention = [];
  final List<String> openedClusters = [];
  final List<String> previewed = [];
  int created = 0;
  int activityOpened = 0;
  bool? popResult;

  _Rig({
    FakeTileShareAttentionSources? attention,
    List<DesignatedTile>? mine,
    FakeTileShareClustersSource? clusters,
    HubSegment? stored,
  })  : attention = attention ?? _attentionWithInvitation(),
        assignments = FakeTileShareAssignmentsSource(mine ?? _defaultMine()),
        clusters = clusters ?? _defaultClusters(),
        prefs = _FakePrefs(stored) {
    attentionCubit = TileShareAttentionCubit(
      attention: this.attention,
      assignments: assignments,
      clusters: this.clusters,
      currentUserId: () => 'me',
      clock: () => kTileShareNow,
      timerFactory: (d, cb) {
        final t = _ManualTimer(cb);
        timers.add(t);
        return t;
      },
    );
    clustersCubit = TileShareClustersCubit(
        clusters: this.clusters,
        assignments: assignments,
        currentUserId: () => 'me');
  }

  int callsStarting(String prefix) =>
      clusters.calls.where((c) => c.startsWith(prefix)).length;

  Future<void> close() async {
    await attentionCubit.close();
    await clustersCubit.close();
  }
}

FakeTileShareAttentionSources _attentionWithInvitation() =>
    FakeTileShareAttentionSources(invitations: [tsInvitation('b1', 'i-bc')]);

List<DesignatedTile> _defaultMine() => [tsDesignatedTile('b1', clusterId: 'i-bc')];

FakeTileShareClustersSource _defaultClusters() => FakeTileShareClustersSource(
      inbox: [
        tsCluster('i-bc', name: 'Weekend brunch', mode: TileShareMode.broadcast, endMs: 200),
      ],
      outbox: [
        tsCluster('o1', name: 'Launch prep', mode: TileShareMode.broadcast, endMs: 100),
      ],
    );

Widget _app(_Rig rig, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => _hub(rig)));
                rig.popResult = result;
              },
              child: const Text('open hub'),
            ),
          ),
        ),
      ),
    );

Widget _hub(_Rig rig) => TileShareHub(
      attention: rig.attentionCubit,
      clusters: rig.clustersCubit,
      preferences: rig.prefs,
      onOpenAttention: (item) async => rig.openedAttention.add(item.id),
      onOpenCluster: (item) async => rig.openedClusters.add(item.id),
      onCreate: () async => rig.created++,
      onOpenActivity: () => rig.activityOpened++,
      onPreview: (assignmentId) async => rig.previewed.add(assignmentId),
    );

Future<void> _openHub(WidgetTester tester, _Rig rig, {ThemeData? theme}) async {
  await tester.pumpWidget(_app(rig, theme: theme));
  await tester.tap(find.text('open hub'));
  await tester.pumpAndSettle();
}

Finder _segment(String name) => find.byKey(Key('hub_segment_$name'));

bool _clustersVisible() => find.byKey(const Key('clusters_chip_all')).hitTestable().evaluate().isNotEmpty;
bool _attentionVisible() => find.byKey(const Key('attention_chip_all')).hitTestable().evaluate().isNotEmpty;

void main() {
  group('the bar', () {
    testWidgets('is slim and carries the title, Activity and create',
        (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
      expect(find.text('Tile Share'), findsOneWidget);
      expect(find.byKey(const Key('hub_activity')), findsOneWidget);
      expect(find.byKey(const Key('hub_create')), findsOneWidget);
      await rig.close();
    });

    testWidgets('back pops with false, as the old route did', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      await tester.tap(find.byKey(const Key('hub_back')));
      await tester.pumpAndSettle();
      expect(find.text('open hub'), findsOneWidget);
      expect(rig.popResult, isFalse);
      await rig.close();
    });

    testWidgets('Activity opens the feed', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      await tester.tap(find.byKey(const Key('hub_activity')));
      expect(rig.activityOpened, 1);
      await rig.close();
    });

    testWidgets('create opens the create flow, and on return both lists '
        'reload', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      final listBefore = rig.callsStarting('clusters(');
      final invitationsBefore =
          rig.attention.calls.where((c) => c.startsWith('invitations')).length;

      await tester.tap(find.byKey(const Key('hub_create')));
      await tester.pumpAndSettle();
      expect(rig.created, 1);
      expect(rig.callsStarting('clusters('), greaterThan(listBefore));
      expect(
          rig.attention.calls.where((c) => c.startsWith('invitations')).length,
          greaterThan(invitationsBefore));
      await rig.close();
    });
  });

  group('the segments', () {
    testWidgets('two segments, Attention first', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      expect(find.text('Attention'), findsOneWidget);
      expect(find.text('Shares'), findsOneWidget);
      expect(_attentionVisible(), isTrue);
      await rig.close();
    });

    testWidgets('switching shows the other list and keeps the first alive',
        (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      expect(_clustersVisible(), isTrue);
      expect(_attentionVisible(), isFalse);

      await tester.tap(_segment('attention'));
      await tester.pumpAndSettle();
      expect(_attentionVisible(), isTrue);
      expect(rig.callsStarting('clusters(isOutbox: true'), 1,
          reason: 'Clusters loaded once, not again on coming back');
      await rig.close();
    });

    testWidgets('the switch fades rather than snaps (T11)', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final fade = tester.widget<FadeTransition>(
          find.byKey(const Key('hub_content_fade')));
      expect(fade.opacity.value, lessThan(1.0));
      expect(fade.opacity.value, greaterThan(0.0));
      await tester.pumpAndSettle();
      expect(tester
              .widget<FadeTransition>(find.byKey(const Key('hub_content_fade')))
              .opacity
              .value,
          1.0);
      await rig.close();
    });

    testWidgets('Clusters is not built or loaded until it is visited',
        (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      expect(rig.callsStarting('clusters(isOutbox'), 0);
      expect(find.byKey(const Key('clusters_chip_all')), findsNothing);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      expect(rig.callsStarting('clusters(isOutbox: true'), 1);
      await rig.close();
    });

    testWidgets('each segment keeps its own scroll offset', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rig = _Rig(
        clusters: FakeTileShareClustersSource(outbox: [
          for (var i = 0; i < 30; i++)
            tsCluster('o${i.toString().padLeft(2, '0')}', endMs: 1000 + i),
        ]),
        mine: [],
        attention: FakeTileShareAttentionSources(),
      );
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
              of: find.byKey(const Key('hub_clusters')),
              matching: find.byType(Scrollable))
          .last;
      await tester.drag(scrollable, const Offset(0, -700));
      await tester.pumpAndSettle();
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(_segment('attention'));
      await tester.pumpAndSettle();
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
      await rig.close();
    });
  });

  group('the Attention badge', () {
    testWidgets('counts what needs attention', (tester) async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(invitations: [
            tsInvitation('a1', 'i-bc'),
            tsInvitation('a2', 'c-x'),
          ]));
      await _openHub(tester, rig);
      expect(find.descendant(of: find.byKey(const Key('hub_badge')), matching: find.text('2')),
          findsOneWidget);
      await rig.close();
    });

    testWidgets('is absent when nothing needs attention', (tester) async {
      final rig = _Rig(attention: FakeTileShareAttentionSources());
      await _openHub(tester, rig);
      expect(find.byKey(const Key('hub_badge')), findsNothing);
      await rig.close();
    });

    testWidgets('follows the list as items leave it', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      expect(find.byKey(const Key('hub_badge')), findsOneWidget);
      rig.attentionCubit.respond('invitation:i-bc', InvitationStatus.declined);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hub_badge')), findsNothing);
      await rig.close();
    });
  });

  group('the opening segment (T7)', () {
    testWidgets('Attention when it has something, whatever was used last',
        (tester) async {
      final rig = _Rig(stored: HubSegment.clusters);
      await _openHub(tester, rig);
      expect(_attentionVisible(), isTrue);
      await rig.close();
    });

    testWidgets('otherwise where the user was last', (tester) async {
      final rig = _Rig(
          stored: HubSegment.clusters,
          attention: FakeTileShareAttentionSources());
      await _openHub(tester, rig);
      expect(_clustersVisible(), isTrue);
      await rig.close();
    });

    testWidgets('with nothing stored and nothing to attend to, Attention',
        (tester) async {
      final rig = _Rig(attention: FakeTileShareAttentionSources());
      await _openHub(tester, rig);
      expect(_attentionVisible(), isTrue);
      await rig.close();
    });

    testWidgets('an Attention that could not load counts as nothing to '
        'attend to', (tester) async {
      final rig = _Rig(stored: HubSegment.clusters);
      rig.attention.failNextOn('invitations', StateError('x'));
      rig.attention.failNextOn('activity', StateError('y'));
      rig.assignments.failNext(StateError('z'));
      await _openHub(tester, rig);
      expect(_clustersVisible(), isTrue);
      await rig.close();
    });

    testWidgets('a choice made by hand is never overridden', (tester) async {
      final rig = _Rig(stored: HubSegment.attention);
      rig.attention.hold();
      await tester.pumpWidget(_app(rig));
      await tester.tap(find.text('open hub'));
      // The pending skeleton shimmers continuously; advance the transition
      // without waiting for the held request's animation to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(_segment('clusters'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_clustersVisible(), isTrue);

      rig.attention.release();
      await tester.pumpAndSettle();
      expect(_clustersVisible(), isTrue,
          reason: 'Attention arrived with items, but the user chose Clusters');
      await rig.close();
    });

    testWidgets('a hand-made choice is remembered; the automatic one is not',
        (tester) async {
      final rig = _Rig(stored: HubSegment.clusters);
      await _openHub(tester, rig);
      expect(rig.prefs.writes, isEmpty,
          reason: 'the rule moved us to Attention; that is not a choice');

      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      expect(rig.prefs.writes, [HubSegment.clusters]);
      await tester.tap(_segment('attention'));
      await tester.pumpAndSettle();
      expect(rig.prefs.writes, [HubSegment.clusters, HubSegment.attention]);
      await rig.close();
    });

    testWidgets('a slow preference read does not delay or break the screen',
        (tester) async {
      final rig = _Rig(
          stored: HubSegment.clusters,
          attention: FakeTileShareAttentionSources());
      rig.prefs.gate = Completer<void>();
      await _openHub(tester, rig);
      expect(_attentionVisible(), isTrue, reason: 'shown while waiting');
      rig.prefs.gate!.complete();
      await tester.pumpAndSettle();
      expect(_clustersVisible(), isTrue);
      await rig.close();
    });
  });

  group('opening things', () {
    testWidgets('an Attention card opens, and Attention reloads on return',
        (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      final before =
          rig.attention.calls.where((c) => c.startsWith('invitations')).length;
      await tester.tap(find.byKey(const ValueKey('attention_card_invitation:i-bc')));
      await tester.pumpAndSettle();
      expect(rig.openedAttention, ['invitation:i-bc']);
      expect(
          rig.attention.calls.where((c) => c.startsWith('invitations')).length,
          greaterThan(before));
      await rig.close();
    });

    testWidgets('a cluster card opens, and Clusters reloads on return',
        (tester) async {
      final rig = _Rig(attention: FakeTileShareAttentionSources());
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      final before = rig.callsStarting('clusters(isOutbox: true');
      await tester.tap(find.text('Launch prep'));
      await tester.pumpAndSettle();
      expect(rig.openedClusters, ['o1']);
      expect(rig.callsStarting('clusters(isOutbox: true'), greaterThan(before));
      await rig.close();
    });
  });

  // Step 9.11b: Check fit opens the accept preview of that one task; what
  // the preview may have answered is reloaded on return.
  group('checking fit', () {
    testWidgets('from an Attention card, then Attention reloads',
        (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      final before =
          rig.attention.calls.where((c) => c.startsWith('invitations')).length;
      await tester.tap(
          find.byKey(const Key('attention_check_fit_invitation:i-bc')));
      await tester.pumpAndSettle();
      expect(rig.previewed, ['b1']);
      expect(
          rig.attention.calls.where((c) => c.startsWith('invitations')).length,
          greaterThan(before));
      await rig.close();
    });

    testWidgets('from a Clusters row, then both lists reload', (tester) async {
      final rig = _Rig();
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
      final attentionBefore =
          rig.attention.calls.where((c) => c.startsWith('invitations')).length;
      final clustersBefore = rig.callsStarting('clusters(isOutbox: false');
      await tester.tap(find.byKey(const Key('cluster_check_fit_i-bc')));
      await tester.pumpAndSettle();
      expect(rig.previewed, ['b1']);
      expect(
          rig.attention.calls.where((c) => c.startsWith('invitations')).length,
          greaterThan(attentionBefore));
      expect(rig.callsStarting('clusters(isOutbox: false'),
          greaterThan(clustersBefore));
      await rig.close();
    });
  });

  group('answering from a Clusters row', () {
    Future<void> toClusters(WidgetTester tester, _Rig rig) async {
      await _openHub(tester, rig);
      await tester.tap(_segment('clusters'));
      await tester.pumpAndSettle();
    }

    testWidgets('goes through the Attention cubit, with the same Undo',
        (tester) async {
      final rig = _Rig();
      await toClusters(tester, rig);
      await tester.tap(find.byKey(const Key('cluster_accept_i-bc')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(rig.assignments.calls.where((c) => c.startsWith('respond')),
          isEmpty,
          reason: 'waits out the undo window');
      await rig.close();
    });

    testWidgets('Undo sends nothing', (tester) async {
      final rig = _Rig();
      await toClusters(tester, rig);
      await tester.tap(find.byKey(const Key('cluster_accept_i-bc')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Undo'));
      await tester.pump();
      for (final t in rig.timers) {
        t.fire();
      }
      await tester.pumpAndSettle();
      expect(rig.assignments.calls.where((c) => c.startsWith('respond')),
          isEmpty);
      await rig.close();
    });

    testWidgets('once the answer is sent the Clusters row updates',
        (tester) async {
      final rig = _Rig();
      await toClusters(tester, rig);
      expect(find.text('Needs your answer'), findsOneWidget);
      final before = rig.callsStarting('clusters(isOutbox: false');

      await tester.tap(find.byKey(const Key('cluster_accept_i-bc')));
      await tester.pump();
      for (final t in rig.timers) {
        t.fire();
      }
      await tester.pumpAndSettle();
      expect(rig.assignments.calls, contains('respond(b1, accepted)'));
      expect(rig.callsStarting('clusters(isOutbox: false'), greaterThan(before));
      expect(find.text('You accepted'), findsOneWidget);
      expect(find.byKey(const Key('cluster_accept_i-bc')), findsNothing);
      await rig.close();
    });

    testWidgets('with no matching invitation in Attention the row is opened '
        'for review instead of doing nothing', (tester) async {
      final rig = _Rig(attention: FakeTileShareAttentionSources());
      await toClusters(tester, rig);
      await tester.tap(find.byKey(const Key('cluster_accept_i-bc')));
      await tester.pumpAndSettle();
      expect(rig.openedClusters, ['i-bc']);
      expect(rig.assignments.calls.where((c) => c.startsWith('respond')),
          isEmpty);
      await rig.close();
    });
  });

  group('looks right', () {
    testWidgets('the loading skeleton fits a short screen (landscape phone)',
        (tester) async {
      tester.view.physicalSize = const Size(700, 330);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rig = _Rig();
      rig.attention.hold();
      await tester.pumpWidget(_app(rig));
      await tester.tap(find.text('open hub'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('attention_skeleton')), findsOneWidget);
      expect(tester.takeException(), isNull);
      rig.attention.release();
      await tester.pumpAndSettle();
      await rig.close();
    });

    testWidgets('both themes, both segments, a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        final rig = _Rig();
        await _openHub(tester, rig, theme: theme);
        expect(tester.takeException(), isNull);
        await tester.tap(_segment('clusters'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await rig.close();
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
