import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/components/tilelist/returnConnector.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Helper builders
  // ---------------------------------------------------------------------------

  SubCalendarEvent _buildLastTile({
    required DateTime end,
    double? travelTimeAfter,
    TravelDetail? travelDetail,
  }) {
    final tile = SubCalendarEvent(
      id: 'last-tile',
      name: 'Last Event',
      start: end.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
    );
    tile.travelTimeAfter = travelTimeAfter;
    tile.travelDetail = travelDetail;
    return tile;
  }

  Location _homeLocation() {
    final loc =
        Location.fromLatitudeAndLongitude(latitude: 37.7, longitude: -122.4);
    loc.description = Location.homeLocationNickName; // 'home'
    loc.address = '123 Home St';
    return loc;
  }

  Location _otherLocation(String address) {
    final loc =
        Location.fromLatitudeAndLongitude(latitude: 37.8, longitude: -122.5);
    loc.address = address;
    loc.description = address;
    return loc;
  }

  Widget _wrap(Widget child) {
    return MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  // ---------------------------------------------------------------------------
  // Group 1: End-of-day section always renders
  // ---------------------------------------------------------------------------

  group('ReturnConnector — end-of-day section always rendered', () {
    testWidgets('wb_twilight icon visible with no travel data', (tester) async {
      final tile = _buildLastTile(end: DateTime(2026, 6, 28, 19));
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.wb_twilight), findsOneWidget);
    });

    testWidgets('"End of Day" text always shown', (tester) async {
      final tile = _buildLastTile(end: DateTime(2026, 6, 28, 19));
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.text('End of Day'), findsOneWidget);
    });

    testWidgets('wb_twilight icon present even when travel data is present',
        (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelTimeAfter: const Duration(minutes: 20).inMilliseconds.toDouble(),
        travelDetail: TravelDetail(
          after: TravelData(
            endLocation: _homeLocation(),
            duration: const Duration(minutes: 20).inMilliseconds.toDouble(),
          ),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.wb_twilight), findsOneWidget);
      expect(find.text('End of Day'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2: End-of-day time
  // ---------------------------------------------------------------------------

  group('ReturnConnector — end-of-day time display', () {
    testWidgets('shows time text when endOfDayTime is provided',
        (tester) async {
      final tile = _buildLastTile(end: DateTime(2026, 6, 28, 19));
      final eod = DateTime(2026, 6, 28, 22, 0); // 10:00 PM
      await tester.pumpWidget(
          _wrap(ReturnConnector(lastTile: tile, endOfDayTime: eod)));
      await tester.pump();
      expect(find.textContaining('PM'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show time text when endOfDayTime is null',
        (tester) async {
      final tile = _buildLastTile(end: DateTime(2026, 6, 28, 19));
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.textContaining('PM'), findsNothing);
      expect(find.textContaining('AM'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3: No travel data — travel section hidden
  // ---------------------------------------------------------------------------

  group('ReturnConnector — no travel data hides travel-specific elements', () {
    testWidgets('no home icon when no travel data', (tester) async {
      final tile = _buildLastTile(end: DateTime(2026, 6, 28, 19));
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('no navigation icon when no travel data', (tester) async {
      final tile = _buildLastTile(end: DateTime(2026, 6, 28, 19));
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.navigation_outlined), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 4: Home destination
  // ---------------------------------------------------------------------------

  group('ReturnConnector — home destination travel section', () {
    testWidgets('shows home icon in travel section', (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelTimeAfter: const Duration(minutes: 20).inMilliseconds.toDouble(),
        travelDetail: TravelDetail(
          after: TravelData(
            travelMedium: 'driving',
            endLocation: _homeLocation(),
            duration: const Duration(minutes: 20).inMilliseconds.toDouble(),
          ),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('does not show navigation icon for home (no outbound nav)',
        (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(endLocation: _homeLocation()),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.navigation_outlined), findsNothing);
    });

    testWidgets('shows duration text for home with non-zero duration',
        (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(
            endLocation: _homeLocation(),
            duration: const Duration(minutes: 25).inMilliseconds.toDouble(),
          ),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.textContaining('25'), findsOneWidget);
    });

    testWidgets('shows "Home" destination label', (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(endLocation: _homeLocation()),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('end-of-day time shown in end-of-day section below travel',
        (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(
            travelMedium: 'driving',
            endLocation: _homeLocation(),
            duration: const Duration(minutes: 20).inMilliseconds.toDouble(),
          ),
        ),
      );
      final eod = DateTime(2026, 6, 28, 22, 0);
      await tester.pumpWidget(
          _wrap(ReturnConnector(lastTile: tile, endOfDayTime: eod)));
      await tester.pump();
      expect(find.textContaining('10'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 5: Non-home location travel section
  // ---------------------------------------------------------------------------

  group('ReturnConnector — non-home location travel section', () {
    testWidgets('shows navigation icon for non-home location', (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(
            travelMedium: 'driving',
            endLocation: _otherLocation('456 Office Blvd'),
            duration: const Duration(minutes: 10).inMilliseconds.toDouble(),
          ),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.navigation_outlined), findsOneWidget);
    });

    testWidgets('shows destination description text', (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(
            travelMedium: 'driving',
            endLocation: _otherLocation('456 Office Blvd'),
            duration: const Duration(minutes: 10).inMilliseconds.toDouble(),
          ),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.textContaining('456 Office Blvd'), findsOneWidget);
    });

    testWidgets('wraps travel section in a GestureDetector', (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelDetail: TravelDetail(
          after: TravelData(
            travelMedium: 'driving',
            endLocation: _otherLocation('456 Office Blvd'),
          ),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Group 6: Duration-only (no location)
  // ---------------------------------------------------------------------------

  group('ReturnConnector — duration-only travel section', () {
    testWidgets('shows duration text when travelTimeAfter set, no travelDetail',
        (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelTimeAfter: const Duration(minutes: 15).inMilliseconds.toDouble(),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.textContaining('15'), findsOneWidget);
    });

    testWidgets('no navigation icon without valid location', (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelTimeAfter: const Duration(minutes: 15).inMilliseconds.toDouble(),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.navigation_outlined), findsNothing);
    });

    testWidgets('zero duration renders without crash and shows end-of-day',
        (tester) async {
      final tile = _buildLastTile(
        end: DateTime(2026, 6, 28, 19),
        travelTimeAfter: 0,
        travelDetail: TravelDetail(
          after: TravelData(endLocation: _homeLocation(), duration: 0),
        ),
      );
      await tester.pumpWidget(_wrap(ReturnConnector(lastTile: tile)));
      await tester.pump();
      expect(find.byIcon(Icons.wb_twilight), findsOneWidget);
      expect(find.text('End of Day'), findsOneWidget);
    });
  });
}
