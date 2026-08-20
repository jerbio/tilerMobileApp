import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/scheduleFullnessSlider.dart';
import 'package:tiler_app/theme/theme_data.dart';

Future<void> _pumpSlider(
  WidgetTester tester, {
  required num? intensityRate,
  ValueChanged<double>? onIntensityChanged,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ScheduleFullnessSlider(
        intensityRate: intensityRate,
        onIntensityChanged: onIntensityChanged ?? (_) {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Slider _slider(WidgetTester tester) =>
    tester.widget<Slider>(find.byType(Slider));

const double _minimum = ScheduleFullnessSlider.minimumIntensity;
const double _maximum = ScheduleFullnessSlider.maximumIntensity;
const double _step = ScheduleFullnessSlider.intensityStep;
const double _scale = ScheduleFullnessSlider.fullIntensity;

/// The backend persists the value as a fraction.
num _rate(double percentage) => percentage / _scale;

void main() {
  group('ScheduleFullnessSlider unit conversion', () {
    test('scales the persisted fraction up to a percentage', () {
      expect(ScheduleFullnessSlider.percentageFromRate(0.5), 50);
      expect(ScheduleFullnessSlider.percentageFromRate(_rate(_minimum)),
          _minimum);
      expect(ScheduleFullnessSlider.percentageFromRate(_rate(_maximum)),
          _maximum);
    });

    test('scales the percentage back down to a fraction', () {
      expect(ScheduleFullnessSlider.rateFromPercentage(50), closeTo(0.5, 1e-9));
      expect(ScheduleFullnessSlider.rateFromPercentage(_minimum),
          closeTo(_minimum / _scale, 1e-9));
    });

    test('round trips a persisted fraction', () {
      for (final double percentage in [_minimum, 50, _maximum]) {
        final num stored = ScheduleFullnessSlider.rateFromPercentage(percentage);
        expect(ScheduleFullnessSlider.percentageFromRate(stored), percentage);
      }
    });

    test('stays within the range the backend accepts', () {
      for (double percentage = _minimum;
          percentage <= _maximum;
          percentage += _step) {
        final double rate =
            ScheduleFullnessSlider.rateFromPercentage(percentage);
        expect(rate, greaterThanOrEqualTo(_minimum / _scale));
        expect(rate, lessThanOrEqualTo(_maximum / _scale));
      }
    });
  });

  group('ScheduleFullnessSlider.normalizeIntensity', () {
    test('falls back to the default when no value is stored', () {
      expect(ScheduleFullnessSlider.normalizeIntensity(null),
          ScheduleFullnessSlider.defaultIntensity);
    });

    test('keeps values already on an allowed increment', () {
      expect(ScheduleFullnessSlider.normalizeIntensity(_minimum), _minimum);
      expect(ScheduleFullnessSlider.normalizeIntensity(_maximum), _maximum);
      expect(ScheduleFullnessSlider.normalizeIntensity(_minimum + _step),
          _minimum + _step);
    });

    test('clamps values below the minimum into the range', () {
      expect(ScheduleFullnessSlider.normalizeIntensity(_minimum - 1), _minimum);
      expect(
          ScheduleFullnessSlider.normalizeIntensity(_minimum - 100), _minimum);
    });

    test('clamps values above the maximum into the range', () {
      expect(ScheduleFullnessSlider.normalizeIntensity(_maximum + 1), _maximum);
      expect(
          ScheduleFullnessSlider.normalizeIntensity(_maximum + 100), _maximum);
    });

    test('snaps off-increment values to the nearest step', () {
      expect(ScheduleFullnessSlider.normalizeIntensity(_minimum + _step * 0.4),
          _minimum);
      expect(ScheduleFullnessSlider.normalizeIntensity(_minimum + _step * 0.6),
          _minimum + _step);
      expect(ScheduleFullnessSlider.normalizeIntensity(_minimum + _step * 1.5),
          _minimum + _step * 2);
    });
  });

  group('ScheduleFullnessSlider widget', () {
    testWidgets('constrains the slider to the supported range',
        (WidgetTester tester) async {
      await _pumpSlider(tester, intensityRate: _minimum + _step);

      final slider = _slider(tester);
      expect(slider.min, _minimum);
      expect(slider.max, _maximum);
      expect(slider.divisions, ScheduleFullnessSlider.divisions);
    });

    testWidgets('renders the stored value', (WidgetTester tester) async {
      await _pumpSlider(tester, intensityRate: _rate(_minimum + _step * 2));

      expect(_slider(tester).value, _minimum + _step * 2);
    });

    testWidgets('renders a percentage stored by an older client in range',
        (WidgetTester tester) async {
      await _pumpSlider(tester, intensityRate: 50);

      final slider = _slider(tester);
      expect(slider.value, greaterThanOrEqualTo(slider.min));
      expect(slider.value, lessThanOrEqualTo(slider.max));
    });

    testWidgets('renders an out of range stored value inside the bounds',
        (WidgetTester tester) async {
      await _pumpSlider(tester, intensityRate: _rate(_minimum - _step * 3));

      final slider = _slider(tester);
      expect(slider.value, _minimum);
      expect(slider.value, greaterThanOrEqualTo(slider.min));
    });

    testWidgets('renders a value above the maximum inside the bounds',
        (WidgetTester tester) async {
      await _pumpSlider(tester, intensityRate: _rate(_maximum + _step * 9));

      final slider = _slider(tester);
      expect(slider.value, _maximum);
      expect(slider.value, lessThanOrEqualTo(slider.max));
    });

    testWidgets('shows the scale labels and the limit message',
        (WidgetTester tester) async {
      await _pumpSlider(tester,
          intensityRate: _rate(ScheduleFullnessSlider.defaultIntensity));

      expect(find.text('Schedule Fullness'), findsOneWidget);
      expect(find.text('Lighter'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Fuller'), findsOneWidget);
      expect(
        find.textContaining(
            'from ${_minimum.round()}% to ${_maximum.round()}%'),
        findsOneWidget,
      );
    });

    testWidgets('lays out dead zones on both ends of the track',
        (WidgetTester tester) async {
      await _pumpSlider(tester,
          intensityRate: _rate(ScheduleFullnessSlider.defaultIntensity));

      final flexes = tester
          .widgetList<Expanded>(find.descendant(
            of: find.byType(Row).first,
            matching: find.byType(Expanded),
          ))
          .map((expanded) => expanded.flex)
          .toList();

      expect(flexes, [
        ScheduleFullnessSlider.leadingDeadZoneFlex,
        ScheduleFullnessSlider.activeFlex,
        ScheduleFullnessSlider.trailingDeadZoneFlex,
      ]);
    });

    testWidgets('reports the persisted fraction when dragged',
        (WidgetTester tester) async {
      final List<double> changes = [];
      await _pumpSlider(
        tester,
        intensityRate: _rate(ScheduleFullnessSlider.defaultIntensity),
        onIntensityChanged: changes.add,
      );

      await tester.drag(find.byType(Slider), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(changes, isNotEmpty);
      for (final value in changes) {
        expect(value, greaterThanOrEqualTo(_minimum / _scale));
        expect(value, lessThanOrEqualTo(_maximum / _scale));
      }
      expect(changes.last,
          greaterThan(ScheduleFullnessSlider.defaultIntensity / _scale));
    });

    testWidgets(
        'does not report values outside the range when dragged to the end',
        (WidgetTester tester) async {
      final List<double> changes = [];
      await _pumpSlider(
        tester,
        intensityRate: _rate(ScheduleFullnessSlider.defaultIntensity),
        onIntensityChanged: changes.add,
      );

      await tester.drag(find.byType(Slider), const Offset(2000, 0));
      await tester.pumpAndSettle();

      expect(changes.last, closeTo(_maximum / _scale, 1e-9));
    });

    testWidgets(
        'does not report values below the minimum when dragged to the start',
        (WidgetTester tester) async {
      final List<double> changes = [];
      await _pumpSlider(
        tester,
        intensityRate: _rate(ScheduleFullnessSlider.defaultIntensity),
        onIntensityChanged: changes.add,
      );

      await tester.drag(find.byType(Slider), const Offset(-2000, 0));
      await tester.pumpAndSettle();

      expect(changes.last, closeTo(_minimum / _scale, 1e-9));
    });
  });
}
