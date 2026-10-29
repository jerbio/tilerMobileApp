// TileShare redesign Step 9.16 (§5.8, T20, T23): the recipient's detail of a
// share - the commitment. The answers follow the mode: Accept / Decline for a
// Check fit for pending assignments, Accept all / Decline all for a Class, and
// Accept / Decline on each of my tasks for a Project (never Accept all). My
// tasks are listed with my answer, my progress once accepted, a way to the
// scheduled tile, and the task's comments. Driven by the real cubits over
// in-memory sources.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tiletteDetailScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/commitmentDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareDisplayOptions.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tap_visible.dart';
import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime(2026, 10, 3, 9);

class _Rig {
  final FakeTileShareClustersSource clusters;
  final FakeTileShareAssignmentsSource assignments;
  late final TileShareDetailCubit detail;
  final List<String> previewed = [];
  final List<String> opened = [];
  final List<String> comments = [];

  _Rig(String clusterId)
      : clusters = FakeTileShareClustersSource(inbox: [
          tsCluster('bc',
              name: 'Brunch',
              mode: TileShareMode.broadcast,
              creatorId: 'sarah'),
          tsCluster('kc',
              name: 'Interview prep',
              mode: TileShareMode.class_,
              creatorId: 'sarah'),
          tsCluster('pj',
              name: 'Launch prep',
              mode: TileShareMode.project,
              creatorId: 'sarah'),
        ], tilettesByCluster: {
          'bc': [tsTilette('tb', clusterId: 'bc')],
          'kc': [
            tsTilette('tk1', clusterId: 'kc'),
            tsTilette('tk2', clusterId: 'kc'),
          ],
          'pj': [
            tsTilette('tp1', clusterId: 'pj'),
            tsTilette('tp2', clusterId: 'pj'),
            tsTilette('tp3', clusterId: 'pj'),
          ],
        }),
        assignments = FakeTileShareAssignmentsSource([
          tsDesignatedTile('b1', clusterId: 'bc', name: 'Bring pastries'),
          tsDesignatedTile('k1',
              clusterId: 'kc',
              name: 'Write the brief',
              note: 'Use the **Q3** numbers'),
          tsDesignatedTile('k2', clusterId: 'kc', name: 'Review the deck'),
          tsDesignatedTile('p1', clusterId: 'pj', name: 'Research'),
          tsDesignatedTile('p2',
              clusterId: 'pj',
              name: 'Design',
              status: InvitationStatus.accepted,
              completion: 40),
          tsDesignatedTile('p3',
              clusterId: 'pj', name: 'Launch', ownerId: 'someone'),
        ]) {
    detail = TileShareDetailCubit(
      clusters: clusters,
      assignments: assignments,
      target: TileShareDetailTarget.cluster(clusterId),
      currentUserId: () => 'me',
    );
  }

  List<String> responds() =>
      assignments.calls.where((c) => c.startsWith('respond')).toList();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {bool preview = true,
    bool detailScreen = false,
    Size size = const Size(390, 900),
    ThemeData? theme,
    double textScale = 1,
    TiletteDensity density = TiletteDensity.compact}) async {
  final display = TileShareDisplaySettings.memory(density: density);
  addTearDown(display.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: BlocProvider.value(
      value: rig.detail,
      child: TileShareDetailScaffold(
        displaySettings: display,
        now: _now,
        contentBuilder: (context, state) => CommitmentDetail(
          detail: state,
          assignments: rig.assignments,
          onAnswered: rig.detail.refresh,
          onPreview: preview ? rig.previewed.add : null,
          onOpenTile: (tile) => rig.opened.add(tile.id!),
          onComments: (tile) => rig.comments.add(tile.id!),
          onOpenTilette: detailScreen
              ? (tile) => TiletteDetailScreen.byTilette(
                    context: context,
                    designatedTile: tile,
                    options: TiletteDetailOptions(
                        shareName: state.cluster?.name,
                        mode: state.mode,
                        assignments: rig.assignments,
                        canRespond: true,
                        onPreview: preview
                            ? () async {
                                rig.previewed.add(tile.id!);
                                return null;
                              }
                            : null,
                        onAnswered: rig.detail.refresh),
                  )
              : null,
        ),
      ),
    ),
  ));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));
Finder _task(String id) => _key('commitment_task_$id');

