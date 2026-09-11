// Name-driven prediction (legacy parity).
//
// The legacy flow calls `NewTilePrediction` as the user types the tile name
// and pre-populates duration, location and the preferred-time profile from
// the answer. The behaviours worth pinning are the ones that decide whether
// that help is welcome or destructive:
//
//   * it never overwrites something the user chose;
//   * a slow response cannot land on top of a newer one;
//   * a failure is invisible, because nothing has actually gone wrong;
//   * placeholder locations ("anywhere") never reach the draft.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePredictionSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tuple/tuple.dart';

import 'add_tile_widget_harness.dart';

final now = DateTime(2026, 9, 4, 14, 0);

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

/// A scripted prediction source. [delay] lets a test hold a response open so
/// a newer request can overtake it.
class _FakePredictionSource implements AddTilePredictionSource {
  _FakePredictionSource(this.responses, {this.delay = Duration.zero});

  /// Name -> what the backend says about it.
  final Map<String, AddTilePrediction> responses;
  final Duration delay;
  final List<String> asked = <String>[];

  @override
  Future<AddTilePrediction> predict(String name) async {
    asked.add(name);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return responses[name] ?? AddTilePrediction.empty;
  }
}

class _FailingPredictionSource implements AddTilePredictionSource {
  int calls = 0;

  @override
  Future<AddTilePrediction> predict(String name) async {
    calls++;
    throw StateError('network down');
  }
}

Location _place(String description, {String? address}) =>
    Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.9)
      ..description = description
      ..address = address;

Future<void> pumpShell(
  WidgetTester tester, {
  required AddTileDraft draft,
  required AddTilePredictionSource source,
}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileRedesignScreen(
      draft: draft,
      now: now,
      predictionSource: source,
    ),
  ));
  await tester.pump();
}

Future<void> typeName(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const ValueKey('taskNameField')), name);
  await tester.pump();
}

/// Lets the debounce elapse and the response settle.
/// The busy affordance while a prediction runs: a shimmer sweep across the
/// WHOLE form, not a spinner and not a mark on the title row (D63). The
/// prediction fills several fields — duration, location, preferred time —
/// so the page as a whole is what is about to change, and the form stays
/// fully usable throughout.
Finder get predictionShimmer => find.byKey(const ValueKey('predictionShimmer'));

