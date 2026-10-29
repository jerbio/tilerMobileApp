// TileShare redesign Step 9.12 (T10, §5.4): the detail scaffold - one frame
// for every mode and role. It owns the bar (back, title, Activity), loading,
// error + Retry, not found, the header summary (mode, whose it is, what I
// answered, when it is due, how many tasks), pull-to-refresh that never
// flashes a spinner, and the mode's content below.
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareDisplayOptions.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime(2026, 10, 3, 9);
int _inDays(int d) => _now.add(Duration(days: d)).millisecondsSinceEpoch;

class _Rig {
  // This suite covers the full header; mobile experience tests cover density.
  final display =
      TileShareDisplaySettings.memory(density: TiletteDensity.comfortable);
  final FakeTileShareClustersSource clusters;
  final FakeTileShareAssignmentsSource assignments;
  late final TileShareDetailCubit cubit;
  int activityOpened = 0;
  Object? popResult = 'not popped';

  _Rig({String id = 'shared'})
      : clusters = FakeTileShareClustersSource(inbox: [
          tsCluster('shared',
              name: 'Launch Prep',
              mode: TileShareMode.class_,
              creatorId: 'sarah',
              creatorName: 'Sarah Kim',
              endMs: _inDays(5)),
        ], outbox: [
          tsCluster('owned',
              name: 'Weekend move',
              mode: TileShareMode.broadcast,
              creatorId: 'me',
              endMs: _inDays(1)),
        ], tilettesByCluster: {
          'shared': [
            tsTilette('t1', clusterId: 'shared', name: 'Write the brief'),
            tsTilette('t2', clusterId: 'shared', name: 'Review the deck'),
          ],
          'owned': [tsTilette('t3', clusterId: 'owned', name: 'Pack boxes')],
        }),
        assignments = FakeTileShareAssignmentsSource([
          tsDesignatedTile('d1', clusterId: 'shared'),
          tsDesignatedTile('d2', clusterId: 'shared'),
        ]) {
    addTearDown(display.dispose);
    cubit = TileShareDetailCubit(
      clusters: clusters,
      assignments: assignments,
      target: TileShareDetailTarget.cluster(id),
      currentUserId: () => 'me',
    );
  }
}

Widget _app(_Rig rig,
        {ThemeData? theme,
        double textScale = 1,
        bool activity = true,
        Widget Function(BuildContext, TileShareDetailState)? content}) =>
    MaterialApp(
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                rig.popResult =
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                            value: rig.cubit,
                            child: TileShareDetailScaffold(
                              displaySettings: rig.display,
                              now: _now,
                              onOpenActivity:
                                  activity ? () => rig.activityOpened++ : null,
                              contentBuilder: content,
                            ))));
              },
              child: const Text('open detail'),
            ),
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {Size size = const Size(390, 844),
    ThemeData? theme,
    double textScale = 1,
    bool activity = true,
    Widget Function(BuildContext, TileShareDetailState)? content}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_app(rig,
      theme: theme,
      textScale: textScale,
      activity: activity,
      content: content));
  await tester.tap(find.text('open detail'));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));

