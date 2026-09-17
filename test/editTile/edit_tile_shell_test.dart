// Step 1.4 — the shell: header, hero, Title, Timing, pinned Save.
//
// The first visible slice of the redesign, behind a debug route. What is
// pinned here is behaviour the legacy screen either lacked or got wrong:
//
//   * a load has THREE states — skeleton, frame, failure with Retry — where
//     legacy had a spinner and no failure branch;
//   * Save exists iff the draft can be saved, and when it cannot the reason
//     is on screen, not inferred from a missing button;
//   * the form is inert while a save is in flight (Add Tile D50);
//   * failure keeps the draft and offers Retry (D50); success pops;
//   * Back with a dirty draft asks; with a clean one just leaves (D13);
//   * every row is a real button for assistive tech (D62).
//
// Pickers are injected (as the Duration screen's `pickEndTime`) so the tests
// drive them without dialogs; the defaults are the platform pickers (D42)
// and the shared Duration screen with its Ends row (D61).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/theme_data.dart';

import '../addTile/add_tile_widget_harness.dart';
import '../addTile/l10n_fixture.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

// English regardless of the generated list's order (it gained de/el/…
// ahead of en on 2026-09-17).
Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    requested ?? const Locale('en');

final DateTime start = DateTime(2026, 9, 12, 14, 0);
final DateTime end = DateTime(2026, 9, 12, 15, 30);

SubCalendarEvent loaded(
        {bool isRigid = false, bool isComplete = false, String? note}) =>
    SubCalendarEvent.fromJson(<String, dynamic>{
      'id': 'sub-1',
      'name': 'Write report',
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'calendarEventStart': start.millisecondsSinceEpoch,
      'calendarEventEnd': end.millisecondsSinceEpoch,
      'splitCount': 1,
      'thirdPartyType': 'tiler',
      'isRigid': isRigid,
      'isComplete': isComplete,
      'priority': 'medium',
      // Notes arrive under `blob` on the wire (TilerEvent.fromJson), and
      // the key must be ABSENT rather than null: the parser checks
      // `containsKey` only and would throw on a null blob.
      if (note != null) 'blob': <String, dynamic>{'note': note},
    });

class FakeLoader implements EditTileLoader {
  FakeLoader(this.result);
  EditTileLoadResult result;
  int calls = 0;
  Completer<EditTileLoadResult>? gate;

  @override
  Future<EditTileLoadResult> load(String tileId,
      {String? source, String? thirdPartyUserId}) async {
    calls++;
    if (gate != null) return gate!.future;
    return result;
  }
}

class FakeSubmission implements EditTileSubmission {
  final List<EditTileDraft> saved = <EditTileDraft>[];
  EditTileSaveResult answer = const EditTileSaveResult.success(null);
  Completer<EditTileSaveResult>? gate;

  @override
  Future<EditTileSaveResult> save(EditTileDraft draft) async {
    saved.add(draft);
    if (gate != null) return gate!.future;
    return answer;
  }

  /// Every non-save call, in order, as 'kind:tileId[:extra]'.
  final List<String> actions = <String>[];
  EditTileSaveResult actionAnswer = const EditTileSaveResult.success(null);

  Future<EditTileSaveResult> _record(String call) async {
    actions.add(call);
    return actionAnswer;
  }

  @override
  Future<EditTileSaveResult> rsvp(EditTileDraft draft, RsvpStatus status) =>
      _record('rsvp:${draft.id}:${status.name}');
  @override
  Future<EditTileSaveResult> complete(SubCalendarEvent tile) =>
      _record('complete:${tile.id}');
  @override
  Future<EditTileSaveResult> startNow(SubCalendarEvent tile) =>
      _record('startNow:${tile.id}');
  @override
  Future<EditTileSaveResult> delete(SubCalendarEvent tile) =>
      _record('delete:${tile.id}');
  @override
  Future<EditTileSaveResult> defer(SubCalendarEvent tile, Duration by) =>
      _record('defer:${tile.id}:${by.inMinutes}');

  /// What-if: every draft previewed, in order; answered by [previewAnswer]
  /// or, when set, by the next gate in [previewGates] (for stale-result
  /// tests that need two calls in flight).
  final List<EditTileDraft> previews = <EditTileDraft>[];
  WhatIfResult? previewAnswer;
  List<Completer<WhatIfResult?>> previewGates = <Completer<WhatIfResult?>>[];

