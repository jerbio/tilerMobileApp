// Phase 2.2 — Preferred time, Location, and Repeat.
//
// Red tests for the second Flexible slice:
//   * the TWO "Anytime" meanings (Complete by vs Preferred time) are
//     separately labeled and separately reachable;
//   * the four simple day parts map to/from a RestrictionProfile, and an
//     advanced/custom profile is never silently overwritten;
//   * the legacy Location and Repeat routes are wrapped in typed adapters
//     that preserve the legacy by-reference result semantics verbatim;
//   * secondary values survive navigation, a cancelled route, a stale
//     suggestion, and a type switch.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/tileRouteAdapters.dart';
import 'package:tiler_app/theme/theme_data.dart';

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

Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Size viewSize = AddTileTestMatrix.standard,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ));
}

/// A location as the Location route returns one: `isDefault`/`isNull` false,
/// so `isNotNullAndNotDefault` (the legacy "user actually picked something"
/// predicate) holds. A bare `Location.fromDefault()` is the ABSENT state.
Location selectedLocation(String description) =>
    Location.fromLatitudeAndLongitude(latitude: 47.6, longitude: -122.3)
      ..description = description;

/// A profile the four simple day parts cannot express: weekdays only, and a
/// window that is not one of the canonical day-part windows.
RestrictionProfile advancedProfile() {
  final days = <RestrictionDay?>[];
  for (int i = 0; i < 7; i++) {
    days.add(i >= 1 && i <= 5
        ? RestrictionDay(
            weekday: i,
            restrictionTimeLine: RestrictionTimeLine(
              start: const TimeOfDay(hour: 9, minute: 30),
              duration: const Duration(hours: 7, minutes: 30),
              weekDay: i,
            ),
          )
        : null);
  }
  return RestrictionProfile(daySelection: days);
}