void main() {
  testWidgets('Review request opens the full detail before accepting',
      (tester) async {
    final rig = _Rig('pj');
    addTearDown(rig.detail.close);
    await _open(tester, rig, detailScreen: true);
    expect(_key('commitment_accept_p1'), findsNothing);
    await tapVisible(tester, _key('commitment_review_p1'));
    await _settle(tester);
    expect(find.byType(TiletteDetailScreen), findsOneWidget);
    expect(find.text('Launch prep'), findsOneWidget);
    expect(_key('tilette_detail_title'), findsOneWidget);
    expect(_key('tilette_invitation_footer'), findsOneWidget);
    expect(rig.responds(), isEmpty);
    await tester.tap(_key('tilette_check_fit'));
    await _settle(tester);
    expect(rig.previewed, ['p1']);
    expect(rig.responds(), isEmpty, reason: 'previewing never accepts');
    await tester.tap(_key('tilette_accept'));
    await _settle(tester);
    expect(rig.responds(), ['respond(p1, accepted)']);
    await tester.pageBack();
    await _settle(tester);
    expect(_key('commitment_review_p1'), findsNothing);
    expect(_key('commitment_open_p1'), findsOneWidget);
  });

  testWidgets(
      'pending Class and Project tilettes keep preview in every density',
      (tester) async {
    for (final share in ['kc', 'pj']) {
      for (final density in TiletteDensity.values) {
        final rig = _Rig(share);
        final id = share == 'kc' ? 'k1' : 'p1';
        await _open(tester, rig, density: density);
        if (density == TiletteDensity.list) {
          await tapVisible(tester,
              find.descendant(of: _task(id), matching: _key('tilette_expand')));
          await _settle(tester);
        }
        await tapVisible(tester, _key('commitment_check_fit_$id'));
        expect(rig.previewed, [id]);
        expect(rig.responds(), isEmpty);
        await rig.detail.close();
      }
    }
  });

  testWidgets('preview actions are absent without a preview callback',
      (tester) async {
    for (final share in ['kc', 'pj']) {
      final rig = _Rig(share);
      await _open(tester, rig, preview: false);
      expect(find.text('Check fit'), findsNothing);
      await rig.detail.close();
    }
  });

  testWidgets(
      'project acceptance works when the mobile embedded roster is null',
      (tester) async {
    final rig = _Rig('pj');
    addTearDown(rig.detail.close);
    final tile = rig.assignments.tiles.firstWhere((t) => t.id == 'p1');
    tile.tileTemplate!.designatedUsers = null;
    rig.clusters.tilettesByCluster['pj'] = [
      TileShareTemplate.fromJson({
        'id': tile.tileTemplate!.id,
        'clusterId': 'pj',
        'designatedUsers': [
          {'designatedTileTemplateId': 'p1', 'userId': 'me'},
        ],
      }),
    ];
    await _open(tester, rig);
    expect(_key('commitment_accept_p1'), findsOneWidget);
    await tapVisible(tester, _key('commitment_accept_p1'));
    await _settle(tester);
    expect(rig.responds(), ['respond(p1, accepted)']);
    expect(
        rig.detail.state.mine.firstWhere((t) => t.id == 'p1').invitationStatus,
        'accepted');
  });

  group('Broadcast', () {
    testWidgets('Accept and Decline, and Check fit for the one task',
        (tester) async {
      final rig = _Rig('bc');
      await _open(tester, rig);
      expect(
          find.descendant(
              of: _key('commitment_accept'), matching: find.text('Accept')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('commitment_decline'), matching: find.text('Decline')),
          findsOneWidget);
      await tapVisible(tester, _key('commitment_check_fit'));
      expect(rig.previewed, ['b1']);
      await tapVisible(tester, _key('commitment_accept'));
      await _settle(tester);
      expect(rig.responds(), ['respond(b1, accepted)']);
      expect(find.descendant(of: _task('b1'), matching: find.text('Accepted')),
          findsOneWidget);
      expect(_key('commitment_accept'), findsNothing, reason: 'answered');
      await rig.detail.close();
    });

    testWidgets('no Check fit without a preview', (tester) async {
      final rig = _Rig('bc');
      await _open(tester, rig, preview: false);
      expect(_key('commitment_check_fit'), findsNothing);
      await rig.detail.close();
    });
  });

  group('Class', () {
    testWidgets(
        'Accept all / Decline all for every task I hold, and my tasks '
        'listed - never per-task buttons', (tester) async {
      final rig = _Rig('kc');
      await _open(tester, rig);
      expect(find.text('Accept all'), findsOneWidget);
      expect(_key('commitment_invitation_panel'), findsOneWidget);
      expect(find.text('Decline all'), findsOneWidget);
      expect(_key('commitment_accept_k1'), findsNothing);
      expect(_key('commitment_check_fit_k1'), findsOneWidget);
      expect(_key('commitment_check_fit_k2'), findsOneWidget);
      expect(find.text('Your tilettes (2)'), findsOneWidget);
      expect(_task('k1'), findsOneWidget);
      expect(_task('k2'), findsOneWidget);
      await tapVisible(tester, _key('commitment_accept'));
      await _settle(tester);
      expect(
          rig.responds(), ['respond(k1, accepted)', 'respond(k2, accepted)']);
      await rig.detail.close();
    });

    testWidgets('only the pending task offers Check fit', (tester) async {
      final rig = _Rig('kc');
      rig.assignments.tiles.firstWhere((t) => t.id == 'k2').invitationStatus =
          'accepted';
      await _open(tester, rig);
      expect(_key('commitment_accept'), findsOneWidget);
      expect(_key('commitment_check_fit_k1'), findsOneWidget);
      expect(_key('commitment_check_fit_k2'), findsNothing);
      await rig.detail.close();
    });

    testWidgets(
        'a task that refuses says how many went through; Retry sends '
        'the rest', (tester) async {
      final rig = _Rig('kc');
      await _open(tester, rig);
      rig.assignments.failNextOn('respond(k2', StateError('offline'));
      await tapVisible(tester, _key('commitment_accept'));
      await _settle(tester);
      expect(find.text('1 of 2 answered; the rest are still pending.'),
          findsOneWidget);
      rig.assignments.calls.clear();
      await tapVisible(tester, _key('commitment_retry'));
      await _settle(tester);
      expect(rig.responds(), ['respond(k2, accepted)']);
      await rig.detail.close();
    });
  });

  group('Project', () {
    testWidgets(
        'Accept / Decline on each of my tasks; only my tasks; no Accept '
        'all, with per-task Check fit', (tester) async {
      final rig = _Rig('pj');
      await _open(tester, rig);
      expect(find.text('Accept all'), findsNothing);
      expect(_key('commitment_accept'), findsNothing);
      expect(_key('commitment_check_fit'), findsNothing);
      expect(_key('commitment_check_fit_p1'), findsOneWidget);
      expect(_key('commitment_check_fit_p2'), findsNothing);
      expect(_task('p1'), findsOneWidget);
      expect(_task('p2'), findsOneWidget);
      expect(_task('p3'), findsNothing, reason: 'someone else\'s task');
      expect(_key('commitment_accept_p1'), findsOneWidget);
      expect(_key('commitment_accept_p2'), findsNothing, reason: 'answered');
      await tapVisible(tester, _key('commitment_decline_p1'));
      await _settle(tester);
      expect(rig.responds(), ['respond(p1, declined)']);
      await rig.detail.close();
    });

    testWidgets('an accepted task shows my progress and opens the tile',
        (tester) async {
      final rig = _Rig('pj');
      await _open(tester, rig);
      expect(find.descendant(of: _task('p2'), matching: find.text('40%')),
          findsOneWidget);
      await tapVisible(tester, _key('commitment_open_p2'));
      expect(rig.opened, ['p2']);
      expect(_key('commitment_open_p1'), findsNothing,
          reason: 'nothing scheduled before accepting');
      await rig.detail.close();
    });
  });

  testWidgets('each task\'s comments are a tap away', (tester) async {
    final rig = _Rig('kc');
    await _open(tester, rig);
    await tapVisible(tester, _key('commitment_comments_k2'));
    expect(rig.comments, ['k2']);
    await rig.detail.close();
  });

  testWidgets('a refused accept says so, with Retry', (tester) async {
    final rig = _Rig('bc');
    await _open(tester, rig);
    rig.assignments.failNextOn('respond', StateError('offline'));
    await tapVisible(tester, _key('commitment_accept'));
    await _settle(tester);
    expect(find.text('Couldn’t accept it. Try again.'), findsOneWidget);
    await tapVisible(tester, _key('commitment_retry'));
    await _settle(tester);
    expect(find.descendant(of: _task('b1'), matching: find.text('Accepted')),
        findsOneWidget);
    await rig.detail.close();
  });

  testWidgets(
      'a schedule that cannot refresh yet is said, and the answer '
      'stands', (tester) async {
    final rig = _Rig('bc');
    await _open(tester, rig);
    rig.assignments.failNextOn('afterAccept', StateError('down'));
    await tapVisible(tester, _key('commitment_accept'));
    await _settle(tester);
    expect(find.text('Accepted, but your schedule couldn’t refresh yet.'),
        findsOneWidget);
    expect(find.descendant(of: _task('b1'), matching: find.text('Accepted')),
        findsOneWidget);
    await rig.detail.close();
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final id in ['bc', 'kc', 'pj']) {
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        for (final scale in [1.0, 1.6]) {
          final rig = _Rig(id);
          await _open(tester, rig,
              size: const Size(320, 700), theme: theme, textScale: scale);
          expect(tester.takeException(), isNull,
              reason: '$id ${theme.brightness} x$scale');
          await rig.detail.close();
        }
      }
    }
  });

  // Step 9.16d (T27): a task's notes are the owner's markdown, shown rendered
  // and short; nothing for a task without notes.
  testWidgets('each task shows its notes, rendered', (tester) async {
    final rig = _Rig('kc');
    await _open(tester, rig, density: TiletteDensity.comfortable);
    expect(
        find.descendant(
            of: _task('k1'), matching: find.byType(MarkdownNoteView)),
        findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(
        find.descendant(
            of: _task('k2'), matching: find.byType(MarkdownNoteView)),
        findsNothing);
    await rig.detail.close();
  });
}
