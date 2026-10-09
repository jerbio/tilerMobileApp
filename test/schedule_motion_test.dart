// "Schedule updates" setting: persistence, cubit,
// the effective-mode resolver, and the settings row + sheet.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart';
import 'package:tiler_app/bloc/scheduleMotion/schedule_motion_cubit.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/scheduleUpdatesSetting.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/scheduleMotion.dart';
import 'package:tiler_app/services/scheduleMotionPreferences.dart';

const _key = ScheduleMotionPreferences.modeKey;

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ScheduleMotionPreferences', () {
    test('absent value defaults to detailed', () async {
      expect(await ScheduleMotionPreferences.getMode(),
          ScheduleUpdateMode.detailed);
    });

    test('unknown or wrong-type values default to detailed', () async {
      SharedPreferences.setMockInitialValues({_key: 'nonsense'});
      expect(await ScheduleMotionPreferences.getMode(),
          ScheduleUpdateMode.detailed);
      SharedPreferences.setMockInitialValues({_key: 3});
      expect(await ScheduleMotionPreferences.getMode(),
          ScheduleUpdateMode.detailed);
    });

    test('every mode round-trips', () async {
      for (final mode in ScheduleUpdateMode.values) {
        await ScheduleMotionPreferences.setMode(mode);
        expect(await ScheduleMotionPreferences.getMode(), mode);
      }
    });
  });

  group('ScheduleUpdateMode', () {
    test('animates / choreographs', () {
      expect(ScheduleUpdateMode.off.animates, isFalse);
      expect(ScheduleUpdateMode.minimal.animates, isTrue);
      expect(ScheduleUpdateMode.minimal.choreographs, isFalse);
      expect(ScheduleUpdateMode.detailed.choreographs, isTrue);
    });

    test('capAt keeps the lower mode', () {
      expect(ScheduleUpdateMode.detailed.capAt(ScheduleUpdateMode.minimal),
          ScheduleUpdateMode.minimal);
      expect(ScheduleUpdateMode.off.capAt(ScheduleUpdateMode.detailed),
          ScheduleUpdateMode.off);
    });
  });

  group('ScheduleMotion.effective', () {
    test('lowest of setting, reduced motion and origin', () {
      const origins = <ScheduleChangeOrigin?>[null, ...ScheduleChangeOrigin.values];
      for (final setting in ScheduleUpdateMode.values) {
        for (final reduce in [false, true]) {
          for (final origin in origins) {
            var expected = setting;
            if (reduce) {
              expected = ScheduleUpdateMode.off;
            } else if (origin == ScheduleChangeOrigin.refresh &&
                setting == ScheduleUpdateMode.detailed) {
              expected = ScheduleUpdateMode.minimal;
            }
            expect(
                ScheduleMotion.effective(
                    setting: setting, reduceMotion: reduce, origin: origin),
                expected,
                reason: '$setting reduce=$reduce origin=$origin');
          }
        }
      }
    });
  });

  group('ScheduleMotionCubit', () {
    tearDown(() => AnalysticsSignal.testSink = null);

    test('starts on detailed and restores the stored mode', () async {
      SharedPreferences.setMockInitialValues({_key: 'minimal'});
      final cubit = ScheduleMotionCubit();
      expect(cubit.state, ScheduleUpdateMode.detailed);
      await settle();
      expect(cubit.state, ScheduleUpdateMode.minimal);
      await cubit.close();
    });

    test('setMode persists and logs from/to', () async {
      final events = <String, Map<String, Object>>{};
      AnalysticsSignal.testSink = (tag, payload) async => events[tag] = payload;
      final cubit = ScheduleMotionCubit();
      await settle();
      await cubit.setMode(ScheduleUpdateMode.off);
      expect(cubit.state, ScheduleUpdateMode.off);
      expect(await ScheduleMotionPreferences.getMode(), ScheduleUpdateMode.off);
      expect(events.keys, contains('schedule_update_mode_changed'));
      expect(events['schedule_update_mode_changed'].toString(),
          allOf(contains('detailed'), contains('off')));
      await cubit.close();
    });

    test('setting the current mode is a no-op', () async {
      var sent = 0;
      AnalysticsSignal.testSink = (tag, payload) async => sent++;
      final cubit = ScheduleMotionCubit();
      await settle();
      await cubit.setMode(ScheduleUpdateMode.detailed);
      expect(sent, 0);
      await cubit.close();
    });
  });

  Widget app(Widget child, {ScheduleMotionCubit? cubit, bool reduce = false}) {
    Widget home = Scaffold(body: child);
    if (reduce) {
      home = Builder(
          builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(body: child)));
    }
    final material = MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
    return cubit == null
        ? material
        : BlocProvider<ScheduleMotionCubit>.value(value: cubit, child: material);
  }

  group('ScheduleMotion.modeFor', () {
    ScheduleUpdateMode? seen;
    final probe = Builder(builder: (context) {
      seen = ScheduleMotion.modeFor(context);
      return const SizedBox();
    });

    testWidgets('defaults to detailed without a cubit', (tester) async {
      await tester.pumpWidget(app(probe));
      expect(seen, ScheduleUpdateMode.detailed);
    });

    testWidgets('follows the cubit and rebuilds on change', (tester) async {
      final cubit = ScheduleMotionCubit();
      await tester.runAsync(settle);
      await tester.pumpWidget(app(probe, cubit: cubit));
      expect(seen, ScheduleUpdateMode.detailed);
      await tester.runAsync(() => cubit.setMode(ScheduleUpdateMode.minimal));
      await tester.pump();
      expect(seen, ScheduleUpdateMode.minimal);
      await cubit.close();
    });

    testWidgets('OS reduced motion forces off', (tester) async {
      await tester.pumpWidget(app(probe, reduce: true));
      expect(seen, ScheduleUpdateMode.off);
    });
  });

  group('Settings row', () {
    testWidgets('shows the mode and changes it from the sheet',
        (tester) async {
      final cubit = ScheduleMotionCubit();
      await tester.runAsync(settle);
      await tester.pumpWidget(
          app(const ScheduleUpdatesSettingTile(color: Colors.black), cubit: cubit));

      expect(find.text('Schedule updates'), findsOneWidget);
      expect(find.text('Detailed'), findsOneWidget);

      await tester.tap(find.byKey(ScheduleUpdatesSettingTile.tileKey));
      await tester.pumpAndSettle();
      for (final mode in ScheduleUpdatesSheet.order) {
        expect(find.byKey(ScheduleUpdatesSheet.optionKey(mode)), findsOneWidget);
      }
      expect(find.text('Update instantly, no animation.'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(
            find.byKey(ScheduleUpdatesSheet.optionKey(ScheduleUpdateMode.off)));
        await settle();
      });
      await tester.pumpAndSettle();

      expect(cubit.state, ScheduleUpdateMode.off);
      expect(find.byKey(ScheduleUpdatesSheet.optionKey(ScheduleUpdateMode.off)),
          findsNothing);
      expect(find.text('Off'), findsOneWidget);
      expect(await tester.runAsync(ScheduleMotionPreferences.getMode),
          ScheduleUpdateMode.off);
      await cubit.close();
    });

    testWidgets('is left out without the app-level cubit', (tester) async {
      await tester
          .pumpWidget(app(const ScheduleUpdatesSettingTile(color: Colors.black)));
      expect(find.byKey(ScheduleUpdatesSettingTile.tileKey), findsNothing);
    });
  });
}
