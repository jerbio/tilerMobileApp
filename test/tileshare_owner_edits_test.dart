// TileShare redesign Step 9.16b: the owner edits a share from its detail
// before the old screens that did this are retired (9.17) - the share's name
// and deadline from the bar, and its tasks from the Tasks tab: add a task
// (a Class's goes to everyone in it, a Project's to no one yet), rename it or
// move its deadline (its length cannot change once shared), and delete it
// after confirming. A refused change says so and changes nothing. Driven by
// the real cubits over in-memory sources.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareRosterDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime(2026, 10, 3, 9);

class _Rig {
  final TileShareMode mode;
  late final FakeTileShareClustersSource clusters;
  late final FakeTileShareRecipientsSource recipients;
  late final FakeTileShareEditSource edits;
  late final TileShareDetailCubit detail;

  _Rig(
      {this.mode = TileShareMode.class_,
      bool withEdits = true,
      String creator = 'me'}) {
    final tilettes = [
      tsTilette('t1', clusterId: 'k', name: 'Write the brief', assignees: [
        tsAssignee('ann@x.com', status: InvitationStatus.accepted),
        if (mode != TileShareMode.project) tsAssignee('bob@x.com'),
      ]),
      tsTilette('t2', clusterId: 'k', name: 'Review the deck', assignees: [
        if (mode != TileShareMode.project) tsAssignee('ann@x.com'),
        tsAssignee('bob@x.com'),
      ]),
    ];
    clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('k', name: 'Interview prep', mode: mode, creatorId: creator),
    ], tilettesByCluster: {
      'k': tilettes,
    });
    recipients = FakeTileShareRecipientsSource(
        tilettes: {for (final t in tilettes) t.id!: t});
    edits = FakeTileShareEditSource(clusters);
    detail = TileShareDetailCubit(
      clusters: clusters,
      edits: withEdits ? edits : null,
      target: const TileShareDetailTarget.cluster('k'),
      currentUserId: () => 'me',
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {Size size = const Size(390, 1000),
    ThemeData? theme,
    double textScale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
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
        now: _now,
        contentBuilder: (context, state) => switch (rig.mode) {
          TileShareMode.project =>
            ProjectDetail(detail: state, recipients: rig.recipients),
          TileShareMode.broadcast =>
            BroadcastDetail(detail: state, recipients: rig.recipients),
          _ => ClassDetail(detail: state, recipients: rig.recipients),
        },
      ),
    ),
  ));
  await _settle(tester);
}

/// The detail pushed over a page, as the hub opens it.
Future<void> _openPushed(WidgetTester tester, _Rig rig) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
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
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                      value: rig.detail,
                      child: TileShareDetailScaffold(
                        now: _now,
                        contentBuilder: (context, state) => ClassDetail(
                            detail: state, recipients: rig.recipients),
                      ),
                    ))),
            child: const Text('open detail'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open detail'));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await _settle(tester);
}

