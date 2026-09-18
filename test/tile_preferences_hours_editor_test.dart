// Step 6.6 — Tile Preferences edits Work / Personal hours in the Phase 6
// Custom hours editor instead of the legacy `/TimeRestrictionRoute` hop.
//
// The page keeps its own Save: the editor runs in profile mode WITHOUT
// persisting (`persist: false`), returns the edited profile with its id, and
// the bloc receives `UpdateWorkProfile` / `UpdatePersonalProfile` exactly as
// before — `ProceedUpdate` still writes both profiles on Save.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileCustomHoursScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/bloc/tile_preferences_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/tilePreferences.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'addTile/restriction_hours_draft_test.dart' as fx;

class FakeSettingsApi extends SettingsApi {
  FakeSettingsApi({this.work, this.personal})
      : super(getContextCallBack: () => null);

  final RestrictionProfile? work;
  final RestrictionProfile? personal;
  int updateCalls = 0;

  @override
  Future<Map<String, RestrictionProfile>> getUserRestrictionProfile() async =>
      <String, RestrictionProfile>{
        if (work != null) 'work': work!,
        if (personal != null) 'personal': personal!,
      };

  @override
  Future<RestrictionProfile> updateRestrictionProfile(
      RestrictionProfile restrictionProfile,
      {String? restrictionProfileType}) async {
    updateCalls++;
    return restrictionProfile;
  }

  @override
  Future<UserSettings> getUserSettings() async => UserSettings.fromJson({
        'scheduleProfile': {
          'sleepDuration': const Duration(hours: 8).inMilliseconds,
        },
      });

  @override
  Future<StartOfDay> getUserStartOfDay() async => StartOfDay();
}

Widget harness(TilePreferencesBloc bloc) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: TileThemeData.lightTheme,
      home: TilePreferencesScreen(bloc: bloc),
    );

String _code(File f) => f
    .readAsLinesSync()
    .where((String l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_timezone'),
            (MethodCall call) async => 'America/New_York');
  });

  Future<(TilePreferencesBloc, FakeSettingsApi)> loaded(
      WidgetTester tester, RestrictionProfile? work) async {
    // A wide logical surface: the page's legacy bed-time row overflows the
    // test font at phone width, which is not what this test is about.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final FakeSettingsApi api = FakeSettingsApi(work: work);
    final TilePreferencesBloc bloc = TilePreferencesBloc(settingsApi: api)
      ..add(FetchProfiles());
    addTearDown(bloc.close);
    await tester.pumpWidget(harness(bloc));
    await tester.pump();
    await tester.pump();
    expect(bloc.state, isA<PreferencesLoaded>());
    return (bloc, api);
  }

  testWidgets(
      'Set Work Hours opens the Custom hours editor in profile mode, without '
      'persisting; Done hands the edited profile to the bloc', (tester) async {
    final RestrictionProfile work = fx.weekdays(id: 'work-1');
    final (TilePreferencesBloc bloc, FakeSettingsApi api) =
        await loaded(tester, work);

    await tester.ensureVisible(find.text('Set Work Hours'));
    await tester.tap(find.text('Set Work Hours'));
    await tester.pumpAndSettle();

    final AddTileCustomHoursScreen editor =
        tester.widget<AddTileCustomHoursScreen>(
            find.byType(AddTileCustomHoursScreen));
    expect(editor.request.profileType, NamedRestrictionProfileType.work);
    expect(editor.request.seed, same(work));
    expect(editor.persist, isFalse,
        reason: 'the page keeps its own Save; the bloc persists');

    // Switch Saturday on and confirm.
    // The editor's OWN list: the page underneath is still in the tree.
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('hoursDay_6')), 120,
        scrollable: find.descendant(
            of: find.byType(AddTileCustomHoursScreen),
            matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const ValueKey('hoursSwitch_6')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hoursDone')));
    await tester.pumpAndSettle();

    expect(find.byType(AddTileCustomHoursScreen), findsNothing);
    expect(api.updateCalls, 0, reason: 'nothing written until Save');
    final PreferencesLoaded state = bloc.state as PreferencesLoaded;
    expect(state.hasChanges, isTrue);
    expect(state.workProfile!.id, 'work-1');
    expect(state.workProfile!.daySelection[6], isNotNull);
    expect(state.workProfile!.daySelection[0], isNull);
  });

  testWidgets('a profile that is not set up opens the editor empty',
      (tester) async {
    final (TilePreferencesBloc bloc, _) = await loaded(tester, null);
    await tester.ensureVisible(find.text('Set Personal Hours'));
    await tester.tap(find.text('Set Personal Hours'));
    await tester.pumpAndSettle();
    final AddTileCustomHoursScreen editor =
        tester.widget<AddTileCustomHoursScreen>(
            find.byType(AddTileCustomHoursScreen));
    expect(editor.request.profileType, NamedRestrictionProfileType.personal);
    expect(editor.request.seed, isNull);
    // Back: nothing reaches the bloc.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect((bloc.state as PreferencesLoaded).hasChanges, isFalse);
  });

  test('the legacy /TimeRestrictionRoute hop is gone from Tile Preferences',
      () {
    final String code = _code(File(
        'lib/routes/authenticatedUser/settings/tilePreferences/tilePreferences.dart'));
    expect(code.contains('/TimeRestrictionRoute'), isFalse);
    expect(code.contains('AddTileCustomHoursScreen('), isTrue);
  });
}
