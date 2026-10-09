// TileShare redesign Step 9.16f (T27): the task sheet - one sheet to add a
// task and to edit one, built from the redesign's form kit. Name (3-100),
// length (chosen when adding, locked once shared), deadline with date and
// time (starts at the share's; a later one is allowed with a warning),
// notes (markdown, on the notes page), and people by mode: everyone in a
// Class, an optional assignee in a Project. A refused save keeps the sheet
// and what was typed; Delete task asks first.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/taskSheet.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final int _shareEnd = DateTime(2026, 10, 10, 17).millisecondsSinceEpoch;

class _Rig {
  final List<TaskSheetValue> saved = [];
  final List<TaskChanges> changes = [];
  int deleted = 0;
  bool saveOk = true;
  DateTime? pickedDate;
  TimeOfDay? pickedTime;
  Duration? pickedDuration;
  String? editedNotes;
  Contact? pickedAssignee;

  TaskSheet sheet({
    TileShareTemplate? task,
    TaskSheetPeople people = TaskSheetPeople.everyone,
    bool canDelete = false,
    TileShareRosterCubit? roster,
  }) =>
      TaskSheet(
        task: task,
        people: people,
        roster: roster,
        shareDeadlineMs: _shareEnd,
        onSave: (value, changed) async {
          saved.add(value);
          changes.add(changed);
          return saveOk;
        },
        onDelete: canDelete
            ? () async {
                deleted++;
                return true;
              }
            : null,
        pickDate: (_, __) async => pickedDate,
        pickTime: (_, __) async => pickedTime,
        pickDuration: (_, __) async => pickedDuration,
        editNotes: (_, __) async => editedNotes,
        pickAssignee: (_, __) async => pickedAssignee,
      );
}

