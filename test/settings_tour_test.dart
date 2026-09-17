// settings_tour_test.dart
//
// TDD stage 2.1–2.4 (+ 2.5 retarget) for the product tour & slim onboarding
// redesign (product-tour-onboarding-redesign.md, Phase 2 "Settings tour").
//
// Stage 2.5 cut the settings tour to a single-step pointer: it exists only
// so users discover the Tile Preferences row, where the tour that actually
// teaches AI preferences lives (test/tile_preferences_tour_test.dart).
// Locks in:
//   1. Contract: exactly one step, anchored to the Tile Preferences row
//      via `SettingsTourKeys`, with real l10n copy.
//   2. Key sync: the live Settings page attaches that anchor exactly once.
//   3. Lifecycle: once per device — starts on the first visit with the
//      spotlight on the live row, the overlay tap completes it and persists
//      `hasCompletedTour_settings`, no restart on revisit, explicit reset
//      replays.
//   4. Production wiring: `/Setting` is built by `buildSettingsRoute`.
//   5. "How to use Tiler" replay-all row clears every registered tour
//      (home, settings, tile_preferences) and the pointer replays on the
//      next settings visit.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/components/tutorial/tourCoordinator.dart';
import 'package:tiler_app/components/tutorial/tourHost.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/components/tutorial/tutorialSpotlightPainter.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/components/tutorial/tours/settingsTour.dart';
import 'package:tiler_app/components/tutorial/tutorialTooltipWidget.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/main.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/settingsWidget.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';
import 'package:tiler_app/theme/theme_data.dart';

const _settle = Duration(milliseconds: 100);
const _fade = Duration(milliseconds: 400);

/// (step id, anchor key) pairs in tour order — section 3.4 of the spec.
final _expectedOrder = <(String, GlobalKey)>[
  ('tile_preferences', SettingsTourKeys.tilePreferencesTileKey),
];

late TutorialBloc capturedBloc;
late BuildContext capturedContext;

/// The spotlight cutout Rect of the currently rendered tour step, or null
/// when no spotlight overlay is rendered. Detected by the
/// `CustomPaint` + [TutorialSpotlightPainter] predicate.
Rect? _spotlightTarget(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint && widget.painter is TutorialSpotlightPainter,
  );
  if (tester.any(finder)) {
    final painter =
        tester.widget<CustomPaint>(finder).painter as TutorialSpotlightPainter;
    return painter.targetRect;
  }
  return null;
}

/// Mounts the real [Settings] surface under a [TourHost] driving the
/// settings tour, exactly the way Phase 2 wires it into the Settings
/// scaffold.
Widget settingsHarness({
  Key? key,
  List<TutorialStep> Function(BuildContext context) stepsBuilder =
      buildSettingsTourSteps,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    theme: TileThemeData.lightTheme,
    home: BlocProvider(
      create: (_) => DeviceSettingBloc(
        getContextCallBack: (context) => context,
        initialIsDarkMode: false,
      ),
      child: TourHost(
        key: key,
        tourId: TourPreferencesHelper.settingsTourId,
        stepCount: kSettingsTourStepCount,
        settleDelay: _settle,
        stepsBuilder: stepsBuilder,
        child: Builder(
          builder: (context) {
            capturedContext = context;
            capturedBloc = context.read<TutorialBloc>();
            return Settings();
          },
        ),
      ),
    ),
  );
}

