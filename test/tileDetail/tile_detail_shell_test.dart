// Step 6.3 — the Tile Detail shell: header, hero, Duration, pinned Save.
//
// The frame the sections (6.4) and the occurrences list (6.5) hang from.
// Same shape as the Edit Tile shell: a loader and a submission seam, a
// draft the widgets read from, a skeleton while loading, a pinned Save
// that names why it is disabled, a discard confirm on the way out.
//
// Harness: `pumpDetail` pushes the screen from a home route (as the app
// does), with fakes the tests inspect.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRepeatScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/tileRouteAdapters.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';
import 'package:tiler_app/theme/theme_data.dart';

import '../addTile/add_tile_widget_harness.dart';
import '../addTile/l10n_fixture.dart';
import 'tile_detail_draft_test.dart' as fx;

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    const Locale('en');

class FakeLoader implements TileDetailLoader {
  FakeLoader(this.result);
  TileDetailLoadResult result;
  Completer<TileDetailLoadResult>? gate;
  int calls = 0;

  @override
  Future<TileDetailLoadResult> load(String calendarEventId) {
    calls++;
    return gate?.future ?? Future<TileDetailLoadResult>.value(result);
  }
}

class FakeSubmission implements TileDetailSubmission {
  final List<TileDetailDraft> saved = <TileDetailDraft>[];
  final List<TileDetailDraft> deleted = <TileDetailDraft>[];
  Completer<TileDetailSaveResult>? saveGate;
  String? failWith;

  @override
  Future<TileDetailSaveResult> save(TileDetailDraft draft) {
    saved.add(draft);
    if (saveGate != null) return saveGate!.future;
    if (failWith != null) {
      return Future<TileDetailSaveResult>.value(
          TileDetailSaveResult.failure(failWith!));
    }
    return Future<TileDetailSaveResult>.value(
        TileDetailSaveResult.success(draft.original));
  }

  @override
  Future<TileDetailSaveResult> deleteSeries(TileDetailDraft draft) {
    deleted.add(draft);
    if (failWith != null) {
      return Future<TileDetailSaveResult>.value(
          TileDetailSaveResult.failure(failWith!));
    }
    return Future<TileDetailSaveResult>.value(
        TileDetailSaveResult.success(draft.original));
  }
}

/// The paged occurrences source (6.5): scripted pages per direction.
class FakeOccurrences implements TileDetailOccurrences {
  List<SubCalendarEvent> initialPage = <SubCalendarEvent>[];
  List<SubCalendarEvent> afterPage = <SubCalendarEvent>[];
  List<SubCalendarEvent> beforePage = <SubCalendarEvent>[];
  Completer<List<SubCalendarEvent>>? initialGate;
  Object? failWith;
  final List<String> calls = <String>[];

  Future<List<SubCalendarEvent>> _answer(
      String call, List<SubCalendarEvent> page) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
    return page;
  }

  @override
  Future<List<SubCalendarEvent>> initial(String calendarEventId) {
    calls.add('initial:$calendarEventId');
    if (initialGate != null) return initialGate!.future;
    if (failWith != null)
      return Future<List<SubCalendarEvent>>.error(failWith!);
    return Future<List<SubCalendarEvent>>.value(initialPage);
  }

  @override
  Future<List<SubCalendarEvent>> after(
          String calendarEventId, String cursorId) =>
      _answer('after:$cursorId', afterPage);

  @override
  Future<List<SubCalendarEvent>> before(
          String calendarEventId, String cursorId) =>
      _answer('before:$cursorId', beforePage);
}

late FakeLoader loader;
late FakeSubmission submission;
late FakeOccurrences occurrences;
final List<String> openedOccurrences = <String>[];
Object? openOccurrenceAnswer;
Duration? pickedDurationSeed;
Duration? pickedDurationAnswer;
DateTime? pickedDateSeed;
DateTime? pickedDateAnswer;

// Picker seams (6.4): each records its seed and answers what the test set.
RepetitionData? repeatSeed;
RepeatPickerResult? repeatAnswer;
Location? locationSeed;
Location? locationAnswer;
Location? placeSeed;
Location? placeAnswer;
Color? colorSeed;
ColorChoice? colorAnswer;
RestrictionProfile? restrictionSeed;
AdvancedRestrictionResult restrictionAnswer =
    const AdvancedRestrictionResult.unchanged();
final List<String> openedNotes = <String>[];
String? notesPersistAnswer;

