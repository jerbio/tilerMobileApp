// A Project with no tilettes - created that way, or after its only tilette
// was deleted (owner, 2026-10-13). It stays, and opens as it was left: the
// tabs, "Tilettes (0)" with Add tilette, and an empty Participants that says
// how people join a Project - by being assigned a tilette (there is no add
// field to point "above" to).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
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

Future<TileShareDetailCubit> _open(WidgetTester tester,
    {required List<TileShareTemplate> tilettes,
    TileShareMode mode = TileShareMode.project}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final clusters = FakeTileShareClustersSource(outbox: [
    tsCluster('k', name: 'Massive', mode: mode, creatorId: 'me'),
  ], tilettesByCluster: {
    'k': tilettes,
  });
  final recipients = FakeTileShareRecipientsSource(
      tilettes: {for (final t in tilettes) t.id!: t});
  final detail = TileShareDetailCubit(
    clusters: clusters,
    edits: FakeTileShareEditSource(clusters),
    target: const TileShareDetailTarget.cluster('k'),
    currentUserId: () => 'me',
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.darkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: detail,
      child: TileShareDetailScaffold(
        now: _now,
        contentBuilder: (context, state) => mode == TileShareMode.project
            ? ProjectDetail(detail: state, recipients: recipients)
            : ClassDetail(detail: state, recipients: recipients),
      ),
    ),
  ));
  await _settle(tester);
  return detail;
}

void main() {
  testWidgets(
      'a Project opened with no tilettes shows its tabs and Add tilette',
      (tester) async {
    final detail = await _open(tester, tilettes: []);
    expect(_key('roster_segment_overview'), findsOneWidget);
    await _tap(tester, 'roster_segment_tasks');
    expect(find.text('Tilettes (0)'), findsOneWidget);
    expect(_key('roster_add_task'), findsOneWidget,
        reason: 'the only way to give it tilettes again');
    await detail.close();
  });

  testWidgets(
      "an empty Project's Participants says how people join - no 'above'",
      (tester) async {
    final detail = await _open(tester, tilettes: []);
    await _tap(tester, 'roster_segment_participants');
    expect(find.textContaining('above'), findsNothing,
        reason: 'a Project has no add field there');
    expect(
        find.text(
            'No one yet. Assign a tilette to add someone to this project.'),
        findsOneWidget);
    await detail.close();
  });

  testWidgets(
      'deleting the only tilette leaves the Project as it would open again',
      (tester) async {
    final detail = await _open(tester, tilettes: [
      tsTilette('t1', clusterId: 'k', name: 'project'),
    ]);
    await _tap(tester, 'roster_segment_tasks');
    expect(await detail.deleteTask('t1'), isTrue);
    await _settle(tester);
    expect(find.text('Tilettes (0)'), findsOneWidget);
    expect(_key('roster_add_task'), findsOneWidget);
    await detail.close();
  });

  testWidgets("a Class's empty Participants keeps its add field and copy",
      (tester) async {
    final detail = await _open(tester,
        mode: TileShareMode.class_,
        tilettes: [tsTilette('t1', clusterId: 'k', name: 'Brief')]);
    await _tap(tester, 'roster_segment_participants');
    expect(find.text('No one yet. Add someone above.'), findsOneWidget);
    await detail.close();
  });
}