void main() {
  group('states', () {
    testWidgets('a skeleton while it loads, then the detail', (tester) async {
      final rig = _Rig();
      rig.clusters.hold();
      await _open(tester, rig);
      expect(_key('detail_loading'), findsOneWidget);
      expect(find.text('Loading share\u2026'), findsOneWidget);
      expect(find.text('Untitled share'), findsNothing);
      expect(_key('detail_load_progress'), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      rig.clusters.release();
      await _settle(tester);
      expect(_key('detail_loading'), findsNothing);
      expect(find.text('Loading share\u2026'), findsNothing);
      expect(_key('detail_load_progress'), findsNothing);
      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('Launch Prep'), findsWidgets);
      await rig.cubit.close();
    });

    testWidgets('a failure says so; Retry loads it', (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('cluster', StateError('offline'));
      await _open(tester, rig);
      expect(find.text('Couldn’t load this share.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await _settle(tester);
      expect(find.text('Launch Prep'), findsWidgets);
      await rig.cubit.close();
    });

    testWidgets('a share that is gone says so, and back still works',
        (tester) async {
      final rig = _Rig(id: 'gone');
      await _open(tester, rig);
      expect(_key('detail_not_found'), findsOneWidget);
      expect(find.text('This share is no longer available.'), findsOneWidget);
      await tester.tap(_key('detail_back'));
      await _settle(tester);
      expect(find.text('open detail'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('the header', () {
    testWidgets(
        'a recipient sees the mode, who it is from, what they '
        'answered, when it is due and how many tasks', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      expect(find.text('Class · From Sarah Kim'), findsOneWidget);
      expect(find.text('Needs your answer'), findsOneWidget);
      expect(find.textContaining('Due '), findsOneWidget);
      expect(find.text('2 tilettes'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('the owner sees it is theirs, with no answer of their own',
        (tester) async {
      final rig = _Rig(id: 'owned');
      await _open(tester, rig);
      expect(find.text('Broadcast · Created by you'), findsOneWidget);
      expect(find.text('Needs your answer'), findsNothing);
      expect(find.text('1 tilette'), findsNothing,
          reason: 'a Broadcast is one task; naming it adds nothing');
      await rig.cubit.close();
    });
  });

  group('content', () {
    testWidgets('the mode\'s content goes below the header', (tester) async {
      final rig = _Rig();
      await _open(tester, rig,
          content: (context, state) => Text('content for ${state.variant.name}',
              key: const Key('variant_content')));
      expect(find.text('content for commitment'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('without one, the tasks are listed', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      expect(find.text('Write the brief'), findsOneWidget);
      expect(find.text('Review the deck'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('tasks that failed to load say so; Retry brings them',
        (tester) async {
      final rig = _Rig();
      rig.clusters.failNextOn('tilettes', StateError('down'));
      await _open(tester, rig);
      expect(_key('detail_tasks_failed'), findsOneWidget);
      await tester.tap(find.descendant(
          of: _key('detail_tasks_failed'), matching: find.text('Retry')));
      await _settle(tester);
      expect(_key('detail_tasks_failed'), findsNothing);
      expect(find.text('Write the brief'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('refreshing', () {
    testWidgets('pull to refresh reloads without hiding what is shown',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      final before =
          rig.clusters.calls.where((c) => c.startsWith('cluster(')).length;
      rig.clusters.hold();
      await tester.fling(
          find.text('Write the brief'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_key('detail_loading'), findsNothing);
      expect(find.text('Launch Prep'), findsWidgets);
      expect(find.text('Loading share\u2026'), findsNothing);
      expect(_key('detail_load_progress'), findsOneWidget);
      expect(find.text('Write the brief'), findsOneWidget);
      rig.clusters.release();
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(rig.clusters.calls.where((c) => c.startsWith('cluster(')).length,
          before + 1);
      await rig.cubit.close();
    });

    testWidgets('a failed refresh keeps the detail with a banner and Retry',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      rig.clusters.failNextOn('cluster', StateError('flaky'));
      await rig.cubit.refresh();
      await _settle(tester);
      expect(_key('detail_refresh_failed'), findsOneWidget);
      expect(find.text('Write the brief'), findsOneWidget);
      await tester.tap(find.descendant(
          of: _key('detail_refresh_failed'), matching: find.text('Retry')));
      await _settle(tester);
      expect(_key('detail_refresh_failed'), findsNothing);
      await rig.cubit.close();
    });
  });

  group('the bar', () {
    testWidgets(
        'inherits shared toolbar sizing, with the share title and Activity',
        (tester) async {
      final rig = _Rig();
      final theme = TileThemeData.lightTheme;
      await _open(tester, rig,
          theme: theme.copyWith(
              appBarTheme: theme.appBarTheme.copyWith(toolbarHeight: 64)));
      expect(tester.getSize(find.byType(AppBar)).height, 64);
      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text('Launch Prep')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('detail_header'), matching: find.text('Launch Prep')),
          findsOneWidget);
      await tester.tap(_key('detail_activity'));
      expect(rig.activityOpened, 1);
      await rig.cubit.close();
    });

    testWidgets('no Activity without a handler', (tester) async {
      final rig = _Rig();
      await _open(tester, rig, activity: false);
      expect(_key('detail_activity'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('back closes', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await tester.tap(_key('detail_back'));
      await _settle(tester);
      expect(find.text('open detail'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
      for (final scale in [1.0, 1.6]) {
        final rig = _Rig();
        await _open(tester, rig,
            size: const Size(320, 640), theme: theme, textScale: scale);
        expect(tester.takeException(), isNull,
            reason: '${theme.brightness} x$scale');
        await rig.cubit.close();
      }
    }
  });
}
