// duration_picker_migration_test.dart
//
// Every remaining duration entry in the app opens the redesigned
// `AddTileDurationScreen` (wheel + preset chips), not the legacy
// `/DurationDial` route. The dial was replaced for the Add/Edit Tile
// redesign but four callers were left on the old route, so the same
// gesture produced two different pickers depending on where the user
// tapped. Locks in:
//   1. `DurationInputWidget` (add-tile sheet, tile-share sheets): tapping
//      opens the new screen seeded with the current value; committing a
//      preset writes it back and fires `onDurationChange`; Back leaves the
//      value alone and fires nothing.
//   2. Tile Preferences sleep duration: tapping opens the new screen seeded
//      with the stored sleep duration; committing a preset dispatches
//      `UpdateSleepDuration` (state updated, `hasChanges` true).
//   3. `pushDurationPicker` is the one adapter every caller goes through:
//      it returns the committed duration, or null on Back.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/bloc/tile_preferences_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/tilePreferences.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final _l10n = lookupAppLocalizations(const Locale('en'));

/// The first preset chip on the new screen and the value it commits.
final Finder _firstPreset = find.byKey(const ValueKey('durationPreset_0'));
final Duration _firstPresetValue = addTileDurationPresets.first;

Widget _app(Widget home) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: _l10nDelegates,
      supportedLocales: const [Locale('en', '')],
      home: home,
    );

class FakeSettingsApi extends SettingsApi {
  FakeSettingsApi() : super(getContextCallBack: () => null);

  @override
  Future<Map<String, RestrictionProfile>> getUserRestrictionProfile() async =>
      {};

  @override
  Future<UserSettings> getUserSettings() async => UserSettings.fromJson({
        'scheduleProfile': {
          'sleepDuration': const Duration(hours: 8).inMilliseconds,
        },
      });

  @override
  Future<StartOfDay> getUserStartOfDay() async => StartOfDay();
}

void _mockTimezoneChannel(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter_timezone'),
    (call) async => 'America/New_York',
  );
}

void main() {
  group('pushDurationPicker — the one adapter', () {
    testWidgets('returns the committed preset', (tester) async {
      Duration? result;
      await tester.pumpWidget(_app(Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            result = await pushDurationPicker(context,
                initialDuration: const Duration(minutes: 45));
          },
          child: const Text('open'),
        );
      })));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final screen = tester
          .widget<AddTileDurationScreen>(find.byType(AddTileDurationScreen));
      expect(screen.initialDuration, const Duration(minutes: 45),
          reason: 'The picker must open on the current value.');

      await tester.tap(_firstPreset);
      await tester.pumpAndSettle();
      expect(result, _firstPresetValue);
      expect(find.byType(AddTileDurationScreen), findsNothing);
    });

    testWidgets('returns null on Back', (tester) async {
      Duration? result = const Duration(minutes: 1);
      await tester.pumpWidget(_app(Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            result = await pushDurationPicker(context,
                initialDuration: const Duration(minutes: 45));
          },
          child: const Text('open'),
        );
      })));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('DurationInputWidget (add-tile & tile-share sheets)', () {
    testWidgets(
        'opens the redesigned picker seeded with its value and applies the '
        'committed preset', (tester) async {
      Duration? changed;
      await tester.pumpWidget(_app(Scaffold(
        body: DurationInputWidget(
          duration: const Duration(hours: 2),
          onDurationChange: (Duration? d) => changed = d,
        ),
      )));

      await tester.tap(find.byType(DurationInputWidget));
      await tester.pumpAndSettle();

      expect(find.byType(AddTileDurationScreen), findsOneWidget,
          reason: 'The sheets must open the same picker as the redesign.');
      expect(
        tester
            .widget<AddTileDurationScreen>(find.byType(AddTileDurationScreen))
            .initialDuration,
        const Duration(hours: 2),
      );

      await tester.tap(_firstPreset);
      await tester.pumpAndSettle();

      expect(changed, _firstPresetValue,
          reason: 'The committed value must reach the sheet.');
      expect(find.byType(AddTileDurationScreen), findsNothing);
    });

    testWidgets('Back leaves the value alone and fires no change',
        (tester) async {
      int calls = 0;
      await tester.pumpWidget(_app(Scaffold(
        body: DurationInputWidget(
          duration: const Duration(hours: 2),
          onDurationChange: (Duration? d) => calls++,
        ),
      )));
      await tester.tap(find.byType(DurationInputWidget));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(calls, 0, reason: 'Cancelling is not a change.');
      expect(find.text('2h'), findsOneWidget,
          reason: 'The label still shows the original value.');
    });
  });

  group('Tile Preferences — sleep duration', () {
    testWidgets(
        'opens the redesigned picker seeded with the stored sleep duration '
        'and dispatches the committed preset', (tester) async {
      _mockTimezoneChannel(tester);
      final bloc = TilePreferencesBloc(settingsApi: FakeSettingsApi())
        ..add(FetchProfiles());
      addTearDown(bloc.close);

      await tester.pumpWidget(_app(TilePreferencesScreen(bloc: bloc)));
      await tester.pump();
      await tester.pump();
      expect(find.text(_l10n.sleepDuration), findsOneWidget);

      // The sleep-duration button shows "8:00" for the stored 8h. The
      // block-out card can sit below the fold, so bring it on screen first.
      await tester.ensureVisible(find.text('8:00'));
      await tester.tap(find.text('8:00'));
      await tester.pumpAndSettle();

      expect(find.byType(AddTileDurationScreen), findsOneWidget,
          reason: 'Settings must open the same picker as the redesign.');
      expect(
        tester
            .widget<AddTileDurationScreen>(find.byType(AddTileDurationScreen))
            .initialDuration,
        const Duration(hours: 8),
      );

      await tester.tap(_firstPreset);
      await tester.pumpAndSettle();

      final state = bloc.state as PreferencesLoaded;
      expect(state.userSettings!.scheduleProfile!.sleepDuration,
          _firstPresetValue.inMilliseconds,
          reason: 'The committed value must reach the preferences bloc.');
      expect(state.hasChanges, isTrue);
    });
  });
}
