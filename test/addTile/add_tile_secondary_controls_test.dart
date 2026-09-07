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
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';
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
  RouteFactory? onGenerateRoute,
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
    onGenerateRoute: onGenerateRoute,
    home: child,
  ));
}

/// Reads a Preferred time chip's ASSISTIVE-TECH selected state.
///
/// Selection must never be carried by color alone, so this goes through the
/// `Semantics` node the chip publishes rather than through its styling. The
/// chip widget itself is private, hence the key plus descendant walk.
bool chipIsSelected(WidgetTester tester, String key) {
  final Semantics semantics = tester.widget<Semantics>(
    find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Semantics),
        )
        .first,
  );
  return semantics.properties.selected ?? false;
}

/// A location as the Location route returns one: `isDefault`/`isNull` false,
/// so `isNotNullAndNotDefault` (the legacy "user actually picked something"
/// predicate) holds. A bare `Location.fromDefault()` is the ABSENT state.
Location selectedLocation(String description) =>
    Location.fromLatitudeAndLongitude(latitude: 47.6, longitude: -122.3)
      ..description = description;

/// A profile the four simple day parts cannot express: weekdays only, and a
/// window that is not one of the canonical day-part windows.
/// Scrolls the name affordance into view, then taps it.
///
/// The header grew at D37, so the Location row now sits below the fold on the
/// standard test viewport and a bare `tap()` misses the hit test — silently,
/// because `tap` only warns.
Future<void> tapNameAction(WidgetTester tester) async {
  final Finder action = find.byKey(const ValueKey('nameLocationAction'));
  await tester.scrollUntilVisible(action, 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Finder chevronInLocationRow() => find.descendant(
      of: find.byKey(const ValueKey('locationRow')),
      matching: find.byIcon(Icons.chevron_right),
    );

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

    test('a day part replaces an advanced profile (D40)', () {
      // The old rule PRESERVED the advanced profile and dropped the
      // selection. That was safe while the four chips were hidden under an
      // advanced profile — the branch was unreachable. D31 put them back on
      // screen, and the rule turned four visible, enabled chips into dead
      // controls.
      final advanced = advancedProfile();
      expect(preferredTimeOfProfile(advanced), isNull,
          reason: 'precondition: this profile is not a simple day part');

      final next =
          restrictionProfileForPreferredTime(PreferredTimeOfDay.morning);
      expect(preferredTimeOfProfile(next), PreferredTimeOfDay.morning);
      expect(next, isNot(same(advanced)));
    });

    test('a selection replaces an absent or simple profile', () {
      final next =
          restrictionProfileForPreferredTime(PreferredTimeOfDay.evening);
      expect(preferredTimeOfProfile(next), PreferredTimeOfDay.evening);
      expect(restrictionProfileForPreferredTime(PreferredTimeOfDay.anytime),
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

    testWidgets('the five preferred-time options sit on ONE row',
        (tester) async {
      // Five labelled options cannot fit a phone width, so the row scrolls
      // horizontally rather than wrapping — the wrapped version read as a
      // lopsided grid on device.
      // Narrowest supported width — at the default 800px test viewport even a
      // Wrap fits five chips on one line, so this only means something here.
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: AddTileDraft.flexible(now: now), now: now),
        viewSize: AddTileTestMatrix.narrow,
      );
      await tester.pump();

      final List<String> keys = <String>[
        'preferredTimeAnytime',
        'preferredTimeMorning',
        'preferredTimeAfternoon',
        'preferredTimeEvening',
        'preferredTimeCustom',
      ];
      final List<Offset> centres = <Offset>[
        for (final String key in keys)
          tester.getCenter(find.byKey(ValueKey(key))),
      ];

      for (int i = 1; i < keys.length; i++) {
        expect(centres[i].dy, closeTo(centres[0].dy, 0.5),
            reason: '${keys[i]} wrapped onto another line');
        expect(centres[i].dx, greaterThan(centres[i - 1].dx),
            reason: '${keys[i]} must follow ${keys[i - 1]} on the same line');
      }
      expect(tester.takeException(), isNull,
          reason: 'the row scrolls, so it must never overflow');
    });

    test('the selected option leads the chip order (D36)', () {
      // The row scrolls, so canonical order would let the current answer sit
      // off-screen — a control unable to show its own value.
      expect(
        preferredTimeChipOrder(PreferredTimeOfDay.evening).first,
        PreferredTimeOfDay.evening,
      );
      expect(preferredTimeChipOrder(PreferredTimeOfDay.anytime).first,
          PreferredTimeOfDay.anytime);

      // `null` is the Custom chip, mirroring preferredTimeOfProfile.
      expect(preferredTimeChipOrder(null).first, isNull);
    });

    test('promoting the selection does not otherwise reshuffle the row', () {
      // Exactly one move: everything else keeps canonical order, so the row
      // stays predictable between selections.
      expect(
          preferredTimeChipOrder(PreferredTimeOfDay.afternoon),
          <PreferredTimeOfDay?>[
            PreferredTimeOfDay.afternoon,
            PreferredTimeOfDay.anytime,
            PreferredTimeOfDay.morning,
            PreferredTimeOfDay.evening,
            null,
          ]);
    });

    test('every option is offered exactly once, whatever is selected', () {
      for (final PreferredTimeOfDay? selected in <PreferredTimeOfDay?>[
        ...PreferredTimeOfDay.values,
        null,
      ]) {
        final List<PreferredTimeOfDay?> order =
            preferredTimeChipOrder(selected);
        expect(order.length, PreferredTimeOfDay.values.length + 1,
            reason: 'a chip was dropped or duplicated for $selected');
        expect(order.toSet().length, order.length,
            reason: 'duplicate chip for $selected');
      }
    });

    testWidgets('the selected chip is visible without scrolling',
        (tester) async {
      // The property the ordering exists to guarantee, asserted against the
      // real viewport rather than the list alone.
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(
          restrictionProfileForPreferredTime(PreferredTimeOfDay.evening));
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: draft, now: now),
        viewSize: AddTileTestMatrix.narrow,
      );
      await tester.pump();

      final Rect chip =
          tester.getRect(find.byKey(const ValueKey('preferredTimeEvening')));
      expect(chip.left, greaterThanOrEqualTo(0));
      expect(chip.right, lessThanOrEqualTo(AddTileTestMatrix.narrow.width),
          reason: 'Evening is selected, so it must be on screen unscrolled');
    });

    testWidgets('a day part can be chosen while Custom is selected (D40)',
        (tester) async {
      // The reported bug: "once custom is selected I cannot switch to
      // anytime, morning, afternoon and evening". The chips rendered, took
      // the tap, and the state layer discarded it.
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(advancedProfile());
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();
      expect(chipIsSelected(tester, 'preferredTimeCustom'), isTrue,
          reason: 'precondition: Custom is the selected chip');

      await tester.tap(find.byKey(const ValueKey('preferredTimeMorning')));
      await tester.pumpAndSettle();

      expect(preferredTimeOfProfile(draft.restrictionProfile),
          PreferredTimeOfDay.morning);
      expect(chipIsSelected(tester, 'preferredTimeMorning'), isTrue);
      expect(chipIsSelected(tester, 'preferredTimeCustom'), isFalse);
    });

    testWidgets('Anytime is reachable from Custom too (D40)', (tester) async {
      // Anytime maps to a NULL profile, so it is the one day part whose
      // selection could be mistaken for "nothing happened".
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(advancedProfile());
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('preferredTimeAnytime')));
      await tester.pumpAndSettle();

      expect(draft.restrictionProfile, isNull);
      expect(chipIsSelected(tester, 'preferredTimeAnytime'), isTrue);
    });

    testWidgets('an advanced profile selects Custom, not a day part',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(advancedProfile());
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      expect(chipIsSelected(tester, 'preferredTimeCustom'), isTrue,
          reason: 'a custom profile must not masquerade as a simple day part');
      for (final part in <String>[
        'Anytime',
        'Morning',
        'Afternoon',
        'Evening'
      ]) {
        expect(chipIsSelected(tester, 'preferredTime$part'), isFalse,
            reason: '$part must not read as selected under a custom profile');
      }
    });

    testWidgets('the four day parts stay offered under a custom profile',
        (tester) async {
      // An earlier revision replaced the whole control with a read-only
      // "Custom" row, which stranded a user holding an advanced profile: no
      // way back to the four simple choices, and no way into the editor from
      // here either.
      final draft = AddTileDraft.flexible(now: now);
      draft.setRestrictionProfile(advancedProfile());
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      for (final part in <String>[
        'Anytime',
        'Morning',
        'Afternoon',
        'Evening'
      ]) {
        expect(find.byKey(ValueKey('preferredTime$part')), findsOneWidget);
      }
    });

    testWidgets('Custom is the single entry point to the advanced editor',
        (tester) async {
      // D34: More options used to carry an "Advanced preferred time" row that
      // opened this same route under a second name. The chip replaced it —
      // it sits where the decision is made, and unlike that row it can show
      // that an advanced profile is already in effect.
      final draft = AddTileDraft.flexible(now: now);
      final List<String> pushed = <String>[];
      await pumpScreen(
        tester,
        AddTileRedesignScreen(draft: draft, now: now),
        onGenerateRoute: (settings) {
          pushed.add(settings.name ?? '');
          return MaterialPageRoute<void>(
            builder: (_) => const SizedBox.shrink(),
            settings: settings,
          );
        },
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('preferredTimeCustom')));
      await tester.pumpAndSettle();

      expect(pushed, contains('/TimeRestrictionRoute'));
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
      // D35: the row is named for the FIELD in both states, like Repeat
      // beside it, with the value as its subtitle.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('locationRow')),
          matching: find.text('Location'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('locationRow')),
          matching: find.text('Not set'),
        ),
        findsOneWidget,
      );
      expect(find.text('Add location'), findsNothing,
          reason: 'the row names a field, not an action');
      expect(find.text('Does not repeat'), findsOneWidget);
    });

    // D35: the affordance must describe where the row GOES, and it goes to
    // the same picker whether or not a location is set. A circled plus in the
    // empty state implied a different, additive destination.
    //
    // Two tests rather than two pumps in one: `AddTileRedesignScreen` copies
    // the draft in `initState`, so re-pumping the same widget TYPE reuses the
    // State and silently keeps the first draft.
    testWidgets('the empty Location row shows a chevron, not a plus (D35)',
        (tester) async {
      await pumpScreen(tester, AddTileRedesignScreen(now: now));
      await tester.pump();

      expect(chevronInLocationRow(), findsOneWidget,
          reason: 'the empty state must still read as navigation');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('locationRow')),
          matching: find.byIcon(Icons.add_circle_outline),
        ),
        findsNothing,
      );
    });

    testWidgets('a chosen location keeps the chevron beside the name action',
        (tester) async {
      final draft = AddTileDraft.flexible(now: now);
      draft.setLocation(selectedLocation('Library'));
      await pumpScreen(tester, AddTileRedesignScreen(draft: draft, now: now));
      await tester.pump();

      expect(find.byKey(const ValueKey('nameLocationAction')), findsOneWidget);
      expect(chevronInLocationRow(), findsOneWidget,
          reason: 'the name action must sit BESIDE the chevron, not replace '
              'it — the row still navigates');
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

      await tapNameAction(tester);

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

      await tapNameAction(tester);
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

      await tapNameAction(tester);
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
