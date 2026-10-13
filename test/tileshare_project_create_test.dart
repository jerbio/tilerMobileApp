// TileShare redesign Step 9.20 (T14, O10): Project create. A Project is made
// of its tilettes - one screen: the share's name, its deadline, the tilettes
// (the same list as Class: drag to reorder, the minus to remove, the tilette
// sheet to add and edit) and their total effort. "Create project" sends it by
// its mode with every tilette for no one yet; the owner assigns them later on
// the board, or never - a Jira-like or personal flow (owner, 2026-10-12).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createProject.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> tap(WidgetTester t, String key) async {
  await t.ensureVisible(k(key));
  await t.tap(k(key));
  await t.pumpAndSettle();
}

void main() {
  late FakeTileShareCreateSource source;
  late List<String> created;
  Duration length = const Duration(minutes: 30);
  String? editedNotes;

  Future<void> open(WidgetTester t,
      {bool dark = false,
      Size size = const Size(390, 844),
      double textScale = 1,
      Locale locale = const Locale('en')}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const SizedBox());
    source = FakeTileShareCreateSource();
    created = [];
    await t.pumpWidget(MaterialApp(
      theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      locale: locale,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!),
      home: CreateProjectScreen(
          source: source,
          now: () => DateTime(2026, 10, 12),
          pickDuration: (_, __) async => length,
          editNotes: (_, __) async => editedNotes,
          onCreated: (context, id) {
            created.add(id);
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Created detail'))));
          }),
    ));
    await t.pumpAndSettle();
  }

  Future<void> tilette(WidgetTester t, String name) async {
    await tap(t, 'create_project_add_task');
    await t.enterText(k('task_sheet_name'), name);
    await tap(t, 'task_sheet_length');
    await tap(t, 'task_sheet_save');
  }

  testWidgets(
      'one screen: name, deadline, tilettes and effort - no people, no steps',
      (t) async {
    await open(t);
    expect(k('create_project'), findsOneWidget);
    expect(find.text('New project'), findsOneWidget);
    expect(find.textContaining('Step 1'), findsNothing);
    expect(k('create_project_name'), findsOneWidget);
    expect(k('create_project_deadline'), findsOneWidget);
    expect(k('create_project_add_task'), findsOneWidget);
    expect(k('create_project_effort'), findsOneWidget);
    expect(k('create_project_length'), findsNothing,
        reason: 'each tilette has its own length; the total is the effort');
    expect(k('create_project_add_person'), findsNothing,
        reason: 'tilettes are assigned later, on the board');
    expect(
        find.text('Assign tilettes to people from the board once it’s '
            'created, or keep them for yourself.'),
        findsOneWidget);
    expect(
        find.descendant(
            of: k('create_project_send'), matching: find.text('Create project')),
        findsOneWidget);
  });

  testWidgets("a Project's tilette sheet asks for no one", (t) async {
    await open(t);
    await tap(t, 'create_project_add_task');
    expect(k('task_sheet'), findsOneWidget);
    expect(k('task_sheet_everyone'), findsNothing);
    expect(k('task_sheet_assignee'), findsNothing);
  });

  testWidgets('Create needs a name and a tilette, and sends nothing until then',
      (t) async {
    await open(t);
    await tap(t, 'create_project_send');
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Add at least one tilette'), findsOneWidget);
    await t.enterText(k('create_project_name'), 'Launch prep');
    await tap(t, 'create_project_send');
    expect(find.text('Add at least one tilette'), findsOneWidget);
    expect(source.calls, isEmpty);
  });

  testWidgets(
      'Create sends a Project by its mode, every tilette for no one yet, then '
      'hands over the new share', (t) async {
    await open(t);
    await t.enterText(k('create_project_name'), ' Launch prep ');
    length = const Duration(minutes: 30);
    await tilette(t, 'Research');
    length = const Duration(hours: 2);
    await tap(t, 'create_project_add_task');
    await t.enterText(k('task_sheet_name'), 'Design');
    await tap(t, 'task_sheet_length');
    editedNotes = 'Use the **brand** kit';
    await tap(t, 'task_sheet_notes');
    await tap(t, 'task_sheet_save');
    expect(find.text('2 hr 30 min'), findsOneWidget);
    await tap(t, 'create_project_send');
    final request = source.requests.single;
    expect(request['Mode'], 'project');
    expect(request['IsMultiTilette'], isNull);
    expect(request['Name'], 'Launch prep');
    expect(request['Contacts'], isEmpty);
    final deadline = DateTime(2026, 10, 19, 23, 59).millisecondsSinceEpoch;
    expect(request['EndTime'], deadline);
    final tasks = request['ClusterTemplateTileModels'] as List;
    expect(tasks.map((e) => e['Name']), ['Research', 'Design']);
    expect(tasks.map((e) => e['OrderedIndex']), [0, 1]);
    expect(tasks.map((e) => e['DurationInMs']), [1800000, 7200000]);
    expect(tasks.map((e) => e['EndTime']), [deadline, deadline]);
    expect(tasks[1]['NoteMiscData'], 'Use the **brand** kit');
    for (final task in tasks) {
      expect(task['Contacts'], isNotNull,
          reason: 'the server reads each tilette\'s contacts');
      expect(task['Contacts'], isEmpty, reason: 'assigned later, if ever');
    }
    expect(created, ['new-share']);
  });

  testWidgets('a refusal keeps the form; a second tap sends nothing more',
      (t) async {
    await open(t);
    await t.enterText(k('create_project_name'), 'Launch prep');
    await tilette(t, 'Research');
    source.failNext(StateError('offline'));
    await tap(t, 'create_project_send');
    expect(find.text('Could not send right now. Your details are kept.'),
        findsOneWidget);
    expect(find.text('Research'), findsOneWidget);
    expect(created, isEmpty);
    source.hold();
    await t.tap(k('create_project_send'));
    await t.pump();
    await t.tap(k('create_project_send'));
    await t.pump();
    source.release();
    await t.pumpAndSettle();
    expect(source.calls, hasLength(2));
    expect(created, ['new-share']);
  });

  testWidgets('fits narrow screens and large text in en and es, light and dark',
      (t) async {
    for (final dark in [false, true]) {
      for (final locale in [const Locale('en'), const Locale('es')]) {
        for (final scale in [1.0, 1.6]) {
          await open(t,
              dark: dark,
              locale: locale,
              size: const Size(320, 720),
              textScale: scale);
          await t.enterText(k('create_project_name'), 'Launch prep');
          await tilette(t, 'A longer tilette name for the launch research');
          expect(t.takeException(), isNull);
        }
      }
    }
  });

  testWidgets("a refused create is logged with the server's reason",
      (t) async {
    final List<String> logs = <String>[];
    final void Function(String) original = TileShareLog.sink;
    TileShareLog.sink = logs.add;
    addTearDown(() => TileShareLog.sink = original);
    await open(t);
    await t.enterText(k('create_project_name'), 'Launch prep');
    await tilette(t, 'Research');
    source.failNext(TilerError(Message: 'A recipient email or phone number is required.'));
    await tap(t, 'create_project_send');
    expect(
        logs.where((l) => l.contains('create project failed') &&
            l.contains('A recipient email or phone number is required.')),
        hasLength(1));
  });
}
