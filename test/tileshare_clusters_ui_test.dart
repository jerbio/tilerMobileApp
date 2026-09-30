// TileShare redesign Step 9.8 (T3, T6, T11): the Clusters list - filter chips
// over an animated list of cluster cards, against the real cubit with
// in-memory sources. Changes animate rather than snap; RSVP counts are asked
// for only the rows that are built; deleting confirms first and comes back if
// the server refuses.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clustersView.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Rig {
  final FakeTileShareClustersSource clusters;
  final FakeTileShareAssignmentsSource assignments;
  late final TileShareClustersCubit cubit;
  final List<ClusterListItem> opened = [];
  final List<String> answered = [];
  int created = 0;

  _Rig({
    List<TileShareClusterData>? outbox,
    List<TileShareClusterData>? inbox,
    List<DesignatedTile>? mine,
    int pageSize = 50,
  })  : clusters = FakeTileShareClustersSource(
            outbox: outbox ?? _defaultOutbox(),
            inbox: inbox ?? _defaultInbox()),
        assignments = FakeTileShareAssignmentsSource(mine ?? _defaultMine()) {
    cubit = TileShareClustersCubit(
        clusters: clusters, assignments: assignments, pageSize: pageSize);
  }
}

List<TileShareClusterData> _defaultOutbox() => [
      tsCluster('o1', name: 'Launch prep', mode: TileShareMode.broadcast, endMs: 100),
      tsCluster('o2', name: 'Sprint board', mode: TileShareMode.project, endMs: 300),
    ];

List<TileShareClusterData> _defaultInbox() => [
      tsCluster('i1', name: 'Yoga class', mode: TileShareMode.class_, endMs: 200),
      tsCluster('i2', name: 'Design review', mode: TileShareMode.broadcast, endMs: 400),
    ];

List<DesignatedTile> _defaultMine() => [
      tsDesignatedTile('d1', clusterId: 'i1'),
      tsDesignatedTile('d2', clusterId: 'i1'),
      tsDesignatedTile('d3', clusterId: 'i2'),
    ];

Widget _app(_Rig rig,
        {ThemeData? theme, bool withCreate = true, bool withAnswer = true}) =>
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
        body: BlocProvider<TileShareClustersCubit>.value(
          value: rig.cubit,
          child: TileShareClustersView(
            onOpen: (item) => rig.opened.add(item),
            onCreate: withCreate ? () => rig.created++ : null,
            onAnswer: withAnswer
                ? (item, status) => rig.answered.add('${item.id}:${status.name}')
                : null,
          ),
        ),
      ),
    );

