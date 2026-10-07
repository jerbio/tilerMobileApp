// TileShare redesign Step 9.14 (§5.4, O9): the owner's Class detail -
// Overview · Tasks · Participants. Everyone has their own copy of every task:
// each person shows one progress segment per task, a person missing from some
// tasks is flagged with "Add to all tasks", tapping a person lists their
// tasks, adding a person adds them to every task, and removing removes them
// from every task. Driven by the real cubits over in-memory sources.
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
          tsTilette('t1', clusterId: 'k', name: 'Write the brief', assignees: [
            tsAssignee('ann@x.com',
                status: InvitationStatus.accepted, completion: 50),
            tsAssignee('bob@x.com'),
          ]),
          tsTilette('t2', clusterId: 'k', name: 'Review the deck', assignees: [
            tsAssignee('ann@x.com', status: InvitationStatus.accepted),
            tsAssignee('bob@x.com', status: InvitationStatus.declined),
          ]),
          tsTilette('t3', clusterId: 'k', name: 'Rehearse', assignees: [
            tsAssignee('ann@x.com', status: InvitationStatus.accepted),
          ]),
        ] {
    clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('k',
          name: 'Interview prep', mode: TileShareMode.class_, creatorId: 'me'),
    ], tilettesByCluster: {
      'k': tilettes,
    });
    recipients = FakeTileShareRecipientsSource(
        tilettes: {for (final t in tilettes) t.id!: t});
    detail = TileShareDetailCubit(
      clusters: clusters,
      target: const TileShareDetailTarget.cluster('k'),
      currentUserId: () => 'me',
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
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
        contentBuilder: (context, state) =>
            ClassDetail(detail: state, recipients: rig.recipients),
      ),
    ),
  ));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));
Finder _row(String label) => _key('participant_row_$label');

Future<void> _segment(WidgetTester tester, String name) async {
  await tester.tap(_key('roster_segment_$name'));
  await _settle(tester);
}

void main() {
  testWidgets('three tabs: Overview, Tasks, Participants', (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    expect(_key('roster_segment_overview'), findsOneWidget);
    expect(_key('roster_segment_tasks'), findsOneWidget);
    expect(_key('roster_segment_participants'), findsOneWidget);
    await rig.detail.close();
  });

  group('Overview', () {
    testWidgets('counts people, not assignments, and flags who is missing '
        'from some tasks', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      expect(find.text('1 of 2 people accepted'), findsOneWidget,
          reason: 'ann accepted every task; bob did not');
      expect(find.text('1 person is missing from some tilettes'), findsOneWidget);
      await tester.tap(find.text('1 person is missing from some tilettes'));
      await _settle(tester);
      expect(_key('roster_add_participant'), findsOneWidget);
      await rig.detail.close();
    });
  });

  group('Tasks', () {
    testWidgets('each task with its own answers', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'tasks');
      expect(
          find.descendant(
              of: _key('class_task_t1'), matching: find.text('Write the brief')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('class_task_t1'), matching: find.text('1 of 2 accepted')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('class_task_t3'), matching: find.text('1 of 1 accepted')),
          findsOneWidget);
      await rig.detail.close();
    });
  });

  group('Participants', () {
    testWidgets('each person shows one segment per task and how many they '
        'accepted', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'participants');
      final segments = _key('class_segments_ann@x.com');
      expect(find.descendant(of: segments, matching: _key('class_segment')),
          findsNWidgets(3));
      expect(
          find.descendant(
              of: _row('ann@x.com'), matching: find.text('3 of 3 tilettes accepted')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _row('bob@x.com'), matching: find.text('0 of 3 tilettes accepted')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a person missing from a task says so and can be added to all '
        'tasks', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'participants');
      expect(find.descendant(of: _row('bob@x.com'), matching: find.text('Not on 1 tilette')),
          findsOneWidget);
      await tester.tap(find.descendant(
          of: _row('bob@x.com'), matching: find.text('Add to all tilettes')));
      await _settle(tester);
      expect(rig.recipients.calls.where((c) => c.startsWith('addRecipient')),
          ['addRecipient(t3, bob@x.com)']);
      expect(find.descendant(of: _row('bob@x.com'), matching: find.text('Not on 1 tilette')),
          findsNothing);
      await rig.detail.close();
    });

    testWidgets('tapping a person lists their tasks, one by one', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'participants');
      await tester.tap(find.descendant(
          of: _row('bob@x.com'), matching: find.text('bob@x.com')));
      await _settle(tester);
      final sheet = _key('class_person_sheet');
      expect(sheet, findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Write the brief')),
          findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Invited')),
          findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Declined')),
          findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Not added')),
          findsOneWidget, reason: 'Rehearse');
      await rig.detail.close();
    });

    testWidgets('adding a person adds them to every task', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'participants');
      await tester.enterText(
          find.descendant(
              of: _key('roster_add_participant'),
              matching: find.byType(TextField)),
          'cy@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(rig.recipients.calls.where((c) => c.startsWith('addRecipient')), [
        'addRecipient(t1, cy@x.com)',
        'addRecipient(t2, cy@x.com)',
        'addRecipient(t3, cy@x.com)',
      ]);
      expect(
          find.descendant(
              of: _row('cy@x.com'), matching: find.text('0 of 3 tilettes accepted')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('removing a person says it removes them from every task',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _segment(tester, 'participants');
      await tester.tap(find.descendant(
          of: _row('bob@x.com'), matching: find.byTooltip('Remove')));
      await _settle(tester);
      expect(find.text('They will be removed from every tilette.'), findsOneWidget);
      await tester.tap(_key('participant_remove_confirm'));
      await _settle(tester);
      expect(_row('bob@x.com'), findsNothing);
      expect(rig.recipients.calls.where((c) => c.startsWith('removeRecipient')),
          hasLength(2));
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
