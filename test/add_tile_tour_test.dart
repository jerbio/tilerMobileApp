import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/components/homeBottomNav.dart';
import 'package:tiler_app/components/tutorial/tourHost.dart';
import 'package:tiler_app/components/tutorial/tourCoordinator.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

late TutorialBloc sheetBloc;
final l10n = lookupAppLocalizations(const Locale('en'));

Future<void> mount(WidgetTester tester) async {
  await tester.runAsync(() async {
    final loader = FontLoader('Rubik');
    loader.addFont(
        rootBundle.load('assets/fonts/Rubik/static/Rubik-Regular.ttf'));
    await loader.load();
  });
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: const [Locale('en')],
    home: Builder(
        builder: (context) => Scaffold(
              bottomNavigationBar: HomeBottomNav(
                onShare: () {},
                onSelectView: (_) {},
                currentView: AuthorizedRouteTileListPage.Daily,
                onAddTile: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SizedBox(
                      height: 560,
                      child: TourHost(
                        tourId: TourPreferencesHelper.addTileTourId,
                        stepCount: kAddTileTourStepCount,
                        stepsBuilder: buildAddTileTourSteps,
                        child: Builder(builder: (context) {
                          sheetBloc = context.read<TutorialBloc>();
                          return const Center(child: Text('Sheet content'));
                        }),
                      )),
                ),
              ),
            )),
  ));
  await tester.pumpAndSettle();
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(TutorialKeys.bottomNavAddTileKey));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TourCoordinator.instance.clear();
  });

  testWidgets(
      'tap starts separate tour; completion keeps sheet open and persists',
      (tester) async {
    await mount(tester);
    expect(find.text('Sheet content'), findsNothing);
    expect(TourCoordinator.instance.activeTourId, isNull);
    await openSheet(tester);
    expect(find.text(l10n.tutorialStepQuickCreateTitle), findsOneWidget);
    expect(sheetBloc.state.totalSteps, 2);
    await tester.tap(find.text(l10n.tutorialNavNext));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tutorialStepTilerWorksTitle), findsOneWidget);
    await tester.tap(find.text(l10n.tutorialNavLetsGo));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsOneWidget);
    expect(
        await TourPreferencesHelper.hasCompletedTour(
            TourPreferencesHelper.addTileTourId),
        isTrue);
    expect(
        await TourPreferencesHelper.hasCompletedTour(
            TourPreferencesHelper.homeTourId),
        isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openSheet(tester);
    expect(sheetBloc.state.isActive, isFalse);
    expect(find.text(l10n.tutorialStepQuickCreateTitle), findsNothing);
    expect(find.text('Sheet content'), findsOneWidget);
  });

  testWidgets(
      'closing unfinished sheet releases coordinator and retries on next tap',
      (tester) async {
    await mount(tester);
    await openSheet(tester);
    expect(TourCoordinator.instance.activeTourId,
        TourPreferencesHelper.addTileTourId);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(TourCoordinator.instance.activeTourId, isNull);
    expect(
        await TourPreferencesHelper.hasCompletedTour(
            TourPreferencesHelper.addTileTourId),
        isFalse);
    await openSheet(tester);
    expect(find.text(l10n.tutorialStepQuickCreateTitle), findsOneWidget);
    await tester.tap(find.text(l10n.tutorialNavSkip));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsOneWidget);
    expect(
        await TourPreferencesHelper.hasCompletedTour(
            TourPreferencesHelper.addTileTourId),
        isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await TourPreferencesHelper.resetTours();
    await openSheet(tester);
    expect(find.text(l10n.tutorialStepQuickCreateTitle), findsOneWidget);
  });
}
