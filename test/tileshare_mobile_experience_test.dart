import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/components/comments/comments_section.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareActivity.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tiletteDetailScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/commitmentDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareRosterDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareWorkWidgets.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tileShareDetailScaffold.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tiletteWorkCard.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareDisplayOptions.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareActivityWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tap_visible.dart';
import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

final _now = DateTime(2026, 11, 1);
final _due = DateTime(2026, 11, 6).millisecondsSinceEpoch;

class _Rig {
  final TileShareMode mode;
  final bool owner;
  late final TileShareDetailCubit detail;
  late final FakeTileShareRecipientsSource recipients;
  late final FakeTileShareAssignmentsSource assignments;
  final notes = <String>[];
  final activityScopes = <String?>[];

  _Rig(this.mode, {this.owner = true}) {
    final names = [
      'Review launch copy',
      'Build demo walkthrough',
      'Press kit approval',
      'Prepare launch metrics'
    ];
    final tilettes = [
      for (int i = 0; i < names.length; i++)
        tsTilette('tpl-d$i',
            clusterId: 'share',
            name: names[i],
            endMs: _due,
            durationMs: (i == 1 ? 120 : 45) * 60000,
            assignees: [
              for (int person = 0;
                  person < (mode == TileShareMode.class_ ? 3 : 1);
                  person++)
                tsAssignee(
                    [
                      'glory@example.com',
                      'jerome@example.com',
                      'aisha@example.com'
                    ][person],
                    status: i == 0 && person == 2 || i == 2
                        ? InvitationStatus.none
                        : InvitationStatus.accepted,
                    completion:
                        i == 3 || i == 0 && person == 0 || i == 1 && person < 2
                            ? 100
                            : i == 0 && person == 1
                                ? 50
                                : 0),
            ]),
    ];
    // Project progress belongs to an assigned task, rather than a person/task grid.
    if (mode == TileShareMode.project) {
      tilettes[0].designatedUsers!.first.rsvpStatus = InvitationStatus.none;
      tilettes[1].designatedUsers!.first.completionPercentage = 40;
    }
    assignments = FakeTileShareAssignmentsSource([
      for (int i = 0; i < (mode == TileShareMode.class_ ? 4 : 2); i++)
        tsDesignatedTile('d$i',
            clusterId: 'share',
            name: names[i],
            endMs: _due,
            durationMs: (i == 1 ? 120 : 45) * 60000,
            status: i == 0 ? InvitationStatus.none : InvitationStatus.accepted,
            completion: i == 1
                ? 40
                : i > 1
                    ? 100
                    : null,
            note: i == 0
                ? 'Confirm the **launch message**.\n\n- [ ] Review headline'
                : null),
    ]);
    final clusters = FakeTileShareClustersSource(outbox: [
      tsCluster('share',
          name: mode == TileShareMode.class_
              ? 'Interview Prep Cohort'
              : 'Launch Readiness',
          mode: mode,
          creatorId: owner ? 'me' : 'creator',
          endMs: _due),
    ], tilettesByCluster: {
      'share': tilettes
    });
    recipients = FakeTileShareRecipientsSource(
        tilettes: {for (final t in tilettes) t.id!: t});
    detail = TileShareDetailCubit(
        clusters: clusters,
        assignments: assignments,
        edits: owner ? FakeTileShareEditSource(clusters) : null,
        target: const TileShareDetailTarget.cluster('share'),
        currentUserId: () => 'me');
  }

  Widget activity(BuildContext context) => TileShareActivityWidget(
        clusterId: 'share',
        embedded: true,
        loader: ({String? clusterId, String? tiletteId, String? cursor}) async {
          activityScopes.add(clusterId);
          return const TileShareActivityPage(
              items: [], historyAvailableFrom: 1);
        },
      );

