// notification_permission_startup_test.dart
//
// TDD red stage for the "no notification prompt on first launch" bug.
//
// Symptom: a fresh install never shows the push-permission prompt, not even
// after a full close and reopen. Signing out and back in does show it.
//
// Hypothesis under test (LocalNotificationService, as driven by
// AuthorizedRoute.initState):
//   H1. `initializeRemoteNotification` calls
//       `OneSignal.Notifications.requestPermission` BEFORE `OneSignal.initialize`
//       (which only runs later in `subscribeToRemoteNotification`). The native
//       SDK is not started yet, so the request is dropped, and the try/catch
//       hides the failure.
//   H2. The prompt depends on "is notification data saved?" instead of on the
//       real permission state. Once the channel data is saved, later launches
//       never ask again. Sign-out deletes that data, and by then OneSignal is
//       started in this process, which is why sign-in "fixes" it.
//   H3. When the channel lookup returns null (e.g. no credentials yet),
//       saving `NotificationData.noCredentials()` throws (its `late` fields
//       are never set), which aborts startup before OneSignal is started.
//
// Product rule locked in alongside the fix:
//   R1. Never prompt before the user has finished (or skipped) the essentials
//       onboarding. The gate is `Utility.checkOnboardingStatus`. The service
//       enforces it itself, so a stray navigation straight to AuthorizedRoute
//       cannot prompt a user who has not set up the app.
//   R2. Every user who enters the app is asked, whether they submitted or
//       skipped onboarding. (There is no Cancel: a user who closes the app
//       mid-flow lands back on onboarding next launch and is asked once they
//       Submit or Skip.)
//
// The tests drive the real service through the same call sequence
// AuthorizedRoute uses and record every OneSignal platform-channel call, so
// they need no production seams. Tests marked [guard] pass today and must keep
// passing after the fix.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/services/api/notificationData.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/constants.dart' as Constants;

const _initialize = 'OneSignal#initialize';
const _requestPermission = 'OneSignal#requestPermission';

const _oneSignalChannels = <String>[
  'OneSignal',
  'OneSignal#notifications',
  'OneSignal#debug',
  'OneSignal#user',
  'OneSignal#pushsubscription',
  'OneSignal#inappmessages',
];

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// The value the `notification` secure-storage key holds after a successful
/// channel lookup on a previous launch.
final _savedNotificationJson = jsonEncode({
  'notificationId': 'tiler-user-1',
  'thirdPartyId': 'third-party-1',
  'expiresIn': 0,
  'channelType': 'upcomingtiles',
});

/// Fake native side: an in-memory keychain plus a OneSignal call log.
class _FakeDevice {
  _FakeDevice({
    Map<String, String>? keychain,
    this.permissionGranted = false,
    this.canRequest = true,
  }) : keychain = keychain ?? {};

  final Map<String, String> keychain;
  final bool permissionGranted;
  final bool canRequest;
  final List<String> oneSignalCalls = [];

  bool get initialized => oneSignalCalls.contains(_initialize);
  int get permissionRequests =>
      oneSignalCalls.where((m) => m == _requestPermission).length;

  /// Whether OneSignal was started when the first permission request arrived.
  bool? initializedAtFirstRequest;

  void install(TestDefaultBinaryMessenger messenger) {
    messenger.setMockMethodCallHandler(_secureStorageChannel, (call) async {
      final args = (call.arguments as Map?) ?? const {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return keychain[key];
        case 'write':
          keychain[key!] = args['value'] as String;
          return null;
        case 'delete':
          keychain.remove(key);
          return null;
        case 'containsKey':
          return keychain.containsKey(key);
        case 'readAll':
          return Map<String, String>.from(keychain);
        case 'deleteAll':
          keychain.clear();
          return null;
      }
      return null;
    });

    for (final name in _oneSignalChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        if (call.method == _requestPermission) {
          initializedAtFirstRequest ??= initialized;
        }
        oneSignalCalls.add(call.method);
        switch (call.method) {
          case 'OneSignal#permission':
            return permissionGranted;
          case 'OneSignal#canRequest':
            return canRequest;
          case 'OneSignal#requestPermission':
            return true;
          case 'OneSignal#pushSubscriptionOptedIn':
            return permissionGranted;
        }
        return null;
      });
    }
  }

  void uninstall(TestDefaultBinaryMessenger messenger) {
    messenger.setMockMethodCallHandler(_secureStorageChannel, null);
    for (final name in _oneSignalChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  }
}

/// Mirrors AuthorizedRoute.initState: initialize, then subscribe on success.
/// Returns the error that aborted startup, if any.
Future<Object?> _runAuthorizedRouteStartup(BuildContext context) async {
  final service = LocalNotificationService();
  try {
    await service.initializeRemoteNotification();
    await service.subscribeToRemoteNotification(context);
  } catch (e) {
    return e;
  }
  return null;
}

