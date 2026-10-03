// TileShare redesign Step 9.13 (§5.4): the owner's Broadcast detail - Overview
// and Participants. Overview previews (the answers, who may not have got the
// invitation, the first few people, "View all") and never repeats the list;
// Participants is the roster - each person's answer, progress and delivery -
// with adding (shown at once, never silently lost) and removing (confirmed,
// back in place if refused). Driven by the real cubits over in-memory sources.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/broadcastDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final DateTime _now = DateTime(2026, 10, 3, 9);

class _Rig {
  final TileShareTemplate tilette;
  late final FakeTileShareClustersSource clusters;
  late final FakeTileShareRecipientsSource recipients;
  late final TileShareDetailCubit detail;

  _Rig({int extra = 0})
      : tilette = tsTilette('tpl-1', clusterId: 'owned', name: 'Pack boxes',
            assignees: [
              tsAssignee('ann@x.com',
                  status: InvitationStatus.accepted, completion: 40),
              tsAssignee('bob@x.com'),
              for (int i = 0; i < extra; i++) tsAssignee('p$i@x.com'),
            ]) {
    clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('owned',
          name: 'Weekend move',
          mode: TileShareMode.broadcast,
          creatorId: 'me'),
    ], tilettesByCluster: {
      'owned': [tilette],
    });
    recipients = FakeTileShareRecipientsSource(tilettes: {
      'tpl-1': tilette,
    }, activity: [
      tsActivity('e2', 'invitation_send_failed',
          cluster: 'owned',
          assignmentId: 'asg-bob@x.com',
          metadata: {'channel': 'sms'}),
      tsActivity('e1', 'invitation_sent',
          cluster: 'owned',
          assignmentId: 'asg-ann@x.com',
          atMsFromNow: -1000,
          metadata: {'channel': 'email'}),
    ]);
    detail = TileShareDetailCubit(
      clusters: clusters,
      target: const TileShareDetailTarget.cluster('owned'),
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
    {Size size = const Size(390, 900),
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
            BroadcastDetail(detail: state, recipients: rig.recipients),
      ),
    ),
  ));
  await _settle(tester);
}

Finder _key(String k) => find.byKey(Key(k));

Future<void> _participants(WidgetTester tester) async {
  await tester.tap(_key('broadcast_segment_participants'));
  await _settle(tester);
}