void main() {
  group('the share', () {
    testWidgets('the owner edits it from the ⋯ menu', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'detail_menu');
      expect(find.text('Edit details'), findsOneWidget);
      expect(find.text('Delete share'), findsOneWidget);
      await _tap(tester, 'detail_menu_edit');
      expect(_key('edit_share'), findsOneWidget);
      await tester.enterText(_key('edit_share_name'), 'Moving day');
      await tester.pump();
      await _tap(tester, 'edit_share_save');
      expect(rig.edits.calls, ['updateShare(k, name: Moving day, end: null)']);
      expect(_key('edit_share'), findsNothing);
      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text('Moving day')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('no ⋯ without an edit source, or on someone else\'s share',
        (tester) async {
      for (final rig in [_Rig(withEdits: false), _Rig(creator: 'sarah')]) {
        await _open(tester, rig);
        expect(_key('detail_menu'), findsNothing);
        await rig.detail.close();
      }
    });

    testWidgets('Delete share asks first, then leaves the detail',
        (tester) async {
      final rig = _Rig();
      await _openPushed(tester, rig);
      await _tap(tester, 'detail_menu');
      await _tap(tester, 'detail_menu_delete');
      expect(find.text('Delete “Interview prep”?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(rig.clusters.calls.where((c) => c.startsWith('deleteCluster')),
          isEmpty);
      await _tap(tester, 'detail_menu');
      await _tap(tester, 'detail_menu_delete');
      await _tap(tester, 'share_delete_confirm');
      expect(rig.clusters.calls, contains('deleteCluster(k)'));
      expect(_key('detail_header'), findsNothing, reason: 'the detail closed');
      expect(find.text('open detail'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a refused delete stays, says so, and retries', (tester) async {
      final rig = _Rig();
      await _openPushed(tester, rig);
      rig.clusters.failNextOn('deleteCluster', StateError('offline'));
      await _tap(tester, 'detail_menu');
      await _tap(tester, 'detail_menu_delete');
      await _tap(tester, 'share_delete_confirm');
      expect(_key('detail_header'), findsOneWidget);
      expect(_key('detail_edit_failed'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await _settle(tester);
      expect(_key('detail_header'), findsNothing);
      await rig.detail.close();
    });
  });

  group('tasks', () {
    testWidgets('the Tasks tab counts the tasks, with Add task beside it',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      expect(find.text('Tilettes (2)'), findsOneWidget);
      expect(_key('roster_add_task'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets("a Class's new task goes to everyone in it", (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'roster_add_task');
      expect(_key('task_sheet'), findsOneWidget);
      await tester.enterText(_key('task_sheet_name'), 'Label boxes');
      await _tap(tester, 'task_sheet_save');
      expect(rig.edits.calls, ['addTask(k, Label boxes, contacts: 2)']);
      expect(_key('task_sheet'), findsNothing);
      expect(_key('class_task_new-1'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets("a Project's new task goes to no one unless assigned",
        (tester) async {
      final rig = _Rig(mode: TileShareMode.project);
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'roster_add_task');
      expect(_key('task_sheet_assignee'), findsOneWidget);
      await tester.enterText(_key('task_sheet_name'), 'Label boxes');
      await _tap(tester, 'task_sheet_save');
      expect(rig.edits.calls, ['addTask(k, Label boxes, contacts: 0)']);
      expect(_key('project_unassigned_new-1'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('Edit task opens the sheet; only what changed is sent',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'task_menu_t1');
      await _tap(tester, 'task_edit_t1');
      expect(_key('task_sheet'), findsOneWidget);
      expect(find.text('A tilette’s length can’t change once it’s shared.'),
          findsOneWidget);
      expect(_key('task_sheet_person_ann@x.com'), findsOneWidget,
          reason: "the share's roster reaches the sheet");
      await tester.enterText(_key('task_sheet_name'), 'Write it');
      await _tap(tester, 'task_sheet_save');
      expect(rig.edits.calls,
          ['updateTask(t1, name: Write it, end: null, notes: null)']);
      expect(
          find.descendant(
              of: _key('class_task_t1'), matching: find.text('Write it')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a refused change stays in the sheet, not behind it',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'task_menu_t1');
      await _tap(tester, 'task_edit_t1');
      rig.edits.failNextOn('updateTask', StateError('offline'));
      await tester.enterText(_key('task_sheet_name'), 'Write it');
      await _tap(tester, 'task_sheet_save');
      expect(_key('task_sheet'), findsOneWidget);
      expect(find.text('Could not save right now. Your changes are kept.'),
          findsOneWidget);
      expect(_key('detail_edit_failed'), findsNothing);
      await rig.detail.close();
    });

    testWidgets('deleting a task asks first, from the menu or the sheet',
        (tester) async {
      final rig = _Rig(mode: TileShareMode.project);
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'task_menu_t2');
      await _tap(tester, 'task_delete_t2');
      expect(find.text('Delete “Review the deck”?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(rig.edits.calls, isEmpty);
      await _tap(tester, 'task_menu_t2');
      await _tap(tester, 'task_delete_t2');
      await _tap(tester, 'task_delete_confirm');
      expect(rig.edits.calls, ['deleteTask(t2)']);
      expect(_key('project_task_t2'), findsNothing);

      await _tap(tester, 'task_menu_t1');
      await _tap(tester, 'task_edit_t1');
      await _tap(tester, 'task_sheet_delete');
      await _tap(tester, 'task_delete_confirm');
      expect(rig.edits.calls.last, 'deleteTask(t1)');
      expect(_key('task_sheet'), findsNothing);
      await rig.detail.close();
    });

    testWidgets(
        'a new task whose notes are refused is kept; the detail '
        'retries the notes', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'roster_add_task');
      await tester.enterText(_key('task_sheet_name'), 'Label boxes');
      await _tap(tester, 'task_sheet_notes');
      final QuillController quill =
          tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;
      quill.replaceText(0, quill.document.length - 1, 'Bring tape',
          const TextSelection.collapsed(offset: 10));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await _settle(tester);
      rig.edits.failNextOn('updateTask', StateError('offline'));
      await _tap(tester, 'task_sheet_save');
      expect(_key('task_sheet'), findsNothing,
          reason: 'the task was added, so the sheet closes');
      expect(_key('class_task_new-1'), findsOneWidget);
      expect(_key('detail_edit_failed'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await _settle(tester);
      expect(rig.edits.calls, [
        'addTask(k, Label boxes, contacts: 2)',
        'updateTask(new-1, name: null, end: null, notes: Bring tape)',
        'updateTask(new-1, name: null, end: null, notes: Bring tape)',
      ]);
      await tester.pump(const Duration(seconds: 1));
      await rig.detail.close();
    });

    testWidgets('without an edit source the tasks are read-only',
        (tester) async {
      final rig = _Rig(withEdits: false);
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      expect(_key('roster_add_task'), findsNothing);
      expect(_key('task_menu_t1'), findsNothing);
      await rig.detail.close();
    });
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final mode in [TileShareMode.class_, TileShareMode.project]) {
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        for (final scale in [1.0, 1.6]) {
          final rig = _Rig(mode: mode);
          await _open(tester, rig,
              size: const Size(320, 700), theme: theme, textScale: scale);
          await _tap(tester, 'roster_segment_tasks');
          await _tap(tester, 'roster_add_task');
          expect(tester.takeException(), isNull,
              reason: '$mode ${theme.brightness} x$scale');
          await rig.detail.close();
        }
      }
    }
  });
}
