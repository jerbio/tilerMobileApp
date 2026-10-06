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
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/components/nameAndDateSheetWidget.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/ownerEdits.dart';
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

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await _settle(tester);
}

/// Types [text] into the first field of the sheet keyed [sheet].
Future<void> _type(WidgetTester tester, String sheet, String text) async {
  await tester.enterText(
      find.descendant(of: _key(sheet), matching: find.byType(TextField)).first,
      text);
  await _settle(tester);
}

Future<void> _submit(WidgetTester tester, String sheet, String label) async {
  final button = find.descendant(of: _key(sheet), matching: find.text(label));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await _settle(tester);
}

void main() {
  test('an edit sends only what changed', () {
    final int end = DateTime(2026, 10, 9).millisecondsSinceEpoch;
    NameDeadlineChange change(String? newName, DateTime? newEnd) =>
        NameDeadlineChange.of(
            NameAndEndTimeUpdate()
              ..Name = newName
              ..EndTime = newEnd,
            name: 'Move',
            endMs: end);
    final moved = change(' Move ', DateTime(2026, 10, 12));
    expect([moved.name, moved.endMs],
        [null, DateTime(2026, 10, 12).millisecondsSinceEpoch]);
    final renamed = change('Moving day', DateTime(2026, 10, 9));
    expect([renamed.name, renamed.endMs], ['Moving day', null]);
    expect(change('  ', null).isEmpty, isTrue,
        reason: 'a blank name and a cleared deadline are not sent');
  });

  group('the share', () {
    testWidgets('the owner renames it from the bar', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'detail_edit');
      expect(_key('share_edit_sheet'), findsOneWidget);
      await _type(tester, 'share_edit_sheet', 'Moving day');
      await _submit(tester, 'share_edit_sheet', 'Update');
      expect(rig.edits.calls, ['updateShare(k, name: Moving day, end: null)'],
          reason: 'only what changed is sent');
      expect(_key('share_edit_sheet'), findsNothing);
      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text('Moving day')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('no edit without an edit source, or for someone else\'s share',
        (tester) async {
      for (final rig in [_Rig(withEdits: false), _Rig(creator: 'sarah')]) {
        await _open(tester, rig);
        expect(_key('detail_edit'), findsNothing);
        await rig.detail.close();
      }
    });

    testWidgets('a refused change says so and changes nothing', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      rig.edits.failNextOn('updateShare', StateError('offline'));
      await _tap(tester, 'detail_edit');
      await _type(tester, 'share_edit_sheet', 'Moving day');
      await _submit(tester, 'share_edit_sheet', 'Update');
      expect(_key('detail_edit_failed'), findsOneWidget);
      expect(
          find.text('Couldn’t save your change. Try again.'), findsOneWidget);
      expect(find.text('Moving day'), findsNothing);
      await rig.detail.close();
    });
  });

  group('tasks', () {
    testWidgets('a Class\'s new task goes to everyone in it', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'roster_add_task');
      expect(_key('add_task_sheet'), findsOneWidget);
      await _type(tester, 'add_task_sheet', 'Label boxes');
      await _submit(tester, 'add_task_sheet', 'Add');
      expect(rig.edits.calls, ['addTask(k, Label boxes, contacts: 2)']);
      expect(_key('class_task_new-1'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a Project\'s new task goes to no one yet', (tester) async {
      final rig = _Rig(mode: TileShareMode.project);
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'roster_add_task');
      await _type(tester, 'add_task_sheet', 'Label boxes');
      await _submit(tester, 'add_task_sheet', 'Add');
      expect(rig.edits.calls, ['addTask(k, Label boxes, contacts: 0)']);
      expect(_key('project_unassigned_new-1'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('renaming a task, which says its length stays', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _tap(tester, 'roster_segment_tasks');
      await _tap(tester, 'task_menu_t1');
      await _tap(tester, 'task_edit_t1');
      expect(find.text('A task’s length can’t change once it’s shared.'),
          findsOneWidget);
      await _type(tester, 'task_edit_sheet', 'Write it');
      await _submit(tester, 'task_edit_sheet', 'Update');
      expect(rig.edits.calls, ['updateTask(t1, name: Write it, end: null)']);
      expect(
          find.descendant(
              of: _key('class_task_t1'), matching: find.text('Write it')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('deleting a task asks first', (tester) async {
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
      expect(_key('project_task_t1'), findsOneWidget);
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
