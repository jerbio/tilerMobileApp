import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/comments/comments_state.dart';
import 'package:tiler_app/components/comments/comment_composer.dart';
import 'package:tiler_app/components/comments/comments_section.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tiletteDetailScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/tiletteWorkCard.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareDisplayOptions.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'helpers/tap_visible.dart';
import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';

class _Rig {
  final DesignatedTile tile;
  late final TileShareTemplate template;
  late final FakeTileShareAssignmentsSource source;
  late final FakeTileShareNotesApi notes;
  late final FakeTileShareRecipientsSource recipients;
  int peopleChanged = 0;
  int answered = 0, opened = 0, notesChanged = 0, previewed = 0;
  DesignatedTile? previewResult;
  final discussionIds = <String>[];

  _Rig({InvitationStatus status = InvitationStatus.none})
      : tile = tsDesignatedTile('assignment',
            clusterId: 'share',
            name: 'Review launch copy',
            durationMs: 45 * 60000,
            endMs: DateTime(2026, 11, 6).millisecondsSinceEpoch,
            status: status,
            completion: status == InvitationStatus.accepted ? 40 : null) {
    template = TileShareTemplate.fromJson({
      'id': 'tpl-assignment',
      'clusterId': 'share',
      'name': tile.name,
      'duration': 45 * 60000,
      'end': tile.tileTemplate!.end,
      'miscData': {
        'userNote': '## Review checklist\n\nConfirm the launch message.\n\n'
            '- [ ] Verify hero headline\n- [x] Check primary CTA\n- [ ] Review supporting copy\n\n'
            '## References\n\n[Launch brief](https://example.com/brief)'
      },
      'designatedUsers': [
        {
          'designatedTileTemplateId': 'assignment',
          'userId': 'me',
          'rsvpStatus': status.name,
          'userProfile': {'id': 'me', 'fullName': 'Glory O.'}
        }
      ],
    });
    source = FakeTileShareAssignmentsSource([tile]);
    recipients =
        FakeTileShareRecipientsSource(tilettes: {template.id!: template});
    notes =
        FakeTileShareNotesApi(FakeTileShareClustersSource(tilettesByCluster: {
      'share': [template]
    }));
  }

  List<String> get responses =>
      source.calls.where((c) => c.startsWith('respond')).toList();
}

