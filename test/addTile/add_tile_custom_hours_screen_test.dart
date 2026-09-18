// Step 6.4 — the Custom hours editor (D67–D71): presets, seven day rows,
// platform time pickers, copy/paste, validity, and the two modes — ad-hoc
// (returns the tile's own hours) and profile (saves the SHARED Work or
// Personal profile through the source).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileCustomHoursScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileTimeRestrictionScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';
import 'restriction_hours_draft_test.dart' as fx;

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    requested ?? const Locale('en');

/// A source whose save the test completes by hand.
class GatedSaveSource implements AddTileRestrictionProfileSource {
  final List<(RestrictionProfile, NamedRestrictionProfileType)> saves = [];
  Completer<RestrictionProfile> gate = Completer<RestrictionProfile>();

  @override
  Future<NamedRestrictionProfiles> load() async =>
      const NamedRestrictionProfiles();

  @override
  Future<RestrictionProfile> save(
      RestrictionProfile profile, NamedRestrictionProfileType type) {
    saves.add((profile, type));
    return gate.future;
  }
}

Finder key(String k) => find.byKey(ValueKey(k));

HoursEditorResult? result;
bool doneCalled = false;
final List<TimeOfDay> pickerSeeds = <TimeOfDay>[];
TimeOfDay? pickerAnswer;

