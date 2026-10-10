// TileShare no-snap regression harness (redesign T11, mirroring the day
// grid's daygrid_no_snap_test and its §16.2 contract).
//
// "Snap" = a single-frame, non-animated change of >= 4 px in the on-screen
// position of a visible row or card, or of a list's scroll offset, that the
// user did not cause with a gesture. Each case hosts a production TileShare
// surface against the real cubits and in-memory sources, records where every
// visible keyed row is, applies one change that arrives from outside (a
// reload, an item added or removed, a filter, a refusal), and asserts at
// t = 0 - the very next frame - that nothing has jumped: rows that stay are
// where they were, and rows that must move (because something above them
// arrived or left) have not moved yet - they animate over the frames that
// follow.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_clusters_state.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionView.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/clusters/clustersView.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/commitmentDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareRosterDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_no_snap.dart';
import 'helpers/tileshare_fixtures.dart';

Widget _app(Widget home) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

double _scrollOffset(WidgetTester tester, Finder scrollable) =>
    tester.state<ScrollableState>(scrollable).position.pixels;

void main() {
  // ---- the hub: Clusters -----------------------------------------------------
  group('Clusters', () {
    late FakeTileShareClustersSource clusters;
    late TileShareClustersCubit cubit;

    Future<void> open(WidgetTester tester) async {
      _phone(tester);
      clusters = FakeTileShareClustersSource(
        outbox: [
          for (int i = 0; i < 6; i++)
            tsCluster('o$i',
                name: 'Mine $i',
                mode: TileShareMode.broadcast,
                creatorId: 'me',
                endMs: 1000 + i * 100),
        ],
        inbox: [
          for (int i = 0; i < 6; i++)
            tsCluster('i$i',
                name: 'Shared $i',
                mode: TileShareMode.class_,
                endMs: 1050 + i * 100),
        ],
      );
      cubit = TileShareClustersCubit(
          clusters: clusters,
          assignments: FakeTileShareAssignmentsSource(const <DesignatedTile>[]),
          currentUserId: () => 'me');
      await tester.pumpWidget(_app(Scaffold(
        body: BlocProvider<TileShareClustersCubit>.value(
          value: cubit,
          child: TileShareClustersView(onOpen: (_) {}),
        ),
      )));
      await cubit.load();
      await _settle(tester);
      // Mid-list, so a reset scroll would show.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await _settle(tester);
    }

    testWidgets(
        '(C1) a reload with nothing new moves nothing and keeps the '
        'scroll', (tester) async {
      await open(tester);
      final before = keyedRects(tester, 'cluster_card_');
      final double offset =
          _scrollOffset(tester, find.byType(Scrollable).first);
      await cubit.refresh();
      await tester.pump();
      expectNoJump(before, keyedRects(tester, 'cluster_card_'));
      expect(_scrollOffset(tester, find.byType(Scrollable).first), offset);
      await cubit.close();
    });

    testWidgets('(C2) a share arriving above the others animates in',
        (tester) async {
      await open(tester);
      final before = keyedRects(tester, 'cluster_card_');
      clusters.outbox.insert(
          0,
          tsCluster('new',
              name: 'New',
              creatorId: 'me',
              mode: TileShareMode.project,
              endMs: 1));
      await cubit.refresh();
      await tester.pump();
      expectNoJump(before, keyedRects(tester, 'cluster_card_'),
          mayAnimate: true);
      await expectGlides(tester, () => keyedRects(tester, 'cluster_card_'));
      await cubit.close();
    });

    testWidgets('(C3) a share leaving animates out', (tester) async {
      await open(tester);
      final before = keyedRects(tester, 'cluster_card_');
      clusters.outbox.removeWhere((c) => c.id == 'o1');
      await cubit.refresh();
      await tester.pump();
      expectNoJump(before, keyedRects(tester, 'cluster_card_'),
          mayAnimate: true);
      await expectGlides(tester, () => keyedRects(tester, 'cluster_card_'));
      await cubit.close();
    });

    testWidgets('(C4) switching the filter animates', (tester) async {
      await open(tester);
      final before = keyedRects(tester, 'cluster_card_');
      cubit.setFilter(ClusterFilter.createdByMe);
      await tester.pump();
      expectNoJump(before, keyedRects(tester, 'cluster_card_'),
          mayAnimate: true);
      await expectGlides(tester, () => keyedRects(tester, 'cluster_card_'));
      await cubit.close();
    });
  });

  // ---- the hub: Attention ------------------------------------------------------
  group('Attention', () {
    testWidgets(
        '(A1) a reload with nothing new moves nothing; an item that '
        'leaves animates out', (tester) async {
      _phone(tester);
      final attention = FakeTileShareAttentionSources(activity: [
        for (int i = 0; i < 6; i++)
          tsActivity('e$i', 'assignment_declined',
              cluster: 'c$i', atMsFromNow: -1000 * (i + 1)),
      ]);
      final cubit = TileShareAttentionCubit(
        attention: attention,
        assignments: FakeTileShareAssignmentsSource(const <DesignatedTile>[]),
        clusters: FakeTileShareClustersSource(outbox: [
          for (int i = 0; i < 6; i++)
            tsCluster('c$i', creatorId: 'me', mode: TileShareMode.broadcast),
        ]),
        currentUserId: () => 'me',
        clock: () => kTileShareNow,
      );
      await tester.pumpWidget(_app(Scaffold(
        body: BlocProvider<TileShareAttentionCubit>.value(
          value: cubit,
          child: TileShareAttentionView(onOpen: (_) {}),
        ),
      )));
      await cubit.load();
      await _settle(tester);
      var before = keyedRects(tester, 'attention_card_');
      await cubit.refresh();
      await tester.pump();
      expectNoJump(before, keyedRects(tester, 'attention_card_'));

      await _settle(tester);
      before = keyedRects(tester, 'attention_card_');
      attention.dismissed.add('e1');
      await cubit.refresh();
      await tester.pump();
      expectNoJump(before, keyedRects(tester, 'attention_card_'),
          mayAnimate: true);
      await expectGlides(tester, () => keyedRects(tester, 'attention_card_'));
      await cubit.close();
    });
  });

  // ---- the detail ---------------------------------------------------------------
  group('Detail', () {
    late FakeTileShareClustersSource clusters;
    late FakeTileShareRecipientsSource recipients;
    late FakeTileShareEditSource edits;
    late TileShareDetailCubit detail;

    Future<void> open(WidgetTester tester,
        {String segment = 'overview',
        TileShareMode mode = TileShareMode.class_}) async {
      _phone(tester);
      final tilettes = [
        for (int i = 0; i < 6; i++)
          tsTilette('t$i', clusterId: 'k', name: 'Tilette $i', assignees: [
            tsAssignee('ann@x.com', status: InvitationStatus.accepted),
            tsAssignee('bob@x.com'),
            tsAssignee('cy@x.com'),
          ]),
      ];
      clusters = FakeTileShareClustersSource(outbox: [
        tsCluster('k', name: 'Launch', mode: mode, creatorId: 'me'),
      ], tilettesByCluster: {
        'k': tilettes,
      });
      recipients = FakeTileShareRecipientsSource(
          tilettes: {for (final t in tilettes) t.id!: t});
      edits = FakeTileShareEditSource(clusters);
      detail = TileShareDetailCubit(
        clusters: clusters,
        edits: edits,
        target: const TileShareDetailTarget.cluster('k'),
        currentUserId: () => 'me',
      );
      await tester.pumpWidget(_app(BlocProvider.value(
        value: detail,
        child: TileShareDetailScaffold(
          contentBuilder: (context, state) => mode == TileShareMode.project
              ? ProjectDetail(detail: state, recipients: recipients)
              : ClassDetail(detail: state, recipients: recipients),
        ),
      )));
      await _settle(tester);
      if (segment != 'overview') {
        await tester.tap(find.byKey(Key('roster_segment_$segment')));
        await _settle(tester);
      }
    }

    Map<String, Rect> content(WidgetTester tester) => {
          ...keyedRects(tester, 'detail_header'),
          ...keyedRects(tester, 'class_task_'),
          ...keyedRects(tester, 'project_task_'),
          ...keyedRects(tester, 'participant_'),
        };

    testWidgets('(D1) a reload with nothing new moves nothing', (tester) async {
      await open(tester, segment: 'tasks');
      final before = content(tester);
      await detail.refresh();
      await tester.pump();
      expectNoJump(before, content(tester));
      await detail.close();
    });

    testWidgets(
        '(D2) a reload that fails says so without pushing the content '
        'down in one frame', (tester) async {
      await open(tester, segment: 'tasks');
      final before = content(tester);
      clusters.failNextOn('cluster(', StateError('offline'));
      await detail.refresh();
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets(
        '(D3) a refused change says so without pushing the content '
        'down in one frame', (tester) async {
      await open(tester, segment: 'tasks');
      final before = content(tester);
      edits.failNextOn('updateShare', StateError('offline'));
      await detail.updateShare(name: 'X');
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets(
        '(D4) a tilette that leaves animates out; the ones below do '
        'not jump up', (tester) async {
      await open(tester, segment: 'tasks');
      final before = content(tester);
      await detail.deleteTask('t1');
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets('(D5) a tilette that arrives animates in', (tester) async {
      await open(tester, segment: 'tasks');
      final before = content(tester);
      clusters.tilettesByCluster['k']!
          .insert(0, tsTilette('t-new', clusterId: 'k', name: 'New'));
      recipients.tilettes['t-new'] = clusters.tilettesByCluster['k']!.first;
      await detail.refresh();
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets('(D6) a Project tilette that leaves the board animates out',
        (tester) async {
      await open(tester, segment: 'tasks', mode: TileShareMode.project);
      final before = content(tester);
      await detail.deleteTask('t1');
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets('(D7) someone removed from Participants animates out',
        (tester) async {
      await open(tester, segment: 'participants');
      final before = content(tester);
      // Bob's row's own Remove button.
      await tester.tap(find.descendant(
          of: find.byKey(const ValueKey<String>('participant_asg-bob@x.com')),
          matching: find.byTooltip(
              lookupAppLocalizations(const Locale('en')).participantRemove)));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('participant_remove_confirm')));
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    /// Replaces the share's tilettes, as another device would, and reloads.
    Future<void> reloadWith(List<TileShareTemplate> next) async {
      clusters.tilettesByCluster['k'] = next;
      recipients.tilettes
        ..clear()
        ..addAll({for (final t in next) t.id!: t});
      await detail.refresh();
    }

    List<TileShareTemplate> current() =>
        List<TileShareTemplate>.of(clusters.tilettesByCluster['k']!);

    testWidgets(
        '(D8) Overview: an alert that appears does not push the preview '
        'down in one frame', (tester) async {
      await open(tester);
      final before = content(tester);
      // A new tilette nobody has yet: everyone is now incomplete.
      await reloadWith(
          [...current(), tsTilette('t-new', clusterId: 'k', name: 'New')]);
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets(
        '(D9) Overview (Project): the unassigned alert does not push the '
        'board preview down in one frame', (tester) async {
      await open(tester, mode: TileShareMode.project);
      final before = content(tester);
      await reloadWith(
          [...current(), tsTilette('t-new', clusterId: 'k', name: 'New')]);
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });

    testWidgets('(D10) Overview: someone who leaves the preview animates out',
        (tester) async {
      await open(tester);
      final before = content(tester);
      await reloadWith([
        for (int i = 0; i < 6; i++)
          tsTilette('t$i', clusterId: 'k', name: 'Tilette $i', assignees: [
            tsAssignee('ann@x.com', status: InvitationStatus.accepted),
            tsAssignee('cy@x.com'),
          ]),
      ]);
      await tester.pump();
      expectNoJump(before, content(tester), mayAnimate: true);
      await expectGlides(tester, () => content(tester));
      await detail.close();
    });
  });

  // ---- the recipient's detail: the commitment ---------------------------------
  group('Commitment', () {
    late FakeTileShareAssignmentsSource assignments;
    late TileShareDetailCubit detail;

    Future<void> open(WidgetTester tester) async {
      _phone(tester);
      final clusters = FakeTileShareClustersSource(inbox: [
        tsCluster('kc',
            name: 'Interview prep',
            mode: TileShareMode.class_,
            creatorId: 'sarah'),
      ], tilettesByCluster: {
        'kc': [
          for (int i = 0; i < 4; i++) tsTilette('tk$i', clusterId: 'kc'),
        ],
      });
      assignments = FakeTileShareAssignmentsSource([
        for (int i = 0; i < 4; i++)
          tsDesignatedTile('k$i', clusterId: 'kc', name: 'Task $i'),
      ]);
      detail = TileShareDetailCubit(
        clusters: clusters,
        assignments: assignments,
        target: const TileShareDetailTarget.cluster('kc'),
        currentUserId: () => 'me',
      );
      await tester.pumpWidget(_app(BlocProvider.value(
        value: detail,
        child: TileShareDetailScaffold(
          contentBuilder: (context, state) => CommitmentDetail(
            detail: state,
            assignments: assignments,
            onAnswered: detail.refresh,
          ),
        ),
      )));
      await _settle(tester);
    }

    Map<String, Rect> rows(WidgetTester tester) =>
        keyedRects(tester, 'commitment_task_');

    testWidgets(
        '(M1) answering everything: the answer buttons leave without the '
        'tasks jumping up', (tester) async {
      await open(tester);
      final before = rows(tester);
      await tester.tap(find.byKey(const Key('commitment_accept')));
      await tester.pump();
      expectNoJump(before, rows(tester), mayAnimate: true);
      await expectGlides(tester, () => rows(tester));
      await detail.close();
    });

    testWidgets(
        '(M2) a refused answer says so without pushing the tasks down in '
        'one frame', (tester) async {
      await open(tester);
      assignments.failNextOn('respond', StateError('offline'));
      final before = rows(tester);
      await tester.tap(find.byKey(const Key('commitment_accept')));
      await tester.pump();
      expectNoJump(before, rows(tester), mayAnimate: true);
      await expectGlides(tester, () => rows(tester));
      await detail.close();
    });

    testWidgets(
        '(M3) a schedule that cannot refresh says so without pushing the '
        'tasks down in one frame', (tester) async {
      await open(tester);
      assignments.failNextOn('afterAccept', StateError('refresh down'));
      final before = rows(tester);
      await tester.tap(find.byKey(const Key('commitment_accept')));
      await tester.pump();
      expectNoJump(before, rows(tester), mayAnimate: true);
      await expectGlides(tester, () => rows(tester));
      await detail.close();
    });
  });
}
