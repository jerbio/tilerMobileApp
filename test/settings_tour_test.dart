// settings_tour_test.dart
//
// TDD stage 2.1 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, section 3.4 "Settings tour steps"
// and Phase 2 "Settings tour").
//
// Locks in the 4-step settings tour contract:
//   1. `buildSettingsTourSteps(context)` returns exactly
//      `kSettingsTourStepCount` (4) steps.
//   2. Step ids are unique and ordered:
//      `account_info`, `tile_preferences`, `notifications`, `connections`.
//   3. Each step id anchors to the correct `SettingsTourKeys` GlobalKey.
//   4. The real `Settings` widget attaches each anchor key exactly once
//      (key-sync test, mirroring the `kTutorialStepCount` sync tests).
//   5. The tour triggers once per device: it starts on the first allowed
//      visit via `TourHost(stepsBuilder: buildSettingsTourSteps)`, the
//      spotlight lands on the live settings rows, and advancing with real
//      taps on the dimmed overlay persists `hasCompletedTour_settings`.
//   6. Revisits do not restart the tour.
//   7. An explicit per-tour reset (`TourPreferencesHelper.resetTour`)
//      replays the tour.
//   8. Home parity: `TourHost` without `stepsBuilder` keeps the home tour
//      as its default (pass-through behavior).

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
  ('account_info', SettingsTourKeys.accountInfoTileKey),
  ('tile_preferences', SettingsTourKeys.tilePreferencesTileKey),
  ('notifications', SettingsTourKeys.notificationsTileKey),
  ('connections', SettingsTourKeys.connectionsTileKey),
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
    testWidgets('returns exactly kSettingsTourStepCount steps',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      final steps = buildSettingsTourSteps(context);

      expect(kSettingsTourStepCount, 4,
          reason: 'Section 3.4 defines exactly four settings tour steps.');
      expect(steps, hasLength(kSettingsTourStepCount));
    });

    testWidgets('step ids are unique and ordered per section 3.4',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final context = await _pumpL10nContext(tester);

      final ids = buildSettingsTourSteps(context).map((s) => s.id).toList();

      expect(ids, [
        'account_info',
        'tile_preferences',
        'notifications',
        'connections',
      ]);
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
      expect(steps.map((s) => s.title).toSet().length, 4,
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
            reason:
                'The real Settings screen must attach the "$id" anchor key '
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

      // The visible tooltip card must be the first settings step. (Match
      // the card itself: the step title intentionally echoes the row
      // label, so a plain find.text would match both.)
      expect(find.byType(TutorialTooltipWidget), findsOneWidget);
      final tooltip = tester
          .widget<TutorialTooltipWidget>(find.byType(TutorialTooltipWidget));
      expect(tooltip.step.id, 'account_info');

      // The spotlight cutout must sit on the live Account Info row.
      expect(
        _spotlightTarget(tester),
        tester.getRect(find.byKey(SettingsTourKeys.accountInfoTileKey)),
        reason: 'The spotlight must target the real settings row, not a '
            'stale rect.',
      );
    });

    testWidgets(
        'advancing with real taps on the dimmed overlay walks the 4 steps '
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

      // Advance through the first three steps with a real tap gesture on
      // the dimmed overlay (the overlay's GestureDetector absorbs the tap,
      // even over the spotlight cutout — the rows underneath never receive
      // it).
      for (int i = 0; i < kSettingsTourStepCount - 1; i++) {
        final rowRect = tester.getRect(find.byKey(_expectedOrder[i].$2));
        await tester.tapAt(Offset(28, rowRect.center.dy));
        await tester.pump();
        await tester.pump(_fade);
        await tester.pump(); // post-frame key resolution for the next row

        expect(capturedBloc.state.currentStepIndex, i + 1,
            reason: 'A tap on the dimmed overlay must advance to step '
                '${i + 2}.');
        // The visible tooltip card must be the advanced step (its title
        // intentionally echoes the row label, so match the card itself).
        final tooltip = tester
            .widget<TutorialTooltipWidget>(find.byType(TutorialTooltipWidget));
        expect(tooltip.step.id, _expectedOrder[i + 1].$1);
        expect(
          _spotlightTarget(tester),
          tester.getRect(find.byKey(_expectedOrder[i + 1].$2)),
          reason: 'Step ${i + 2} must spotlight the live settings row.',
        );
      }

      // The fourth (last) step: tapping the overlay completes the tour.
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
      expect(tooltip.step.id, 'account_info',
          reason:
              'First visit to the production /Setting route must start the '
              'settings tour at step 1.');
      expect(
        _spotlightTarget(tester),
        tester.getRect(find.byKey(SettingsTourKeys.accountInfoTileKey)),
        reason:
            "The production route's spotlight must target the real row.",
      );
    });
  });
}