/// Opens [sheet] the way the app does: a modal bottom sheet over a page.
Future<void> _open(WidgetTester tester, TaskSheet sheet,
    {Size size = const Size(390, 844),
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
    supportedLocales: const [Locale('en', '')],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showTaskSheet(context, sheet),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _name(WidgetTester tester, String text) async {
  await tester.enterText(_key('task_sheet_name'), text);
  await tester.pump();
}

void main() {
  group('adding', () {
    testWidgets(
        'a Class task: name, an hour by default, due with the share, '
        'everyone gets it', (tester) async {
      final rig = _Rig();
      await _open(tester, rig.sheet());
      expect(find.text('Add tilette'), findsWidgets);
      expect(_key('task_sheet_everyone'), findsOneWidget);
      expect(find.text('Everyone in this class has this tilette.'),
          findsOneWidget);
      expect(_key('task_sheet_assignee'), findsNothing);
      await _name(tester, 'Label boxes');
      await _tap(tester, 'task_sheet_save');
      expect(rig.saved, hasLength(1));
      final v = rig.saved.single;
      expect(v.name, 'Label boxes');
      expect(v.length, const Duration(hours: 1));
      expect(v.deadline.millisecondsSinceEpoch, _shareEnd);
      expect(v.notes, '');
      expect(v.assignee, isNull);
      expect(_key('task_sheet'), findsNothing, reason: 'saved, so it closes');
    });

    testWidgets('the name is required, three characters at least',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig.sheet());
      await _tap(tester, 'task_sheet_save');
      expect(find.text('Name is required'), findsOneWidget);
      await _name(tester, 'ab');
      await _tap(tester, 'task_sheet_save');
      expect(find.text('Use at least 3 characters'), findsOneWidget);
      expect(rig.saved, isEmpty);
    });

    testWidgets('length, deadline (date then time) and notes are chosen',
        (tester) async {
      final rig = _Rig()
        ..pickedDuration = const Duration(minutes: 90)
        ..pickedDate = DateTime(2026, 10, 9)
        ..pickedTime = const TimeOfDay(hour: 9, minute: 30)
        ..editedNotes = 'Use **tape**';
      await _open(tester, rig.sheet());
      await _name(tester, 'Label boxes');
      await _tap(tester, 'task_sheet_length');
      await _tap(tester, 'task_sheet_deadline');
      await _tap(tester, 'task_sheet_notes');
      expect(find.text('Use **tape**'), findsOneWidget,
          reason: 'the notes row previews the text, as in Edit Tile');
      await _tap(tester, 'task_sheet_save');
      final v = rig.saved.single;
      expect(v.length, const Duration(minutes: 90));
      expect(v.deadline, DateTime(2026, 10, 9, 9, 30));
      expect(v.notes, 'Use **tape**');
    });

    testWidgets('a cancelled time keeps the time of day', (tester) async {
      final rig = _Rig()..pickedDate = DateTime(2026, 10, 9);
      await _open(tester, rig.sheet());
      await _name(tester, 'Label boxes');
      await _tap(tester, 'task_sheet_deadline');
      await _tap(tester, 'task_sheet_save');
      expect(rig.saved.single.deadline, DateTime(2026, 10, 9, 17));
    });

    testWidgets('a deadline after the share is allowed, with a warning',
        (tester) async {
      final rig = _Rig()
        ..pickedDate = DateTime(2026, 10, 12)
        ..pickedTime = const TimeOfDay(hour: 9, minute: 0);
      await _open(tester, rig.sheet());
      expect(_key('task_sheet_late'), findsNothing);
      await _name(tester, 'Label boxes');
      await _tap(tester, 'task_sheet_deadline');
      expect(_key('task_sheet_late'), findsOneWidget);
      expect(find.textContaining('after the share’s deadline'), findsOneWidget);
      await _tap(tester, 'task_sheet_save');
      expect(rig.saved, hasLength(1));
    });

    testWidgets('a Project task can name its assignee, or no one',
        (tester) async {
      final rig = _Rig()..pickedAssignee = (Contact()..email = 'ann@x.com');
      await _open(tester, rig.sheet(people: TaskSheetPeople.assignee));
      expect(_key('task_sheet_everyone'), findsNothing);
      expect(find.text('No one assigned'), findsOneWidget);
      await _name(tester, 'Label boxes');
      await _tap(tester, 'task_sheet_assignee');
      expect(find.text('ann@x.com'), findsOneWidget);
      await _tap(tester, 'task_sheet_save');
      expect(rig.saved.single.assignee?.email, 'ann@x.com');
    });

    testWidgets('a refused save keeps the sheet and what was typed',
        (tester) async {
      final rig = _Rig()..saveOk = false;
      await _open(tester, rig.sheet());
      await _name(tester, 'Label boxes');
      await _tap(tester, 'task_sheet_save');
      expect(_key('task_sheet'), findsOneWidget);
      expect(find.text('Could not save right now. Your changes are kept.'),
          findsOneWidget);
      expect(find.text('Label boxes'), findsOneWidget);
    });
  });

  group('editing', () {
    TileShareTemplate task() => tsTilette('t1',
        name: 'Prepare the deck',
        durationMs: 7200000,
        endMs: DateTime(2026, 10, 9, 12).millisecondsSinceEpoch);

    testWidgets('the length is locked; nothing changed, nothing saved',
        (tester) async {
      final rig = _Rig()..pickedDuration = const Duration(hours: 5);
      await _open(tester, rig.sheet(task: task()));
      expect(find.text('Edit tilette'), findsOneWidget);
      expect(find.text('Prepare the deck'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
      expect(
          find.descendant(
              of: _key('task_sheet_length'),
              matching: find.byIcon(Icons.chevron_right)),
          findsNothing,
          reason: 'information, not a control');
      expect(
          find.descendant(
              of: _key('task_sheet_length'),
              matching: find
                  .text('A tilette’s length can’t change once it’s shared.')),
          findsOneWidget,
          reason: 'the reason sits with the value it explains');
      await _tap(tester, 'task_sheet_length');
      await _tap(tester, 'task_sheet_save');
      expect(rig.saved, isEmpty);
      expect(_key('task_sheet'), findsOneWidget);
    });

    testWidgets("a later deadline on an accepted tilette says the share's "
        'deadline moves', (tester) async {
      final rig = _Rig()
        ..pickedDate = DateTime(2026, 10, 12)
        ..pickedTime = const TimeOfDay(hour: 9, minute: 0);
      final accepted = tsTilette('t1', name: 'Deck', durationMs: 3600000,
          assignees: [tsAssignee('ann@x.com', status: InvitationStatus.accepted)]);
      await _open(tester, rig.sheet(task: accepted));
      await _tap(tester, 'task_sheet_deadline');
      expect(
          find.textContaining('The share’s deadline will move to Mon, Oct 12, 2026'),
          findsOneWidget,
          reason: 'the server moves it when someone has accepted (O27)');
    });

    testWidgets('a rename is saved', (tester) async {
      final rig = _Rig();
      await _open(tester, rig.sheet(task: task()));
      await _name(tester, 'Prepare the pitch');
      await _tap(tester, 'task_sheet_save');
      expect(rig.changes.single, const TaskChanges(name: 'Prepare the pitch'));
    });

    testWidgets(
        'a task due with the share is not given a deadline by a '
        'rename', (tester) async {
      final rig = _Rig();
      await _open(tester,
          rig.sheet(task: tsTilette('t2', name: 'Deck', durationMs: 3600000)));
      expect(find.textContaining('Oct 10, 2026'), findsOneWidget,
          reason: "it shows the share's deadline");
      await _name(tester, 'Deck two');
      await _tap(tester, 'task_sheet_save');
      expect(rig.changes.single, const TaskChanges(name: 'Deck two'));
    });

    testWidgets('Delete task asks first', (tester) async {
      final rig = _Rig();
      await _open(tester, rig.sheet(task: task(), canDelete: true));
      await _tap(tester, 'task_sheet_delete');
      expect(find.text('Delete “Prepare the deck”?'), findsOneWidget);
      await _tap(tester, 'task_delete_confirm');
      expect(rig.deleted, 1);
      expect(_key('task_sheet'), findsNothing);
    });
  });

  // The edit sheet manages who has the tilette, by mode. People changes go
  // out at once, one per tilette, with their own retry - not with Save.
  group('people while editing', () {
    late FakeTileShareRecipientsSource recipients;
    late TileShareRosterCubit roster;
    late List<TileShareTemplate> tilettes;

    void rosterOf(List<TileShareTemplate> list) {
      tilettes = list;
      recipients = FakeTileShareRecipientsSource(
          tilettes: {for (final t in list) t.id!: t});
      roster = TileShareRosterCubit(
          source: recipients, clusterId: 'c1', tilettes: list);
    }

    testWidgets(
        'a Class tilette lists who has it; adding someone adds them to '
        'every tilette', (tester) async {
      rosterOf([
        tsTilette('t1', name: 'Brief', durationMs: 3600000, assignees: [
          tsAssignee('ann@x.com', status: InvitationStatus.accepted),
          tsAssignee('bob@x.com'),
        ]),
        tsTilette('t2', name: 'Deck', assignees: [
          tsAssignee('ann@x.com'),
          tsAssignee('bob@x.com'),
        ]),
      ]);
      await _open(tester, _Rig().sheet(task: tilettes.first, roster: roster));
      expect(_key('task_sheet_people'), findsOneWidget);
      expect(
          find.descendant(
              of: _key('task_sheet_person_ann@x.com'),
              matching: find.text('Accepted')),
          findsOneWidget);
      expect(_key('task_sheet_person_bob@x.com'), findsOneWidget);
      expect(_key('task_sheet_people_hint'), findsOneWidget);
      await tester.ensureVisible(_key('task_sheet_add_person'));
      await tester.enterText(
          find.descendant(
              of: _key('task_sheet_add_person'),
              matching: find.byType(TextField)),
          'cy@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(recipients.calls.where((c) => c.startsWith('addRecipient')),
          ['addRecipient(t1, cy@x.com)', 'addRecipient(t2, cy@x.com)']);
      expect(_key('task_sheet_person_cy@x.com'), findsOneWidget);
      await roster.close();
    });

    testWidgets('a Project tilette shows its assignee; Change reassigns it',
        (tester) async {
      rosterOf([
        tsTilette('t1', name: 'Brief', durationMs: 3600000, assignees: [
          tsAssignee('ann@x.com', status: InvitationStatus.accepted),
        ]),
        tsTilette('t2', name: 'Deck', assignees: [tsAssignee('bob@x.com')]),
      ]);
      final rig = _Rig()..pickedAssignee = (Contact()..email = 'bob@x.com');
      await _open(
          tester,
          rig.sheet(
              task: tilettes.first,
              people: TaskSheetPeople.assignee,
              roster: roster));
      expect(
          find.descendant(
              of: _key('task_sheet_assignee'),
              matching: find.text('ann@x.com')),
          findsOneWidget);
      await _tap(tester, 'task_sheet_assignee');
      expect(recipients.calls, contains('addRecipient(t1, bob@x.com)'));
      expect(recipients.calls, contains('removeRecipient(t1, asg-ann@x.com)'));
      expect(
          find.descendant(
              of: _key('task_sheet_assignee'),
              matching: find.text('bob@x.com')),
          findsOneWidget);
      expect(rig.saved, isEmpty, reason: 'people are not part of Save');
      await roster.close();
    });
  });

  test('only what changed is sent', () {
    final DateTime end = DateTime(2026, 10, 9, 12);
    TaskSheetValue v(String name, DateTime at, String notes) => TaskSheetValue(
        name: name,
        length: const Duration(hours: 1),
        deadline: at,
        notes: notes);
    final before = v('Deck', end, '');
    expect(v('Deck', end, '').changesSince(before), const TaskChanges());
    expect(v(' Deck ', DateTime(2026, 10, 9, 13), '').changesSince(before),
        TaskChanges(endMs: DateTime(2026, 10, 9, 13).millisecondsSinceEpoch));
    expect(v('Deck', end, 'n').changesSince(before),
        const TaskChanges(notes: 'n'));
    expect(v('Deck', end, '').changesSince(v('Deck', end, 'n')),
        const TaskChanges(notes: ''),
        reason: 'clearing notes is a change');
    expect(const TaskChanges().isEmpty, isTrue);
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final people in [TaskSheetPeople.everyone, TaskSheetPeople.assignee]) {
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        for (final scale in [1.0, 1.6]) {
          await _open(tester, _Rig().sheet(people: people),
              size: const Size(320, 640), theme: theme, textScale: scale);
          expect(tester.takeException(), isNull,
              reason: '$people ${theme.brightness} x$scale');
        }
      }
    }
  });
}