Future<({_FakeDevice device, Object? error})> _launch(
  WidgetTester tester, {
  required Map<String, Object> prefs,
  required _FakeDevice device,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  device.install(tester.binding.defaultBinaryMessenger);
  addTearDown(() => device.uninstall(tester.binding.defaultBinaryMessenger));

  late BuildContext context;
  await tester.pumpWidget(Builder(builder: (c) {
    context = c;
    return const SizedBox.shrink();
  }));

  final error = await _runAuthorizedRouteStartup(context);
  await tester.pump();
  return (device: device, error: error);
}

const _onboarded = <String, Object>{
  OnBoardingSharedPreferencesHelper.essentialsOnboardingDoneKey: true,
};

void main() {
  setUpAll(() {
    dotenv.testLoad(mergeWith: {Constants.oneSignalAppIdKey: 'test-app-id'});
  });

  group('H1: permission is requested only after OneSignal is started', () {
    testWidgets('fresh install after onboarding: prompt follows initialize',
        (tester) async {
      final result = await _launch(tester,
          prefs: _onboarded, device: _FakeDevice());

      expect(result.device.permissionRequests, greaterThan(0),
          reason: 'An onboarded user with no decision yet must be prompted.');
      expect(result.device.initializedAtFirstRequest, isTrue,
          reason: 'requestPermission reached OneSignal before '
              'OneSignal#initialize. The native SDK is not started yet, so '
              'the prompt is dropped (H1). Calls: '
              '${result.device.oneSignalCalls}');
    });
  });

  group('H2: prompt depends on permission state, not on saved channel data',
      () {
    testWidgets(
        'relaunch with saved channel data and no decision yet: still prompts',
        (tester) async {
      // Also the iOS reinstall case: the keychain (secure storage) survives
      // an uninstall, so a "fresh" install can already hold channel data.
      final result = await _launch(tester,
          prefs: _onboarded,
          device: _FakeDevice(
              keychain: {'notification': _savedNotificationJson},
              permissionGranted: false,
              canRequest: true));

      expect(result.error, isNull);
      expect(result.device.permissionRequests, 1,
          reason: 'Saved channel data skipped the prompt entirely. A user '
              'who never answered it is never asked again (H2). Calls: '
              '${result.device.oneSignalCalls}');
      expect(result.device.initializedAtFirstRequest, isTrue);
    });

    testWidgets('[guard] relaunch with permission already granted: no prompt',
        (tester) async {
      final result = await _launch(tester,
          prefs: _onboarded,
          device: _FakeDevice(
              keychain: {'notification': _savedNotificationJson},
              permissionGranted: true,
              canRequest: false));

      expect(result.error, isNull);
      expect(result.device.permissionRequests, 0);
      expect(result.device.initialized, isTrue);
    });
  });

  group('H3: a missing notification channel does not abort startup', () {
    testWidgets('channel lookup returns null: OneSignal is still started',
        (tester) async {
      // Empty keychain = no credentials, so getNotificationChannel
      // returns null without touching the network.
      final result = await _launch(tester,
          prefs: _onboarded, device: _FakeDevice());

      expect(result.error, isNull,
          reason: 'Saving NotificationData.noCredentials() threw, which '
              'aborts startup before subscribeToRemoteNotification (H3).');
      expect(result.device.initialized, isTrue);
    });

    test('noCredentials survives a save/read round trip and stays invalid',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final device = _FakeDevice();
      final messenger = TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger;
      device.install(messenger);
      addTearDown(() => device.uninstall(messenger));

      final storage = SecureStorageManager();
      await storage.saveNotificationData(NotificationData.noCredentials());
      final readBack = await storage.readNotificationData();

      expect(readBack, isNotNull);
      expect(readBack!.isValid, isFalse,
          reason: 'fromJson always sets isValid = true, so an empty record '
              'is read back as valid and suppresses the prompt forever.');
    });
  });

  group('R1: never prompt before onboarding is complete', () {
    testWidgets('fresh device, onboarding not done: no prompt',
        (tester) async {
      final result = await _launch(tester, prefs: {}, device: _FakeDevice());

      expect(result.device.permissionRequests, 0,
          reason: 'The user has not set up the app yet. The prompt belongs '
              'after the essentials onboarding. Calls: '
              '${result.device.oneSignalCalls}');
    });

    testWidgets(
        '[guard] onboarding not done, stale channel data in keychain: no prompt',
        (tester) async {
      final result = await _launch(tester,
          prefs: {},
          device: _FakeDevice(
              keychain: {'notification': _savedNotificationJson},
              permissionGranted: false,
              canRequest: true));

      expect(result.device.permissionRequests, 0);
    });

    testWidgets('user taps Skip on the essentials flow: prompts on entry',
        (tester) async {
      // Run the real Skip handler so the test tracks whatever flags it
      // writes, rather than assuming them.
      SharedPreferences.setMockInitialValues({});
      final bloc = OnboardingBloc(
          onBoardingApi: OnBoardingApi(),
          settingsApi: SettingsApi(getContextCallBack: () => null));
      addTearDown(bloc.close);
      bloc.add(SkipOnboardingEvent());
      await tester.runAsync(() =>
          bloc.stream.firstWhere((s) => s.step == OnboardingStep.skipped));
      final prefsAfterSkip = await SharedPreferences.getInstance();
      final writtenBySkip = <String, Object>{
        for (final key in prefsAfterSkip.getKeys())
          key: prefsAfterSkip.get(key)!,
      };

      final result = await _launch(tester,
          prefs: writtenBySkip,
          device: _FakeDevice(permissionGranted: false, canRequest: true));

      expect(result.device.permissionRequests, 1,
          reason: 'Skipping onboarding still enters the app, so the user '
              'must be asked. Calls: ${result.device.oneSignalCalls}');
      expect(result.device.initializedAtFirstRequest, isTrue);
    });

    testWidgets('legacy skipOnboarding counts as set up: prompts',
        (tester) async {
      final result = await _launch(tester,
          prefs: {'skipOnboarding': true},
          device: _FakeDevice(
              keychain: {'notification': _savedNotificationJson},
              permissionGranted: false,
              canRequest: true));

      expect(result.device.permissionRequests, 1,
          reason: 'skipOnboarding == true passes the onboarding gate '
              '(Utility.checkOnboardingStatus).');
      expect(result.device.initializedAtFirstRequest, isTrue);
    });
  });
}
