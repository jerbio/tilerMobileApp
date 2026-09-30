// TileShare redesign Step 9.5 (T7, T11): the Attention screen — chips, cards,
// the animated list and its states — against the real cubit with in-memory
// sources. Mirrors the no-snap discipline of the Daily grid: changes animate,
// existing rows do not jump in the first frame.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_attention_cubit.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionCard.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionView.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

// ---- rig -------------------------------------------------------------------

class _Rig {
  final FakeTileShareAttentionSources attention;
  final FakeTileShareAssignmentsSource assignments;
  final FakeTileShareClustersSource clusters;
  late final TileShareAttentionCubit cubit;
  final List<AttentionItem> opened = [];

  _Rig({
    FakeTileShareAttentionSources? attention,
    FakeTileShareAssignmentsSource? assignments,
    FakeTileShareClustersSource? clusters,
  })  : attention = attention ?? _fullAttention(),
        assignments = assignments ?? _fullAssignments(),
        clusters = clusters ?? _fullClusters() {
    cubit = TileShareAttentionCubit(
      attention: this.attention,
      assignments: this.assignments,
      clusters: this.clusters,
      currentUserId: () => 'me',
      clock: () => kTileShareNow,
    );
  }
}

FakeTileShareAttentionSources _fullAttention() => FakeTileShareAttentionSources(
      invitations: [
        tsInvitation('a1', 'c-class',
            deadlineMs: tileShareMsFromNow(const Duration(days: 5)))
      ],
      activity: [
        tsActivity('e-decl', 'assignment_declined',
            cluster: 'c-own', atMsFromNow: -1000),
        tsActivity('e-edit', 'tilette_edited',
            cluster: 'c-edit', atMsFromNow: -2000, metadata: {
          'changedFields': ['deadline'],
          'deadlineBefore': 1760000000000,
          'deadlineAfter': 1760086400000,
        }),
        tsActivity('e-done', 'assignment_completed',
            cluster: 'c-done', actorName: 'Marcus', atMsFromNow: -3000),
        tsActivity('e-fail', 'invitation_send_failed',
            cluster: 'c-fail', actorId: 'me', atMsFromNow: -4000),
      ],
    );

FakeTileShareAssignmentsSource _fullAssignments() =>
    FakeTileShareAssignmentsSource([
      tsDesignatedTile('d1',
          clusterId: 'c-risk',
          name: 'Design review',
          status: InvitationStatus.accepted,
          viable: false),
    ]);

FakeTileShareClustersSource _fullClusters() => FakeTileShareClustersSource(
      inbox: [
        tsCluster('c-class', mode: TileShareMode.class_),
        tsCluster('c-risk', mode: TileShareMode.project),
        tsCluster('c-edit', mode: TileShareMode.broadcast),
      ],
      outbox: [
        tsCluster('c-own', mode: TileShareMode.broadcast),
        tsCluster('c-done', mode: TileShareMode.project),
        tsCluster('c-fail', mode: TileShareMode.broadcast),
      ],
    );

Widget _app(_Rig rig, {ThemeData? theme, Widget? child}) => MaterialApp(
      theme: theme ?? TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<TileShareAttentionCubit>.value(
          value: rig.cubit,
          child: child ??
              TileShareAttentionView(onOpen: (item) => rig.opened.add(item)),
        ),
      ),
    );

