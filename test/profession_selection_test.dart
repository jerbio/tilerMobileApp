import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

OnboardingBloc _bloc() => OnboardingBloc(
      onBoardingApi: OnBoardingApi(),
      settingsApi: SettingsApi(getContextCallBack: () => null),
    );

Widget _app(OnboardingBloc bloc, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      theme: TileThemeData.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingView(bloc: bloc),
    );

Future<void> _flushToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('no default profession; Next asks for an explicit choice',
      (tester) async {
    final bloc = _bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc));
    await tester.pump();

    expect(bloc.state.profession, isNull);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(bloc.state.pageNumber, 0);
    expect(find.text(l10n.selectProfession), findsOneWidget);
    expect(find.text(l10n.enter3chars), findsNothing);
    await _flushToast(tester);

    await tester.tap(find.text(l10n.student));
    await tester.pump();
    expect(bloc.state.step, isNot(OnboardingStep.error));
    expect(find.text(l10n.selectProfession), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(bloc.state.pageNumber, 1);
    expect(bloc.state.profession, 'Student');
  });

  testWidgets('swiping cannot bypass the profession choice', (tester) async {
    final bloc = _bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc));
    await tester.pump();

    final page = find
        .ancestor(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.fling(page, const Offset(-300, 0), 800);
    await tester.pump();
    expect(bloc.state.pageNumber, 0);
    expect(bloc.state.profession, isNull);
    await _flushToast(tester);
  });

  testWidgets(
      'label, circle, and blank row space select exactly one profession',
      (tester) async {
    final bloc = _bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc));
    await tester.pump();

    final engineer = find.byKey(const ValueKey('profession_Engineer'));
    await tester
        .tapAt(tester.getRect(engineer).centerRight - const Offset(8, 0));
    await tester.pump();
    expect(bloc.state.profession, 'Engineer');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text(l10n.engineer));
    await tester.pump();
    expect(bloc.state.profession, 'Engineer');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text(l10n.student));
    await tester.pump();
    expect(bloc.state.profession, 'Student');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final medical =
        find.byKey(const ValueKey('profession_Medical Professional'));
    await tester.tap(find.descendant(
      of: medical,
      matching: find.byIcon(Icons.radio_button_unchecked),
    ));
    await tester.pump();
    expect(bloc.state.profession, 'Medical Professional');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('clearing Other removes the old answer and blocks Next',
      (tester) async {
    final bloc = _bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc));
    await tester.pump();
    await tester.ensureVisible(find.text(l10n.other));
    await tester.tap(find.text(l10n.other));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Carpenter');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    expect(bloc.state.profession, '');
    expect(bloc.state.isCustomProfession, isTrue);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();
    expect(bloc.state.pageNumber, 0);
    expect(find.text(l10n.enter3chars), findsOneWidget);
    await _flushToast(tester);
  });

  testWidgets('custom profession text survives Next and Back', (tester) async {
    final bloc = _bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc));
    await tester.pump();
    await tester.ensureVisible(find.text(l10n.other));
    await tester.tap(find.text(l10n.other));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Carpenter');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(bloc.state.pageNumber, 1);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Carpenter');
    expect(bloc.state.profession, 'Carpenter');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('translated options use stable values and Other opens its field',
      (tester) async {
    const locale = Locale('de');
    final translated = lookupAppLocalizations(locale);
    final bloc = _bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc, locale: locale));
    await tester.pump();

    await tester.tap(find.text(translated.engineer));
    await tester.pump();
    expect(bloc.state.profession, 'Engineer');
    expect(bloc.state.isCustomProfession, isFalse);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.ensureVisible(find.text(translated.other));
    await tester.tap(find.text(translated.other));
    await tester.pumpAndSettle();
    expect(bloc.state.profession, 'Other');
    expect(bloc.state.isCustomProfession, isTrue);
    expect(find.byType(TextField), findsOneWidget);
  });
}
