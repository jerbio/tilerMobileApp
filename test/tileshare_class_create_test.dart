import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createClass.dart';
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
  Future<void> open(WidgetTester t, {bool dark = false,
      Size size = const Size(390, 844), double textScale = 1,
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
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!),
      home: CreateClassScreen(
          source: source,
          now: () => DateTime(2026, 10, 12),
          pickDuration: (_, __) async => length,
          onCreated: (context, id) {
            created.add(id);
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Created detail'))));
          }),
    ));
    await t.pumpAndSettle();
  }

  Future<void> task(WidgetTester t, String name) async {
    await tap(t, 'create_class_add_task');
    await t.enterText(k('task_sheet_name'), name);
    await tap(t, 'task_sheet_length');
    await tap(t, 'task_sheet_save');
  }

  Future<void> person(WidgetTester t, String email) async {
    await t.ensureVisible(k('create_class_add_person'));
    await t.enterText(
        find.descendant(
            of: k('create_class_add_person'), matching: find.byType(TextField)),
        email);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
  }

  testWidgets('details need a valid name and a task; people need a person',
      (t) async {
    await open(t);
    await tap(t, 'create_class_next');
    expect(find.text('Name is required'), findsOneWidget);
    expect(source.calls, isEmpty);
    await t.enterText(k('create_class_name'), 'Weekly class');
    await tap(t, 'create_class_next');
    expect(find.text('Add at least one tilette'), findsOneWidget);
    await task(t, 'Reading');
    await tap(t, 'create_class_next');
    await tap(t, 'create_class_send');
    expect(find.text('Add at least one person'), findsOneWidget);
    expect(source.calls, isEmpty);
  });

  testWidgets('effort is summed; every person is on every ordered tilette',
      (t) async {
    await open(t);
    await t.enterText(k('create_class_name'), ' Weekly class ');
    length = const Duration(minutes: 30);
    await task(t, 'Reading');
    length = const Duration(minutes: 45);
    await task(t, 'Practice');
    expect(find.text('1 hr 15 min'), findsOneWidget);
    await tap(t, 'create_class_next');
    await person(t, 'ann@example.com');
    await person(t, 'bob@example.com');
    await person(t, 'ANN@example.com');
    await tap(t, 'create_class_send');
    final request = source.requests.single;
    expect(request['Mode'], 'class');
    expect(request['IsMultiTilette'], isNull);
    expect(request['Contacts'], isEmpty);
    expect(request['Name'], 'Weekly class');
    final tasks = request['ClusterTemplateTileModels'] as List;
    expect(tasks.map((e) => e['Name']), ['Reading', 'Practice']);
    expect(tasks.map((e) => e['OrderedIndex']), [0, 1]);
    expect(tasks.map((e) => e['DurationInMs']), [1800000, 2700000]);
    for (final task in tasks) {
      expect((task['Contacts'] as List).map((e) => e['Email']),
          ['ann@example.com', 'bob@example.com']);
    }
    expect(created, ['new-share']);
  });

  testWidgets('draft edit changes length; removing a tilette changes effort',
      (t) async {
    await open(t);
    await t.enterText(k('create_class_name'), 'Weekly class');
    length = const Duration(minutes: 30);
    await task(t, 'Reading');
    await task(t, 'Practice');
    await tap(t, 'create_class_task_0');
    length = const Duration(minutes: 45);
    await tap(t, 'task_sheet_length');
    await t.enterText(k('task_sheet_name'), 'New reading');
    await tap(t, 'task_sheet_save');
    expect(find.text('New reading'), findsOneWidget);
    expect(find.text('1 hr 15 min'), findsOneWidget);
    await tap(t, 'create_class_remove_task_1');
    expect(find.text('Practice'), findsNothing);
    await tap(t, 'create_class_next');
    await person(t, 'ann@example.com');
    await tap(t, 'create_class_send');
    final tasks = source.requests.single['ClusterTemplateTileModels'] as List;
    expect(tasks, hasLength(1));
    expect(tasks.single['Name'], 'New reading');
    expect(tasks.single['DurationInMs'], 2700000);
    expect(tasks.single['OrderedIndex'], 0);
  });

  testWidgets('dragging changes the order sent, keeping tilette identities',
      (t) async {
    await open(t);
    await t.enterText(k('create_class_name'), 'Weekly class');
    length = const Duration(minutes: 30);
    await task(t, 'Reading');
    await task(t, 'Practice');
    final handle = find.descendant(
        of: k('create_class_task_0'),
        matching: find.byType(ReorderableDragStartListener));
    final start = t.getCenter(handle);
    final gesture = await t.startGesture(start);
    await t.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 20));
    await t.pump();
    await gesture.moveBy(const Offset(0, 200));
    await t.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await t.pumpAndSettle();
    expect(t.getTopLeft(k('create_class_task_1')).dy,
        lessThan(t.getTopLeft(k('create_class_task_0')).dy));
    await tap(t, 'create_class_next');
    await person(t, 'ann@example.com');
    await tap(t, 'create_class_send');
    final tasks = source.requests.single['ClusterTemplateTileModels'] as List;
    expect(tasks.map((e) => e['Name']), ['Practice', 'Reading']);
    expect(tasks.map((e) => e['OrderedIndex']), [0, 1]);
  });

  testWidgets('removing a tilette shrinks its slot without a first-frame jump', (t) async {
    await open(t);
    await task(t, 'Reading');
    await task(t, 'Practice');
    final before = t.getTopLeft(k('create_class_task_1')).dy;
    await t.tap(k('create_class_remove_task_0'));
    await t.pump();
    expect(t.getTopLeft(k('create_class_task_1')).dy, closeTo(before, 1));
    await t.pump(const Duration(milliseconds: 125));
    final halfway = t.getTopLeft(k('create_class_task_1')).dy;
    expect(halfway, lessThan(before));
    await t.pumpAndSettle();
    expect(t.getTopLeft(k('create_class_task_1')).dy, lessThan(halfway));
  });

  testWidgets('both steps fit narrow screens and large text in en and es', (t) async {
    for (final dark in [false, true]) {
      for (final locale in [const Locale('en'), const Locale('es')]) {
        for (final scale in [1.0, 1.6]) {
          await open(t, dark: dark, locale: locale,
            size: const Size(320, 720), textScale: scale);
          await t.enterText(k('create_class_name'), 'Weekly class');
          await task(t, 'A longer tilette name for the weekly reading');
          await tap(t, 'create_class_next');
          await person(t, 'someone.with.a.long.address@example.com');
          expect(t.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('failure keeps both steps; back keeps people; retry sends once',
      (t) async {
    await open(t, dark: true);
    await t.enterText(k('create_class_name'), 'Weekly class');
    await task(t, 'Reading');
    await tap(t, 'create_class_next');
    await person(t, 'ann@example.com');
    source.failNext(StateError('part-way refusal'));
    await tap(t, 'create_class_send');
    expect(find.text('Could not send right now. Your details are kept.'),
        findsOneWidget);
    expect(created, isEmpty);
    await tap(t, 'create_class_back');
    expect(find.text('Reading'), findsOneWidget);
    await tap(t, 'create_class_next');
    expect(find.text('ann@example.com'), findsOneWidget);
    source.hold();
    await t.tap(k('create_class_send'));
    await t.pump();
    await t.tap(k('create_class_send'));
    await t.pump();
    source.release();
    await t.pumpAndSettle();
    expect(source.calls, hasLength(2));
    expect(created, ['new-share']);
    expect(t.takeException(), isNull);
  });
}