  @override
  Future<WhatIfResult?> preview(EditTileDraft draft) async {
    previews.add(draft);
    if (previewGates.isNotEmpty) return previewGates.removeAt(0).future;
    return previewAnswer;
  }
}

/// Picker seams: what they were opened with, and what they answer.
DateTime? pickedDateSeed;
DateTime? pickedDateAnswer;
TimeOfDay? pickedTimeSeed;
TimeOfDay? pickedTimeAnswer;
Duration? pickedDurationSeed;
DateTime? pickedDurationStart;
Duration? pickedDurationAnswer;

late FakeLoader loader;
late FakeSubmission submission;
final List<RouteSettings> pushedRoutes = <RouteSettings>[];

/// Hosts the screen under a real Navigator so pops are observable.
Future<void> pumpEdit(
  WidgetTester tester, {
  SubCalendarEvent? tile,
  EditTileLoadResult? loadResult,
  Size viewSize = AddTileTestMatrix.standard,
  EditTileOpenSeries? openSeries,
  double textScale = 1.0,
  bool dark = false,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  pickedDateSeed = pickedDateAnswer = null;
  pickedTimeSeed = pickedTimeAnswer = null;
  pickedDurationSeed = pickedDurationAnswer = null;
  pickedDurationStart = null;
  pushedRoutes.clear();
  loader = FakeLoader(loadResult ??
      EditTileLoadResult.success(
          tile ?? loaded(), const <NextTileSuggestion>[]));
  submission = FakeSubmission();

  await tester.pumpWidget(MaterialApp(
    // A fresh app per pump: without the key a second pump in one test keeps
    // the old Navigator, with the previous edit screen still pushed.
    key: UniqueKey(),
    theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // Named pushes (the suggestion hand-off) land on a placeholder and are
    // recorded, so a test can assert the route and its arguments.
    onGenerateRoute: (RouteSettings settings) {
      pushedRoutes.add(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: Placeholder()),
      );
    },
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: const ValueKey('open'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => EditTileRedesignScreen(
                tileId: 'sub-1',
                loader: loader,
                submission: submission,
                pickDate: (_, DateTime seed) async {
                  pickedDateSeed = seed;
                  return pickedDateAnswer;
                },
                pickTime: (_, TimeOfDay seed) async {
                  pickedTimeSeed = seed;
                  return pickedTimeAnswer;
                },
                pickDuration: (_, Duration seed, DateTime? startTime) async {
                  pickedDurationSeed = seed;
                  pickedDurationStart = startTime;
                  return pickedDurationAnswer;
                },
                openSeries: openSeries ?? (_, __) async {},
              ),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

Finder get screen => find.byType(EditTileRedesignScreen);
Finder get titleField => find.byKey(const ValueKey('editTitleField'));
Finder get save => find.byKey(const ValueKey('editTileSave'));
Finder get startTime => find.byKey(const ValueKey('editStartTime'));
Finder get startDate => find.byKey(const ValueKey('editStartDate'));
Finder get endTime => find.byKey(const ValueKey('editEndTime'));
Finder get endDate => find.byKey(const ValueKey('editEndDate'));
Finder get startRow => find.byKey(const ValueKey('editStartRow'));
Finder get durationRow => find.byKey(const ValueKey('editDurationRow'));
Finder get endRow => find.byKey(const ValueKey('editEndRow'));

EditTileDraft draftOf(WidgetTester tester) =>
    tester.state<EditTileRedesignScreenState>(screen).draft!;

String norm(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  group('Load', () {
    testWidgets('a skeleton while loading, the frame once loaded',
        (tester) async {
      await pumpEdit(tester);
      // Re-open with a gated loader to catch the in-between.
      loader.gate = Completer<EditTileLoadResult>();
      await tester.tap(find.byKey(const ValueKey('editTileClose')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open')));
      // The pushed route is offstage on its first frame; let the transition
      // start, but do NOT settle — the loader is gated.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The CARDS shimmer (2026-09-17): one sweep per card silhouette, each
      // the size of its card, and none the size of the screen.
      final Iterable<Element> sweeps =
          find.byType(AddTilePendingSweep).evaluate();
      expect(sweeps.length, 3,
          reason: 'the skeleton sweeps (D63) rather than spinning');
      final Size screen = tester.getSize(find.byType(Scaffold).last);
      for (final Element e in sweeps) {
        final Size size = (e.renderObject as RenderBox).size;
        expect(size.width, lessThan(screen.width),
            reason: 'inset by the card padding, not full-bleed');
        expect(size.height, lessThan(screen.height / 2));
      }
      expect(titleField, findsNothing);

      loader.gate!.complete(
          EditTileLoadResult.success(loaded(), const <NextTileSuggestion>[]));
      await tester.pumpAndSettle();
      expect(find.byType(AddTilePendingSweep), findsNothing);
      expect(titleField, findsOneWidget);
    });

    testWidgets('a failure says so and Retry loads again', (tester) async {
      await pumpEdit(tester,
          loadResult:
              const EditTileLoadResult.failure(editTileFailureApiRejected));
      expect(find.text(testL10n.editTileLoadFailed), findsOneWidget);
      expect(find.byKey(const ValueKey('editTileClose')), findsOneWidget,
          reason: 'Close is always available');

      loader.result =
          EditTileLoadResult.success(loaded(), const <NextTileSuggestion>[]);
      await tester.tap(find.byKey(const ValueKey('editTileRetryLoad')));
      await tester.pumpAndSettle();
      expect(loader.calls, 2);
      expect(titleField, findsOneWidget);
    });
  });

  group('Header and hero', () {
    testWidgets('a flexible tile is "Edit Tile" with its type chip',
        (tester) async {
      await pumpEdit(tester);
      expect(find.text(testL10n.editTileTitleTile), findsOneWidget);
      // Once, in the hero chip: the Type row under the title was removed as
      // tautological (user, 2026-09-15).
      expect(find.text(testL10n.addTileTypeFlexible), findsOneWidget);
      expect(find.text('Write report'), findsWidgets);
    });

    testWidgets('a block is "Edit Block"', (tester) async {
      await pumpEdit(tester, tile: loaded(isRigid: true));
      expect(find.text(testL10n.editTileTitleBlock), findsOneWidget);
      expect(find.text(testL10n.addTileTypeFixed), findsOneWidget);
    });

    testWidgets(
        'the hero owns the title editor: a pencil to its left focuses it, and '
        'there is no Title row below (2026-09-15)', (tester) async {
      await pumpEdit(tester);
      expect(find.byKey(const ValueKey('editHero')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('editHero')), matching: titleField),
          findsOneWidget,
          reason: 'the editable title IS the hero title');
      expect(find.byType(AddTileTextFieldRow), findsNothing,
          reason: 'no TITLE row: it repeated the hero');
      final Finder pencil = find.byKey(const ValueKey('editTitlePencil'));
      expect(pencil, findsOneWidget);
      expect(tester.getRect(pencil).right,
          lessThanOrEqualTo(tester.getRect(titleField).left + 1),
          reason: 'pencil to the LEFT of the title');
      expect(tester.widget<TextField>(titleField).focusNode!.hasFocus, isFalse);
      await tester.tap(pencil);
      await tester.pump();
      expect(tester.widget<TextField>(titleField).focusNode!.hasFocus, isTrue);
      await tester.enterText(titleField, 'Write REPORT');
      await tester.pump();
      expect(draftOf(tester).name, 'Write REPORT');
      expect(find.text('Write REPORT'), findsOneWidget,
          reason: 'the title is rendered once');
    });

    testWidgets('the pencil is a labelled button', (tester) async {
      await pumpEdit(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester.getSemantics(find.byKey(const ValueKey('editTitlePencil'))),
          matchesSemantics(
              // D62 shape: the tap lives on the node, the IconButton is
              // excluded, so no focus action — as every kit row.
              isButton: true,
              hasTapAction: true,
              label: testL10n.editTileEditTitle));
      h.dispose();
    });

    testWidgets('a locked tile shows the title as text, with no pencil',
        (tester) async {
      await pumpEdit(tester, tile: loaded(isComplete: true));
      expect(titleField, findsNothing);
      expect(find.byKey(const ValueKey('editTitlePencil')), findsNothing);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('editHero')),
              matching: find.byKey(const ValueKey('editTitleLocked'))),
          findsOneWidget);
      expect(find.text('Write report'), findsOneWidget);
    });

    testWidgets('a stored "null" note reads as no note (legacy pollution)',
        (tester) async {
      // The legacy screen sends `Notes: note.toString()` — the string
      // "null" for a tile without a note — so that is what many tiles hold
      // today. Seen on device 2026-09-15 as a literal "null" in the hero
      // and the Notes row.
      await pumpEdit(tester, tile: loaded(note: 'null'));
      expect(find.text('null'), findsNothing);
      await scrollTo(tester, find.byKey(const ValueKey('editNotesRow')));
      expect(find.text(testL10n.addTileValueNotSet), findsOneWidget);
    });

    testWidgets('the notes preview shows when there is a note', (tester) async {
      await pumpEdit(tester, tile: loaded(note: 'bring the charts'));
      expect(find.text('bring the charts'), findsOneWidget);
    });

    testWidgets('the type is displayed in the hero only, never editable (D3)',
        (tester) async {
      await pumpEdit(tester);
      expect(find.byKey(const ValueKey('editTypeRow')), findsNothing);
      final Finder chip = find.text(testL10n.addTileTypeFlexible);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(tester.getSemantics(chip),
          matchesSemantics(isButton: false, hasTapAction: false));
      h.dispose();
    });
  });

  group('Title', () {
    testWidgets('editing the title dirties the draft and enables Save',
        (tester) async {
      await pumpEdit(tester);
      expect(draftOf(tester).canSave, isFalse);
      await tester.enterText(titleField, 'Write REPORT');
      await tester.pump();
      expect(draftOf(tester).name, 'Write REPORT');
      expect(draftOf(tester).canSave, isTrue);
    });

    testWidgets('an empty title names the reason under Save', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(titleField, '');
      await tester.pump();
      await scrollTo(tester, save);
      expect(find.text(testL10n.editTileReasonNameRequired), findsOneWidget);
    });
  });

  group('Timing', () {
    testWidgets('shows start, duration and end from the draft', (tester) async {
      await pumpEdit(tester);
      expect(
          find.textContaining(norm(formatClockTime(start)), findRichText: true),
          findsWidgets);
      expect(find.text(formatDurationSummaryForTest(90)), findsOneWidget);
    });

    testWidgets('Duration opens the wheel with the START and moves the end',
        (tester) async {
      await pumpEdit(tester);
      pickedDurationAnswer = const Duration(hours: 2);
      await scrollTo(tester, durationRow);
      await tester.tap(durationRow);
      await tester.pumpAndSettle();
      expect(pickedDurationSeed, const Duration(minutes: 90));
      expect(pickedDurationStart, start,
          reason: 'the Duration screen renders the Ends row (D61)');
      expect(draftOf(tester).endTime, start.add(const Duration(hours: 2)));
      expect(draftOf(tester).startTime, start, reason: 'start is anchored');
    });

    testWidgets(
        'Ends opens a time picker seeded on the end; an earlier '
        'clock time is the next day', (tester) async {
      await pumpEdit(tester);
      pickedTimeAnswer = const TimeOfDay(hour: 13, minute: 0);
      await scrollTo(tester, endTime);
      await tester.tap(endTime);
      await tester.pumpAndSettle();
      expect(pickedTimeSeed, const TimeOfDay(hour: 15, minute: 30));
      expect(draftOf(tester).endTime, DateTime(2026, 9, 13, 13, 0));
    });

    testWidgets(
        'Starts date opens a date picker seeded on the start and keeps the '
        'clock time and duration (D24)', (tester) async {
      await pumpEdit(tester);
      pickedDateAnswer = DateTime(2026, 9, 14);
      await tester.tap(startDate);
      await tester.pumpAndSettle();
      expect(pickedDateSeed, start);
      expect(pickedTimeSeed, isNull, reason: 'the day alone');
      expect(draftOf(tester).startTime, DateTime(2026, 9, 14, 14, 0));
      expect(draftOf(tester).endTime, DateTime(2026, 9, 14, 15, 30),
          reason: 'moving the start moves the end by the same amount, as '
              'the legacy timeline did');
    });

    testWidgets(
        'Starts time opens a time picker and keeps the day and duration',
        (tester) async {
      await pumpEdit(tester);
      pickedTimeAnswer = const TimeOfDay(hour: 9, minute: 15);
      await tester.tap(startTime);
      await tester.pumpAndSettle();
      expect(pickedTimeSeed, const TimeOfDay(hour: 14, minute: 0));
      expect(pickedDateSeed, isNull, reason: 'no date step on Starts');
      expect(draftOf(tester).startTime, DateTime(2026, 9, 12, 9, 15));
      expect(draftOf(tester).endTime, DateTime(2026, 9, 12, 10, 45));
    });

    testWidgets('dismissing a picker changes nothing', (tester) async {
      await pumpEdit(tester);
      pickedDateAnswer = null;
      await tester.tap(startDate);
      await tester.pumpAndSettle();
      await tester.tap(endDate);
      await tester.pumpAndSettle();
      pickedTimeAnswer = null;
      await tester.tap(startTime);
      await tester.pumpAndSettle();
      await tester.tap(endTime);
      await tester.pumpAndSettle();
      expect(draftOf(tester).isDirty, isFalse);
    });
  });

  group('Save', () {
    testWidgets('sends the draft once and pops on success', (tester) async {
      await pumpEdit(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(submission.saved, hasLength(1));
      expect(submission.saved.single.name, 'Changed');
      expect(screen, findsNothing, reason: 'popped');
    });

    testWidgets('the form is inert while the save is in flight',
        (tester) async {
      await pumpEdit(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      submission.gate = Completer<EditTileSaveResult>();
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pump();

      final AbsorbPointer absorb = tester.widget<AbsorbPointer>(find
          .descendant(of: screen, matching: find.byType(AbsorbPointer))
          .first);
      final ExcludeFocus exclude = tester.widget<ExcludeFocus>(find
          .descendant(of: screen, matching: find.byType(ExcludeFocus))
          .first);
      expect(absorb.absorbing, isTrue);
      expect(exclude.excluding, isTrue);
      expect(find.byType(AddTilePendingSweep), findsOneWidget);

      // A second tap while pending is a guarded no-op.
      await tester.tap(save, warnIfMissed: false);
      await tester.pump();
      expect(submission.saved, hasLength(1));

      submission.gate!.complete(const EditTileSaveResult.success(null));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
    });

    testWidgets('a failure keeps the draft, unlocks, and offers Retry',
        (tester) async {
      await pumpEdit(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      submission.answer =
          const EditTileSaveResult.failure(editTileFailureNetwork);
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(screen, findsOneWidget);
      expect(draftOf(tester).name, 'Changed');
      expect(find.text(testL10n.editTileSaveFailed), findsOneWidget);
      final AbsorbPointer absorb = tester.widget<AbsorbPointer>(find
          .descendant(of: screen, matching: find.byType(AbsorbPointer))
          .first);
      expect(absorb.absorbing, isFalse);

      submission.answer = const EditTileSaveResult.success(null);
      await tester.tap(find.text(testL10n.addTileRetry));
      await tester.pumpAndSettle();
      expect(submission.saved, hasLength(2));
      expect(screen, findsNothing);
    });

    testWidgets('a clean draft cannot be saved', (tester) async {
      await pumpEdit(tester);
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(submission.saved, isEmpty);
      expect(screen, findsOneWidget);
    });
  });

  group('Back', () {
    testWidgets('a clean draft just leaves', (tester) async {
      await pumpEdit(tester);
      await tester.tap(find.byKey(const ValueKey('editTileClose')));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a dirty draft asks; Keep editing stays; Discard leaves',
        (tester) async {
      await pumpEdit(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('editTileClose')));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.editTileDiscardTitle), findsOneWidget);

      await tester.tap(find.text(testL10n.editTileKeepEditing));
      await tester.pumpAndSettle();
      expect(screen, findsOneWidget);
      expect(draftOf(tester).name, 'Changed');

      await tester.tap(find.byKey(const ValueKey('editTileClose')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.editTileDiscard));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
    });
  });

  group('Accessibility (D62)', () {
    testWidgets('every timing row and Save are activatable buttons',
        (tester) async {
      await pumpEdit(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      for (final Finder f in <Finder>[
        startTime,
        startDate,
        endTime,
        endDate,
        durationRow
      ]) {
        await scrollTo(tester, f);
        expect(tester.getSemantics(f),
            matchesSemantics(isButton: true, hasTapAction: true),
            reason: '$f');
      }
      await scrollTo(tester, save);
      final Finder saveNode = find.descendant(
          of: save,
          matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.button == true));
      expect(
          tester.getSemantics(saveNode),
          matchesSemantics(
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: false, // clean draft: nothing to save yet
          ));
      h.dispose();
    });
  });

  group('Narrow width', () {
    testWidgets('nothing overflows at 320pt', (tester) async {
      await pumpEdit(tester, viewSize: AddTileTestMatrix.narrow);
      await scrollTo(tester, save);
      expect(tester.takeException(), isNull);
    });
  });
}

/// "1 hr 30 min" through the shared formatter, kept in one place.
String formatDurationSummaryForTest(int minutes) =>
    formatDurationSummary(testL10n, Duration(minutes: minutes)) ?? '';
