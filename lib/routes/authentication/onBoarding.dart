import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/components/onBoarding/bottmNavigatorBar/onBoardingBottomBar.dart';
import 'package:tiler_app/components/onBoarding/onBoardingProgressIndicator.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/energyLevelDescriptionWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/primaryLocationWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/wakeUpTimeWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/workDayStartingWidget.dart';
import 'package:tiler_app/routes/authentication/authorizedRoute.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/localizationService.dart';

class OnboardingView extends StatefulWidget {
  static final String routeName = '/OnBoarding';

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

Widget renderPending() {
  return Center(
    child: Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: TileStyles.defaultBackground,
          ),
        ),
        Center(
          child: SizedBox(
            child: CircularProgressIndicator(),
            height: 200.0,
            width: 200.0,
          ),
        ),
        Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7),
        ),
      ],
    ),
  );
}

void showErrorMessage(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      backgroundColor: TileStyles.errorBackgroundColor,
      textColor: TileStyles.errorTxtColor,
      fontSize: 16.0);
}

class _OnboardingViewState extends State<OnboardingView> {

  final List<Widget> pages = [
    WakeUpTimeWidget(),
    EnergyLevelDescriptionWidget(),
    PrimaryLocationWidget(),
    WorkDayStartWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    // final localizationService = LocalizationService(AppLocalizations.of(context)!);
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.step == OnboardingStep.skipped ||
            state.step == OnboardingStep.submitted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => AuthorizedRoute()));
        }
        if (state.step == OnboardingStep.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 30.0),
                      child: OnBoardingProgressIndicator(
                          currentPage: state.pageNumber ?? 0,
                          totalPages: pages.length),
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Padding(
                            key: ValueKey<int>(state.pageNumber ?? 0),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30.0),
                            child: pages[state.pageNumber ?? 0],
                          ),
                        ),
                      ),
                    ),
                    OnboardingBottomNavigationBar(
                      currentPage: state.pageNumber ?? 0,
                      totalPages: pages.length,
                    ),
                  ],
                ),
              ),
              if (state.step == OnboardingStep.loading) renderPending(),
            ],
          ),
        );
      },
    );
  }
}