Future<void> pumpEditor(
  WidgetTester tester, {
  required HoursEditorRequest request,
  GatedSaveSource? source,
  Size viewSize = AddTileTestMatrix.standard,
  double textScale = 1.0,
  bool dark = false,
  bool persist = true,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  result = null;
  doneCalled = false;
  pickerSeeds.clear();
  pickerAnswer = null;
  await tester.pumpWidget(MaterialApp(
    theme: dark ? TileThemeData.darkTheme : TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: AddTileCustomHoursScreen(
      request: request,
      source: source ?? GatedSaveSource(),
      persist: persist,
      onDone: (HoursEditorResult r) {
        result = r;
        doneCalled = true;
      },
      pickTime: (BuildContext _, TimeOfDay initial) async {
        pickerSeeds.add(initial);
        return pickerAnswer;
      },
    ),
  ));
  await tester.pump();
}

/// Reveals a row of the lazy list, scrolling the editor's own list. Rows
/// above the viewport do not exist either, so the list is first returned
/// to its top and then scrolled down to the target.
Future<void> reveal(WidgetTester tester, Finder f) async {
  if (f.evaluate().isNotEmpty) {
    await tester.ensureVisible(f);
    await tester.pump();
    return;
  }
  final Finder list = find.byType(Scrollable).first;
  await tester.drag(list, const Offset(0, 4000));
  await tester.pump();
  await tester.scrollUntilVisible(f, 120, scrollable: list);
  await tester.pump();
}

Future<void> tapDone(WidgetTester tester) async {
  await tester.tap(key('hoursDone'));
  await tester.pump();
}

RestrictionHoursDraft draftOf(WidgetTester tester) => tester
    .state<AddTileCustomHoursScreenState>(find.byType(AddTileCustomHoursScreen))
    .draft;

String startText(WidgetTester tester, int day) => tester
    .widget<Text>(find.descendant(
        of: key('hoursStart_$day'), matching: find.byType(Text)))
    .data!;

void main() {
  final RestrictionProfile weekdays = fx.weekdays(id: null);
  final HoursEditorRequest adHoc = HoursEditorRequest(seed: weekdays);

  group('Rows from the seed', () {
    testWidgets('Mon–Fri on at 9:00 AM – 6:00 PM, weekend off', (tester) async {
      await pumpEditor(tester, request: adHoc);
      expect(find.text(testL10n.addTileCustomHoursTitle), findsOneWidget);
      for (int d = 1; d <= 5; d++) {
        await reveal(tester, key('hoursDay_$d'));
        expect(tester.widget<Switch>(key('hoursSwitch_$d')).value, isTrue);
        expect(startText(tester, d), '9:00 AM');
      }
      await reveal(tester, key('hoursDay_6'));
      expect(tester.widget<Switch>(key('hoursSwitch_6')).value, isFalse);
      await reveal(tester, key('hoursDay_0'));
      expect(tester.widget<Switch>(key('hoursSwitch_0')).value, isFalse);
    });

    testWidgets('a null seed is every day off', (tester) async {
      await pumpEditor(tester, request: const HoursEditorRequest(seed: null));
      await reveal(tester, key('hoursDay_3'));
      expect(tester.widget<Switch>(key('hoursSwitch_3')).value, isFalse);
    });
  });

  group('Presets (D69)', () {
    testWidgets('the matching preset is highlighted; a tap rewrites the rows',
        (tester) async {
      await pumpEditor(tester, request: adHoc);
      expect(
          tester
              .widget<HoursPresetChip>(key('hoursPreset_weekdays9to6'))
              .selected,
          isTrue);
      expect(
          tester
              .widget<HoursPresetChip>(key('hoursPreset_weekends10to4'))
              .selected,
          isFalse);
      await tester.tap(key('hoursPreset_weekends10to4'));
      await tester.pump();
      expect(
          tester
              .widget<HoursPresetChip>(key('hoursPreset_weekends10to4'))
              .selected,
          isTrue);
      expect(tester.widget<Switch>(key('hoursSwitch_0')).value, isTrue);
      expect(startText(tester, 0), '10:00 AM');
      await reveal(tester, key('hoursDay_3'));
      expect(tester.widget<Switch>(key('hoursSwitch_3')).value, isFalse);
    });

    testWidgets('no chip is highlighted once the rows drift', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await tester.tap(key('hoursSwitch_0'));
      await tester.pump();
      for (final RestrictionHoursPreset p in RestrictionHoursPreset.values) {
        expect(
            tester
                .widget<HoursPresetChip>(key('hoursPreset_${p.name}'))
                .selected,
            isFalse,
            reason: p.name);
      }
    });
  });

  group('Day rows', () {
    testWidgets('switching a day on gives it 9:00 AM – 6:00 PM (D69)',
        (tester) async {
      await pumpEditor(tester, request: const HoursEditorRequest(seed: null));
      await tester.tap(key('hoursSwitch_0'));
      await tester.pump();
      expect(tester.widget<Switch>(key('hoursSwitch_0')).value, isTrue);
      expect(startText(tester, 0), '9:00 AM');
      expect(
          tester
              .widget<Text>(find.descendant(
                  of: key('hoursEnd_0'), matching: find.byType(Text)))
              .data,
          '6:00 PM');
    });

    testWidgets(
        'the start opens the platform picker seeded on the row; '
        'the answer updates it; cancel changes nothing', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await reveal(tester, key('hoursDay_1'));
      pickerAnswer = const TimeOfDay(hour: 10, minute: 30);
      await tester.tap(key('hoursStart_1'));
      await tester.pump();
      expect(pickerSeeds.single, const TimeOfDay(hour: 9, minute: 0));
      expect(startText(tester, 1), '10:30 AM');
      pickerAnswer = null;
      await tester.tap(key('hoursStart_1'));
      await tester.pump();
      expect(startText(tester, 1), '10:30 AM');
    });

    testWidgets('a disabled day\'s times cannot be picked', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await tester.tap(key('hoursStart_0'));
      await tester.pump();
      expect(pickerSeeds, isEmpty);
    });

    testWidgets('an equal start and end reads All day and is valid (D74)',
        (tester) async {
      await pumpEditor(tester, request: adHoc);
      await reveal(tester, key('hoursDay_2'));
      pickerAnswer = const TimeOfDay(hour: 9, minute: 0);
      await tester.tap(key('hoursEnd_2'));
      await tester.pump();
      expect(key('hoursAllDay_2'), findsOneWidget);
      expect(find.text(testL10n.addTileRestrictionAllDay), findsOneWidget);
      expect(key('hoursInvalid_2'), findsNothing);
      expect(
          tester.widget<AddTileDoneButton>(key('hoursDone')).enabled, isTrue);
      await tapDone(tester);
      expect(result!.profile!.daySelection[2]!.restrictionTimeLine!.duration,
          const Duration(hours: 24));
    });

    testWidgets(
        'an end before its start shows the error and disables '
        'Done (D70)', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await reveal(tester, key('hoursDay_2'));
      pickerAnswer = const TimeOfDay(hour: 8, minute: 0);
      await tester.tap(key('hoursEnd_2'));
      await tester.pump();
      expect(key('hoursInvalid_2'), findsOneWidget);
      expect(find.text(testL10n.addTileHoursEndBeforeStart), findsOneWidget);
      expect(
          tester.widget<AddTileDoneButton>(key('hoursDone')).enabled, isFalse);
      await tapDone(tester);
      expect(doneCalled, isFalse);
      pickerAnswer = const TimeOfDay(hour: 12, minute: 0);
      await tester.tap(key('hoursEnd_2'));
      await tester.pump();
      expect(key('hoursInvalid_2'), findsNothing);
      expect(
          tester.widget<AddTileDoneButton>(key('hoursDone')).enabled, isTrue);
    });
  });

  group('Copy and paste (D71)', () {
    testWidgets(
        'copy a day, the others offer paste, paste writes the hours, '
        'copying the source again clears', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await reveal(tester, key('hoursDay_1'));
      pickerAnswer = const TimeOfDay(hour: 7, minute: 15);
      await tester.tap(key('hoursStart_1'));
      await tester.pump();
      await tester.tap(key('hoursCopy_1'));
      await tester.pump();
      expect(draftOf(tester).copiedDay, 1);
      expect(tester.widget<IconButton>(key('hoursCopy_6')).tooltip,
          testL10n.addTileHoursPaste('Saturday'));
      await reveal(tester, key('hoursDay_6'));
      await tester.tap(key('hoursCopy_6'));
      await tester.pump();
      expect(tester.widget<Switch>(key('hoursSwitch_6')).value, isTrue,
          reason: 'pasting enables the day');
      expect(startText(tester, 6), '7:15 AM');
      await reveal(tester, key('hoursDay_1'));
      await tester.tap(key('hoursCopy_1'));
      await tester.pump();
      expect(draftOf(tester).copiedDay, isNull);
      expect(tester.widget<IconButton>(key('hoursCopy_6')).tooltip,
          testL10n.addTileHoursCopy('Saturday'));
    });
  });

  group('Ad-hoc mode (D68)', () {
    testWidgets('Done returns the hours as a fresh profile', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await tester.tap(key('hoursSwitch_0'));
      await tester.pump();
      await tapDone(tester);
      expect(result, isNotNull);
      final RestrictionProfile out = result!.profile!;
      expect(out.id, isNull);
      expect(out.daySelection[0], isNotNull);
      expect(out.daySelection[6], isNull);
      expect(
          describeRestrictionProfile(out).first.days, <int>[0, 1, 2, 3, 4, 5]);
    });

    testWidgets('every day off returns a null profile — Anytime',
        (tester) async {
      await pumpEditor(tester, request: const HoursEditorRequest(seed: null));
      await tapDone(tester);
      expect(doneCalled, isTrue);
      expect(result!.profile, isNull);
    });

    testWidgets('the footer explains disabled days', (tester) async {
      await pumpEditor(tester, request: adHoc);
      await reveal(tester, find.text(testL10n.addTileCustomHoursFooter));
      expect(find.text(testL10n.addTileCustomHoursFooter), findsOneWidget);
    });
  });

  group('Profile mode (D67)', () {
    final HoursEditorRequest workRequest = HoursEditorRequest(
        seed: fx.weekdays(id: 'work-1'),
        profileType: NamedRestrictionProfileType.work);

    testWidgets('titled by the profile; the footer says it is shared',
        (tester) async {
      await pumpEditor(tester, request: workRequest);
      expect(find.text(testL10n.addTileRestrictionWork), findsWidgets);
      await reveal(
          tester,
          find.text(testL10n.addTileCustomHoursProfileFooter(
              testL10n.addTileRestrictionWork)));
      expect(
          find.text(testL10n.addTileCustomHoursProfileFooter(
              testL10n.addTileRestrictionWork)),
          findsOneWidget);
    });

    testWidgets(
        'Done saves through the source, sweeps while pending, and '
        'returns the server\'s copy', (tester) async {
      final GatedSaveSource source = GatedSaveSource();
      await pumpEditor(tester, request: workRequest, source: source);
      await reveal(tester, key('hoursDay_6'));
      await tester.tap(key('hoursSwitch_6'));
      await tester.pump();
      await tapDone(tester);
      expect(source.saves.single.$2, NamedRestrictionProfileType.work);
      expect(source.saves.single.$1.id, 'work-1', reason: 'the seed\'s id');
      expect(source.saves.single.$1.daySelection[6], isNotNull);
      expect(key('hoursSaving'), findsOneWidget);
      expect(
          tester.widget<AddTileDoneButton>(key('hoursDone')).enabled, isFalse);
      expect(doneCalled, isFalse);
      final RestrictionProfile serverCopy = fx.weekdays(id: 'work-1');
      source.gate.complete(serverCopy);
      await tester.pump();
      expect(doneCalled, isTrue);
      expect(result!.profile, same(serverCopy));
    });

    testWidgets('a failed save shows a callout with Retry and keeps the form',
        (tester) async {
      final GatedSaveSource source = GatedSaveSource();
      await pumpEditor(tester, request: workRequest, source: source);
      await tapDone(tester);
      source.gate.completeError(TilerError(Message: 'no'));
      await tester.pump();
      expect(key('hoursSaveFailed'), findsOneWidget);
      expect(key('hoursSaving'), findsNothing);
      expect(doneCalled, isFalse);
      expect(
          tester.widget<AddTileDoneButton>(key('hoursDone')).enabled, isTrue);
      source.gate = Completer<RestrictionProfile>();
      await tester.tap(key('hoursRetry'));
      await tester.pump();
      expect(source.saves.length, 2);
      expect(key('hoursSaveFailed'), findsNothing);
      source.gate.complete(fx.weekdays(id: 'work-1'));
      await tester.pump();
      expect(doneCalled, isTrue);
    });

    testWidgets('every day off saves the profile DISABLED, keeping its id',
        (tester) async {
      final GatedSaveSource source = GatedSaveSource();
      await pumpEditor(tester, request: workRequest, source: source);
      for (int d = 1; d <= 5; d++) {
        await reveal(tester, key('hoursDay_$d'));
        await tester.tap(key('hoursSwitch_$d'));
        await tester.pump();
      }
      await tapDone(tester);
      final RestrictionProfile sent = source.saves.single.$1;
      expect(sent.id, 'work-1');
      expect(sent.isEnabled, isFalse);
      expect(sent.isAnyDayNotNull, isFalse);
    });
  });

  group('Profile mode without persisting (Tile Preferences, 6.6)', () {
    testWidgets('Done returns the edited profile, id kept, and never saves',
        (tester) async {
      final GatedSaveSource source = GatedSaveSource();
      await pumpEditor(tester,
          request: HoursEditorRequest(
              seed: fx.weekdays(id: 'work-1'),
              profileType: NamedRestrictionProfileType.work),
          source: source,
          persist: false);
      await tester.tap(key('hoursSwitch_0'));
      await tester.pump();
      await tapDone(tester);
      expect(source.saves, isEmpty);
      expect(result!.profile!.id, 'work-1');
      expect(result!.profile!.daySelection[0], isNotNull);
    });

    testWidgets('every day off returns the profile DISABLED, id kept',
        (tester) async {
      await pumpEditor(tester,
          request: HoursEditorRequest(
              seed: fx.weekdays(id: 'work-1'),
              profileType: NamedRestrictionProfileType.work),
          persist: false);
      for (int d = 1; d <= 5; d++) {
        await reveal(tester, key('hoursDay_$d'));
        await tester.tap(key('hoursSwitch_$d'));
        await tester.pump();
      }
      await tapDone(tester);
      expect(result!.profile!.id, 'work-1');
      expect(result!.profile!.isEnabled, isFalse);
    });
  });

  group('Semantics and matrix', () {
    testWidgets('a day switch is a named toggle', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpEditor(tester, request: adHoc);
      expect(
          tester.getSemantics(key('hoursSwitch_0')),
          matchesSemantics(
              hasToggledState: true,
              isToggled: false,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true,
              label: 'Sunday'));
      handle.dispose();
    });

    testWidgets('320pt with large text, and dark, without overflow',
        (tester) async {
      for (final bool dark in <bool>[false, true]) {
        await pumpEditor(tester,
            request: adHoc,
            viewSize: AddTileTestMatrix.narrow,
            textScale: AddTileTestMatrix.largeTextScale,
            dark: dark);
        await reveal(tester, key('hoursDay_6'));
        await tapDone(tester);
        expect(tester.takeException(), isNull, reason: 'dark=$dark');
      }
    });
  });
}
