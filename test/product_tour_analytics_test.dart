import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/components/tutorial/tourHost.dart';
import 'package:tiler_app/components/tutorial/tourCoordinator.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onboardingExplainerRoute.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/services/analyticsSignal.dart';

Widget app(Widget child) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  final events = <String>[];
  late TutorialBloc bloc;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TourCoordinator.instance.clear();
    events.clear();
    AnalysticsSignal.testSink = (name, parameters) async {
      events.add('$name:${parameters['stepId'] ?? ''}');
    };
  });
  Widget host(List<TutorialStep> steps, {Widget? surface}) => app(TourHost(
        tourId: 'test',
        stepCount: steps.length,
        settleDelay: Duration.zero,
        stepsBuilder: (_) => steps,
        child: Builder(builder: (context) {
          bloc = context.read<TutorialBloc>();
          return Scaffold(body: surface ?? const SizedBox.expand());
        }),
      ));
  TutorialStep step(String id, [GlobalKey? key]) => TutorialStep(
      id: id,
      targetKey: key,
      title: id,
      body: 'Description',
      tooltipPosition: TooltipPosition.center);
  Future<void> tick(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
      'missing target advances once; null target stays; rebuilds do not duplicate',
      (tester) async {
    await tester
        .pumpWidget(host([step('missing', GlobalKey()), step('intro')]));
    await tester.pump();
    await tick(tester);
    expect(bloc.state.currentStepIndex, 1);
    expect(events, [
      'TOUR_STARTED:missing',
      'TOUR_STEP:missing',
      'TOUR_TARGET_MISSING:missing',
      'TOUR_STEP:intro'
    ]);
    await tick(tester);
    expect(bloc.state.isActive, isTrue);
    expect(events.length, 4);
    bloc.add(CompleteTutorialEvent());
    await tester.pump();
    expect(events.last, 'TOUR_COMPLETED:intro');
    expect(TourCoordinator.instance.requestStart('other'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('late anchor resolves before retry budget expires',
      (tester) async {
    final key = GlobalKey();
    final visible = ValueNotifier(false);
    addTearDown(visible.dispose);
    await tester.pumpWidget(host([step('late', key)],
        surface: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, value, __) => value
              ? SizedBox(key: key, width: 40, height: 40)
              : const SizedBox(),
        )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    visible.value = true;
    await tester.pump();
    await tick(tester);
    expect(events, ['TOUR_STARTED:late', 'TOUR_STEP:late']);
    expect(bloc.state.isActive, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('manual next cancels stale target retries', (tester) async {
    await tester
        .pumpWidget(host([step('missing', GlobalKey()), step('intro')]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(bloc.state.isActive, isTrue);
    bloc.add(NextTutorialStepEvent());
    await tester.pump();
    await tick(tester);
    expect(bloc.state.currentStepIndex, 1);
    expect(events.where((e) => e.startsWith('TOUR_TARGET_MISSING')), isEmpty);
    bloc.add(SkipTutorialEvent());
    await tester.pump();
    expect(events.last, 'TOUR_SKIPPED:intro');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'missing final target completes and unmount cancels pending retries',
      (tester) async {
    await tester.pumpWidget(host([step('last', GlobalKey())]));
    await tester.pump();
    await tick(tester);
    expect(bloc.state.isCompleted, isTrue);
    expect(events.where((e) => e == 'TOUR_TARGET_MISSING:last').length, 1);
    await tester.pumpWidget(const SizedBox());
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(host([step('abandoned', GlobalKey())]));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tick(tester);
    expect(events.where((e) => e == 'TOUR_TARGET_MISSING:abandoned'), isEmpty);
  });

  testWidgets('demo records shown once and continued once', (tester) async {
    await tester.pumpWidget(app(OnboardingExplainerScreen(
        destinationBuilder: (_) => const Scaffold(body: Text('Done')))));
    await tester.pumpAndSettle();
    expect(events, ['EXPLAINER_SHOWN:']);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(events, ['EXPLAINER_SHOWN:', 'EXPLAINER_CONTINUED:']);
    expect(find.text('Done'), findsOneWidget);
  });
  tearDown(() => AnalysticsSignal.testSink = null);
  test(
      'existing additionalInfo callers retain their payload and empty tags are ignored',
      () async {
    final payloads = <Map<String, Object>>[];
    AnalysticsSignal.testSink = (_, payload) async => payloads.add(payload);
    await AnalysticsSignal.send('LEGACY_EVENT',
        additionalInfo: {'source': 'settings'});
    await AnalysticsSignal.send('');
    expect(payloads, hasLength(1));
    expect(payloads.single['additionalInfo'], '{source: settings}');
    expect(payloads.single['tag'], 'LEGACY_EVENT');
  });
  test(
      'emits identifiers with session metadata and isolates transport failures',
      () async {
    final calls = <Map<String, Object>>[];
    AnalysticsSignal.testSink = (name, parameters) async {
      calls.add({'name': name, ...parameters});
      throw StateError('offline');
    };
    await AnalysticsSignal.send('TOUR_STEP',
        parameters: {'tourId': 'settings', 'stepId': 'tiles'});
    expect(calls, hasLength(1));
    expect(calls.single, containsPair('name', 'TOUR_STEP'));
    expect(calls.single, containsPair('tourId', 'settings'));
    expect(calls.single, containsPair('stepId', 'tiles'));
    expect(calls.single['sessionId'], isA<String>());
    expect(calls.single['sequnceNumber'], isA<int>());
    expect(
        calls.single.keys,
        unorderedEquals([
          'name',
          'tourId',
          'stepId',
          'sessionId',
          'sequnceNumber',
          'tag',
          'time',
        ]));
  });
}