Future<void> _addContact(WidgetTester tester, String value) async {
  await tester.enterText(
      find.descendant(
          of: _key('broadcast_add_participant'),
          matching: find.byType(TextField)),
      value);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

Finder _row(String label) => _key('participant_row_$label');

void main() {
  group('Overview', () {
    testWidgets('opens first: the answers, the first few people and View all '
        '- never the whole list', (tester) async {
      final rig = _Rig(extra: 3);
      await _open(tester, rig);
      expect(find.text('1 of 5 accepted'), findsOneWidget);
      expect(_row('ann@x.com'), findsOneWidget);
      expect(_row('p2@x.com'), findsNothing, reason: 'only the first three');
      expect(find.text('View all (5)'), findsOneWidget);
      expect(_key('broadcast_add_participant'), findsNothing);
      expect(find.byTooltip('Remove'), findsNothing,
          reason: 'Overview previews, it does not manage');
      await tester.tap(find.text('View all (5)'));
      await _settle(tester);
      expect(_row('p2@x.com'), findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('says when invitations may not have arrived, and opens the '
        'people', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      expect(find.text('1 invitation may not have arrived'), findsOneWidget);
      await tester.tap(find.text('1 invitation may not have arrived'));
      await _settle(tester);
      expect(_key('broadcast_add_participant'), findsOneWidget);
      await rig.detail.close();
    });
  });

  group('Participants', () {
    testWidgets('each person with their answer, progress and delivery',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _participants(tester);
      expect(find.descendant(of: _row('ann@x.com'), matching: find.text('Accepted')),
          findsOneWidget);
      expect(find.descendant(of: _row('ann@x.com'), matching: find.text('40%')),
          findsOneWidget);
      expect(
          find.descendant(of: _row('ann@x.com'), matching: find.text('Sent by email')),
          findsOneWidget);
      expect(find.descendant(of: _row('bob@x.com'), matching: find.text('Invited')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _row('bob@x.com'), matching: find.text('Couldn’t send by SMS')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('adding shows at once, then as invited', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _participants(tester);
      rig.recipients.hold();
      await _addContact(tester, 'cy@x.com');
      expect(find.descendant(of: _row('cy@x.com'), matching: find.text('Adding…')),
          findsOneWidget);
      rig.recipients.release();
      await _settle(tester);
      expect(find.descendant(of: _row('cy@x.com'), matching: find.text('Invited')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a refused add stays with Retry and Dismiss', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _participants(tester);
      rig.recipients.failNextOn('addRecipient',
          const TileShareRecipientFailure(TileShareFailureKind.server));
      await _addContact(tester, 'cy@x.com');
      await _settle(tester);
      expect(find.descendant(of: _row('cy@x.com'), matching: find.text('Couldn’t add.')),
          findsOneWidget);
      await tester.tap(find.descendant(
          of: _row('cy@x.com'), matching: find.text('Retry')));
      await _settle(tester);
      expect(find.descendant(of: _row('cy@x.com'), matching: find.text('Invited')),
          findsOneWidget);

      rig.recipients.failNextOn('addRecipient', StateError('offline'));
      await _addContact(tester, 'di@x.com');
      await _settle(tester);
      await tester.tap(find.descendant(
          of: _row('di@x.com'), matching: find.byTooltip('Dismiss')));
      await _settle(tester);
      expect(_row('di@x.com'), findsNothing);
      await rig.detail.close();
    });

    testWidgets('someone already invited is not added twice, and it says so',
        (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _participants(tester);
      await _addContact(tester, 'ann@x.com');
      await _settle(tester);
      expect(find.text('ann@x.com is already invited.'), findsOneWidget);
      expect(rig.recipients.calls.where((c) => c.startsWith('addRecipient')),
          isEmpty);
      await rig.detail.close();
    });

    testWidgets('removing asks first; cancelling sends nothing', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _participants(tester);
      await tester.tap(find.descendant(
          of: _row('bob@x.com'), matching: find.byTooltip('Remove')));
      await _settle(tester);
      expect(find.text('Remove bob@x.com?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(_row('bob@x.com'), findsOneWidget);
      expect(rig.recipients.calls.where((c) => c.startsWith('removeRecipient')),
          isEmpty);

      await tester.tap(find.descendant(
          of: _row('bob@x.com'), matching: find.byTooltip('Remove')));
      await _settle(tester);
      await tester.tap(_key('participant_remove_confirm'));
      await _settle(tester);
      expect(_row('bob@x.com'), findsNothing);
      expect(rig.recipients.calls.last, 'removeRecipient(tpl-1, asg-bob@x.com)');
      await rig.detail.close();
    });

    testWidgets('a refused removal comes back, saying so', (tester) async {
      final rig = _Rig();
      await _open(tester, rig);
      await _participants(tester);
      rig.recipients.failNextOn('removeRecipient', StateError('offline'));
      await tester.tap(find.descendant(
          of: _row('bob@x.com'), matching: find.byTooltip('Remove')));
      await _settle(tester);
      await tester.tap(_key('participant_remove_confirm'));
      await _settle(tester);
      expect(find.descendant(of: _row('bob@x.com'), matching: find.text('Couldn’t remove.')),
          findsOneWidget);
      await rig.detail.close();
    });

    testWidgets('a share with no one yet says how to start', (tester) async {
      final rig = _Rig();
      rig.tilette.designatedUsers = [];
      await _open(tester, rig);
      await _participants(tester);
      expect(find.text('No one yet. Add someone above.'), findsOneWidget);
      await rig.detail.close();
    });
  });

  testWidgets('a reload of the share brings its new roster', (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    await _participants(tester);
    rig.tilette.designatedUsers = [
      ...rig.tilette.designatedUsers!,
      tsAssignee('eve@x.com'),
    ];
    await rig.detail.refresh();
    await _settle(tester);
    expect(_row('eve@x.com'), findsOneWidget);
    await rig.detail.close();
  });

  testWidgets('looks right in both themes, at 320 px and with large text',
      (tester) async {
    for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
      for (final scale in [1.0, 1.6]) {
        final rig = _Rig(extra: 2);
        await _open(tester, rig,
            size: const Size(320, 700), theme: theme, textScale: scale);
        expect(tester.takeException(), isNull, reason: 'overview');
        await _participants(tester);
        expect(tester.takeException(), isNull, reason: 'participants');
        await rig.detail.close();
      }
    }
  });
}
