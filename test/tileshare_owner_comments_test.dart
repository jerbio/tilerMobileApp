// The creator's way to a tilette's comments. A tilette has one thread,
// shared by its owner and everyone on it (target `tileshare_tilette`, the
// tilette's own id). The recipient reaches it from each of their tasks; the
// owner now does too: a comments button on every tilette (Class's Tilettes
// tab, Project's board) and, for a Broadcast - one tilette, no Tilettes tab
// - a Comments row on the Overview (owner, 2026-10-12).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tiletteDetailScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareRosterDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime(2026, 10, 3, 9);

Finder _key(String k) => find.byKey(Key(k));

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await _settle(tester);
}

class _Rig {
  final TileShareMode mode;
  late final FakeTileShareRecipientsSource recipients;
  late final TileShareDetailCubit detail;
  final List<String> opened = <String>[];

  _Rig(this.mode) {
    final tilettes = [
      tsTilette('t1', clusterId: 'k', name: 'Write the brief', assignees: [
        tsAssignee('ann@x.com', status: InvitationStatus.accepted),
      ]),
      if (mode != TileShareMode.broadcast)
        tsTilette('t2', clusterId: 'k', name: 'Review the deck', assignees: [
          tsAssignee('bob@x.com'),
        ]),
    ];
    final clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('k', name: 'Interview prep', mode: mode, creatorId: 'me'),
    ], tilettesByCluster: {
      'k': tilettes,
    });
    recipients = FakeTileShareRecipientsSource(
        tilettes: {for (final t in tilettes) t.id!: t});
    detail = TileShareDetailCubit(
      clusters: clusters,
      edits: FakeTileShareEditSource(clusters),
      target: const TileShareDetailTarget.cluster('k'),
      currentUserId: () => 'me',
    );
  }

  void onComments(TileShareTemplate tilette) => opened.add(tilette.id!);
}

Future<void> _open(WidgetTester tester, _Rig rig, {bool comments = true}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  final void Function(TileShareTemplate)? onComments =
      comments ? rig.onComments : null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: rig.detail,
      child: TileShareDetailScaffold(
        now: _now,
        contentBuilder: (context, state) => switch (rig.mode) {
          TileShareMode.project => ProjectDetail(
              detail: state, recipients: rig.recipients, onComments: onComments),
          TileShareMode.broadcast => BroadcastDetail(
              detail: state, recipients: rig.recipients, onComments: onComments),
          _ => ClassDetail(
              detail: state, recipients: rig.recipients, onComments: onComments),
        },
      ),
    ),
  ));
  await _settle(tester);
}

void main() {
  testWidgets("a Class's tilettes each open their own comments", (tester) async {
    final rig = _Rig(TileShareMode.class_);
    await _open(tester, rig);
    await _tap(tester, 'roster_segment_tasks');
    expect(
        find.descendant(
            of: _key('class_task_t1'), matching: find.byTooltip('Comments')),
        findsOneWidget);
    await _tap(tester, 'class_task_comments_t2');
    await _tap(tester, 'class_task_comments_t1');
    expect(rig.opened, ['t2', 't1']);
    await rig.detail.close();
  });

  testWidgets("a Project's board opens each tilette's comments",
      (tester) async {
    final rig = _Rig(TileShareMode.project);
    await _open(tester, rig);
    await _tap(tester, 'roster_segment_tasks');
    expect(
        find.descendant(
            of: _key('project_task_t2'), matching: find.byTooltip('Comments')),
        findsOneWidget);
    await _tap(tester, 'project_task_comments_t2');
    expect(rig.opened, ['t2']);
    await rig.detail.close();
  });

  testWidgets("a Broadcast's Overview opens its one tilette's comments",
      (tester) async {
    final rig = _Rig(TileShareMode.broadcast);
    await _open(tester, rig);
    expect(
        find.descendant(
            of: _key('broadcast_comments'), matching: find.text('Comments')),
        findsOneWidget);
    await _tap(tester, 'broadcast_comments');
    expect(rig.opened, ['t1']);
    await rig.detail.close();
  });

  testWidgets('without a way to open them, no comments buttons show',
      (tester) async {
    for (final mode in [TileShareMode.class_, TileShareMode.project]) {
      final rig = _Rig(mode);
      await _open(tester, rig, comments: false);
      await _tap(tester, 'roster_segment_tasks');
      expect(find.byTooltip('Comments'), findsNothing);
      await rig.detail.close();
    }
    final rig = _Rig(TileShareMode.broadcast);
    await _open(tester, rig, comments: false);
    expect(_key('broadcast_comments'), findsNothing);
    await rig.detail.close();
  });

  test("the thread for a tilette is keyed by the tilette's own id", () {
    final tilette = tsTilette('TileShareTemplate+k+t1',
        clusterId: 'k',
        name: 'Write the brief',
        endMs: DateTime(2026, 10, 10, 17).millisecondsSinceEpoch);
    final DesignatedTile tile = TiletteDetailScreen.tileFor(tilette);
    expect(tile.tileTemplate?.id, 'TileShareTemplate+k+t1');
    expect(tile.name, 'Write the brief');
    expect(tile.endTime, DateTime(2026, 10, 10, 17));
  });
}