  Widget content(BuildContext context, TileShareDetailState state) {
    if (!owner)
      return CommitmentDetail(
          detail: state,
          assignments: assignments,
          onAnswered: detail.refresh,
          activityBuilder: activity,
          onNotes: (tile) => notes.add(tile.id!),
          onComments: (_) {},
          onOpenTile: (_) {});
    if (mode == TileShareMode.class_)
      return ClassDetail(
          detail: state,
          recipients: recipients,
          activityBuilder: activity,
          onNotes: (tile) => notes.add(tile.id!),
          onComments: (_) {});
    return ProjectDetail(
        detail: state,
        recipients: recipients,
        activityBuilder: activity,
        onNotes: (tile) => notes.add(tile.id!),
        onComments: (_) {});
  }
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {bool dark = true,
    Size size = const Size(390, 844),
    double textScale = 1,
    TiletteDensity density = TiletteDensity.compact,
    TileShareDisplaySettings? displaySettings}) async {
  final display =
      displaySettings ?? TileShareDisplaySettings.memory(density: density);
  if (displaySettings == null) addTearDown(display.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(rig.detail.close);
  await tester.pumpWidget(RepaintBoundary(
      key: const Key('preview'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: BlocProvider.value(
            value: rig.detail,
            child: TileShareDetailScaffold(
                displaySettings: display,
                now: _now,
                contentBuilder: rig.content)),
      )));
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('TILESHARE_PREVIEW')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory =
        await Directory('build/tileshare-previews').create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('TILESHARE_PREVIEW')) {
      for (final family in ['Rubik', 'Roboto']) {
        await (FontLoader(family)
              ..addFont(rootBundle
                  .load('assets/fonts/Rubik/Rubik-VariableFont_wght.ttf')))
            .load();
      }
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    }
  });
  testWidgets(
      'Class counts completed assignments across people, independently of acceptance',
      (tester) async {
    final rig = _Rig(TileShareMode.class_);
    await _open(tester, rig);
    expect(find.text('6 of 12 complete'), findsOneWidget);
    expect(find.byKey(const Key('class_task_tpl-d0')), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    for (final label in ['Managing', 'Instructing', 'Learners', 'Lessons']) {
      expect(find.text(label), findsNothing);
    }
    await _preview(tester, 'class-owner');
    await tapVisible(tester, find.byKey(const Key('roster_segment_activity')));
    await tester.pumpAndSettle();
    expect(rig.activityScopes, ['share']);
    expect(find.text('No activity yet.'), findsOneWidget);
  });

  testWidgets(
      'Project opens its work board, filters by progress and opens notes',
      (tester) async {
    final rig = _Rig(TileShareMode.project);
    await _open(tester, rig);
    await _preview(tester, 'project-owner');
    await tapVisible(tester, find.byTooltip('Notes').first);
    expect(rig.notes, ['tpl-d0']);
    await tapVisible(tester, find.byKey(const Key('share_work_filter')));
    await tester.pumpAndSettle();
    await tapVisible(
        tester,
        find.widgetWithText(
            CheckedPopupMenuItem<ShareWorkFilter>, 'In progress'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project_task_tpl-d1')), findsOneWidget);
    expect(find.byKey(const Key('project_task_tpl-d0')), findsNothing);
  });

  for (final mode in [TileShareMode.class_, TileShareMode.project]) {
    testWidgets(
        '${mode.name} personal work keeps decisions separate and responds',
        (tester) async {
      final rig = _Rig(mode, owner: false);
      await _open(tester, rig);
      expect(find.text('My work'), findsOneWidget);
      await _preview(tester,
          mode == TileShareMode.class_ ? 'class-personal' : 'project-personal');
      if (mode == TileShareMode.project) {
        expect(find.byKey(const Key('commitment_decisions')), findsOneWidget);
        expect(find.byKey(const Key('commitment_commitments')), findsOneWidget);
      } else {
        expect(find.text('2 of 4 complete'), findsOneWidget);
      }
      await tapVisible(tester, find.byKey(const Key('commitment_notes_d0')));
      expect(rig.notes, ['d0']);
      await tapVisible(
          tester,
          find.byKey(Key(mode == TileShareMode.project
              ? 'commitment_accept_d0'
              : 'commitment_accept')));
      await tester.pumpAndSettle();
      expect(rig.assignments.calls, contains('respond(d0, accepted)'));
      expect(rig.detail.state.mine.first.invitationStatus, 'accepted');
    });
  }

  testWidgets('live tab configuration fits a small phone with enlarged text',
      (tester) async {
    for (final mode in [TileShareMode.class_, TileShareMode.project]) {
      for (final owner in [true, false]) {
        final rig = _Rig(mode, owner: owner);
        await tester.pumpWidget(const SizedBox());
        await _open(tester, rig, size: const Size(320, 700), textScale: 1.6);
        expect(tester.takeException(), isNull, reason: '$mode owner=$owner');
        await tapVisible(tester, find.text('Activity'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'all roles use the same card sections and Notes then Comments footer',
      (tester) async {
    final metadataOffsets = <double>[];
    for (final mode in [TileShareMode.class_, TileShareMode.project]) {
      for (final owner in [true, false]) {
        await tester.pumpWidget(const SizedBox());
        final rig = _Rig(mode, owner: owner);
        await _open(tester, rig, density: TiletteDensity.comfortable);
        final card = find.byType(TiletteWorkCard).first;
        final meta = find.descendant(
            of: card, matching: find.byKey(const Key('tilette_meta')));
        final status = find.descendant(
            of: card, matching: find.byKey(const Key('tilette_status')));
        final footer = find.descendant(
            of: card, matching: find.byKey(const Key('tilette_footer')));
        expect(meta, findsOneWidget);
        expect(status, findsOneWidget);
        expect(footer, findsOneWidget);
        final header = find.descendant(
            of: card, matching: find.byKey(const Key('tilette_header')));
        final title = find.descendant(
            of: header, matching: find.text('Review launch copy'));
        metadataOffsets
            .add(tester.getTopLeft(meta).dy - tester.getBottomLeft(title).dy);
        final notes = find.descendant(of: footer, matching: find.text('Notes'));
        final comments =
            find.descendant(of: footer, matching: find.text('Comments'));
        expect(notes, findsOneWidget);
        expect(comments, findsOneWidget);
        expect(tester.getTopLeft(status).dy,
            greaterThan(tester.getTopLeft(meta).dy));
        expect(tester.getTopLeft(footer).dy,
            greaterThan(tester.getTopLeft(status).dy));
        expect(tester.getTopLeft(notes).dx,
            lessThan(tester.getTopLeft(comments).dx));
        await tapVisible(tester, notes);
        expect(rig.notes, [owner ? 'tpl-d0' : 'd0']);
        if (!owner && mode == TileShareMode.project) {
          final actions = find.descendant(
              of: card, matching: find.byKey(const Key('tilette_actions')));
          expect(find.descendant(of: actions, matching: find.text('Accept')),
              findsOneWidget);
          expect(find.descendant(of: footer, matching: find.text('Accept')),
              findsNothing);
        }
      }
    }
    expect(metadataOffsets, everyElement(closeTo(metadataOffsets.first, 0.01)),
        reason: 'metadata follows the title even when a long title wraps');
  });

  testWidgets('dedicated notes render without starting a comment request',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
        key: const Key('preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TileThemeData.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TiletteDetailScreen(
              initialTab: TiletteDetailTab.notes,
              designatedTile: tsDesignatedTile('d0',
                  name: 'Review launch copy',
                  endMs: _due,
                  durationMs: 45 * 60000,
                  status: InvitationStatus.accepted,
                  note:
                      '## Review checklist\n\nConfirm the launch message.\n\n- [ ] Verify headline\n- [x] Check primary CTA\n\n## References\n\n[Launch brief](https://example.com/brief)')),
        )));
    await tester.pumpAndSettle();
    expect(find.byType(CommentsSection), findsNothing);
    expect(find.text('Review checklist'), findsOneWidget);
    await _preview(tester, 'tilette-notes');
  });

  testWidgets(
      'Compact defaults to shorter cards with no note preview and accessible quick actions',
      (tester) async {
    final settings = TileShareDisplaySettings.memory();
    addTearDown(settings.dispose);
    final rig = _Rig(TileShareMode.class_, owner: false);
    await _open(tester, rig, displaySettings: settings);
    final card = find.byKey(const Key('commitment_task_d0'));
    final compactHeight = tester.getSize(card).height;
    expect(find.descendant(of: card, matching: find.byType(MarkdownNoteView)),
        findsNothing);
    final notes = find.byKey(const Key('commitment_notes_d0'));
    expect(tester.getSize(notes).height, greaterThanOrEqualTo(48));
    expect(
        find.byKey(const Key('commitment_invitation_panel')), findsOneWidget);
    await _preview(tester, 'density-compact');
    await tapVisible(tester, find.byKey(const Key('share_view_options')));
    await tester.pumpAndSettle();
    expect(find.text('Comfortable'), findsOneWidget);
    expect(find.text('Compact'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    await tapVisible(
        tester, find.byKey(const Key('share_density_comfortable')));
    await tester.pumpAndSettle();
    expect(settings.density, TiletteDensity.comfortable);
    expect(tester.getSize(card).height, greaterThan(compactHeight));
    expect(find.descendant(of: card, matching: find.byType(MarkdownNoteView)),
        findsOneWidget);
    await _preview(tester, 'density-comfortable');
  });

  testWidgets('List rows expand to expose acceptance, notes and comments',
      (tester) async {
    final rig = _Rig(TileShareMode.project, owner: false);
    await _open(tester, rig, density: TiletteDensity.list);
    final card = find.byKey(const Key('commitment_task_d0'));
    final collapsedHeight = tester.getSize(card).height;
    expect(find.byKey(const Key('commitment_accept_d0')), findsNothing);
    await _preview(tester, 'density-list');
    await tapVisible(
        tester,
        find.descendant(
            of: card, matching: find.byKey(const Key('tilette_expand'))));
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, greaterThan(collapsedHeight));
    expect(find.byKey(const Key('commitment_notes_d0')), findsOneWidget);
    expect(find.byKey(const Key('commitment_comments_d0')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('commitment_accept_d0')));
    await tester.pumpAndSettle();
    expect(rig.assignments.calls, contains('respond(d0, accepted)'));
    await tapVisible(
        tester,
        find.descendant(
            of: card, matching: find.byKey(const Key('tilette_collapse'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('commitment_open_d0')), findsNothing);
  });

  testWidgets('the density choice is restored when another share opens',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final first = TileShareDisplaySettings();
    addTearDown(first.dispose);
    await first.load();
    await _open(tester, _Rig(TileShareMode.project), displaySettings: first);
    await tapVisible(tester, find.byKey(const Key('share_view_options')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('share_density_list')));
    await tester.pumpAndSettle();
    expect(
        (await SharedPreferences.getInstance())
            .getString(StoredTileShareDisplayPreferences.key),
        'list');
    await tester.pumpWidget(const SizedBox());
    final next = TileShareDisplaySettings();
    addTearDown(next.dispose);
    await next.load();
    await _open(tester, _Rig(TileShareMode.class_), displaySettings: next);
    expect(next.density, TiletteDensity.list);
    final card = find.byType(TiletteWorkCard).first;
    expect(
        find.descendant(
            of: card, matching: find.byKey(const Key('tilette_expand'))),
        findsOneWidget);
    expect(
        find.descendant(
            of: card, matching: find.byKey(const Key('tilette_footer'))),
        findsNothing);
    await tapVisible(
        tester,
        find.descendant(
            of: card, matching: find.byKey(const Key('tilette_expand'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task_menu_tpl-d0')), findsOneWidget);
  });

  testWidgets('Compact bulk decline is available in the response panel',
      (tester) async {
    final rig = _Rig(TileShareMode.class_, owner: false);
    await _open(tester, rig);
    expect(
        find.byKey(const Key('commitment_invitation_panel')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('commitment_decline')));
    await tester.pumpAndSettle();
    expect(rig.assignments.calls, contains('respond(d0, declined)'));
    expect(rig.assignments.calls, isNot(contains('respond(d1, declined)')));
  });

  testWidgets('all densities fit small phones with large text in both themes',
      (tester) async {
    for (final density in TiletteDensity.values) {
      for (final mode in [TileShareMode.class_, TileShareMode.project]) {
        for (final owner in [true, false]) {
          for (final dark in [true, false]) {
            await tester.pumpWidget(const SizedBox());
            await _open(tester, _Rig(mode, owner: owner),
                density: density,
                dark: dark,
                size: const Size(320, 700),
                textScale: 1.6);
            expect(tester.takeException(), isNull,
                reason: '$density $mode owner=$owner dark=$dark');
            if (density == TiletteDensity.list) {
              await tapVisible(
                  tester, find.byKey(const Key('tilette_expand')).first);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    }
  });

  testWidgets('the full summary becomes a strip after scrolling',
      (tester) async {
    final settings =
        TileShareDisplaySettings.memory(density: TiletteDensity.comfortable);
    addTearDown(settings.dispose);
    await _open(tester, _Rig(TileShareMode.class_), displaySettings: settings);
    expect(settings.condensedSummary, isFalse);
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(settings.condensedSummary, isTrue);
    expect(find.byKey(const Key('share_summary_strip')), findsOneWidget);
  });

  test('work filters require accepted work and ignore unknown completion', () {
    expect(shareCompletion(double.nan), isNull);
    expect(
        matchesShareWorkFilter(
            ShareWorkFilter.completed, [(InvitationStatus.none, 100)]),
        isFalse);
    expect(
        matchesShareWorkFilter(
            ShareWorkFilter.completed, [(InvitationStatus.accepted, null)]),
        isFalse);
    expect(
        matchesShareWorkFilter(
            ShareWorkFilter.inProgress, [(InvitationStatus.accepted, 40)]),
        isTrue);
    expect(matchesShareWorkFilter(ShareWorkFilter.attention, []), isTrue);
  });
}