Future<void> settlePrediction(WidgetTester tester) async {
  await tester.pump(predictionDebounce + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  group('Trigger rule', () {
    test('matches the legacy character threshold', () {
      // Strictly greater than 3, on the RAW text — legacy compares the
      // controller's length, so this is which keystroke fires the first
      // request, not a detail.
      expect(shouldRequestPrediction(''), isFalse);
      expect(shouldRequestPrediction('gym'), isFalse);
      expect(shouldRequestPrediction('gyms'), isTrue);
    });
  });

  group('Translating the prediction response', () {
    RestrictionProfile enabledProfile() {
      final days = <RestrictionDay?>[
        for (int i = 0; i < 7; i++)
          RestrictionDay(
            weekday: i,
            restrictionTimeLine: RestrictionTimeLine(
              start: const TimeOfDay(hour: 9, minute: 0),
              duration: const Duration(hours: 8),
              weekDay: i,
            ),
          ),
      ];
      return RestrictionProfile(daySelection: days);
    }

    test('an empty response predicts nothing', () {
      final prediction = predictionFromAutoResult(Tuple4(
        <Duration>[],
        <Location>[],
        RestrictionProfile.noRestriction(),
        <String>[],
      ));
      expect(prediction.isEmpty, isTrue);
    });

    test('duration is the LONGEST offered', () {
      // getAutoResult sorts ascending and legacy takes `.last`. The bias is
      // deliberate: an under-booked tile gets rescheduled, an over-booked one
      // just finishes early.
      final prediction = predictionFromAutoResult(Tuple4(
        <Duration>[
          const Duration(minutes: 15),
          const Duration(minutes: 30),
          const Duration(minutes: 45),
        ],
        <Location>[],
        RestrictionProfile.noRestriction(),
        <String>[],
      ));
      expect(prediction.duration, const Duration(minutes: 45));
    });

    test('a placeholder location is dropped, not stored', () {
      // "anywhere" means "no particular place"; storing it would put a
      // meaningless string on the wire and into the user's saved places.
      final prediction = predictionFromAutoResult(Tuple4(
        <Duration>[],
        <Location>[_place('anywhere', address: 'anywhere')],
        RestrictionProfile.noRestriction(),
        <String>[],
      ));
      expect(prediction.location, isNull);
    });

    test('a real location survives', () {
      final prediction = predictionFromAutoResult(Tuple4(
        <Duration>[],
        <Location>[_place('Gym', address: '100 Main St')],
        RestrictionProfile.noRestriction(),
        <String>[],
      ));
      expect(prediction.location?.description, 'Gym');
    });

    test('a disabled profile is no profile', () {
      // noRestriction() is the endpoint's "nothing to say" value, which is
      // exactly the draft's absent state.
      final prediction = predictionFromAutoResult(Tuple4(
        <Duration>[],
        <Location>[],
        RestrictionProfile.noRestriction(),
        <String>[],
      ));
      expect(prediction.restrictionProfile, isNull);
    });

    test('an enabled profile survives', () {
      final prediction = predictionFromAutoResult(Tuple4(
        <Duration>[],
        <Location>[],
        enabledProfile(),
        <String>[],
      ));
      expect(prediction.restrictionProfile, isNotNull);
    });
  });

  group('Applying a prediction to the draft', () {
    testWidgets('populates duration and location from the name',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      final source = _FakePredictionSource(<String, AddTilePrediction>{
        'gym session': AddTilePrediction(
          duration: const Duration(minutes: 45),
          location: _place('Gym', address: '100 Main St'),
        ),
      });

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym session');
      await settlePrediction(tester);

      expect(draft.duration, const Duration(minutes: 45));
      expect(draft.location?.description, 'Gym');
    });

    testWidgets('never overwrites a duration the user chose', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setUserDuration(const Duration(hours: 2));

      final source = _FakePredictionSource(<String, AddTilePrediction>{
        'gym session': AddTilePrediction(
          duration: const Duration(minutes: 45),
          location: _place('Gym', address: '100 Main St'),
        ),
      });

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym session');
      await settlePrediction(tester);

      expect(draft.duration, const Duration(hours: 2),
          reason: 'a manual duration outranks any prediction');
      expect(draft.location?.description, 'Gym',
          reason: 'the untouched fields are still fair game');
    });

    testWidgets('never overwrites a preferred time the user chose',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(
          restrictionProfileForPreferredTime(PreferredTimeOfDay.evening));
      final RestrictionProfile? chosen = draft.restrictionProfile;

      final source = _FakePredictionSource(<String, AddTilePrediction>{
        'work block': AddTilePrediction(
          restrictionProfile:
              restrictionProfileForPreferredTime(PreferredTimeOfDay.morning),
        ),
      });

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'work block');
      await settlePrediction(tester);

      expect(draft.restrictionProfile, same(chosen));
      expect(preferredTimeOfProfile(draft.restrictionProfile),
          PreferredTimeOfDay.evening);
    });

    testWidgets('does not ask when nothing could accept an answer',
        (tester) async {
      // No request at all — the cheapest correct behaviour, and it keeps a
      // fully-specified draft from generating traffic on every keystroke.
      final draft = AddTileDraft.flexible(now: now);
      draft.setUserDuration(const Duration(hours: 2));
      draft.setLocation(_place('Home', address: '1 Elm St'));
      draft.setRestrictionProfile(
          restrictionProfileForPreferredTime(PreferredTimeOfDay.evening));

      final source = _FakePredictionSource(const <String, AddTilePrediction>{});
      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym session');
      await settlePrediction(tester);

      expect(source.asked, isEmpty);
    });

    testWidgets('a prediction does not make the draft dirty', (tester) async {
      // Dirtiness gates the discard prompt (D2). A value the user never chose
      // must not make closing the screen feel like losing work.
      final draft = AddTileDraft.flexible(now: now);
      final source = _FakePredictionSource(<String, AddTilePrediction>{
        'gyms': const AddTilePrediction(duration: Duration(minutes: 45)),
      });

      await pumpShell(tester, draft: draft, source: source);
      // The name itself is a user edit, so drive the prediction without one:
      // apply the value through the same path the response uses.
      draft.applySuggestedDuration(const Duration(minutes: 45));
      await tester.pump();

      expect(draft.isDirty, isFalse);
      expect(source.asked, isEmpty);
    });
  });

  group('Racing and failure', () {
    testWidgets('a slow response cannot land on top of a newer one',
        (tester) async {
      // These responses carry no request id, so ordering cannot be recovered
      // from them — the generation counter is the only defence.
      final draft = AddTileDraft.flexible(now: now);
      final source = _FakePredictionSource(
        <String, AddTilePrediction>{
          'gym session': const AddTilePrediction(duration: Duration(hours: 1)),
          'gym session tomorrow':
              const AddTilePrediction(duration: Duration(minutes: 20)),
        },
        delay: const Duration(seconds: 2),
      );

      await pumpShell(tester, draft: draft, source: source);

      await typeName(tester, 'gym session');
      await tester.pump(predictionDebounce + const Duration(milliseconds: 50));

      // Second request goes out while the first is still open.
      await typeName(tester, 'gym session tomorrow');
      await tester.pump(predictionDebounce + const Duration(milliseconds: 50));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(source.asked, <String>['gym session', 'gym session tomorrow']);
      expect(draft.duration, const Duration(minutes: 20),
          reason: 'the stale first response must be discarded');
    });

    testWidgets('typing again before the debounce elapses asks once',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      final source = _FakePredictionSource(const <String, AddTilePrediction>{});

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym ');
      await tester.pump(const Duration(milliseconds: 100));
      await typeName(tester, 'gym se');
      await tester.pump(const Duration(milliseconds: 100));
      await typeName(tester, 'gym session');
      await settlePrediction(tester);

      expect(source.asked, <String>['gym session'],
          reason: 'each keystroke replaces the pending request');
    });

    testWidgets('a failed prediction is invisible', (tester) async {
      // Nothing has gone wrong from the user's point of view: the form is
      // fully usable and they never asked for a prediction.
      final draft = AddTileDraft.flexible(now: now);
      final source = _FailingPredictionSource();

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym session');
      await settlePrediction(tester);

      expect(source.calls, 1);
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(predictionShimmer, findsNothing,
          reason: 'the busy affordance must clear even when the call fails');
    });

    testWidgets('the name row shows a busy affordance while asking',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      final source = _FakePredictionSource(
        const <String, AddTilePrediction>{},
        delay: const Duration(seconds: 2),
      );

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym session');
      await tester.pump(predictionDebounce + const Duration(milliseconds: 50));

      expect(predictionShimmer, findsOneWidget);
      expect(
          find.descendant(
              of: predictionShimmer, matching: find.byType(Shimmer)),
          findsOneWidget,
          reason: 'the affordance must actually shimmer');
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'the spinner was replaced, not joined');

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(predictionShimmer, findsNothing);
    });

    testWidgets('the shimmer is the whole form, not the title row',
        (tester) async {
      // Requested to match the preview add sheet, which sweeps its entire
      // surface while a result is pending. Two earlier cuts marked only the
      // title row (a 2px baseline, then the row's background); both said
      // "the title is busy" when the truth is that duration, location and
      // preferred time are the fields about to change.
      final draft = AddTileDraft.flexible(now: now);
      final source = _FakePredictionSource(
        const <String, AddTilePrediction>{},
        delay: const Duration(seconds: 2),
      );

      await pumpShell(tester, draft: draft, source: source);
      await typeName(tester, 'gym session');
      await tester.pump(predictionDebounce + const Duration(milliseconds: 50));

      final Rect sweep = tester.getRect(predictionShimmer);
      final Rect form =
          tester.getRect(find.byType(SingleChildScrollView).first);
      expect(sweep.top, lessThanOrEqualTo(form.top + 0.5),
          reason: 'the sweep must reach at least the top of the form');
      expect(sweep.bottom, greaterThanOrEqualTo(form.bottom - 0.5),
          reason: 'and its bottom');
      expect(sweep.width, closeTo(form.width, 1));

      // It must lie under EVERY field the prediction can fill, not only
      // the one being typed into.
      // Rows below the fold are scrolled to first: the sweep fills the
      // VIEWPORT, so what matters is that each row is under it once seen.
      // Fixed pumps, not pumpAndSettle — the shimmer never settles.
      for (final String key in <String>[
        'taskNameField',
        'durationRow',
        'locationRow',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.pump(const Duration(milliseconds: 300));
        final Rect field = tester.getRect(find.byKey(ValueKey(key)));
        expect(tester.getRect(predictionShimmer).contains(field.center), isTrue,
            reason: '$key is one of the fields about to change');
      }

      // And it sits BEHIND the content: the title row itself carries no
      // shimmer of its own, and the field stays usable.
      expect(
          find.descendant(
              of: find.byType(AddTileTextFieldRow),
              matching: find.byType(Shimmer)),
          findsNothing);
      await tester.enterText(
          find.byKey(const ValueKey('taskNameField')), 'gym sessions');
      expect(draft.name, 'gym sessions');
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('no prediction source means no prediction', (tester) async {
      // Most widget tests, and any flow that has not opted in.
      final draft = AddTileDraft.flexible(now: now);
      tester.view.physicalSize =
          AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        locale: const Locale('en'),
        localeResolutionCallback: _resolve,
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddTileRedesignScreen(draft: draft, now: now),
      ));
      await tester.pump();

      await typeName(tester, 'gym session');
      await settlePrediction(tester);

      expect(tester.takeException(), isNull);
      expect(draft.duration, Duration.zero);
    });
  });
}