void main() {
  group('Preferred time — day-part mapping', () {
    test('Anytime is the ABSENCE of a restriction profile', () {
      expect(restrictionProfileForPreferredTime(PreferredTimeOfDay.anytime),
          isNull);
      expect(preferredTimeOfProfile(null), PreferredTimeOfDay.anytime);
    });

    test('each day part round-trips through a profile', () {
      for (final part in [
        PreferredTimeOfDay.morning,
        PreferredTimeOfDay.afternoon,
        PreferredTimeOfDay.evening,
      ]) {
        final profile = restrictionProfileForPreferredTime(part);
        expect(profile, isNotNull, reason: '$part must build a profile');
        expect(profile!.daySelection.length, 7);
        expect(preferredTimeOfProfile(profile), part,
            reason: '$part must round-trip back to itself');
      }
    });

    test('an advanced/custom profile is not one of the four simple choices',
        () {
      expect(preferredTimeOfProfile(advancedProfile()), isNull);
    });

    test('a simple selection never overwrites an advanced profile', () {
      final advanced = advancedProfile();
      expect(
        applyPreferredTimeSelection(advanced, PreferredTimeOfDay.morning),
        same(advanced),
        reason: 'advanced values change only through the advanced editor',
      );
    });

    test('a selection replaces an absent or simple profile', () {
      final simple =
          restrictionProfileForPreferredTime(PreferredTimeOfDay.morning);
      final next =
          applyPreferredTimeSelection(simple, PreferredTimeOfDay.evening);
      expect(preferredTimeOfProfile(next), PreferredTimeOfDay.evening);
      expect(applyPreferredTimeSelection(null, PreferredTimeOfDay.anytime),
          isNull);
    });
  });

  group('Preferred time — control (widget)', () {
    testWidgets('the two Anytime meanings are separately labeled',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      // "Complete by" and "Preferred time" are distinct labeled sections...
      expect(find.text('COMPLETE BY'), findsOneWidget);
      expect(find.text('PREFERRED TIME'), findsOneWidget);
      // ...each carrying its own, separately reachable "Anytime" value.
      expect(find.text('Anytime'), findsNWidgets(2),
          reason: 'deadline Anytime and preferred-time Anytime are distinct');
      expect(find.byKey(const ValueKey('completeByRow')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('preferredTimeAnytime')), findsOneWidget);
    });

    testWidgets('selecting a day part stores the matching profile',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('preferredTimeMorning')));
      await tester.pump();

      expect(preferredTimeOfProfile(draft.restrictionProfile),
          PreferredTimeOfDay.morning);
    });

    testWidgets('an advanced profile shows a Custom summary, not a day part',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(advancedProfile());
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      expect(find.text('Custom'), findsOneWidget,
          reason: 'a custom profile must not masquerade as a simple day part');
    });
  });

  group('Suggestions never overwrite manual edits', () {
    test('a manual preferred-time edit rejects a suggested profile', () {
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(
          restrictionProfileForPreferredTime(PreferredTimeOfDay.evening));
      expect(
        draft.canAcceptSuggestion(AddTileSuggestedField.restrictionProfile),
        isFalse,
      );
    });

    test('a manual location edit rejects an inferred location', () {
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(selectedLocation('Library'));
      expect(
          draft.canAcceptSuggestion(AddTileSuggestedField.location), isFalse);
    });
  });

  group('Repeat route adapter — legacy result semantics', () {
    RepetitionData enabled() =>
        RepetitionData(frequency: RepetitionFrequency.daily, isEnabled: true);
    RepetitionData disabled() =>
        RepetitionData(frequency: RepetitionFrequency.none, isEnabled: false);

    test('proceed + enabled + valid end => apply the updated repetition', () {
      final r = enabled();
      final result = resolveRepeatRouteResult(
          updatedRepetition: r, isRepetitionEndValid: true);
      expect(result.action, RepeatRouteAction.apply);
      expect(result.repetition, same(r));
    });

    test('proceed + enabled + invalid end => clear (legacy behavior)', () {
      final result = resolveRepeatRouteResult(
          updatedRepetition: enabled(), isRepetitionEndValid: false);
      expect(result.action, RepeatRouteAction.clear);
    });

    test('proceed + disabled selection + valid end => unchanged', () {
      final result = resolveRepeatRouteResult(
          updatedRepetition: disabled(), isRepetitionEndValid: true);
      expect(result.action, RepeatRouteAction.unchanged);
    });

    test('cancel (no updatedRepetition) + valid end => unchanged', () {
      final result = resolveRepeatRouteResult(
          updatedRepetition: null, isRepetitionEndValid: true);
      expect(result.action, RepeatRouteAction.unchanged);
    });

    test('cancel + invalid end => clear (legacy cleared here too)', () {
      final result = resolveRepeatRouteResult(
          updatedRepetition: null, isRepetitionEndValid: false);
      expect(result.action, RepeatRouteAction.clear);
    });

    test('applying a result mutates the draft per the action', () {
      final draft = AddTileDraft.flexible(now: now);
      final r = enabled();

      applyRepeatRouteResult(
          draft, const RepeatRouteResult(RepeatRouteAction.unchanged));
      expect(draft.repetitionData, isNull, reason: 'unchanged is a no-op');

      applyRepeatRouteResult(
          draft, RepeatRouteResult(RepeatRouteAction.apply, r));
      expect(draft.repetitionData, same(r));

      applyRepeatRouteResult(
          draft, const RepeatRouteResult(RepeatRouteAction.clear));
      expect(draft.repetitionData, isNull);
    });
  });

  group('Secondary rows — summaries and route cancellation', () {
    testWidgets('Location and Repeat rows show their unset summaries',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      expect(find.byKey(const ValueKey('locationRow')), findsOneWidget);
      expect(find.byKey(const ValueKey('repeatRow')), findsOneWidget);
      expect(find.text('Add location'), findsOneWidget);
      expect(find.text('Does not repeat'), findsOneWidget);
    });

    testWidgets('configured Location and Repeat show compact summaries',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(selectedLocation('Library'));
      draft.setRepetitionData(RepetitionData(
          frequency: RepetitionFrequency.weekly, isEnabled: true));
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('an unregistered (cancelled) route leaves the draft untouched',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      // No '/LocationRoute' or '/RepetitionRoute' is registered in the test
      // harness: the adapters must resolve to a no-op, not a crash.
      await tester.tap(find.byKey(const ValueKey('locationRow')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repeatRow')));
      await tester.pumpAndSettle();

      expect(draft.repetitionData, isNull);
      expect(draft.isDirty, isFalse,
          reason: 'a cancelled picker is not a user edit');
    });
  });

  group('Naming a chosen location from the Add form', () {
    // Naming moved off the Location picker (tap there commits immediately), so
    // the Add form is where a place gets named — the minority case, kept out
    // of the one-tap path.

    testWidgets('an unnamed location offers a name action', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(
        Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.9)
          ..address = '532 Wylie Street, Denver, CO',
      );
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      expect(find.byKey(const ValueKey('nameLocationAction')), findsOneWidget);
    });

    testWidgets('no name action when there is no location', (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();
      expect(find.byKey(const ValueKey('nameLocationAction')), findsNothing);
    });

    testWidgets('the edit affordance opens the shared place editor',
        (tester) async {
      // D19: one editor, two entry points. The Add form opens the same
      // Name + Address surface the picker uses, rather than a naming-only
      // dialog that could not supply an address.
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(
        Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.9)
          ..address = '532 Wylie Street, Denver, CO'
          ..description = 'Some Place'
          ..id = 'loc-123',
      );
      await pumpScreen(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          now: now,
          locationSource: _EditorOnlySource(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('nameLocationAction')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('placeNameField')), findsOneWidget);
      expect(find.byKey(const ValueKey('placeAddressField')), findsOneWidget,
          reason: 'the address must be editable here too — that is the whole '
              'point of one shared editor');
    });

    testWidgets('editing name and address updates the draft', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(
        Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.9)
          ..address = '532 Wylie Street, Denver, CO'
          ..description = 'Some Place'
          ..id = 'loc-123',
      );
      await pumpScreen(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          now: now,
          locationSource: _EditorOnlySource(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('nameLocationAction')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), "Ashley's Home");
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(draft.location!.description, "Ashley's Home");
      expect(draft.location!.id, '', reason: 'a renamed place is a new one');
      expect(draft.location!.address, '532 Wylie Street, Denver, CO',
          reason: 'an untouched address must survive a rename');
    });

    testWidgets('cancelling the editor changes nothing', (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(
        Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.9)
          ..address = '532 Wylie Street, Denver, CO'
          ..description = 'Some Place'
          ..id = 'loc-123',
      );
      await pumpScreen(
        tester,
        AddTileRedesignScreen(
          draft: draft,
          now: now,
          locationSource: _EditorOnlySource(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('nameLocationAction')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), 'Discarded');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('placeCancel')));
      await tester.pumpAndSettle();

      expect(draft.location!.description, 'Some Place');
      expect(draft.location!.id, 'loc-123');
    });
  });

  group('Type switching preserves secondary values', () {
    test('preferred time is dormant for Fixed and restores on switch back', () {
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(
          restrictionProfileForPreferredTime(PreferredTimeOfDay.afternoon));
      final profile = draft.restrictionProfile;

      draft.switchToFixed();
      expect(draft.restrictionProfile, same(profile),
          reason: 'retained in a dormant state, never discarded');

      draft.switchToFlexible();
      expect(preferredTimeOfProfile(draft.restrictionProfile),
          PreferredTimeOfDay.afternoon);
    });

    test('location and repeat are preserved across both switches', () {
      final draft = AddTileDraft.flexible(now: now);
      final loc = selectedLocation('Library');
      final rep =
          RepetitionData(frequency: RepetitionFrequency.daily, isEnabled: true);
      draft.setLocation(loc);
      draft.setRepetitionData(rep);

      draft.switchToFixed();
      expect(draft.location, same(loc));
      expect(draft.repetitionData, same(rep));

      draft.switchToFlexible();
      expect(draft.location, same(loc));
      expect(draft.repetitionData, same(rep));
    });
  });
}

/// Minimal source for the Add-form editor tests: no saved places, no search,
/// and no name ever collides.
class _EditorOnlySource implements AddTileLocationSource {
  @override
  Future<List<Location>> savedPlaces() async => const <Location>[];

  @override
  Future<List<Location>> search(String query) async => const <Location>[];

  @override
  Future<Location?> findByName(String name) async => null;
}
