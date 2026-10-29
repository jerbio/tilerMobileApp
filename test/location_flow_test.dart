import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/permissionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

Position _position({double latitude = 39.83, double longitude = -105.21}) =>
    Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

class _Geolocator extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Future<Position> Function() acquire = () async => _position();
  int acquisitionCount = 0;
  int permissionRequestCount = 0;
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequestCount++;
    return permission = LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    acquisitionCount++;
    settings = locationSettings;
    return acquire();
  }
}

class _Settings extends DeviceSettingBloc {
  final events = <DeviceSettingEvent>[];

  _Settings() : super(getContextCallBack: () => null, initialIsDarkMode: false);

  @override
  void add(DeviceSettingEvent event) {
    events.add(event);
    super.add(event);
  }
}

class _Api extends AppApi {
  _Api(BuildContext? Function() context) : super(getContextCallBack: context);
}

const _params = {'TimeZone': 'UTC', 'TimeZoneOffset': '0'};

Widget _harness(DeviceSettingBloc settings, Widget child) =>
    BlocProvider<DeviceSettingBloc>.value(
      value: settings,
      child: MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

// The permission dialog contains a looping Lottie animation.
Future<void> _pumpLocationFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GeolocatorPlatform originalGeolocator;
  late _Geolocator geolocator;

  setUp(() {
    originalGeolocator = GeolocatorPlatform.instance;
    geolocator = _Geolocator();
    GeolocatorPlatform.instance = geolocator;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'access': jsonEncode({
        'location': jsonEncode({
          'accessAllowed': true,
          'lastLocationAccessRequest': 0,
        }),
      }),
    });
  });

  tearDown(() => GeolocatorPlatform.instance = originalGeolocator);

  test('timeout preserves permission, stays unverified, and allows retry',
      () async {
    geolocator.acquire = () async =>
        throw TimeoutException('No fix', const Duration(seconds: 20));
    final manager = AccessManager();
    final failed = await manager.locationAccess();

    expect(failed.isGranted, isTrue);
    expect(failed.hasVerifiedPosition, isFalse);
    expect(failed.lastTimeLoaded, isNull);
    expect((await SecureStorageManager().getLocationAccess())!['accessAllowed'],
        isTrue);

    geolocator.acquire = () async => _position();
    final recovered = await manager.locationAccess();
    expect(recovered.hasVerifiedPosition, isTrue);
    expect(recovered.lastTimeLoaded, isNotNull);
    expect(geolocator.acquisitionCount, 2);
    expect(geolocator.permissionRequestCount, 0);
    expect(geolocator.settings!.accuracy, LocationAccuracy.high);
    expect(geolocator.settings!.timeLimit, const Duration(seconds: 20));
  });

  test('disabled services do not turn granted permission into denial',
      () async {
    geolocator.serviceEnabled = false;
    final profile = await AccessManager().locationAccess();
    expect(profile.isGranted, isTrue);
    expect(profile.hasVerifiedPosition, isFalse);
    expect(geolocator.acquisitionCount, 0);
  });

  test('actual permission denial remains denied', () async {
    geolocator.permission = LocationPermission.deniedForever;
    final profile = await AccessManager().locationAccess();
    expect(profile.isGranted, isFalse);
    expect(profile.hasVerifiedPosition, isFalse);
    expect(geolocator.acquisitionCount, 0);
    expect((await SecureStorageManager().getLocationAccess())!['accessAllowed'],
        isFalse);
  });

  test('permission does not verify absent, placeholder, or invalid coordinates',
      () {
    final profile = LocationProfile()..permission = PermissionProfile.accept();
    for (final position in <Position?>[
      null,
      Utility.getDefaultPosition(),
      _position(latitude: 91),
      _position(longitude: -181),
      _position(latitude: double.nan),
      _position(longitude: double.infinity),
    ]) {
      profile.position = position;
      expect(profile.hasVerifiedPosition, isFalse);
    }
    profile.position = _position(latitude: 0, longitude: 0);
    expect(profile.hasVerifiedPosition, isTrue);
    profile.permission = PermissionProfile.deny();
    expect(profile.hasVerifiedPosition, isFalse);
  });

  test('API rejects verified flags on invalid caller coordinates', () async {
    final api = _Api(() => null);
    addTearDown(api.dispose);
    final result = await api.injectRequestParams({
      ..._params,
      'UserLatitude': '7777.0',
      'UserLongitude': '7777.0',
      'UserLocationVerified': 'true',
    });
    expect(result['UserLocationVerified'], 'false');
    final valid = await api.injectRequestParams({
      ..._params,
      'UserLatitude': '0',
      'UserLongitude': '0',
      'UserLocationVerified': 'true',
    });
    expect(valid['UserLocationVerified'], 'true');
  });

  testWidgets('API sends unverified fallback when acquisition times out',
      (tester) async {
    geolocator.acquire = () async => throw TimeoutException('No fix');
    final settings = _Settings();
    addTearDown(settings.close);
    settings.sessionProfile.locationProfile = LocationProfile.empty()
      ..permission = PermissionProfile.accept();
    late BuildContext context;
    await tester.pumpWidget(_harness(settings, Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    await tester.pumpAndSettle();
    final api = _Api(() => context);
    addTearDown(api.dispose);
    final request =
        api.injectRequestParams(_params, includeLocationParams: true);
    await tester.pumpAndSettle();
    final result = await request;
    expect(result['UserLocationVerified'], 'false');
    expect(result['UserLatitude'], '7777.0');
    expect(settings.sessionProfile.locationProfile!.isGranted, isTrue);
    expect(
        settings.sessionProfile.locationProfile!.hasVerifiedPosition, isFalse);
  });

  testWidgets('concurrent requests share permission UI and complete together',
      (tester) async {
    geolocator.permission = LocationPermission.denied;
    final settings = _Settings();
    addTearDown(settings.close);
    settings.sessionProfile.locationProfile = LocationProfile.empty();
    late BuildContext context;
    await tester.pumpWidget(_harness(settings, Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    await tester.pumpAndSettle();
    final api = _Api(() => context);
    addTearDown(api.dispose);
    final first = api.injectRequestParams(_params, includeLocationParams: true);
    await _pumpLocationFrames(tester);
    final second =
        api.injectRequestParams(_params, includeLocationParams: true);
    await _pumpLocationFrames(tester);
    expect(find.byType(LocationAccessWidget), findsOneWidget);

    tester
        .state<LocationAccessWidgetState>(find.byType(LocationAccessWidget))
        .generateCallBack(forceDeviceCheck: true)();
    await _pumpLocationFrames(tester);
    final results = await Future.wait([first, second]);
    for (final result in results) {
      expect(result['UserLocationVerified'], 'true');
      expect(result['UserLatitude'], '39.83');
      expect(result['UserLongitude'], '-105.21');
    }
    final firstEvent =
        settings.events.whereType<GetLocationProfileDeviceSettingEvent>().first;
    final loaded = settings.events
        .whereType<LoadedLocationProfileDeviceSettingEvent>()
        .single;
    expect(loaded.id, firstEvent.id);
    expect(geolocator.acquisitionCount, 1);
    expect(geolocator.permissionRequestCount, 1);
    expect(find.byType(LocationAccessWidget), findsNothing);
  });

  testWidgets('disposing permission widget during acquisition is safe',
      (tester) async {
    final result = Completer<Position>();
    geolocator.acquire = () => result.future;
    final settings = _Settings();
    addTearDown(settings.close);
    await tester.pumpWidget(
        _harness(settings, LocationAccessWidget(AccessManager(), (_) {})));
    await _pumpLocationFrames(tester);
    tester
        .state<LocationAccessWidgetState>(find.byType(LocationAccessWidget))
        .generateCallBack(forceDeviceCheck: true)();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    result.complete(_position());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(settings.events.whereType<LoadedLocationProfileDeviceSettingEvent>(),
        isEmpty);
  });
}
