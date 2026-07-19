// Tests for RepetitionSelectorWidget.
//
// These lock in the behavior that a repetition chosen on the RepetitionRoute is
// always applied to the selector and propagated to the parent, and that the
// selector never desyncs into a non-recurring state when a change was actually
// made. This is a regression guard for the bug where changing the frequency
// forced the tile detail into a non-recurring state and hid the save button.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/repetition.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/repetitionSelectorWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ── fake RepetitionRoute ──────────────────────────────────────────────────────
//
// Mimics the real RepetitionRoute: it mutates the shared arguments Map (which is
// the same `repetitionParams` map the selector inspects in `whenComplete`) and
// then pops. `_fakeResult` configures what it returns for each test.

class _FakeRepetitionResult {
  RepetitionData? updatedRepetition;
  bool isRepetitionEndValid;

  /// When false, simulates the user cancelling: no `updatedRepetition` is set.
  bool proceed;

  _FakeRepetitionResult({
    this.updatedRepetition,
    this.isRepetitionEndValid = true,
    this.proceed = true,
  });
}

_FakeRepetitionResult _fakeResult = _FakeRepetitionResult();

class _FakeRepetitionRoute extends StatefulWidget {
  const _FakeRepetitionRoute();

  @override
  State<_FakeRepetitionRoute> createState() => _FakeRepetitionRouteState();
}

class _FakeRepetitionRouteState extends State<_FakeRepetitionRoute> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final Map args = ModalRoute.of(context)!.settings.arguments as Map;
      if (_fakeResult.proceed) {
        args['updatedRepetition'] = _fakeResult.updatedRepetition;
        args['isRepetitionEndValid'] = _fakeResult.isRepetitionEndValid;
      }
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

// ── test harness ─────────────────────────────────────────────────────────────

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
    routes: {
      '/RepetitionRoute': (context) => const _FakeRepetitionRoute(),
    },
    home: Scaffold(body: child),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_buildTestApp(child: child));
  await tester.pumpAndSettle();
}

RepetitionData _repetitionData(RepetitionFrequency frequency) =>
    RepetitionData(frequency: frequency, isEnabled: true);

Repetition _enabledRepetition(RepetitionFrequency frequency) =>
    Repetition.fromRepetitionData(_repetitionData(frequency));

void main() {
  setUp(() {
    _fakeResult = _FakeRepetitionResult();
  });

  group('RepetitionSelectorWidget', () {
    testWidgets('renders non-recurring when repetition is null',
        (WidgetTester tester) async {
      await _pump(
        tester,
        RepetitionSelectorWidget(
          repetition: null,
          onRepetitionUpdate: (_) {},
        ),
      );

      expect(find.text('Non-Recurring'), findsOneWidget);
    });

    testWidgets(
        'switching from disabled to a frequency applies the change and notifies parent',
        (WidgetTester tester) async {
      Repetition? captured;
      _fakeResult = _FakeRepetitionResult(
        updatedRepetition: _repetitionData(RepetitionFrequency.weekly),
        isRepetitionEndValid: true,
      );

      await _pump(
        tester,
        RepetitionSelectorWidget(
          repetition: null,
          onRepetitionUpdate: (r) => captured = r as Repetition,
        ),
      );

      expect(find.text('Non-Recurring'), findsOneWidget);

      await tester.tap(find.text('Non-Recurring'));
      await tester.pumpAndSettle();

      // Parent was notified with an enabled weekly repetition.
      expect(captured, isNotNull);
      expect(captured!.isEnabled, isTrue);
      expect(captured!.frequency, RepetitionFrequency.weekly);

      // Selector now reflects the recurring state (not forced to non-recurring).
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Non-Recurring'), findsNothing);
    });

    testWidgets(
        'applies the frequency change even when the deadline is reported invalid',
        (WidgetTester tester) async {
      // Regression guard: previously an invalid deadline discarded the change and
      // forced the selector into a non-recurring state, hiding the save button.
      Repetition? captured;
      _fakeResult = _FakeRepetitionResult(
        updatedRepetition: _repetitionData(RepetitionFrequency.daily),
        isRepetitionEndValid: false,
      );

      await _pump(
        tester,
        RepetitionSelectorWidget(
          repetition: null,
          onRepetitionUpdate: (r) => captured = r as Repetition,
        ),
      );

      await tester.tap(find.text('Non-Recurring'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.isEnabled, isTrue);
      expect(captured!.frequency, RepetitionFrequency.daily);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Non-Recurring'), findsNothing);
    });

    testWidgets(
        'changing the frequency on an already-recurring tile updates it',
        (WidgetTester tester) async {
      Repetition? captured;
      _fakeResult = _FakeRepetitionResult(
        updatedRepetition: _repetitionData(RepetitionFrequency.monthly),
        isRepetitionEndValid: true,
      );

      await _pump(
        tester,
        RepetitionSelectorWidget(
          repetition: _enabledRepetition(RepetitionFrequency.weekly),
          onRepetitionUpdate: (r) => captured = r as Repetition,
        ),
      );

      expect(find.text('Weekly'), findsOneWidget);

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.frequency, RepetitionFrequency.monthly);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Weekly'), findsNothing);
    });

    testWidgets('cancelling leaves the repetition unchanged',
        (WidgetTester tester) async {
      Repetition? captured;
      _fakeResult = _FakeRepetitionResult(proceed: false);

      await _pump(
        tester,
        RepetitionSelectorWidget(
          repetition: _enabledRepetition(RepetitionFrequency.weekly),
          onRepetitionUpdate: (r) => captured = r as Repetition,
        ),
      );

      expect(find.text('Weekly'), findsOneWidget);

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // No selection returned -> parent not notified and UI unchanged.
      expect(captured, isNull);
      expect(find.text('Weekly'), findsOneWidget);
    });
  });
}