Future<void> _pumpView(WidgetTester tester, _Rig rig,
    {ThemeData? theme, bool load = true}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_app(rig, theme: theme));
  if (load) {
    rig.cubit.load();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Finder _card(String id) => find.byKey(ValueKey('attention_card_$id'));
Finder _chip(String name) => find.byKey(Key('attention_chip_$name'));

double _luminance(Color c) => c.computeLuminance();

/// WCAG contrast ratio between two colours (opaque).
double _contrast(Color a, Color b) {
  final hi = _luminance(a) > _luminance(b) ? a : b;
  final lo = identical(hi, a) ? b : a;
  return (_luminance(hi) + 0.05) / (_luminance(lo) + 0.05);
}

/// The Undo action must be legible on the snack bar it sits on (its default
/// colour looks disabled, and the brand red is too faint on the light theme's
/// translucent-black bar). The bar's colour is blended over the page.
void _expectLegibleUndo(WidgetTester tester) {
  final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
  final theme =
      Theme.of(tester.element(find.byType(TileShareAttentionView)));
  final background = Color.alphaBlend(
      theme.snackBarTheme.backgroundColor ?? theme.colorScheme.inverseSurface,
      theme.scaffoldBackgroundColor);
  expect(action.textColor, isNotNull);
  expect(_contrast(action.textColor!, background), greaterThanOrEqualTo(3.0),
      reason: 'Undo must be readable against the snack bar');
}

/// Opens a card's overflow menu, lets its route finish animating, and picks
/// Dismiss.
Future<void> _chooseDismiss(WidgetTester tester, String itemId) async {
  await tester.tap(find.byKey(Key('attention_menu_$itemId')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text('Dismiss'));
}

/// The chips scroll sideways (five of them), so bring one into view first.
Future<void> _tapChip(WidgetTester tester, String name) async {
  await tester.ensureVisible(_chip(name));
  await tester.pump();
  await tester.tap(_chip(name));
}

// ---- card in isolation -----------------------------------------------------

Widget _cardApp(AttentionItem item,
        {ThemeData? theme,
        VoidCallback? onDismiss,
        VoidCallback? onAccept,
        VoidCallback? onDecline}) =>
    MaterialApp(
      theme: theme ?? TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: SingleChildScrollView(
              child: AttentionCard(
                  item: item,
                  onOpen: () {},
                  onDismiss: onDismiss,
                  onAccept: onAccept,
                  onDecline: onDecline))),
    );

Future<void> _pumpCard(WidgetTester tester, AttentionItem item,
    {ThemeData? theme,
    VoidCallback? onDismiss,
    VoidCallback? onAccept,
    VoidCallback? onDecline}) async {
  await tester.pumpWidget(_cardApp(item,
      theme: theme,
      onDismiss: onDismiss,
      onAccept: onAccept,
      onDecline: onDecline));
  await tester.pump();
}

void main() {
  group('AttentionCard wording', () {
    testWidgets('an invitation from one person: reason, mode, tasks, due, CTA',
        (tester) async {
      await _pumpCard(
          tester,
          AttentionItem(
              type: AttentionType.invitation,
              clusterId: 'c',
              clusterTitle: 'Launch Prep',
              mode: TileShareMode.class_,
              inviterName: 'Sarah Kim',
              deadlineMs: tileShareMsFromNow(const Duration(days: 5)),
              assignmentIds: const ['a1']));
      expect(find.text('Launch Prep'), findsOneWidget);
      expect(find.text('Sarah Kim invited you'), findsOneWidget);
      expect(find.text('Invitation'), findsOneWidget);
      expect(find.textContaining('Class'), findsOneWidget);
      expect(find.textContaining('1 task'), findsOneWidget);
      expect(find.textContaining('Due'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('several tasks, and an unknown inviter', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.invitation,
              clusterId: 'c',
              clusterTitle: 'Sprint',
              count: 3,
              inviterName: 'Sarah'));
      expect(find.text('Sarah invited you to 3 tasks'), findsOneWidget);
      expect(find.textContaining('3 tasks'), findsWidgets);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.invitation, clusterId: 'c', clusterTitle: 'X'));
      expect(find.text('Someone invited you'), findsOneWidget);
    });

    testWidgets('an unknown mode shows no mode label', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.invitation,
              clusterId: 'c',
              clusterTitle: 'X',
              inviterName: 'A'));
      expect(find.textContaining('Broadcast'), findsNothing);
      expect(find.textContaining('Project'), findsNothing);
      expect(find.textContaining('Class'), findsNothing);
    });

    testWidgets('at risk: titled, untitled and several', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.atRisk,
              clusterId: 'c',
              clusterTitle: 'C',
              taskTitle: 'Design review'));
      expect(find.text('“Design review” no longer fits your schedule'),
          findsOneWidget);
      expect(find.text('At risk'), findsOneWidget);
      expect(find.text('Review plan'), findsOneWidget);

      await _pumpCard(tester,
          const AttentionItem(type: AttentionType.atRisk, clusterId: 'c', clusterTitle: 'C'));
      expect(find.text('A task no longer fits your schedule'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.atRisk, clusterId: 'c', clusterTitle: 'C', count: 3));
      expect(find.text('3 tasks no longer fit your schedule'), findsOneWidget);
    });

    testWidgets('changed: each kind of edit reads differently', (tester) async {
      Future<void> changed(List<String> fields,
          {int count = 1, DateTime? before, DateTime? after, String? actor = 'Jordan'}) async {
        await _pumpCard(
            tester,
            AttentionItem(
                type: AttentionType.changed,
                clusterId: 'c',
                clusterTitle: 'C',
                actorName: actor,
                count: count,
                changedFields: fields,
                deadlineBefore: before,
                deadlineAfter: after,
                eventIds: const ['e']));
      }

      await changed(['name']);
      expect(find.text('Jordan renamed a task'), findsOneWidget);
      expect(find.text('Changed'), findsOneWidget);
      expect(find.text('Review changes'), findsOneWidget);

      await changed(['note']);
      expect(find.text('Jordan updated the notes'), findsOneWidget);

      await changed(['deadline']);
      expect(find.text('Jordan changed the deadline'), findsOneWidget);

      await changed(['deadline'],
          before: DateTime.utc(2026, 10, 9, 12), after: DateTime.utc(2026, 10, 12, 12));
      expect(find.textContaining('Jordan moved the deadline from Oct 9 to Oct 12'),
          findsOneWidget);

      await changed(['name', 'note']);
      expect(find.text('Jordan updated a task'), findsOneWidget);

      await changed(['name'], count: 3);
      expect(find.text('Jordan made 3 changes'), findsOneWidget);

      await changed(['name'], actor: null);
      expect(find.text('Someone renamed a task'), findsOneWidget);
    });

    testWidgets('declined, completed and delivery problems', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.declined,
              clusterId: 'c',
              clusterTitle: 'C',
              actorName: 'Aisha',
              eventIds: ['e']));
      expect(find.text('Aisha declined'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.declined,
              clusterId: 'c',
              clusterTitle: 'C',
              count: 3,
              eventIds: ['e']));
      expect(find.text('3 people declined'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.completed,
              clusterId: 'c',
              clusterTitle: 'C',
              actorName: 'Marcus',
              taskTitle: 'Review PR',
              eventIds: ['e']));
      expect(find.text('Marcus completed Review PR'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.completed,
              clusterId: 'c',
              clusterTitle: 'C',
              actorName: 'Marcus',
              eventIds: ['e']));
      expect(find.text('Marcus completed a task'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.completed,
              clusterId: 'c',
              clusterTitle: 'C',
              count: 4,
              eventIds: ['e']));
      expect(find.text('4 tasks completed'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.deliveryFailed,
              clusterId: 'c',
              clusterTitle: 'C',
              eventIds: ['e']));
      expect(find.text('Couldn’t send an invitation'), findsOneWidget);
      expect(find.text('Not sent'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.deliveryFailed,
              clusterId: 'c',
              clusterTitle: 'C',
              count: 2,
              eventIds: ['e']));
      expect(find.text('Couldn’t send 2 invitations'), findsOneWidget);

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.deliveryFailed,
              clusterId: 'c',
              clusterTitle: 'C',
              hasUnknownOutcome: true,
              eventIds: ['e']));
      expect(
          find.text(
              'An invitation may not have been sent — resend if needed'),
          findsOneWidget);
    });

    testWidgets('the overflow menu appears only when the item can be dismissed',
        (tester) async {
      const dismissible = AttentionItem(
          type: AttentionType.declined,
          clusterId: 'c',
          clusterTitle: 'C',
          eventIds: ['e']);
      await _pumpCard(tester, dismissible, onDismiss: () {});
      expect(find.byKey(const Key('attention_menu_declined:c')), findsOneWidget);

      await _pumpCard(tester, dismissible);
      expect(find.byKey(const Key('attention_menu_declined:c')), findsNothing,
          reason: 'no handler → no menu');

      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.invitation, clusterId: 'c', clusterTitle: 'C'),
          onDismiss: () {});
      expect(find.byKey(const Key('attention_menu_invitation:c')), findsNothing,
          reason: 'an invitation is answered, not dismissed');
    });

    testWidgets('the action label keeps the theme font (it once fell back to '
        'the platform default)', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.declined, clusterId: 'c', clusterTitle: 'C'));
      final style = DefaultTextStyle.of(tester.element(find.text('View'))).style;
      final themed = Theme.of(tester.element(find.text('View'))).textTheme;
      expect(style.fontFamily, isNotNull);
      expect(style.fontFamily, themed.bodyMedium!.fontFamily);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('renders in the dark theme without errors', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.atRisk,
              clusterId: 'c',
              clusterTitle: 'C',
              mode: TileShareMode.project,
              taskTitle: 'T'),
          theme: TileThemeData.darkTheme);
      expect(tester.takeException(), isNull);
      expect(find.text('At risk'), findsOneWidget);
    });
  });

  group('AttentionCard inline answers (T20)', () {
    AttentionItem invitation(TileShareMode? mode, {int count = 1}) =>
        AttentionItem(
            type: AttentionType.invitation,
            clusterId: 'c',
            clusterTitle: 'Launch Prep',
            inviterName: 'Sarah',
            mode: mode,
            count: count,
            assignmentIds: [for (int i = 0; i < count; i++) 'a$i']);

    Finder accept() => find.byKey(const Key('attention_accept_invitation:c'));
    Finder decline() => find.byKey(const Key('attention_decline_invitation:c'));

    testWidgets('a Broadcast invitation offers Accept and Decline',
        (tester) async {
      await _pumpCard(tester, invitation(TileShareMode.broadcast),
          onAccept: () {}, onDecline: () {});
      expect(find.descendant(of: accept(), matching: find.text('Accept')),
          findsOneWidget);
      expect(find.descendant(of: decline(), matching: find.text('Decline')),
          findsOneWidget);
      expect(find.text('Review'), findsOneWidget,
          reason: 'opening the invitation stays available');
    });

    testWidgets('a Class invitation offers Accept all and Decline all',
        (tester) async {
      await _pumpCard(tester, invitation(TileShareMode.class_, count: 3),
          onAccept: () {}, onDecline: () {});
      expect(find.text('Accept all'), findsOneWidget);
      expect(find.text('Decline all'), findsOneWidget);
    });

    testWidgets('a Project invitation only offers Review — never Accept all',
        (tester) async {
      await _pumpCard(tester, invitation(TileShareMode.project, count: 3),
          onAccept: () {}, onDecline: () {});
      expect(accept(), findsNothing);
      expect(decline(), findsNothing);
      expect(find.text('Accept all'), findsNothing);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('an unknown mode only offers Review', (tester) async {
      await _pumpCard(tester, invitation(null),
          onAccept: () {}, onDecline: () {});
      expect(accept(), findsNothing);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('no answer handlers → no buttons', (tester) async {
      await _pumpCard(tester, invitation(TileShareMode.broadcast));
      expect(accept(), findsNothing);
    });

    testWidgets('only invitations get the buttons', (tester) async {
      await _pumpCard(
          tester,
          const AttentionItem(
              type: AttentionType.declined,
              clusterId: 'c',
              clusterTitle: 'C',
              mode: TileShareMode.broadcast,
              eventIds: ['e']),
          onAccept: () {},
          onDecline: () {});
      expect(find.text('Accept'), findsNothing);
      expect(find.text('View'), findsOneWidget);
    });

    testWidgets('the buttons call their handlers', (tester) async {
      int accepted = 0, declined = 0;
      await _pumpCard(tester, invitation(TileShareMode.broadcast),
          onAccept: () => accepted++, onDecline: () => declined++);
      await tester.tap(accept());
      await tester.tap(decline());
      expect((accepted, declined), (1, 1));
    });

    testWidgets('the buttons fit a narrow phone without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pumpCard(tester, invitation(TileShareMode.class_, count: 3),
          onAccept: () {}, onDecline: () {});
      expect(tester.takeException(), isNull);
    });
  });

  group('the screen', () {
    testWidgets('lists every item in urgency order with its pill and action',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);

      double top(String id) => tester.getTopLeft(_card(id)).dy;
      expect(top('invitation:c-class'), lessThan(top('atRisk:c-risk')));
      expect(top('atRisk:c-risk'), lessThan(top('declined:c-own')));
      expect(top('declined:c-own'), lessThan(top('deliveryFailed:c-fail')));
      expect(top('deliveryFailed:c-fail'), lessThan(top('changed:c-edit')));
      expect(top('changed:c-edit'), lessThan(top('completed:c-done')));

      expect(find.text('Sarah Kim invited you'), findsOneWidget);
      expect(find.text('Jordan declined'), findsOneWidget);
      expect(find.textContaining('Jordan moved the deadline'), findsOneWidget);
      expect(find.text('Marcus completed a task'), findsOneWidget);
      expect(find.text('Couldn’t send an invitation'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('an at-risk card is titled by its cluster, not by the task',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      expect(
          find.descendant(
              of: _card('atRisk:c-risk'), matching: find.text('Cluster c-risk')),
          findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('modes resolved by the cubit show up on the cards',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      expect(
          find.descendant(
              of: _card('invitation:c-class'), matching: find.textContaining('Class')),
          findsOneWidget);
      expect(
          find.descendant(
              of: _card('atRisk:c-risk'), matching: find.textContaining('Project')),
          findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('tapping a card opens its item', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await tester.tap(_card('declined:c-own'));
      await tester.pump();
      expect(rig.opened.single.id, 'declined:c-own');
      await rig.cubit.close();
    });

    testWidgets('shows a skeleton while the first load is in flight',
        (tester) async {
      final rig = _Rig();
      rig.attention.hold();
      await _pumpView(tester, rig, load: false);
      rig.cubit.load();
      await tester.pump();
      expect(find.byKey(const Key('attention_skeleton')), findsOneWidget);
      expect(find.byKey(const Key('attention_empty')), findsNothing);
      rig.attention.release();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('attention_skeleton')), findsNothing);
      expect(_card('invitation:c-class'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('an empty inbox says you are all caught up', (tester) async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('attention_empty')), findsOneWidget);
      expect(find.text('You’re all caught up'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('renders in the dark theme without errors', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig, theme: TileThemeData.darkTheme);
      expect(tester.takeException(), isNull);
      expect(_card('invitation:c-class'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('answering an invitation on the screen', () {
    _Rig answerRig() => _Rig(
          attention: FakeTileShareAttentionSources(invitations: [
            tsInvitation('b1', 'c-bc'),
            tsInvitation('k1', 'c-class'),
            tsInvitation('k2', 'c-class'),
            tsInvitation('p1', 'c-proj'),
          ]),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource(inbox: [
            tsCluster('c-bc', mode: TileShareMode.broadcast),
            tsCluster('c-class', mode: TileShareMode.class_),
            tsCluster('c-proj', mode: TileShareMode.project),
          ]),
        );

    Finder accept(String c) => find.byKey(Key('attention_accept_invitation:$c'));
    Finder decline(String c) =>
        find.byKey(Key('attention_decline_invitation:$c'));
    List<String> sent(_Rig r) =>
        r.assignments.calls.where((c) => c.startsWith('respond')).toList();
    List<String> refreshed(_Rig r) =>
        r.assignments.calls.where((c) => c.startsWith('afterAccept')).toList();

    testWidgets('each mode shows its own buttons', (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      expect(accept('c-bc'), findsOneWidget);
      expect(find.descendant(of: accept('c-class'), matching: find.text('Accept all')),
          findsOneWidget);
      expect(accept('c-proj'), findsNothing, reason: 'a Project is reviewed');
      await rig.cubit.close();
    });

    testWidgets('Accept removes the card, offers Undo, and Undo brings it '
        'back without sending anything', (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      await tester.tap(accept('c-bc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-bc'), findsNothing);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-bc'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(sent(rig), isEmpty, reason: 'undone inside the window');
      await rig.cubit.close();
    });

    testWidgets('after the window the answer is sent and the schedule '
        'refreshed', (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      await tester.tap(accept('c-bc'));
      await tester.pump();
      expect(sent(rig), isEmpty);
      await tester.pump(TileShareAttentionCubit.defaultUndoWindow +
          const Duration(seconds: 1));
      expect(sent(rig), ['respond(b1, accepted)']);
      expect(refreshed(rig).length, 1);
      expect(_card('invitation:c-bc'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('the Undo action is readable: the theme default looks disabled',
        (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      await tester.tap(accept('c-bc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _expectLegibleUndo(tester);
      await rig.cubit.close();
    });

    testWidgets('the Undo action is readable in the dark theme too',
        (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig, theme: TileThemeData.darkTheme);
      await tester.tap(accept('c-bc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _expectLegibleUndo(tester);
      await rig.cubit.close();
    });

    testWidgets('the answer message goes away by itself', (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      await tester.tap(accept('c-bc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Accepted'), findsOneWidget);
      await tester.pump(TileShareAttentionCubit.defaultUndoWindow); // times out
      await tester.pump(const Duration(milliseconds: 500)); // and slides away
      expect(find.text('Accepted'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('Decline sends a decline and never refreshes the schedule',
        (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      await tester.tap(decline('c-bc'));
      await tester.pump();
      expect(find.text('Declined'), findsWidgets);
      await tester.pump(TileShareAttentionCubit.defaultUndoWindow +
          const Duration(seconds: 1));
      expect(sent(rig), ['respond(b1, declined)']);
      expect(refreshed(rig), isEmpty);
      await rig.cubit.close();
    });

    testWidgets('a Class says how many tasks it answered', (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      await tester.tap(accept('c-class'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Accepted 2 tasks'), findsOneWidget);
      await tester.pump(TileShareAttentionCubit.defaultUndoWindow +
          const Duration(seconds: 1));
      expect(sent(rig), ['respond(k1, accepted)', 'respond(k2, accepted)']);
      await rig.cubit.close();
    });

    testWidgets('a refused answer puts the card back and says so',
        (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      rig.assignments.failNextOn('respond', StateError('offline'));
      await tester.tap(accept('c-bc'));
      await tester.pump();
      await tester.pump(TileShareAttentionCubit.defaultUndoWindow +
          const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-bc'), findsOneWidget);
      expect(find.text('Couldn’t accept it. Try again.'), findsOneWidget);
      expect(rig.cubit.state.respondFailure, isNull, reason: 'acknowledged');
      await rig.cubit.close();
    });

    testWidgets('a schedule refresh that fails is reported, and the card '
        'stays gone', (tester) async {
      final rig = answerRig();
      await _pumpView(tester, rig);
      rig.assignments.failNextOn('afterAccept', StateError('refresh failed'));
      await tester.tap(accept('c-bc'));
      await tester.pump();
      await tester.pump(TileShareAttentionCubit.defaultUndoWindow +
          const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-bc'), findsNothing);
      expect(find.text('Accepted, but your schedule couldn’t refresh yet.'),
          findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('chips', () {
    testWidgets('show a count each; All is the total', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      String label(String name) => tester
          .widget<Text>(find.descendant(
              of: _chip(name), matching: find.byKey(Key('attention_chip_label_$name'))))
          .data!;
      expect(label('all'), 'All 6');
      expect(label('invitations'), 'Invitations 1');
      expect(label('changes'), 'Changes 1');
      expect(label('atRisk'), 'At risk 1');
      expect(label('responses'), 'Responses 3');
      await rig.cubit.close();
    });

    testWidgets('a chip filters the list; All brings everything back',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);

      await _tapChip(tester, 'responses');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('declined:c-own'), findsOneWidget);
      expect(_card('completed:c-done'), findsOneWidget);
      expect(_card('deliveryFailed:c-fail'), findsOneWidget);
      expect(_card('invitation:c-class'), findsNothing);
      expect(_card('changed:c-edit'), findsNothing);

      await _tapChip(tester, 'all');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-class'), findsOneWidget);
      expect(_card('changed:c-edit'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('switching chips animates: leaving cards are still there in '
        'the first frame and gone afterwards', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _tapChip(tester, 'invitations');
      await tester.pump(); // t = 0
      expect(_card('declined:c-own'), findsOneWidget,
          reason: 'exit animation, not a snap');
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('declined:c-own'), findsNothing);
      expect(tester.takeException(), isNull);
      await rig.cubit.close();
    });

    testWidgets('a chip with nothing in it shows the filtered empty state',
        (tester) async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(invitations: [
            tsInvitation('a1', 'c-class'),
          ]),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: _fullClusters());
      await _pumpView(tester, rig);
      await _tapChip(tester, 'atRisk');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Nothing to show here'), findsOneWidget);
      expect(find.byKey(const Key('attention_empty')), findsNothing,
          reason: 'not the all-caught-up state: there IS something under All');
      await rig.cubit.close();
    });

    testWidgets('the chosen chip survives a refresh', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _tapChip(tester, 'responses');
      await tester.pump(const Duration(milliseconds: 500));
      await rig.cubit.refresh();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-class'), findsNothing);
      expect(_card('declined:c-own'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('dismissing', () {
    testWidgets('the menu dismisses an activity item and offers Undo',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _chooseDismiss(tester, 'declined:c-own');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('declined:c-own'), findsNothing);
      expect(rig.attention.dismissed, {'e-decl'});
      expect(find.text('Dismissed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('declined:c-own'), findsOneWidget);
      expect(rig.attention.dismissed, isEmpty);
      await rig.cubit.close();
    });

    testWidgets('the Undo action on the dismiss message is readable too',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _chooseDismiss(tester, 'declined:c-own');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _expectLegibleUndo(tester);
      await rig.cubit.close();
    });

    testWidgets('the dismiss message goes away by itself', (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      await _chooseDismiss(tester, 'declined:c-own');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Dismissed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5)); // the message times out
      await tester.pump(const Duration(milliseconds: 500)); // and slides away
      expect(find.text('Dismissed'), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('invitation and at-risk cards have no dismiss menu',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('attention_menu_invitation:c-class')),
          findsNothing);
      expect(find.byKey(const Key('attention_menu_atRisk:c-risk')), findsNothing);
      await rig.cubit.close();
    });

    testWidgets('a refused dismissal puts the card back and says so',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      rig.attention.failNextOn('setDismissed', StateError('offline'));
      await _chooseDismiss(tester, 'declined:c-own');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('declined:c-own'), findsOneWidget);
      expect(find.text('Couldn’t dismiss it. Try again.'), findsOneWidget);
      expect(rig.cubit.state.dismissFailure, isNull,
          reason: 'shown once, then acknowledged');
      await rig.cubit.close();
    });
  });

  group('failures', () {
    testWidgets('a source failing shows a banner and keeps the rest; Retry '
        'reloads', (tester) async {
      final rig = _Rig();
      rig.attention.failNextOn('activity', StateError('feed down'));
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('attention_error_banner')), findsOneWidget);
      expect(find.text('Some updates couldn’t load'), findsOneWidget);
      expect(_card('invitation:c-class'), findsOneWidget);
      expect(_card('declined:c-own'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('attention_error_banner')), findsNothing);
      expect(_card('declined:c-own'), findsOneWidget);
      await rig.cubit.close();
    });

    testWidgets('a source failing with nothing else to show does NOT claim '
        'you are all caught up', (tester) async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: FakeTileShareClustersSource());
      rig.attention.failNextOn('invitations', StateError('not deployed'));
      await _pumpView(tester, rig);
      expect(find.byKey(const Key('attention_empty')), findsNothing,
          reason: 'we could not check everything');
      expect(find.text('You’re all caught up'), findsNothing);
      expect(find.text('Some updates couldn’t load'), findsOneWidget,
          reason: 'said once, not as a banner AND an empty state');
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('attention_empty')), findsOneWidget,
          reason: 'now every source answered, so it is honestly empty');
      await rig.cubit.close();
    });

    testWidgets('the banner’s Retry is readable in both themes',
        (tester) async {
      for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
        final rig = _Rig();
        rig.attention.failNextOn('activity', StateError('feed down'));
        await _pumpView(tester, rig, theme: theme);
        final banner = find.byKey(const Key('attention_error_banner'));
        expect(banner, findsOneWidget);
        final retry = tester.widget<TextButton>(
            find.descendant(of: banner, matching: find.byType(TextButton)));
        final color = retry.style!.foregroundColor!.resolve(<WidgetState>{})!;
        final background = Color.alphaBlend(
            theme.colorScheme.errorContainer.withValues(alpha: 0.5),
            theme.scaffoldBackgroundColor);
        expect(_contrast(color, background), greaterThanOrEqualTo(3.0),
            reason: 'Retry on the ${theme.brightness.name} banner');
        await rig.cubit.close();
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('everything failing shows one error state with Retry',
        (tester) async {
      final rig = _Rig();
      rig.attention.failNextOn('invitations', StateError('x'));
      rig.attention.failNextOn('activity', StateError('x'));
      rig.assignments.failNext(StateError('x'));
      await _pumpView(tester, rig);
      expect(find.text('Attention couldn’t load'), findsOneWidget);
      expect(find.byKey(const Key('attention_empty')), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_card('invitation:c-class'), findsOneWidget);
      await rig.cubit.close();
    });
  });

  group('no snapping (T11)', () {
    testWidgets('a refresh that changes nothing keeps every card element',
        (tester) async {
      final rig = _Rig();
      await _pumpView(tester, rig);
      final before = tester.element(_card('declined:c-own'));
      final top = tester.getTopLeft(_card('declined:c-own'));
      await rig.cubit.refresh();
      await tester.pump();
      expect(identical(tester.element(_card('declined:c-own')), before), isTrue,
          reason: 'keyed by item id, not rebuilt');
      expect(tester.getTopLeft(_card('declined:c-own')), top);
      await tester.pump(const Duration(milliseconds: 500));
      await rig.cubit.close();
    });

    testWidgets('a new item arriving above existing ones does not move them '
        'in the first frame; they slide down afterwards', (tester) async {
      final rig = _Rig(
          attention: FakeTileShareAttentionSources(activity: [
            tsActivity('e-decl', 'assignment_declined', cluster: 'c-own'),
          ]),
          assignments: FakeTileShareAssignmentsSource(),
          clusters: _fullClusters());
      await _pumpView(tester, rig);
      final before = tester.getTopLeft(_card('declined:c-own')).dy;

      rig.attention.invitationList
          .add(tsInvitation('a9', 'c-class', inviter: 'Sarah Kim'));
      await rig.cubit.refresh();
      await tester.pump(); // t = 0 after the change
      final atStart = tester.getTopLeft(_card('declined:c-own')).dy;
      expect((atStart - before).abs(), lessThan(4),
          reason: 'the new card grows in from zero height');

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getTopLeft(_card('declined:c-own')).dy, greaterThan(before + 40),
          reason: 'it has made room for the new card');
      expect(tester.takeException(), isNull);
      await rig.cubit.close();
    });
  });
}
