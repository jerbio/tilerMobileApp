// TileShare redesign Step 9.16e (T27): Edit share - a full screen from the
// detail's ⋯, built from the redesign form kit. The share's name (3-100) and
// deadline (a date then a time), its mode shown but fixed, its total effort
// (the sum of its tilettes) as information. Only what changed is sent; a
// deadline earlier than some tilettes' says how many are due after it (they
// keep theirs); a refused save keeps the screen and what was typed; leaving
// with changes asks first. The description waits on O25.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/editShareScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/shareDetailsForm.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _end = DateTime(2026, 10, 10, 17);

class _Rig {
  late final FakeTileShareClustersSource clusters;
  late final FakeTileShareEditSource edits;
  late final TileShareDetailCubit detail;
  DateTime? pickedDate;
  TimeOfDay? pickedTime;

  _Rig({TileShareMode mode = TileShareMode.class_}) {
    clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('k',
          name: 'Launch prep',
          mode: mode,
          creatorId: 'me',
          endMs: _end.millisecondsSinceEpoch),
    ], tilettesByCluster: {
      'k': [
        tsTilette('t1',
            clusterId: 'k',
            durationMs: 3600000,
            endMs: DateTime(2026, 10, 9, 12).millisecondsSinceEpoch),
        tsTilette('t2',
            clusterId: 'k',
            durationMs: 5400000,
            endMs: DateTime(2026, 10, 10, 12).millisecondsSinceEpoch,
            assignees: [
              tsAssignee('ann@x.com', status: InvitationStatus.accepted)
            ]),
        tsTilette('t3', clusterId: 'k', durationMs: 1800000),
      ],
    });
    edits = FakeTileShareEditSource(clusters);
    detail = TileShareDetailCubit(
      clusters: clusters,
      edits: edits,
      target: const TileShareDetailTarget.cluster('k'),
      currentUserId: () => 'me',
    );
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {Size size = const Size(390, 844),
    ThemeData? theme,
    double textScale = 1}) async {
  await rig.detail.load();
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
            onPressed: () => showEditShare(context, rig.detail,
                pickDate: (_, __) async => rig.pickedDate,
                pickTime: (_, __) async => rig.pickedTime),
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

void main() {
  testWidgets(
      'the share as it is: name, deadline, the mode (fixed) and the '
      'total effort', (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    expect(_key('edit_share'), findsOneWidget);
    expect(find.text('Edit share'), findsOneWidget);
    expect(find.text('Launch prep'), findsOneWidget);
    expect(
        find.descendant(
            of: _key('edit_share_deadline'),
            matching: find.textContaining('Oct 10, 2026')),
        findsOneWidget);
    expect(
        find.descendant(
            of: _key('edit_share_mode'), matching: find.text('Class')),
        findsOneWidget);
    expect(find.text('The mode can’t change after sharing.'), findsOneWidget);
    expect(
        find.descendant(
            of: _key('edit_share_effort'), matching: find.text('3 hr')),
        findsOneWidget,
        reason: '1 hr + 1 hr 30 min + 30 min');
    expect(
        find.descendant(
            of: _key('edit_share_effort'),
            matching: find.byIcon(Icons.chevron_right)),
        findsNothing,
        reason: 'information, not a control');
    await rig.detail.close();
  });

  testWidgets('Save changes, in sentence case', (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    expect(find.text('Save changes'), findsOneWidget);
    await rig.detail.close();
  });

  testWidgets('a rename sends only the name, and closes', (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    await tester.enterText(_key('edit_share_name'), 'Launch day');
    await tester.pump();
    await _tap(tester, 'edit_share_save');
    expect(rig.edits.calls, ['updateShare(k, name: Launch day, end: null)']);
    expect(_key('edit_share'), findsNothing);
    await rig.detail.close();
  });

  testWidgets('nothing changed, nothing sent; a short name says so',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    await _tap(tester, 'edit_share_save');
    expect(rig.edits.calls, isEmpty);
    expect(_key('edit_share'), findsOneWidget);
    await tester.enterText(_key('edit_share_name'), 'ab');
    await tester.pump();
    await _tap(tester, 'edit_share_save');
    expect(find.text('Use at least 3 characters'), findsOneWidget);
    expect(rig.edits.calls, isEmpty);
    await rig.detail.close();
  });

  testWidgets('an earlier deadline says how many tilettes are due after it',
      (tester) async {
    final rig = _Rig()
      ..pickedDate = DateTime(2026, 10, 9)
      ..pickedTime = const TimeOfDay(hour: 9, minute: 0);
    await _open(tester, rig);
    expect(_key('edit_share_late'), findsNothing);
    await _tap(tester, 'edit_share_deadline');
    expect(_key('edit_share_late'), findsOneWidget);
    expect(
        find.text('1 accepted tilette will be moved to this deadline.'),
        findsOneWidget,
        reason: 'the server pulls accepted tilettes in (O27)');
    expect(
        find.text('1 tilette nobody has accepted keeps its later deadline.'),
        findsOneWidget);
    await _tap(tester, 'edit_share_save');
    expect(rig.edits.calls, [
      'updateShare(k, name: null, end: '
          '${DateTime(2026, 10, 9, 9).millisecondsSinceEpoch})'
    ]);
    await rig.detail.close();
  });

  testWidgets('a refused save keeps the screen and what was typed',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    rig.edits.failNextOn('updateShare', StateError('offline'));
    await tester.enterText(_key('edit_share_name'), 'Launch day');
    await tester.pump();
    await _tap(tester, 'edit_share_save');
    expect(_key('edit_share'), findsOneWidget);
    expect(find.text('Could not save right now. Your changes are kept.'),
        findsOneWidget);
    expect(find.text('Launch day'), findsOneWidget);
    expect(rig.detail.state.editFailed, isNull,
        reason: 'said here, not again on the detail');
    await rig.detail.close();
  });

  testWidgets('leaving with changes asks first', (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    await _tap(tester, 'edit_share_close');
    expect(_key('edit_share'), findsNothing, reason: 'nothing to lose');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('edit_share_name'), 'Launch day');
    await tester.pump();
    await _tap(tester, 'edit_share_close');
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Launch day'), findsOneWidget);
    // The system back button asks too.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(_key('edit_share'), findsOneWidget);
    await _tap(tester, 'edit_share_close');
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(_key('edit_share'), findsNothing);
    expect(rig.edits.calls, isEmpty);
    await rig.detail.close();
  });

  test('only what changed is sent; tilettes due after a deadline', () {
    final before = ShareDetailsValue(name: 'Launch', deadline: _end);
    expect(
        ShareDetailsValue(name: ' Launch ', deadline: _end)
            .changesSince(before),
        const ShareChanges());
    expect(
        ShareDetailsValue(name: 'Launch', deadline: DateTime(2026, 10, 11))
            .changesSince(before),
        ShareChanges(endMs: DateTime(2026, 10, 11).millisecondsSinceEpoch));
    final tilettes = [
      tsTilette('a', endMs: DateTime(2026, 10, 9).millisecondsSinceEpoch),
      tsTilette('b', endMs: DateTime(2026, 10, 12).millisecondsSinceEpoch),
      tsTilette('c'),
    ];
    expect(tilettesDueAfter(tilettes, DateTime(2026, 10, 10)),
        (accepted: 0, notAccepted: 1),
        reason: 'a tilette without its own deadline follows the share');
    expect(
        totalEffort(
            tilettes..first.durationInMs = 600000, TileShareMode.class_),
        const Duration(minutes: 10));
    expect(
        totalEffort([
          tsTilette('x', durationMs: 3600000),
          tsTilette('y', durationMs: 3600000),
        ], TileShareMode.broadcast),
        const Duration(hours: 1),
        reason: 'a Broadcast is one tilette, everyone their own copy');
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
      for (final scale in [1.0, 1.6]) {
        final rig = _Rig()
          ..pickedDate = DateTime(2026, 10, 9)
          ..pickedTime = const TimeOfDay(hour: 9, minute: 0);
        await _open(tester, rig,
            size: const Size(320, 640), theme: theme, textScale: scale);
        await _tap(tester, 'edit_share_deadline');
        expect(tester.takeException(), isNull,
            reason: '${theme.brightness} x$scale');
        await rig.detail.close();
      }
    }
  });
}
