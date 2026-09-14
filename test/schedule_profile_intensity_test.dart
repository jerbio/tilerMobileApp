import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/scheduleProfile.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/scheduleFullnessSlider.dart';

// Mirrors ScheduleProfileModel on the server, which rejects anything outside it.
const double _serverMinimumRate = 0.15;
const double _serverMaximumRate = 0.95;

void main() {
  group('ScheduleProfile intensityRate', () {
    test('is null when absent from the response', () {
      expect(ScheduleProfile.fromJson({}).intensityRate, isNull);
    });

    test('reads the fraction returned by the api', () {
      expect(ScheduleProfile.fromJson({'intensityRate': 0.65}).intensityRate,
          0.65);
    });

    test('sends the fraction under the key the api expects', () {
      final profile = ScheduleProfile.fromJson({});
      profile.intensityRate = 0.45;

      expect(profile.toJsonForUpdate()['IntensityRate'], 0.45);
    });

    test('survives a response to payload round trip', () {
      final profile = ScheduleProfile.fromJson({'intensityRate': 0.8});

      expect(profile.toJsonForUpdate()['IntensityRate'], 0.8);
    });
  });

  group('user settings payload', () {
    test('nests the schedule profile the api expects', () {
      final profile = ScheduleProfile.fromJson({});
      profile.intensityRate = 0.5;
      final settings = UserSettings(
        userPreference: null,
        marketingPreference: null,
        scheduleProfile: profile,
      );

      final payload = settings.toJsonForUpdate();

      expect(payload['ScheduleProfile'], isA<Map<String, dynamic>>());
      expect(payload['ScheduleProfile']['IntensityRate'], 0.5);
    });
  });

  group('values sent to the server', () {
    test('every selectable percentage is inside the accepted range', () {
      for (double percentage = ScheduleFullnessSlider.minimumIntensity;
          percentage <= ScheduleFullnessSlider.maximumIntensity;
          percentage += ScheduleFullnessSlider.intensityStep) {
        final profile = ScheduleProfile.fromJson({});
        profile.intensityRate =
            ScheduleFullnessSlider.rateFromPercentage(percentage);

        final sent = profile.toJsonForUpdate()['IntensityRate'] as num;
        expect(sent, greaterThanOrEqualTo(_serverMinimumRate));
        expect(sent, lessThanOrEqualTo(_serverMaximumRate));
      }
    });
  });
}
