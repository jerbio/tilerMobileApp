// TileShare redesign Step 9.15 (§5.4, T13, T20, O10): the owner's Project
// detail - Overview · Tasks · Participants. One shared project: the board
// shows each task with its assignee, their answer and that task's own
// progress (never a rolled-up total); a task with no one is flagged; a task is
// assigned or reassigned from its row; there is no Accept all anywhere.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareRosterDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/services/tileShare/tileShareDisplaySettings.dart';

import 'helpers/tap_visible.dart';
import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime(2026, 10, 3, 9);

class _Rig {
  final List<TileShareTemplate> tilettes;
  late final FakeTileShareClustersSource clusters;
  late final FakeTileShareRecipientsSource recipients;
  late final TileShareDetailCubit detail;

  _Rig()
      : tilettes = [
          tsTilette('t1', clusterId: 'p', name: 'Research', assignees: [
            tsAssignee('ann@x.com',
                status: InvitationStatus.accepted, completion: 40),
          ]),
          tsTilette('t2', clusterId: 'p', name: 'Design', assignees: [
            tsAssignee('bob@x.com'),
          ]),
          tsTilette('t3', clusterId: 'p', name: 'Launch', assignees: []),
        ] {
    clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('p',
          name: 'Launch prep', mode: TileShareMode.project, creatorId: 'me'),
    ], tilettesByCluster: {
      'p': tilettes,
    });
    recipients = FakeTileShareRecipientsSource(
        tilettes: {for (final t in tilettes) t.id!: t});
    detail = TileShareDetailCubit(
      clusters: clusters,
      target: const TileShareDetailTarget.cluster('p'),
      currentUserId: () => 'me',
    );
  }

  List<String> changes() => recipients.calls
      .where((c) =>
          c.startsWith('addRecipient') || c.startsWith('removeRecipient'))
      .toList();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {Size size = const Size(390, 1000),
    ThemeData? theme,
    TiletteDensity density = TiletteDensity.compact,
    void Function(TileShareTemplate)? onOpen,
    double textScale = 1}) async {
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
        contentBuilder: (context, state) => ProjectDetail(
            detail: state, recipients: rig.recipients, onOpen: onOpen),
      ),
    ),
  ));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));
Finder _task(String id) => _key('project_task_$id');

Future<void> _segment(WidgetTester tester, String name) async {
  await tapVisible(tester, _key('roster_segment_$name'));
  await _settle(tester);
}