Future<void> _open(WidgetTester tester, _Rig rig,
    {bool dark = true,
    bool canRespond = true,
    bool canEdit = false,
    bool canManagePeople = false,
    bool preview = true,
    bool omitEmbeddedNote = false,
    bool settle = true,
    WidgetBuilder? discussionBody,
    TileShareMode mode = TileShareMode.project,
    TiletteDetailTab initialTab = TiletteDetailTab.overview,
    Size size = const Size(390, 844),
    double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(RepaintBoundary(
      key: const Key('detail_preview'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          FlutterQuillLocalizations.delegate
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: TiletteDetailScreen(
          designatedTile: rig.tile,
          initialTab: initialTab,
          options: TiletteDetailOptions(
              shareName: 'Launch Readiness',
              mode: mode,
              template: omitEmbeddedNote
                  ? TileShareTemplate.fromJson({
                      'id': rig.template.id,
                      'name': rig.template.name,
                      'duration': rig.template.durationInMs,
                      'end': rig.template.end,
                    })
                  : rig.template,
              assignments: rig.source,
              canRespond: canRespond,
              notesApi: canEdit ? rig.notes : null,
              notesReadApi: rig.notes,
              onNotesChanged: () => rig.notesChanged++,
              ownerRecipients: canManagePeople ? rig.recipients : null,
              ownerTilettes: [rig.template],
              onPeopleChanged: () => rig.peopleChanged++,
              onAnswered: () => rig.answered++,
              onOpenTile: () => rig.opened++,
              onPreview: preview
                  ? () async {
                      rig.previewed++;
                      return rig.previewResult;
                    }
                  : null,
              discussionBuilder: (context, id) {
                rig.discussionIds.add(id);
                if (discussionBody != null) return discussionBody(context);
                return Column(children: [
                  const Expanded(
                      child: SingleChildScrollView(
                          child: Text('Shared discussion'))),
                  TextField(
                      decoration:
                          const InputDecoration(labelText: 'Add a comment')),
                ]);
              }),
        ),
      )));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('TILESHARE_PREVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('detail_preview')));
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

  testWidgets('owners add people from detail without replacing existing people',
      (tester) async {
    for (final mode in [TileShareMode.project, TileShareMode.class_]) {
      final rig = _Rig();
      await _open(tester, rig,
          mode: mode, canRespond: false, canManagePeople: true);
      expect(rig.recipients.calls, isEmpty,
          reason: 'uses the share roster already loaded');
      await tapVisible(tester, find.byKey(const Key('tilette_add_person')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('project_assign_sheet')),
              matching: find.byType(TextField)),
          'new@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('new@x.com'), findsOneWidget);
      expect(find.text('Glory O.'), findsOneWidget);
      expect(rig.recipients.calls, ['addRecipient(tpl-assignment, new@x.com)']);
      expect(rig.peopleChanged, 1);
      expect(rig.notes.calls, isEmpty);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('unassigned detail adds the first person and can retry failure',
      (tester) async {
    final rig = _Rig();
    rig.template.designatedUsers = [];
    await _open(tester, rig, canRespond: false, canManagePeople: true);
    await tapVisible(tester, find.byKey(const Key('tilette_add_person')));
    await tester.pumpAndSettle();
    rig.recipients.failNext(StateError('offline'));
    await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('project_assign_sheet')),
            matching: find.byType(TextField)),
        'first@x.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('first@x.com'), findsNothing);
    expect(rig.peopleChanged, 0);
    expect(find.byKey(const Key('tilette_assign_retry')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('tilette_assign_retry')));
    await tester.pumpAndSettle();
    expect(find.text('first@x.com'), findsOneWidget);
    expect(find.byKey(const Key('tilette_assign_retry')), findsNothing);
    expect(rig.peopleChanged, 1);
  });

  testWidgets(
      'read-only details cannot assign and picker cancellation sends nothing',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    expect(find.byKey(const Key('tilette_add_person')), findsNothing);
    await _open(tester, rig, canRespond: false, canManagePeople: true);
    await tapVisible(tester, find.byKey(const Key('tilette_add_person')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(const Key('project_assign_sheet'))))
        .pop();
    await tester.pumpAndSettle();
    expect(rig.recipients.calls, isEmpty);
    expect(rig.peopleChanged, 0);
  });

  testWidgets('owner assignment remains usable on narrow screens while saving',
      (tester) async {
    for (final dark in [false, true]) {
      final rig = _Rig();
      rig.template.designatedUsers = [];
      await _open(tester, rig,
          canRespond: false,
          canManagePeople: true,
          dark: dark,
          size: const Size(320, 700),
          scale: 1.6);
      await tapVisible(tester, find.byKey(const Key('tilette_add_person')));
      await tester.pumpAndSettle();
      rig.recipients.hold();
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('project_assign_sheet')),
              matching: find.byType(TextField)),
          'first@x.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      final button = tester
          .widget<TextButton>(find.byKey(const Key('tilette_add_person')));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      rig.recipients.release();
      await tester.pumpAndSettle();
      expect(find.text('first@x.com'), findsOneWidget);
      expect(rig.peopleChanged, 1);
    }
  });

  testWidgets('comments composer stays above the home indicator and keyboard',
      (tester) async {
    for (final dark in [false, true]) {
      final bloc = CommentsBloc(
          targetType: 'tileshare_tilette',
          targetId: 'tpl-assignment',
          getContextCallBack: null);
      addTearDown(bloc.close);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewInsets = const FakeViewPadding();
      final rig = _Rig();
      await _open(tester, rig,
          dark: dark,
          canRespond: false,
          initialTab: TiletteDetailTab.comments,
          discussionBody: (_) => BlocProvider.value(
              value: bloc, child: CommentsSection(onToast: (_) {})));
      final composer = find.byType(CommentComposer);
      expect(tester.getRect(composer).bottom, closeTo(844 - 34, 1));
      expect(
          tester.getRect(find.text('0/2000')).bottom, lessThanOrEqualTo(810));
      await tester.tap(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = const FakeViewPadding(top: 47);
      await tester.pumpAndSettle();
      expect(tester.getRect(composer).bottom, closeTo(844 - 300, 1));
      expect(
          tester.getRect(find.text('0/2000')).bottom, lessThanOrEqualTo(544));
      await tester.enterText(find.byType(TextField), 'A comment draft');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      await tester.pumpAndSettle();
      expect(tester.getRect(composer).bottom, closeTo(810, 1));
    }
  });

  testWidgets('response dock consumes the bottom inset only once',
      (tester) async {
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    final rig = _Rig(status: InvitationStatus.accepted);
    await _open(tester, rig, initialTab: TiletteDetailTab.comments);
    final footer = find.byKey(const Key('tilette_invitation_footer'));
    final open = find.byKey(const Key('tilette_open_tile'));
    expect(tester.getRect(footer).bottom, 844);
    expect(tester.getRect(open).bottom, closeTo(810, 1));
    final field = find.byType(TextField);
    expect(
        tester.getRect(field).bottom, closeTo(tester.getRect(footer).top, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Class overview stays compact and Notes loads once when opened',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig,
        canRespond: false,
        canEdit: true,
        mode: TileShareMode.class_,
        omitEmbeddedNote: true);
    expect(rig.notes.calls, isEmpty);
    expect(find.text('No notes have been added yet.'), findsNothing);
    expect(find.text('Review checklist'), findsNothing);
    expect(find.byKey(const Key('tilette_read_notes')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('tilette_tab_notes')));
    await tester.pumpAndSettle();
    expect(find.text('Review checklist'), findsOneWidget);
    expect(find.text('Launch brief'), findsOneWidget);
    expect(rig.notes.calls.length, 1,
        reason: 'tab changes reuse the loaded note');
    await tapVisible(tester, find.byKey(const Key('tilette_tab_overview')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('tilette_read_notes')));
    await tester.pumpAndSettle();
    expect(rig.notes.calls.length, 1);
  });

  testWidgets('recipients read saved notes without getting edit permissions',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig,
        omitEmbeddedNote: true, initialTab: TiletteDetailTab.notes);
    expect(find.text('Review checklist'), findsOneWidget);
    expect(find.byKey(const Key('tilette_edit_notes')), findsNothing);
    expect(rig.notes.calls, ['get(tpl-assignment)']);
  });

  testWidgets('loading and failed reads never claim the note is empty',
      (tester) async {
    final rig = _Rig();
    rig.notes.hold();
    rig.notes.failNext(StateError('offline'));
    await _open(tester, rig,
        omitEmbeddedNote: true,
        settle: false,
        initialTab: TiletteDetailTab.notes);
    expect(find.byKey(const Key('tilette_notes_loading')), findsOneWidget);
    expect(find.text('No notes have been added yet.'), findsNothing);
    rig.notes.release();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tilette_notes_failed')), findsOneWidget);
    expect(find.text('No notes have been added yet.'), findsNothing);
    await tapVisible(tester, find.byKey(const Key('tilette_notes_retry')));
    await tester.pumpAndSettle();
    expect(find.text('Review checklist'), findsOneWidget);
    expect(find.byKey(const Key('tilette_notes_failed')), findsNothing);
    expect(rig.notes.calls, ['get(tpl-assignment)', 'get(tpl-assignment)']);
  });

  testWidgets('only a successful empty response shows the empty-note message',
      (tester) async {
    final rig = _Rig();
    rig.notes.store('tpl-assignment', '');
    await _open(tester, rig,
        omitEmbeddedNote: true, initialTab: TiletteDetailTab.notes);
    expect(find.text('No notes have been added yet.'), findsOneWidget);
    expect(find.byKey(const Key('tilette_notes_failed')), findsNothing);
  });

  testWidgets('closing a tilette while notes load is safe', (tester) async {
    final rig = _Rig();
    rig.notes.hold();
    await _open(tester, rig,
        omitEmbeddedNote: true,
        settle: false,
        initialTab: TiletteDetailTab.notes);
    await tester.pumpWidget(const SizedBox());
    rig.notes.release();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'comments and Overview do not fetch notes; reopening gets fresh notes',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig, initialTab: TiletteDetailTab.comments);
    expect(rig.notes.calls, isEmpty);
    await tapVisible(tester, find.byKey(const Key('tilette_tab_overview')));
    await tester.pumpAndSettle();
    expect(rig.notes.calls, isEmpty);
    await tapVisible(tester, find.byKey(const Key('tilette_read_notes')));
    await tester.pumpAndSettle();
    expect(rig.notes.calls.length, 1);
    rig.notes.store('tpl-assignment', 'A newer shared note');
    await _open(tester, rig, initialTab: TiletteDetailTab.notes);
    expect(rig.notes.calls.length, 2);
    expect(find.text('A newer shared note'), findsOneWidget);
  });

  testWidgets('viewing the editor reuses notes without refreshing the share',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig, canEdit: true, initialTab: TiletteDetailTab.notes);
    for (var visit = 0; visit < 2; visit++) {
      await tapVisible(tester, find.byKey(const Key('tilette_edit_notes')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(rig.notes.calls, ['get(tpl-assignment)']);
    expect(rig.notesChanged, 0);
  });

  testWidgets('Check fit previews each mode without accepting on cancel',
      (tester) async {
    for (final mode in TileShareMode.values) {
      final rig = _Rig();
      await _open(tester, rig, mode: mode);
      await tester.tap(find.byKey(const Key('tilette_check_fit')));
      await tester.pumpAndSettle();
      expect(rig.previewed, 1);
      expect(rig.responses, isEmpty);
      expect(find.byKey(const Key('tilette_accept')), findsOneWidget);
    }
  });

  testWidgets('returning after preview acceptance updates the detail actions',
      (tester) async {
    final rig = _Rig();
    rig.previewResult = _Rig(status: InvitationStatus.accepted).tile;
    await _open(tester, rig);
    await tester.tap(find.byKey(const Key('tilette_check_fit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tilette_check_fit')), findsNothing);
    expect(find.byKey(const Key('tilette_accept')), findsNothing);
    expect(find.byKey(const Key('tilette_open_tile')), findsOneWidget);
    expect(rig.responses, isEmpty, reason: 'never sends a second response');
  });

  testWidgets(
      'preview is hidden without permission, callback or after acceptance',
      (tester) async {
    await _open(tester, _Rig(status: InvitationStatus.accepted));
    expect(find.byKey(const Key('tilette_check_fit')), findsNothing);
    await _open(tester, _Rig(), canRespond: false);
    expect(find.byKey(const Key('tilette_check_fit')), findsNothing);
    await _open(tester, _Rig(), preview: false);
    expect(find.byKey(const Key('tilette_check_fit')), findsNothing);
  });

  testWidgets(
      'overview gives the tilette context and keeps the response docked across tabs',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    expect(find.text('Launch Readiness'), findsOneWidget);
    expect(find.text('Review launch copy'), findsOneWidget);
    expect(find.text('TILETTE · PROJECT'), findsOneWidget);
    expect(find.text('Glory O.'), findsOneWidget);
    expect(rig.discussionIds, isEmpty,
        reason: 'discussion loads only when opened');
    final footer = find.byKey(const Key('tilette_invitation_footer'));
    final footerRect = tester.getRect(footer);
    expect(footerRect.bottom, 844);
    await _preview(tester, 'tilette-invitation');
    await tapVisible(tester, find.byKey(const Key('tilette_tab_notes')));
    await tester.pumpAndSettle();
    expect(find.text('Review checklist'), findsOneWidget);
    expect(tester.getRect(footer), footerRect);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(tester.getRect(footer), footerRect);
    await tapVisible(tester, find.byKey(const Key('tilette_tab_comments')));
    await tester.pumpAndSettle();
    expect(rig.discussionIds.last, 'tpl-assignment');
    expect(tester.getRect(footer), footerRect);
    await tester.tap(find.byKey(const Key('tilette_decline')));
    await tester.pumpAndSettle();
    expect(rig.responses, ['respond(assignment, declined)']);
    expect(rig.answered, 1);
    expect(find.byKey(const Key('tilette_accept')), findsOneWidget);
    expect(find.byKey(const Key('tilette_decline')), findsNothing);
    await tester.tap(find.byKey(const Key('tilette_accept')));
    await tester.pumpAndSettle();
    expect(rig.responses,
        ['respond(assignment, declined)', 'respond(assignment, accepted)']);
    expect(find.byKey(const Key('tilette_open_tile')), findsOneWidget);
  });

  testWidgets('declined tilettes can be previewed and accepted in every mode',
      (tester) async {
    for (final mode in TileShareMode.values) {
      final rig = _Rig(status: InvitationStatus.declined);
      await _open(tester, rig, mode: mode);
      expect(find.text('You declined this tilette. You can still accept it.'),
          findsOneWidget);
      expect(find.byKey(const Key('tilette_decline')), findsNothing);
      await tester.tap(find.byKey(const Key('tilette_check_fit')));
      await tester.pumpAndSettle();
      expect(rig.previewed, 1);
      expect(rig.responses, isEmpty);
      await tester.tap(find.byKey(const Key('tilette_accept')));
      await tester.pumpAndSettle();
      expect(rig.responses, ['respond(assignment, accepted)']);
      expect(rig.source.calls.where((c) => c == 'afterAccept()'), hasLength(1));
      expect(find.byKey(const Key('tilette_open_tile')), findsOneWidget);
    }
  });

  testWidgets(
      'accepted tilettes can be declined and accepted again in every mode',
      (tester) async {
    for (final mode in TileShareMode.values) {
      final rig = _Rig(status: InvitationStatus.accepted);
      await _open(tester, rig, mode: mode);
      await tester.tap(find.byKey(const Key('tilette_decline')));
      await tester.pumpAndSettle();
      expect(rig.responses, ['respond(assignment, declined)']);
      expect(
          rig.source.calls.where((c) => c == 'afterDecline()'), hasLength(1));
      expect(find.byKey(const Key('tilette_open_tile')), findsNothing);
      expect(find.byKey(const Key('tilette_accept')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tilette_accept')));
      await tester.pumpAndSettle();
      expect(rig.responses,
          ['respond(assignment, declined)', 'respond(assignment, accepted)']);
      expect(find.byKey(const Key('tilette_decline')), findsOneWidget);
      expect(find.byKey(const Key('tilette_open_tile')), findsOneWidget);
    }
  });

  testWidgets(
      'failed decline keeps acceptance, disables duplicate sends and retries',
      (tester) async {
    final rig = _Rig(status: InvitationStatus.accepted);
    await _open(tester, rig, size: const Size(320, 700), scale: 1.6);
    rig.source.hold();
    rig.source.failNextOn('respond', StateError('offline'));
    await tester.tap(find.byKey(const Key('tilette_decline')));
    await tester.pump();
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('tilette_decline')))
            .onPressed,
        isNull);
    rig.source.release();
    await tester.pumpAndSettle();
    expect(rig.tile.invitationStatus, 'accepted');
    expect(find.byKey(const Key('tilette_open_tile')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tilette_response_retry')));
    await tester.pumpAndSettle();
    expect(rig.tile.invitationStatus, 'declined');
    expect(tester.takeException(), isNull);
  });

  testWidgets('withdrawal schedule refresh failure does not report acceptance',
      (tester) async {
    final rig = _Rig(status: InvitationStatus.accepted);
    await _open(tester, rig);
    rig.source.failNextOn('afterDecline', StateError('offline'));
    await tester.tap(find.byKey(const Key('tilette_decline')));
    await tester.pumpAndSettle();
    expect(find.text('Declined, but your schedule couldn’t refresh yet.'),
        findsOneWidget);
    expect(rig.tile.invitationStatus, 'declined');
    expect(find.byKey(const Key('tilette_open_tile')), findsNothing);
  });

  testWidgets('failed reconsideration keeps the declined response and retries',
      (tester) async {
    final rig = _Rig(status: InvitationStatus.declined);
    await _open(tester, rig, size: const Size(320, 700), scale: 1.6);
    rig.source.failNextOn('respond', StateError('offline'));
    await tester.tap(find.byKey(const Key('tilette_accept')));
    await tester.pumpAndSettle();
    expect(rig.tile.invitationStatus, 'declined');
    expect(find.byKey(const Key('tilette_accept')), findsOneWidget);
    expect(find.byKey(const Key('tilette_open_tile')), findsNothing);
    await tester.tap(find.byKey(const Key('tilette_response_retry')));
    await tester.pumpAndSettle();
    expect(rig.tile.invitationStatus, 'accepted');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'accept cannot submit twice and opens the scheduled tile after accepting',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    rig.source.hold();
    await tester.tap(find.byKey(const Key('tilette_accept')));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tilette_accept')))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('tilette_decline')))
            .onPressed,
        isNull);
    rig.source.release();
    await tester.pumpAndSettle();
    expect(rig.responses, ['respond(assignment, accepted)']);
    expect(rig.source.calls.where((c) => c == 'afterAccept()'), hasLength(1));
    expect(rig.answered, 1);
    await tester.tap(find.byKey(const Key('tilette_open_tile')));
    expect(rig.opened, 1);
  });

  testWidgets('response failure retries in the dock without hiding the task',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    rig.source.failNextOn('respond', StateError('offline'));
    await tester.tap(find.byKey(const Key('tilette_accept')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tilette_response_retry')), findsOneWidget);
    expect(find.byKey(const Key('tilette_detail_title')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tilette_response_retry')));
    await tester.pumpAndSettle();
    expect(rig.responses,
        ['respond(assignment, accepted)', 'respond(assignment, accepted)']);
    expect(rig.answered, 1);
  });

  testWidgets('a schedule refresh failure remains separate from acceptance',
      (tester) async {
    final rig = _Rig();
    await _open(tester, rig);
    rig.source.failNextOn('afterAccept', StateError('offline'));
    await tester.tap(find.byKey(const Key('tilette_accept')));
    await tester.pumpAndSettle();
    expect(find.text('Accepted, but your schedule couldn’t refresh yet.'),
        findsOneWidget);
    expect(find.byKey(const Key('tilette_accept')), findsNothing);
    expect(find.byKey(const Key('tilette_open_tile')), findsOneWidget);
  });

  testWidgets('ownership permission gates response and notes editing',
      (tester) async {
    final rig = _Rig(status: InvitationStatus.accepted);
    await _open(tester, rig,
        canRespond: false, canEdit: true, initialTab: TiletteDetailTab.notes);
    expect(find.byKey(const Key('tilette_invitation_footer')), findsNothing);
    expect(find.byKey(const Key('tilette_edit_notes')), findsOneWidget);
    await _preview(tester, 'tilette-notes-detail');
    await tapVisible(tester, find.byKey(const Key('tilette_edit_notes')));
    await tester.pumpAndSettle();
    expect(rig.notes.calls, ['get(tpl-assignment)']);
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    final controller =
        tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;
    controller.replaceText(0, controller.document.length - 1,
        'Updated launch notes', const TextSelection.collapsed(offset: 20));
    await tester.pump();
    await tapVisible(tester, find.text('Save now'));
    await tester.pumpAndSettle();
    expect(
        rig.notes.calls.any(
            (c) => c.startsWith('put(tpl-assignment, Updated launch notes')),
        isTrue);
    expect(rig.notes.calls.where((c) => c.startsWith('get')).length, 1);
    expect(rig.notesChanged, 1, reason: 'one share refresh after actual saves');
    await tester.pump(const Duration(seconds: 1));
    await _open(tester, rig,
        canRespond: false, canEdit: false, initialTab: TiletteDetailTab.notes);
    expect(find.byKey(const Key('tilette_edit_notes')), findsNothing);
    expect(find.byKey(const Key('tilette_accept')), findsNothing);
  });

  testWidgets(
      'detail and action dock fit narrow phones in both themes with large text',
      (tester) async {
    for (final dark in [true, false]) {
      final rig = _Rig();
      await _open(tester, rig,
          dark: dark, size: const Size(320, 700), scale: 1.6);
      for (final key in [
        'tilette_tab_notes',
        'tilette_tab_comments',
        'tilette_tab_overview'
      ]) {
        await tapVisible(tester, find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byKey(const Key('tilette_accept'))).bottom,
            lessThanOrEqualTo(700));
      }
    }
  });

  testWidgets('compact action footer stays on one line and scrolls to comments',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [390.0, 320.0]) {
      for (final dark in [false, true]) {
        tester.view.physicalSize = Size(width, 844);
        var previews = 0, reviews = 0, comments = 0, opened = 0;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(MaterialApp(
            theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(width == 320 ? 1.6 : 1)),
                child: child!),
            home: Scaffold(
                body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TiletteWorkCard(
                        title: 'Rum ulus',
                        onOpen: () => opened++,
                        onNotes: () {},
                        onComments: () => comments++,
                        notesKey: const Key('footer_notes'),
                        commentsKey: const Key('footer_comments'),
                        actions: [
                          TextButton.icon(
                              key: const Key('footer_fit'),
                              onPressed: () => previews++,
                              icon:
                                  const Icon(Icons.calendar_view_day_outlined),
                              label: const Text('Check fit')),
                          FilledButton.icon(
                              key: const Key('footer_review'),
                              onPressed: () => reviews++,
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Review request')),
                        ])))));
        await tester.pumpAndSettle();
        final fit = find.byKey(const Key('footer_fit'));
        final footer = find.byKey(const Key('tilette_footer'));
        final center = tester.getCenter(fit).dy;
        for (final key in [
          'footer_review',
          'footer_notes',
          'footer_comments'
        ]) {
          expect(tester.getCenter(find.byKey(Key(key))).dy, closeTo(center, 1));
        }
        await tester.tap(fit);
        expect(previews, 1);
        await tester.drag(footer, const Offset(-600, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('footer_comments')));
        expect(comments, 1);
        expect(reviews, 0);
        expect(opened, 0, reason: 'footer actions do not open the card');
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('card taps open details in every density without hijacking notes',
      (tester) async {
    final settings = TileShareDisplaySettings.memory();
    addTearDown(settings.dispose);
    for (final density in TiletteDensity.values) {
      await settings.setDensity(density);
      int opened = 0, notes = 0;
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: TileShareDisplayScope(
                settings: settings,
                child: TiletteWorkCard(
                    title: 'Review copy',
                    onOpen: () => opened++,
                    onNotes: () => notes++))),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review copy'));
      expect(opened, 1);
      if (density != TiletteDensity.list) {
        await tester.tap(find.byTooltip('Notes'));
        expect(notes, 1);
        expect(opened, 1);
      }
    }
  });
}
