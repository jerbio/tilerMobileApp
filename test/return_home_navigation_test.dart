import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/returnConnector.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/travelBandWidget.dart';
import 'package:tiler_app/services/analyticsSignal.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final launches = <Uri>[];
  var canLaunch = true;

  setUp(() {
    launches.clear();
    canLaunch = true;
    AnalysticsSignal.testSink = (_, __) async {};
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'canLaunch') return canLaunch;
      if (call.method == 'launch') {
        final arguments = call.arguments as Map;
        launches.add(Uri.parse(arguments['url'] as String));
        expect(arguments['useWebView'], isFalse);
        return true;
      }
      throw StateError('Unexpected URL launcher method: ${call.method}');
    });
  });

  tearDown(() {
    AnalysticsSignal.testSink = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<Finder> pumpConnector(
      WidgetTester tester, String view, Location? destination) async {
    final tile = SubCalendarEvent(
      id: 'last-tile',
      start: DateTime(2026, 11, 6, 20, 18).millisecondsSinceEpoch,
      end: DateTime(2026, 11, 6, 21, 18).millisecondsSinceEpoch,
    )
      ..travelTimeAfter = 31 * 60000.0
      ..location =
          Location.fromLatitudeAndLongitude(latitude: 37.8, longitude: -122.5)
      ..travelDetail = TravelDetail(
        after: TravelData(
          endLocation: destination,
          duration: 31 * 60000.0,
          travelMedium: 'driving',
        ),
      );
    final Widget connector = view == 'list'
        ? ReturnConnector(lastTile: tile)
        : SizedBox(
            height: 100,
            child: Stack(children: [
              TravelBandWidget(
                tile: tile,
                kind: TravelBandKind.post,
                top: 0,
                left: 0,
                width: 300,
                height: 80,
                animate: false,
              ),
            ]),
          );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: connector),
    ));
    await tester.pumpAndSettle();
    return view == 'list'
        ? find.text('Home')
        : find.byKey(TravelBandWidget.cardKey);
  }

  for (final view in ['list', 'grid']) {
    for (final useAddress in [true, false]) {
      testWidgets(
          '$view: tapping home launches maps '
          '(${useAddress ? "address" : "coordinates"})', (tester) async {
        final home =
            Location.fromLatitudeAndLongitude(latitude: 37.7, longitude: -122.4)
              ..description = Location.homeLocationNickName
              ..address = useAddress ? '123 Home St' : null;
        final target = await pumpConnector(tester, view, home);

        await tester.tap(target);
        await tester.pumpAndSettle();

        expect(launches, hasLength(1));
        expect(launches.single.queryParameters['destination'],
            useAddress ? '123 Home St' : '37.7,-122.4');
        expect(launches.single.queryParameters['origin'], '37.8,-122.5');
        expect(launches.single.queryParameters['travelmode'], 'driving');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$view: invalid home stays disabled', (tester) async {
      final home = Location.fromDefault()
        ..description = Location.homeLocationNickName;
      final target = await pumpConnector(tester, view, home);

      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(launches, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$view: handles unavailable maps', (tester) async {
      canLaunch = false;
      final home =
          Location.fromLatitudeAndLongitude(latitude: 37.7, longitude: -122.4)
            ..description = Location.homeLocationNickName;
      final target = await pumpConnector(tester, view, home);

      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(launches, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
