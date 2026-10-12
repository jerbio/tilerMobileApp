// TileShare redesign Step 9.18 (T14, §5.7): create starts with the mode.
// The chooser offers Broadcast, Class and Project in plain words, each
// creatable (Class 9.19, Project 9.20); Broadcast is one
// screen - name, length, deadline (a week out by default) and people - and
// Send creates the share by its mode (`Mode: broadcast`, its one tilette
// sent explicitly; the legacy `IsMultiTilette` is for older apps) and hands
// over its id. Send says what is missing; a refusal keeps the form;
// leaving with something entered asks first.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createBroadcast.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/create/createModeChooser.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/contactFieldRow.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';

final DateTime _now = DateTime(2026, 10, 10, 9, 30);

Widget _app(Widget home, {ThemeData? theme, double textScale = 1}) =>
    MaterialApp(
      theme: theme ?? TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
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
      home: home,
    );

void _phone(WidgetTester tester, [Size size = const Size(390, 844)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  group('the chooser', () {
    Future<List<TileShareMode?>> open(WidgetTester tester) async {
      _phone(tester);
      final List<TileShareMode?> chosen = <TileShareMode?>[];
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  chosen.add(await showCreateModeChooser(context)),
              child: const Text('new'),
            ),
          ),
        ),
      )));
      await tester.tap(find.text('new'));
      await tester.pumpAndSettle();
      return chosen;
    }

    testWidgets('offers the three modes in plain words', (tester) async {
      await open(tester);
      expect(find.text('Share work'), findsOneWidget);
      expect(find.text('How should people take part?'), findsOneWidget);
      for (final (key, title, body) in [
        (
          'create_mode_broadcast',
          'Broadcast',
          'Everyone gets their own copy of one tilette'
        ),
        (
          'create_mode_class',
          'Class',
          'Everyone gets their own copy of a set of tilettes'
        ),
        (
          'create_mode_project',
          'Project',
          'Everyone works on one shared set of tilettes'
        ),
      ]) {
        expect(find.descendant(of: _key(key), matching: find.text(title)),
            findsOneWidget);
        expect(find.descendant(of: _key(key), matching: find.text(body)),
            findsOneWidget);
      }
    });

    testWidgets('every mode can be chosen; none is coming soon',
        (tester) async {
      for (final (key, mode) in [
        ('create_mode_broadcast', TileShareMode.broadcast),
        ('create_mode_class', TileShareMode.class_),
        ('create_mode_project', TileShareMode.project),
      ]) {
        final chosen = await open(tester);
        expect(find.text('Coming soon'), findsNothing);
        await _tap(tester, key);
        expect(_key('create_mode_chooser'), findsNothing);
        expect(chosen, [mode]);
      }
    });

    testWidgets('closing it chooses nothing', (tester) async {
      final chosen = await open(tester);
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(chosen, [null]);
    });
  });

  group('Broadcast', () {
    late FakeTileShareCreateSource source;
    late List<String> created;
    Duration? pickedDuration;
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    CreateBroadcastScreen screen() => CreateBroadcastScreen(
          source: source,
          now: () => _now,
          onCreated: (context, id) {
            created.add(id);
            Navigator.of(context).pop();
          },
          pickDuration: (_, __) async => pickedDuration,
          pickDate: (_, __) async => pickedDate,
          pickTime: (_, __) async => pickedTime,
        );

    Future<void> open(WidgetTester tester,
        {Size size = const Size(390, 844),
        ThemeData? theme,
        double textScale = 1}) async {
      _phone(tester, size);
      source = FakeTileShareCreateSource();
      created = <String>[];
      pickedDuration = null;
      pickedDate = null;
      pickedTime = null;
      await tester.pumpWidget(_app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => screen())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        theme: theme,
        textScale: textScale,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> name(WidgetTester tester, String text) async {
      await tester.enterText(_key('create_broadcast_name'), text);
      await tester.pump();
    }

    Future<void> addPerson(WidgetTester tester, String who) async {
      await tester.ensureVisible(_key('create_broadcast_add_person'));
      await tester.enterText(
          find.descendant(
              of: _key('create_broadcast_add_person'),
              matching: find.byType(TextField)),
          who);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    testWidgets(
        'opens with an hour, a deadline a week out at the end of the day, '
        'and no one yet', (tester) async {
      await open(tester);
      expect(find.text('New broadcast'), findsOneWidget);
      expect(
          find.descendant(
              of: _key('create_broadcast_length'), matching: find.text('1 hr')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('create_broadcast_deadline'),
              matching:
                  find.textContaining(RegExp(r'Sat, Oct 17, 2026 11:59\s?PM'))),
          findsOneWidget);
      expect(find.text('PEOPLE'), findsOneWidget);
      expect(find.byType(ContactFieldRow), findsOneWidget,
          reason: 'the same add field as the tilette sheet');
      expect(
          find.text('Each person gets their own copy and is asked to accept.'),
          findsOneWidget);
      expect(
          find.descendant(
              of: _key('create_broadcast_send'), matching: find.text('Send')),
          findsOneWidget);
    });

    testWidgets('Send says what is missing and sends nothing', (tester) async {
      await open(tester);
      await _tap(tester, 'create_broadcast_send');
      expect(find.text('Name is required'), findsOneWidget);
      expect(source.calls, isEmpty);
      await name(tester, 'Weekly reading');
      await _tap(tester, 'create_broadcast_send');
      expect(find.text('Add at least one person'), findsOneWidget);
      expect(source.calls, isEmpty);
      await name(tester, 'Wr');
      await addPerson(tester, 'ann@x.com');
      await _tap(tester, 'create_broadcast_send');
      expect(find.text('Use at least 3 characters'), findsOneWidget);
      expect(source.calls, isEmpty);
    });

    testWidgets(
        'Send creates a Broadcast with its length, deadline and people, then '
        'hands over the new share', (tester) async {
      await open(tester);
      await name(tester, '  Weekly reading ');
      pickedDuration = const Duration(minutes: 45);
      await _tap(tester, 'create_broadcast_length');
      pickedDate = DateTime(2026, 10, 20);
      pickedTime = const TimeOfDay(hour: 17, minute: 0);
      await _tap(tester, 'create_broadcast_deadline');
      await addPerson(tester, 'ann@x.com');
      await addPerson(tester, '+15555550100');
      expect(
          find.descendant(
              of: _key('create_broadcast_send'),
              matching: find.text('Send to 2 people')),
          findsOneWidget);
      await _tap(tester, 'create_broadcast_send');
      expect(source.calls, ['createShare(Weekly reading)']);
      final request = source.requests.single;
      expect(request['Name'], 'Weekly reading');
      expect(request['Mode'], 'broadcast');
      expect(request['IsMultiTilette'], isNull,
          reason: 'the legacy flag is for older apps; create sends the mode');
      expect(request['StartTime'], _now.millisecondsSinceEpoch);
      expect(request['EndTime'],
          DateTime(2026, 10, 20, 17).millisecondsSinceEpoch);
      expect(request['Contacts'], isEmpty,
          reason: 'the people are on the one tilette (never null - the '
              'server joins the lists)');
      final tilette = (request['ClusterTemplateTileModels'] as List).single;
      expect(tilette['Name'], 'Weekly reading');
      expect(
          tilette['DurationInMs'], const Duration(minutes: 45).inMilliseconds);
      expect(tilette['StartTime'], _now.millisecondsSinceEpoch);
      expect(tilette['EndTime'],
          DateTime(2026, 10, 20, 17).millisecondsSinceEpoch);
      expect(
          (tilette['Contacts'] as List)
              .map((c) => c['Email'] ?? c['PhoneNumber'])
              .toList(),
          ['ann@x.com', '+15555550100']);
      expect(created, ['new-share']);
      expect(_key('create_broadcast'), findsNothing);
    });

    testWidgets('one person: "Send to 1 person"; the minus takes them off',
        (tester) async {
      await open(tester);
      await addPerson(tester, 'ann@x.com');
      expect(
          find.descendant(
              of: _key('create_broadcast_send'),
              matching: find.text('Send to 1 person')),
          findsOneWidget);
      expect(_key('create_broadcast_person_ann@x.com'), findsOneWidget);
      await _tap(tester, 'create_broadcast_remove_ann@x.com');
      expect(_key('create_broadcast_person_ann@x.com'), findsNothing);
      expect(
          find.descendant(
              of: _key('create_broadcast_send'), matching: find.text('Send')),
          findsOneWidget);
    });

    testWidgets('someone added twice is said once', (tester) async {
      await open(tester);
      await addPerson(tester, 'ann@x.com');
      await addPerson(tester, 'ANN@x.com');
      expect(find.text('ann@x.com is already invited.'), findsOneWidget);
      expect(find.byKey(const Key('create_broadcast_person_ann@x.com')),
          findsOneWidget);
    });

    testWidgets('a refusal keeps the form and says so; Send again works',
        (tester) async {
      await open(tester);
      await name(tester, 'Weekly reading');
      await addPerson(tester, 'ann@x.com');
      source.failNext(StateError('offline'));
      await _tap(tester, 'create_broadcast_send');
      expect(_key('create_broadcast'), findsOneWidget);
      expect(find.text('Could not send right now. Your details are kept.'),
          findsOneWidget);
      expect(created, isEmpty);
      await _tap(tester, 'create_broadcast_send');
      expect(created, ['new-share']);
    });

    testWidgets('a second tap while sending sends nothing more',
        (tester) async {
      await open(tester);
      await name(tester, 'Weekly reading');
      await addPerson(tester, 'ann@x.com');
      source.hold();
      await tester.tap(_key('create_broadcast_send'));
      await tester.pump();
      await tester.tap(_key('create_broadcast_send'));
      await tester.pump();
      source.release();
      await tester.pumpAndSettle();
      expect(source.calls, hasLength(1));
    });

    testWidgets('leaving with something entered asks first', (tester) async {
      await open(tester);
      await _tap(tester, 'create_broadcast_close');
      expect(_key('create_broadcast'), findsNothing,
          reason: 'nothing entered: it just closes');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await name(tester, 'Weekly reading');
      await _tap(tester, 'create_broadcast_close');
      expect(find.text('Discard this share?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(_key('create_broadcast'), findsOneWidget);
      await _tap(tester, 'create_broadcast_close');
      await _tap(tester, 'create_broadcast_discard');
      expect(_key('create_broadcast'), findsNothing);
      expect(source.calls, isEmpty);
    });

    testWidgets('looks right in both themes, at 320 px and with large text',
        (tester) async {
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        for (final (size, scale) in [
          (const Size(320, 640), 1.0),
          (const Size(390, 844), 1.6),
        ]) {
          await open(tester, size: size, theme: theme, textScale: scale);
          await name(tester, 'A rather long name for a weekly reading share');
          await addPerson(tester, 'someone.with.a.long.address@example.com');
          await _tap(tester, 'create_broadcast_send');
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