Future<void> _pumpView(WidgetTester tester, _Rig rig,
    {ThemeData? theme,
    bool load = true,
    bool withCreate = true,
    bool withAnswer = true}) async {
  await tester.pumpWidget(
      _app(rig, theme: theme, withCreate: withCreate, withAnswer: withAnswer));
  if (load) {
    await rig.cubit.load();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapChip(WidgetTester tester, String name) async {
  final finder = find.byKey(Key('clusters_chip_$name'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

Finder _card(String id) => find.byKey(ValueKey('cluster_card_$id'));

Future<void> _chooseDelete(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('cluster_menu_$id')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text('Delete').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('loading and rows', () {
    testWidgets('a skeleton shows while the first load is in flight, then the '
        'cards', (tester) async {
      final rig = _Rig();
      await tester.pumpWidget(_app(rig));
      rig.clusters.hold();
      rig.assignments.hold();
      final loading = rig.cubit.load();
      await tester.pump();
      expect(find.byKey(const Key('clusters_skeleton')), findsOneWidget);
      rig.clusters.release();
      rig.assignments.release();
      await loading;
      await _settle(tester);
      expect(find.byKey(const Key('clusters_skeleton')), findsNothing);
      expect(_card('o1'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('rows are in deadline order across both sources',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      final tops = ['o1', 'i1', 'o2', 'i2']
          .map((id) => tester.getTopLeft(_card(id)).dy)
          .toList();
      expect(tops, orderedEquals([...tops]..sort()));
      await rig.cubit.close();
    });

    testWidgets('tapping a card reports the row', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await tester.tap(find.text('Yoga class'));
      expect(rig.opened.single.id, 'i1');
      await rig.cubit.close();
    });

    testWidgets('renders in the dark theme too', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig, theme: TileThemeData.darkTheme);
      expect(tester.takeException(), isNull);
      expect(_card('o1'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('filters (T6)', () {
    testWidgets('three chips, All first and selected', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      for (final name in ['all', 'sharedWithMe', 'createdByMe']) {
        expect(find.byKey(Key('clusters_chip_$name')), findsOneWidget);
      }
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Shared with me'), findsOneWidget);
      expect(find.text('Created by me'), findsOneWidget);
      expect(
          tester
              .widget<ChoiceChip>(find.byKey(const Key('clusters_chip_all')))
              .selected,
          isTrue);
      await rig.cubit.close();
    });

    testWidgets('Shared with me and Created by me narrow the list',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _tapChip(tester, 'sharedWithMe');
      await _settle(tester);
      expect(_card('i1'), findsOneWidget);
      expect(_card('i2'), findsOneWidget);
      expect(_card('o1'), findsNothing);

      await _tapChip(tester, 'createdByMe');
      await _settle(tester);
      expect(_card('o1'), findsOneWidget);
      expect(_card('i1'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('a row that stays is the same widget after the switch, and '
        'the ones that go fade out rather than vanish (T11)', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      final before = tester.element(_card('o1'));

      await _tapChip(tester, 'createdByMe');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_card('i1'), findsOneWidget,
          reason: 'still on screen, part-way through leaving');
      expect(identical(tester.element(_card('o1')), before), isTrue);

      await _settle(tester);
      expect(_card('i1'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('a filter switch asks the server for nothing',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      final before = rig.clusters.calls.length;
      await _tapChip(tester, 'sharedWithMe');
      await _settle(tester);
      expect(rig.clusters.calls.length, before);
      await rig.cubit.close();
    });
  });

  group('empty and failed states', () {
    testWidgets('each filter explains its own emptiness', (tester) async {
      final rig = _Rig(outbox: [], inbox: [], mine: []);
      await _pumpView(tester, rig);
      expect(find.text('Nothing shared yet'), findsOneWidget);
      expect(find.byKey(const Key('clusters_empty')), findsOneWidget);

      await _tapChip(tester, 'sharedWithMe');
      await _settle(tester);
      expect(find.text('Nothing shared with you'), findsOneWidget);

      await _tapChip(tester, 'createdByMe');
      await _settle(tester);
      expect(find.text('You haven’t shared anything'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('"Share a tile" is offered where it makes sense and calls '
        'back', (tester) async {
      final rig = _Rig(outbox: [], inbox: [], mine: []);
      await _pumpView(tester, rig);
      expect(find.text('Share a tile'), findsOneWidget);
      await tester.tap(find.text('Share a tile'));
      expect(rig.created, 1);

      await _tapChip(tester, 'sharedWithMe');
      await _settle(tester);
      expect(find.text('Share a tile'), findsNothing,
          reason: 'sharing cannot put something in "shared with me"');

      await _tapChip(tester, 'createdByMe');
      await _settle(tester);
      expect(find.text('Share a tile'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('no action without a handler', (tester) async {
      final rig = _Rig(outbox: [], inbox: [], mine: []);
      await _pumpView(tester, rig, withCreate: false);
      expect(find.text('Share a tile'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('everything failing is one error state with Retry, never '
        '"nothing shared"', (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('clusters(isOutbox: true', StateError('a'));
      rig.clusters.failNextOn('clusters(isOutbox: false', StateError('b'));
      await _pumpView(tester, rig);
      expect(find.text('Shares couldn’t load'), findsOneWidget);
      expect(find.byKey(const Key('clusters_empty')), findsNothing);
      expect(find.text('Nothing shared yet'), findsNothing);

      await tester.tap(find.text('Retry'));
      await _settle(tester);
      expect(_card('o1'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('one source failing is a banner above the other\'s rows, '
        'with Retry', (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('clusters(isOutbox: false', StateError('down'));
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('clusters_error_banner')), findsOneWidget);
      expect(find.text('Some shares couldn’t load'), findsOneWidget);
      expect(_card('o1'), findsOneWidget);
      expect(_card('i1'), findsNothing);

      await tester.tap(find.text('Retry'));
      await _settle(tester);
      expect(find.byKey(const Key('clusters_error_banner')), findsNothing);
      expect(_card('i1'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('a source the current filter does not show is no banner '
        'there', (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('clusters(isOutbox: false', StateError('down'));
      await _pumpView(tester, rig);
      await _tapChip(tester, 'createdByMe');
      await _settle(tester);
      expect(find.byKey(const Key('clusters_error_banner')), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('a failed source that is the only one shown is the error '
        'state, not an empty list', (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('clusters(isOutbox: false', StateError('down'));
      await _pumpView(tester, rig);
      await _tapChip(tester, 'sharedWithMe');
      await _settle(tester);
      expect(find.byKey(const Key('clusters_empty')), findsNothing);
      expect(find.text('Some shares couldn’t load'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('responses are counted for the rows on screen (O2)', () {
    testWidgets('an owner row asks once and shows the counts', (tester) async {
      final rig = _Rig(outbox: [
        tsCluster('o1', name: 'Launch prep', mode: TileShareMode.broadcast),
      ], inbox: [], mine: []);
      rig.clusters.tilettesByCluster['o1'] = [
        tsTilette('t1', clusterId: 'o1', assignees: [
          tsAssignee('a@x.com', status: InvitationStatus.accepted),
          tsAssignee('b@x.com'),
        ]),
      ];
      await _pumpView(tester, rig);
      expect(find.text('1 of 2 accepted'), findsOneWidget);
      expect(rig.clusters.calls.where((c) => c == 'tilettes(o1)'), hasLength(1));
      await rig.cubit.close();
    });

    testWidgets('a shared row never asks', (tester) async {
      final rig = _Rig(outbox: [], mine: []);
      await _pumpView(tester, rig);
      expect(rig.clusters.calls.where((c) => c.startsWith('tilettes(')),
          isEmpty);
      await rig.cubit.close();
    });

    testWidgets('only the rows that are built are asked about; scrolling '
        'asks about more', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rig = _Rig(outbox: [
        for (var i = 0; i < 40; i++)
          tsCluster('o${i.toString().padLeft(2, '0')}',
              endMs: 1000 + i, mode: TileShareMode.broadcast),
      ], inbox: [], mine: []);
      await _pumpView(tester, rig);
      int asked() =>
          rig.clusters.calls.where((c) => c.startsWith('tilettes(')).length;
      final first = asked();
      expect(first, greaterThan(0));
      expect(first, lessThan(40), reason: 'not every row is built');

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await _settle(tester);
      expect(asked(), greaterThan(first));
      await rig.cubit.close();
    });

    testWidgets('a failed count leaves the card, with Retry that asks again',
        (tester) async {
      final rig = _Rig(outbox: [
        tsCluster('o1', name: 'Launch prep', mode: TileShareMode.broadcast),
      ], inbox: [], mine: []);
      rig.clusters.tilettesByCluster['o1'] = [
        tsTilette('t1', clusterId: 'o1', assignees: [
          tsAssignee('a@x.com', status: InvitationStatus.accepted),
        ]),
      ];
      rig.clusters.failNextOn('tilettes(o1)', StateError('no roster'));
      await _pumpView(tester, rig);
      expect(find.text('Launch prep'), findsOneWidget);
      expect(find.text('Responses unavailable'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await _settle(tester);
      expect(find.text('1 of 1 accepted'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('inline answers (T3, T20)', () {
    testWidgets('a pending Broadcast and a pending Class offer their buttons '
        'and report the row and the answer', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('cluster_accept_i2')), findsOneWidget);
      expect(find.text('Accept all'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('cluster_accept_i2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cluster_accept_i2')));
      await tester.ensureVisible(find.byKey(const Key('cluster_decline_i1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cluster_decline_i1')));
      expect(rig.answered, ['i2:accepted', 'i1:declined']);
      await rig.cubit.close();
    });

    testWidgets('without a handler there are no buttons', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig, withAnswer: false);
      expect(find.byKey(const Key('cluster_accept_i2')), findsNothing);
      await rig.cubit.close();
    });
  });

  group('delete (owner)', () {
    testWidgets('asks first; cancelling keeps the row and asks the server '
        'nothing', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _chooseDelete(tester, 'o1');
      expect(find.text('Delete this share?'), findsOneWidget);
      expect(find.textContaining('Launch prep'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(_card('o1'), findsOneWidget);
      expect(rig.clusters.calls.where((c) => c.startsWith('deleteCluster')),
          isEmpty);
      await rig.cubit.close();
    });

    testWidgets('confirming removes the row with an animation and deletes it',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _chooseDelete(tester, 'o1');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_card('o1'), findsOneWidget, reason: 'part-way out, not snapped');
      await _settle(tester);
      expect(_card('o1'), findsNothing);
      expect(rig.clusters.calls, contains('deleteCluster(o1)'));
      await rig.cubit.close();
    });

    testWidgets('a refusal brings the row back and says which one',
        (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('deleteCluster', StateError('refused'));
      await _pumpView(tester, rig);
      await _chooseDelete(tester, 'o1');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await _settle(tester);
      await _settle(tester);
      expect(_card('o1'), findsOneWidget);
      expect(find.text('Couldn’t delete “Launch prep”. It’s back in your list.'),
          findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('a shared row has no delete menu', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('cluster_menu_i1')), findsNothing);
      await rig.cubit.close();
    });
  });

  group('load more', () {
    _Rig paged() => _Rig(
        pageSize: 2,
        outbox: [
          tsCluster('o1', endMs: 10),
          tsCluster('o2', endMs: 30),
          tsCluster('o3', endMs: 50),
        ],
        inbox: [],
        mine: []);

    testWidgets('a full page offers "Load more"; it fetches the next page and '
        'goes away when there is no more', (tester) async {
      final rig = paged();
      await _pumpView(tester, rig);
      await tester.ensureVisible(find.text('Load more'));
      expect(_card('o3'), findsNothing);
      await tester.tap(find.text('Load more'));
      await _settle(tester);
      await tester.dragUntilVisible(
          _card('o3'), find.byType(CustomScrollView), const Offset(0, -200));
      expect(_card('o3'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('nothing to offer when everything is loaded', (tester) async {
      final rig = _Rig(pageSize: 50);
      await _pumpView(tester, rig);
      expect(find.text('Load more'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('a failed page says so and Retry asks again', (tester) async {
      final rig = paged();
      await _pumpView(tester, rig);
      rig.clusters
          .failNextOn('clusters(isOutbox: true, index: 2', StateError('x'));
      await tester.ensureVisible(find.text('Load more'));
      await tester.tap(find.text('Load more'));
      await _settle(tester);
      expect(find.text('Couldn’t load more'), findsOneWidget);

      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await _settle(tester);
      await tester.dragUntilVisible(
          _card('o3'), find.byType(CustomScrollView), const Offset(0, -200));
      expect(_card('o3'), findsOneWidget);
      await rig.cubit.close();
    });
  });
}