Future<BuildContext> _pumpL10nContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The coordinator is in-memory app state; reset it between tests.
    TourCoordinator.instance.clear();
  });

  group('buildSettingsTourSteps — contract', () {
    testWidgets('returns exactly kSettingsTourStepCount steps', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      final steps = buildSettingsTourSteps(context);

      expect(kSettingsTourStepCount, 1,
          reason: 'Section 3.4 defines the settings tour as a single-step '
              'pointer at the Tile Preferences row.');
      expect(steps, hasLength(kSettingsTourStepCount));
    });

    testWidgets('step ids are unique and ordered per section 3.4',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      final ids = buildSettingsTourSteps(context).map((s) => s.id).toList();

      expect(ids, ['tile_preferences']);
      expect(ids.toSet().length, ids.length,
          reason: 'Step ids must be unique.');
    });

    testWidgets('each step id anchors to the correct SettingsTourKeys key',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      final byId = {
        for (final step in buildSettingsTourSteps(context)) step.id: step,
      };

      for (final (id, anchor) in _expectedOrder) {
        expect(byId[id]!.targetKey, anchor,
            reason: 'Step "$id" must spotlight $anchor.');
      }
    });

    testWidgets('every step has distinct, non-empty l10n title and body',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      final steps = buildSettingsTourSteps(context);

      expect(
        steps.every((s) => s.title.isNotEmpty && s.body.isNotEmpty),
        isTrue,
        reason: 'Titles and bodies must come from real l10n strings.',
      );
      expect(steps.map((s) => s.title).toSet().length, 1,
          reason: 'Titles must be distinct.');
    });
  });

  group('Settings surface — anchor key sync', () {
    testWidgets('attaches each settings-tour anchor key exactly once',
        (tester) async {
      // Completed: no tour starts, the test only observes the surface.
      SharedPreferences.setMockInitialValues(
          {'hasCompletedTour_settings': true});

      await tester.pumpWidget(settingsHarness(
        key: const Key('harness'),
        stepsBuilder: buildSettingsTourSteps,
      ));

      for (final (id, anchor) in _expectedOrder) {
        expect(find.byKey(anchor), findsOneWidget,
            reason: 'The real Settings screen must attach the "$id" anchor key '
                'exactly once.');
      }
    });
  });

  group('Settings tour lifecycle (once per device)', () {
    testWidgets('starts on the first allowed visit, spotlighting row 1',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(settingsHarness(
        key: const Key('harness'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      expect(capturedBloc.state.isActive, isFalse,
          reason: 'The tour must wait for the settle delay.');

      await tester.pump(_settle);
      await tester.pump(); // post-frame key resolution
      await tester.pump(_fade);

      expect(capturedBloc.state.isActive, isTrue);
      expect(capturedBloc.state.currentStepIndex, 0);
      expect(capturedBloc.state.totalSteps, kSettingsTourStepCount);

      // The visible tooltip card must be the pointer step. (Match the card
      // itself: the step title intentionally echoes the row label, so a
      // plain find.text would match both.)
      expect(find.byType(TutorialTooltipWidget), findsOneWidget);
      final tooltip = tester
          .widget<TutorialTooltipWidget>(find.byType(TutorialTooltipWidget));
      expect(tooltip.step.id, 'tile_preferences');

      // The spotlight cutout must sit on the live Tile Preferences row.
      expect(
        _spotlightTarget(tester),
        tester.getRect(find.byKey(SettingsTourKeys.tilePreferencesTileKey)),
        reason: 'The spotlight must target the real settings row, not a '
            'stale rect.',
      );
    });

    testWidgets(
        'a real tap on the dimmed overlay completes the single-step pointer '
        'and completion persists hasCompletedTour_settings', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(settingsHarness(
        key: const Key('harness'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);
      await tester.pump();
      await tester.pump(_fade);

      expect(capturedBloc.state.isActive, isTrue);

      expect(capturedBloc.state.totalSteps, 1);

      // The only step: a real tap gesture on the dimmed overlay completes
      // the tour (the overlay's GestureDetector absorbs the tap, even over
      // the spotlight cutout — the row underneath never receives it, so
      // the pointer never navigates by itself).
      final lastRect = tester.getRect(find.byKey(_expectedOrder.last.$2));
      await tester.tapAt(Offset(28, lastRect.center.dy));
      await tester.pump();
      await tester.pump(_fade);

      expect(capturedBloc.state.isActive, isFalse);
      expect(capturedBloc.state.isCompleted, isTrue,
          reason: 'The final overlay tap must complete the tour.');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isTrue,
          reason: 'Completion must persist once per device.');
      expect(TourCoordinator.instance.activeTourId, isNull,
          reason: 'Completion must release the coordinator.');
      expect(find.byType(Settings), findsOneWidget,
          reason: 'Completing the pointer must not navigate away.');
    });

    testWidgets('does not restart the tour on revisit after completion',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {'hasCompletedTour_settings': true});

      await tester.pumpWidget(settingsHarness(
        key: const Key('harness'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);
      await tester.pump(const Duration(seconds: 1));

      expect(capturedBloc.state.isActive, isFalse,
          reason: 'Completion is terminal until an explicit reset.');
      expect(_spotlightTarget(tester), isNull,
          reason: 'No spotlight overlay may render after completion.');
      expect(
        find.text(AppLocalizations.of(capturedContext)!.accountInfo),
        findsOneWidget,
        reason: 'The settings surface must remain fully interactive.',
      );
    });

    testWidgets('explicit per-tour reset replays the tour', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'hasCompletedTour_settings': true});

      // First visit: nothing starts (already completed).
      await tester.pumpWidget(settingsHarness(
        key: const Key('first'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);
      expect(capturedBloc.state.isActive, isFalse);

      // Navigate away from Settings.
      await tester.pumpWidget(const SizedBox.shrink());

      // "How to use Tiler"-style per-tour reset.
      await TourPreferencesHelper.resetTour(
          TourPreferencesHelper.settingsTourId);

      // Next visit: the tour replays from step 1.
      await tester.pumpWidget(settingsHarness(
        key: const Key('second'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);
      await tester.pump();
      await tester.pump(_fade);

      expect(capturedBloc.state.isActive, isTrue,
          reason: 'An explicit reset must replay the tour.');
      expect(capturedBloc.state.currentStepIndex, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isFalse,
          reason: 'Reset writes false (it never removes the key).');
    });
  });

  group('TourHost — stepsBuilder pass-through', () {
    testWidgets('without stepsBuilder the home tour remains the default',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BlocProvider(
            // The home tour's overlay injects dummy tiles into the
            // ScheduleBloc (fetch errors are swallowed).
            create: (_) =>
                ScheduleBloc(getContextCallBack: (context) => context),
            child: TourHost(
              tourId: TourPreferencesHelper.homeTourId,
              stepCount: kTutorialStepCount,
              settleDelay: _settle,
              child: Builder(
                builder: (context) {
                  capturedBloc = context.read<TutorialBloc>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(_settle);
      await tester.pump();

      expect(capturedBloc.state.isActive, isTrue,
          reason: 'The default stepsBuilder must remain the home tour.');
      expect(capturedBloc.state.totalSteps, kTutorialStepCount);
    });
  });

  group('Production /Setting route wiring (Phase 2 item 3)', () {
    testWidgets(
        'buildSettingsRoute hosts the real Settings page under the settings TourHost',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      // Static contract on the production route builder itself: it must
      // wrap the real Settings page in a TourHost driving the per-device
      // settings tour (not the default home tour).
      final host = buildSettingsRoute(context) as TourHost;
      expect(host.tourId, TourPreferencesHelper.settingsTourId,
          reason: '/Setting must drive the settings tour.');
      expect(host.stepCount, kSettingsTourStepCount);
      expect(host.stepsBuilder, buildSettingsTourSteps,
          reason: 'The production route must build the settings tour steps.');
      expect(host.child, isA<Settings>(),
          reason: 'The tour host must wrap the real Settings page.');
    });

    testWidgets('first visit to the real /Setting route starts the tour',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Mount the production builder (main.dart's route target), not a
      // test-local TourHost.
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => DeviceSettingBloc(
            getContextCallBack: (context) => context,
            initialIsDarkMode: false,
          ),
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', '')],
            theme: TileThemeData.lightTheme,
            routes: {'/Setting': buildSettingsRoute},
            initialRoute: '/Setting',
          ),
        ),
      );
      // The production route uses TourHost's default 1200ms settle delay.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(); // post-frame key resolution
      await tester.pump(_fade);

      expect(find.byType(Settings), findsOneWidget);
      expect(find.byType(TutorialTooltipWidget), findsOneWidget);
      final tooltip = tester
          .widget<TutorialTooltipWidget>(find.byType(TutorialTooltipWidget));
      expect(tooltip.step.id, 'tile_preferences',
          reason: 'First visit to the production /Setting route must start the '
              'settings pointer.');
      expect(
        _spotlightTarget(tester),
        tester.getRect(find.byKey(SettingsTourKeys.tilePreferencesTileKey)),
        reason: "The production route's spotlight must target the real row.",
      );
    });
  });

  group('"How to use Tiler" manual replay row (Phase 2 item 4)', () {
    testWidgets('the settings surface shows the "How to use Tiler" row',
        (tester) async {
      // Completed: no tour starts, the test only observes the surface.
      SharedPreferences.setMockInitialValues({
        'hasCompletedTour_settings': true,
      });

      await tester.pumpWidget(settingsHarness(
        key: const Key('harness'),
        stepsBuilder: buildSettingsTourSteps,
      ));

      final l10n = AppLocalizations.of(capturedContext)!;
      expect(find.text(l10n.howToUseTiler), findsOneWidget,
          reason:
              'The settings list must offer the manual per-device tour replay.');
    });

    testWidgets('tapping the row resets every tour (replay-all)',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'hasCompletedTour_home': true,
        'hasCompletedTour_settings': true,
        'hasCompletedTour_tile_preferences': true,
      });

      await tester.pumpWidget(settingsHarness(
        key: const Key('harness'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);

      final l10n = AppLocalizations.of(capturedContext)!;
      await tester.tap(find.text(l10n.howToUseTiler));
      await tester.pump();
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_home'), isFalse,
          reason: 'Replay-all must clear the home tour completion.');
      expect(prefs.getBool('hasCompletedTour_settings'), isFalse,
          reason: 'Replay-all must clear the settings pointer completion.');
      expect(prefs.getBool('hasCompletedTour_tile_preferences'), isFalse,
          reason:
              'Replay-all must clear the Tile Preferences tour completion.');
      expect(prefs.getBool('hasCompletedAppTutorial'), isNull,
          reason:
              'The multi-tour path must never write the legacy flag (1.2).');
      expect(find.byType(Settings), findsOneWidget,
          reason: 'The row acts in place; tapping it must not navigate away.');
    });

    testWidgets(
        'after tapping the row the next settings visit replays the tour and '
        'the home tour is primed to replay as well', (tester) async {
      SharedPreferences.setMockInitialValues({
        'hasCompletedTour_home': true,
        'hasCompletedTour_settings': true,
      });

      // Visit 1: both tours completed -> nothing starts.
      await tester.pumpWidget(settingsHarness(
        key: const Key('first'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);
      expect(capturedBloc.state.isActive, isFalse);

      final l10n = AppLocalizations.of(capturedContext)!;
      await tester.tap(find.text(l10n.howToUseTiler));
      await tester.pump();
      await tester.pump();

      // Leave the settings surface.
      await tester.pumpWidget(const SizedBox.shrink());

      // Visit 2: the settings tour replays from step 1.
      await tester.pumpWidget(settingsHarness(
        key: const Key('second'),
        stepsBuilder: buildSettingsTourSteps,
      ));
      await tester.pump(_settle);
      await tester.pump(); // post-frame key resolution
      await tester.pump(_fade);

      expect(capturedBloc.state.isActive, isTrue,
          reason: '"How to use Tiler" must replay the tour on the next visit.');
      expect(capturedBloc.state.currentStepIndex, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_home'), isFalse,
          reason:
              'The home tour must be primed for replay on the next home visit.');
    });
  });
}
