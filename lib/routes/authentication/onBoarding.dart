import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/onBoarding/on_boarding_bloc.dart';
import '../../../bloc/onBoarding/on_boarding_state.dart';
import '../../../styles.dart';
import '../../components/onBoarding/bottmNavigatorBar/onBoardingBottomBar.dart';
import '../../components/onBoarding/onBoardingProgressIndicator.dart';
import '../../components/onBoarding/subWidgets/energyLevelDescriptionWidget.dart';
import '../../components/onBoarding/subWidgets/primaryLocationWidget.dart';
import '../../components/onBoarding/subWidgets/wakeUpTimeWidget.dart';
import '../../components/onBoarding/subWidgets/workDayStartingWidget.dart';
import '../../routes/authentication/authorizedRoute.dart';

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
            decoration:TileStyles.defaultBackground,
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

class _OnboardingViewState extends State<OnboardingView> {
  final List<Widget> pages = [
    WeakUpTimeWidget(),
    EnergyLevelDescriptionWidget(),
    PrimaryLocationWidget(),
    WorkDayStartWidget(),
  ];

  @override
  Widget build(BuildContext context) {
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