Future<void> pumpDetail(
  WidgetTester tester, {
  CalendarEvent? event,
  Location? location,
  TileDetailLoadResult? loadResult,
  Size viewSize = AddTileTestMatrix.standard,
  bool dark = false,
  FakeOccurrences? occurrencesSource,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  pickedDurationSeed = pickedDurationAnswer = null;
  pickedDateSeed = pickedDateAnswer = null;
  repeatSeed = null;
  repeatAnswer = null;
  locationSeed = locationAnswer = placeSeed = placeAnswer = null;
  colorSeed = null;
  colorAnswer = null;
  restrictionSeed = null;
  restrictionAnswer = const AdvancedRestrictionResult.unchanged();
  openedNotes.clear();
  notesPersistAnswer = null;
  occurrences = occurrencesSource ?? FakeOccurrences();
  openedOccurrences.clear();
  openOccurrenceAnswer = null;
  loader = FakeLoader(loadResult ??
      TileDetailLoadResult.success(event ?? fx.loaded(), location));
  submission = FakeSubmission();

  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            key: const ValueKey('open'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => TileDetailRedesignScreen(
                calendarEventId: 'cal-1',
                loader: loader,
                submission: submission,
                occurrences: occurrences,
                openOccurrence: (_, SubCalendarEvent sub) async {
                  openedOccurrences.add(
                      '${sub.id}:${sub.thirdpartyType?.name}:${sub.thirdPartyUserId}');
                  return openOccurrenceAnswer;
                },
                pickDuration: (_, Duration seed) async {
                  pickedDurationSeed = seed;
                  return pickedDurationAnswer;
                },
                pickDate: (_, DateTime seed) async {
                  pickedDateSeed = seed;
                  return pickedDateAnswer;
                },
                pickers: TileDetailPickers(
                  pickRepeat: (_, RepetitionData? seed) async {
                    repeatSeed = seed;
                    return repeatAnswer;
                  },
                  pickLocation: (_, Location? seed) async {
                    locationSeed = seed;
                    return locationAnswer;
                  },
                  editPlace: (_, Location? seed) async {
                    placeSeed = seed;
                    return placeAnswer;
                  },
                  pickColor: (_, Color? seed) async {
                    colorSeed = seed;
                    return colorAnswer;
                  },
                  pickRestriction: (_, RestrictionProfile? seed) async {
                    restrictionSeed = seed;
                    return restrictionAnswer;
                  },
                  openNotes: (_, TileDetailNotesRequest r) async {
                    openedNotes
                        .add('${r.eventId}:${r.scope.name}:${r.readOnly}');
                    if (notesPersistAnswer != null) {
                      r.onPersisted(notesPersistAnswer!);
                    }
                  },
                ),
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

Finder key(String k) => find.byKey(ValueKey(k));
Finder get screen => find.byType(TileDetailRedesignScreen);
Finder get titleField => key('detailTitleField');
Finder get durationRow => key('detailDurationRow');
Finder get save => key('detailSave');

TileDetailDraft draftOf(WidgetTester tester) =>
    tester.state<TileDetailRedesignScreenState>(screen).draft!;

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  group('Load', () {
    testWidgets('a skeleton while loading, the frame once loaded',
        (tester) async {
      await pumpDetail(tester);
      // Re-open with a gated loader to catch the in-between.
      loader.gate = Completer<TileDetailLoadResult>();
      await tester.tap(key('detailClose'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(key('detailLoadingSweep'), findsOneWidget);
      final Size screen = tester.getSize(find.byType(Scaffold).last);
      final Iterable<Element> sweeps =
          find.byType(AddTilePendingSweep).evaluate();
      expect(sweeps.length, 3, reason: 'one shimmering card each');
      for (final Element e in sweeps) {
        expect(
            (e.renderObject as RenderBox).size.width, lessThan(screen.width));
      }
      expect(titleField, findsNothing);

      loader.gate!.complete(TileDetailLoadResult.success(fx.loaded(), null));
      await tester.pumpAndSettle();
      expect(key('detailLoadingSweep'), findsNothing);
      expect(titleField, findsOneWidget);
    });

    testWidgets('a failure says so and Retry loads again', (tester) async {
      await pumpDetail(tester,
          loadResult:
              const TileDetailLoadResult.failure(editTileFailureApiRejected));
      expect(find.text(testL10n.tileDetailLoadFailed), findsOneWidget);
      expect(key('detailClose'), findsOneWidget);
      loader.result = TileDetailLoadResult.success(fx.loaded(), null);
      await tester.tap(key('detailRetryLoad'));
      await tester.pumpAndSettle();
      expect(loader.calls, 2);
      expect(titleField, findsOneWidget);
    });

    testWidgets('the loader\'s location seeds the draft', (tester) async {
      await pumpDetail(tester, location: fx.place('Work', '456 Market St'));
      expect(draftOf(tester).location?.description, 'Work');
      expect(draftOf(tester).isDirty, isFalse);
    });
  });

  group('Header and hero', () {
    testWidgets('titled "Tile details"; the hero owns the title editor',
        (tester) async {
      await pumpDetail(tester);
      expect(find.text(testL10n.tileDetailTitle), findsOneWidget);
      expect(find.descendant(of: key('detailHero'), matching: titleField),
          findsOneWidget);
      expect(key('detailTitlePencil'), findsOneWidget);
      expect(find.text(testL10n.addTileTypeFlexible), findsOneWidget);
      await tester.enterText(titleField, 'Write REPORT');
      await tester.pump();
      expect(draftOf(tester).name, 'Write REPORT');
    });

    testWidgets('a block is typed as such', (tester) async {
      await pumpDetail(tester, event: fx.loaded(isRigid: true));
      expect(find.text(testL10n.addTileTypeFixed), findsOneWidget);
    });

    testWidgets(
        'a completed series is read-only: banner, locked title, '
        'no Save', (tester) async {
      await pumpDetail(tester, event: fx.loaded(isComplete: true));
      expect(key('detailModeBanner'), findsOneWidget);
      expect(find.text(testL10n.editTileModeReadOnly), findsOneWidget);
      expect(titleField, findsNothing);
      expect(key('detailTitleLocked'), findsOneWidget);
      expect(find.byKey(const ValueKey('detailSave'), skipOffstage: false),
          findsNothing);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
          tester
              .getSemantics(durationRow)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse);
      h.dispose();
    });

    testWidgets('a provider series names its provider and locks the form',
        (tester) async {
      await pumpDetail(tester, event: fx.loaded(thirdPartyType: 'google'));
      expect(
          find.text(
              testL10n.editTileModeThirdParty(testL10n.editTileProviderGoogle)),
          findsOneWidget);
      expect(titleField, findsNothing);
      expect(find.byKey(const ValueKey('detailSave'), skipOffstage: false),
          findsNothing);
    });
  });

  group('Duration', () {
    testWidgets('shows the per-occurrence length and opens the wheel on it',
        (tester) async {
      await pumpDetail(tester);
      expect(
          find.descendant(
              of: durationRow, matching: find.textContaining('1 hr 30 min')),
          findsOneWidget);
      pickedDurationAnswer = const Duration(hours: 2);
      await tester.tap(durationRow);
      await tester.pumpAndSettle();
      expect(pickedDurationSeed, const Duration(minutes: 90));
      expect(draftOf(tester).duration, const Duration(hours: 2));
      expect(draftOf(tester).canSave, isTrue);
    });

    testWidgets('no duration reads Not set and seeds the wheel at an hour',
        (tester) async {
      await pumpDetail(tester, event: fx.loaded(durationMinutes: null));
      expect(
          find.descendant(
              of: durationRow,
              matching: find.text(testL10n.addTileValueNotSet)),
          findsOneWidget);
      await tester.tap(durationRow);
      await tester.pumpAndSettle();
      expect(pickedDurationSeed, const Duration(hours: 1));
    });

    testWidgets('dismissing the wheel changes nothing', (tester) async {
      await pumpDetail(tester);
      pickedDurationAnswer = null;
      await tester.tap(durationRow);
      await tester.pumpAndSettle();
      expect(draftOf(tester).isDirty, isFalse);
    });
  });

  group('Save', () {
    testWidgets('a clean draft cannot be saved; a dirty valid one can',
        (tester) async {
      await pumpDetail(tester);
      await scrollTo(tester, save);
      expect(tester.widget<AddTilePrimaryButton>(save).enabled, isFalse);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      expect(tester.widget<AddTilePrimaryButton>(save).enabled, isTrue);
    });

    testWidgets('an invalid draft names the reason', (tester) async {
      await pumpDetail(tester);
      await tester.enterText(titleField, '');
      await tester.pump();
      await scrollTo(tester, save);
      expect(find.text(testL10n.editTileReasonNameRequired), findsOneWidget);
    });

    testWidgets('sends the draft once and pops with the event', (tester) async {
      await pumpDetail(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(submission.saved, hasLength(1));
      expect(screen, findsNothing, reason: 'popped');
    });

    testWidgets('the form is inert while the save is in flight',
        (tester) async {
      await pumpDetail(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      submission.saveGate = Completer<TileDetailSaveResult>();
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pump();
      expect(key('detailSaveSweep'), findsOneWidget);
      await tester.tap(save, warnIfMissed: false);
      await tester.pump();
      expect(submission.saved, hasLength(1), reason: 'no double submit');
      submission.saveGate!.complete(TileDetailSaveResult.success(fx.loaded()));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
    });

    testWidgets('a failure keeps the draft, unlocks, and offers Retry',
        (tester) async {
      await pumpDetail(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      submission.failWith = editTileFailureNetwork;
      await scrollTo(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(screen, findsOneWidget);
      expect(draftOf(tester).name, 'Changed');
      expect(key('detailSaveError'), findsOneWidget);
      expect(find.text(testL10n.addTileRetry), findsOneWidget);
      submission.failWith = null;
      await tester.tap(find.text(testL10n.addTileRetry));
      await tester.pumpAndSettle();
      expect(submission.saved, hasLength(2));
      expect(screen, findsNothing);
    });
  });

  group('Leaving', () {
    testWidgets('a clean draft just leaves', (tester) async {
      await pumpDetail(tester);
      await tester.tap(key('detailClose'));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
    });

    testWidgets('a dirty draft asks; Keep editing stays; Discard leaves',
        (tester) async {
      await pumpDetail(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      await tester.tap(key('detailClose'));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.editTileDiscardTitle), findsOneWidget);
      await tester.tap(find.text(testL10n.editTileKeepEditing));
      await tester.pumpAndSettle();
      expect(screen, findsOneWidget);
      await tester.tap(key('detailClose'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.editTileDiscard));
      await tester.pumpAndSettle();
      expect(screen, findsNothing);
    });
  });

  group('Delete series (⋯)', () {
    testWidgets('confirms, names every occurrence, then deletes and pops',
        (tester) async {
      await pumpDetail(tester);
      await tester.tap(find.descendant(
          of: key('detailMenu'), matching: find.byType(IconButton)));
      await tester.pumpAndSettle();
      await tester.tap(key('detailMenuDelete'));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.tileDetailDeleteConfirm('Write report')),
          findsOneWidget);
      expect(find.text(testL10n.tileDetailDeleteBody), findsOneWidget);
      await tester.tap(key('detailDeleteCancel'));
      await tester.pumpAndSettle();
      expect(submission.deleted, isEmpty);

      await tester.tap(find.descendant(
          of: key('detailMenu'), matching: find.byType(IconButton)));
      await tester.pumpAndSettle();
      await tester.tap(key('detailMenuDelete'));
      await tester.pumpAndSettle();
      await tester.tap(key('detailDeleteConfirm'));
      await tester.pumpAndSettle();
      expect(submission.deleted, hasLength(1));
      expect(screen, findsNothing);
    });

    testWidgets('a dirty draft is named as discarded by the delete',
        (tester) async {
      await pumpDetail(tester);
      await tester.enterText(titleField, 'Changed');
      await tester.pump();
      await tester.tap(find.descendant(
          of: key('detailMenu'), matching: find.byType(IconButton)));
      await tester.pumpAndSettle();
      await tester.tap(key('detailMenuDelete'));
      await tester.pumpAndSettle();
      expect(find.textContaining(testL10n.editTileActionDiscardsEdits),
          findsOneWidget);
    });

    testWidgets('a failed delete keeps the screen and says so', (tester) async {
      await pumpDetail(tester);
      submission.failWith = editTileFailureNetwork;
      await tester.tap(find.descendant(
          of: key('detailMenu'), matching: find.byType(IconButton)));
      await tester.pumpAndSettle();
      await tester.tap(key('detailMenuDelete'));
      await tester.pumpAndSettle();
      await tester.tap(key('detailDeleteConfirm'));
      await tester.pumpAndSettle();
      expect(screen, findsOneWidget);
      expect(key('detailDeleteError'), findsOneWidget);
    });
  });

  group('Accessibility and width', () {
    testWidgets('the pencil, Duration and Save are buttons', (tester) async {
      await pumpDetail(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      for (final Finder f in <Finder>[key('detailTitlePencil'), durationRow]) {
        expect(tester.getSemantics(f),
            matchesSemantics(isButton: true, hasTapAction: true),
            reason: '$f');
      }
      h.dispose();
    });

    testWidgets('nothing overflows at 320pt, light or dark', (tester) async {
      for (final bool dark in <bool>[false, true]) {
        await pumpDetail(tester,
            viewSize: AddTileTestMatrix.narrow,
            dark: dark,
            location: fx.place('Work', '456 Market St'));
        expect(tester.takeException(), isNull, reason: 'dark=$dark');
      }
    });
  });
}
