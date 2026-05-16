import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnhancedTileBatch travel connector ordering', () {
    testWidgets(
      'renders the connector after intervening conflict groups and before its destination tile',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final day = DateTime(2026, 5, 15);
        final tiles = <SubCalendarEvent>[
          _buildTile(
            id: 'source',
            name: 'TilerWeb Sync',
            start: DateTime(2026, 5, 15, 10),
            end: DateTime(2026, 5, 15, 10, 45),
          ),
          _buildTile(
            id: 'conflict-1',
            name: 'Engr fix dev',
            start: DateTime(2026, 5, 15, 11),
            end: DateTime(2026, 5, 15, 11, 30),
          ),
          _buildTile(
            id: 'conflict-2',
            name: 'will be deleted',
            start: DateTime(2026, 5, 15, 11),
            end: DateTime(2026, 5, 15, 12),
          ),
          _buildTile(
            id: 'destination',
            name: 'Hiking Trail',
            address: 'Trailhead Parking',
            addressDescription: 'hiking trail',
            start: DateTime(2026, 5, 15, 12, 15),
            end: DateTime(2026, 5, 15, 13, 45),
            travelTimeBeforeMs: const Duration(minutes: 25).inMilliseconds.toDouble(),
            travelDetail: TravelDetail(
              before: TravelData(
                travelMedium: 'driving',
                startLocation: _location('123 Office St', 37.33, -122.03),
                endLocation: _location('456 Trail Rd', 37.44, -122.15),
                travelLegs: const [
                  TravelLeg(description: 'Head west on Highway 9'),
                ],
              ),
            ),
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ScheduleBloc(getContextCallBack: () => null),
                ),
                BlocProvider(
                  create: (_) =>
                      ScheduleSummaryBloc(getContextCallBack: () => null),
                ),
              ],
              child: Scaffold(
                body: SingleChildScrollView(
                  child: EnhancedTileBatch(
                    dayIndex: day.difference(DateTime.utc(1970, 1, 1)).inDays,
                    tiles: tiles,
                    showProactiveAlerts: false,
                    showTimelineMarkers: false,
                    showEnhancedCards: true,
                    showConflictAlerts: true,
                    showTravelConnectors: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final connectorFinder = find.byType(TravelConnector);
        final conflictFinder = find.text('2 conflicts');
        final destinationFinder = find.text('Hiking Trail');

        expect(connectorFinder, findsOneWidget);
        expect(conflictFinder, findsOneWidget);
        expect(destinationFinder, findsOneWidget);

        final conflictY = tester.getTopLeft(conflictFinder).dy;
        final connectorY = tester.getTopLeft(connectorFinder).dy;
        final destinationY = tester.getTopLeft(destinationFinder).dy;

        expect(
          connectorY,
          greaterThan(conflictY),
          reason: 'The travel connector must render after the conflicting block that occurs before the destination tile.',
        );
        expect(
          connectorY,
          lessThan(destinationY),
          reason: 'The travel connector must render immediately before the destination tile it describes.',
        );
      },
    );
  });
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

SubCalendarEvent _buildTile({
  required String id,
  required String name,
  required DateTime start,
  required DateTime end,
  String? address,
  String? addressDescription,
  double? travelTimeBeforeMs,
  TravelDetail? travelDetail,
}) {
  final tile = SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    address: address,
    addressDescription: addressDescription,
  );
  tile.travelTimeBefore = travelTimeBeforeMs;
  tile.travelDetail = travelDetail;
  return tile;
}

Location _location(String address, double latitude, double longitude) {
  final location = Location.fromLatitudeAndLongitude(
    latitude: latitude,
    longitude: longitude,
  );
  location.address = address;
  return location;
}