void main() {
  testWidgets('owners can assign the first person directly in every density',
      (tester) async {
    for (final density in TiletteDensity.values) {
      final rig = _Rig();
      rig.clusters.tilettesByCluster['p'] = [rig.tilettes.last];
      final opened = <String>[];
      await _open(tester, rig,
          density: density,
          size: density == TiletteDensity.list
              ? const Size(320, 900)
              : const Size(390, 1000),
          textScale: density == TiletteDensity.list ? 1.6 : 1,
          onOpen: (task) => opened.add(task.id!));
      await _segment(tester, 'tasks');
      await tapVisible(tester, _key('project_assign_t3'));
      await _settle(tester);
      expect(opened, isEmpty,
          reason: 'Assign opens the picker, not the detail');
      await tester.enterText(
          find.descendant(
              of: _key('project_assign_sheet'),
              matching: find.byType(TextField)),
          'first@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(rig.changes(), ['addRecipient(t3, first@x.com)']);
      expect(rig.tilettes.last.designatedUsers, hasLength(1));
      expect(_key('project_assign_t3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await rig.detail.close();
    }
  });

  testWidgets(
      'pending assignment fits every density without duplicate controls',
      (tester) async {
    for (final density in TiletteDensity.values) {
      final rig = _Rig();
      rig.clusters.tilettesByCluster['p'] = [rig.tilettes.last];
      await _open(tester, rig, density: density, onOpen: (_) {});
      await _segment(tester, 'tasks');
      await tapVisible(tester, _key('project_assign_t3'));
      await _settle(tester);
      rig.recipients.hold();
      await tester.enterText(
          find.descendant(
              of: _key('project_assign_sheet'),
              matching: find.byType(TextField)),
          'first@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(_key('project_assign_t3'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      rig.recipients.release();
      await _settle(tester);
      expect(_key('project_assign_t3'), findsOneWidget);
      expect(rig.changes(), ['addRecipient(t3, first@x.com)']);
      await rig.detail.close();
    }
  });

  testWidgets('List view keeps failed assignment retry accessible',
      (tester) async {
    final rig = _Rig();
    rig.clusters.tilettesByCluster['p'] = [rig.tilettes.last];
    await _open(tester, rig, density: TiletteDensity.list, onOpen: (_) {});
    await _segment(tester, 'tasks');
    rig.recipients.failNextOn('addRecipient', StateError('offline'));
    await tapVisible(tester, _key('project_assign_t3'));
    await _settle(tester);
    await tester.enterText(
        find.descendant(
            of: _key('project_assign_sheet'), matching: find.byType(TextField)),
        'first@x.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(rig.tilettes.last.designatedUsers, isEmpty);
    await tapVisible(tester, _key('project_retry_t3'));
    await _settle(tester);
    expect(rig.tilettes.last.designatedUsers, hasLength(1));
    expect(_key('project_retry_t3'), findsNothing);
    expect(tester.takeException(), isNull);
    await rig.detail.close();
  });

  group('Overview', () {
    testWidgets(
        'counts tasks, flags tasks with no one, and previews the '
        'board', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'overview');
      expect(find.text('1 of 3 tilettes accepted'), findsOneWidget);
      expect(find.text('1 tilette has no one assigned'), findsOneWidget);
      expect(_task('t1'), findsOneWidget);
      expect(find.text('Accept all'), findsNothing);
      await tapVisible(tester, find.text('1 tilette has no one assigned'));
      await _settle(tester);
      expect(_key('project_assign_t3'), findsOneWidget);
      await rig.detail.close();
    });
  });

  group('Tasks', () {
    testWidgets(
        'each task with its assignee, their answer and that task\'s '
        'own progress; a task with no one is flagged', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'tasks');
      expect(find.descendant(of: _task('t1'), matching: find.text('ann@x.com')),
          findsOneWidget);
      expect(find.descendant(of: _task('t1'), matching: find.text('Accepted')),
          findsOneWidget);
      expect(find.descendant(of: _task('t1'), matching: find.text('40%')),
          findsOneWidget);
      expect(find.descendant(of: _task('t2'), matching: find.text('Invited')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _task('t3'), matching: find.text('No one assigned')),
          findsOneWidget);
      expect(find.descendant(of: _task('t3'), matching: find.text('Assign')),
          findsOneWidget);
      expect(find.descendant(of: _task('t1'), matching: find.text('Reassign')),
          findsOneWidget);
      expect(find.text('Accept all'), findsNothing,
          reason: 'a Project is answered task by task (T20)');
      await rig.detail.close();
    });

    testWidgets('reassigning adds the new person, then removes the old one',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'tasks');
      await tapVisible(tester, _key('project_assign_t1'));
      await _settle(tester);
      expect(find.text('Assign Research'), findsOneWidget);
      await tester.enterText(
          find.descendant(
              of: _key('project_assign_sheet'),
              matching: find.byType(TextField)),
          'cy@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(rig.changes(),
          ['addRecipient(t1, cy@x.com)', 'removeRecipient(t1, asg-ann@x.com)']);
      expect(find.descendant(of: _task('t1'), matching: find.text('cy@x.com')),
          findsOneWidget);
      expect(find.descendant(of: _task('t1'), matching: find.text('ann@x.com')),
          findsNothing);
      await rig.detail.close();
    });

    testWidgets(
        'a task with no one can be given to someone already in the '
        'project', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'tasks');
      await tapVisible(tester, _key('project_assign_t3'));
      await _settle(tester);
      await tapVisible(
          tester,
          find.descendant(
              of: _key('project_assign_sheet'),
              matching: find.text('bob@x.com')));
      await _settle(tester);
      expect(rig.changes(), ['addRecipient(t3, bob@x.com)']);
      expect(find.descendant(of: _task('t3'), matching: find.text('bob@x.com')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a refused reassignment keeps the assignee and offers Retry',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'tasks');
      rig.recipients.failNextOn('addRecipient', StateError('offline'));
      await tapVisible(tester, _key('project_assign_t1'));
      await _settle(tester);
      await tester.enterText(
          find.descendant(
              of: _key('project_assign_sheet'),
              matching: find.byType(TextField)),
          'cy@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(
          find.descendant(
              of: _task('t1'), matching: find.text('Couldn’t reassign.')),
          findsOneWidget);
      expect(find.descendant(of: _task('t1'), matching: find.text('ann@x.com')),
          findsOneWidget);
      await tapVisible(tester, _key('project_retry_t1'));
      await _settle(tester);
      expect(find.descendant(of: _task('t1'), matching: find.text('cy@x.com')),
          findsOneWidget);
      await rig.detail.close();
    });
  });

  group('Participants', () {
    testWidgets(
        'who is in and what each owns; people join through a task, '
        'so there is no add field', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'participants');
      expect(
          find.descendant(
              of: _key('participant_row_ann@x.com'),
              matching: find.text('Owns 1 tilette')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('participant_row_ann@x.com'),
              matching: find.text('Research')),
          findsOneWidget);
      expect(_key('roster_add_participant'), findsNothing);
      await rig.detail.close();
    });
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
      for (final scale in [1.0, 1.6]) {
        final rig = _Rig();
        await _open(tester, rig,
            size: const Size(320, 700), theme: theme, textScale: scale);
        expect(tester.takeException(), isNull, reason: 'overview');
        await _segment(tester, 'tasks');
        expect(tester.takeException(), isNull, reason: 'tasks');
        await _segment(tester, 'participants');
        expect(tester.takeException(), isNull, reason: 'participants');
        await rig.detail.close();
      }
    }
  });
}
