import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/onBoarding/bottmNavigatorBar/onBoardingBottomBar.dart';
import 'package:tiler_app/components/onBoarding/onBoardingProgressIndicator.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/energyLevelDescriptionWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/primaryLocationWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/wakeUpTimeWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/workDayStartingWidget.dart';
import 'package:tiler_app/routes/authentication/authorizedRoute.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';


class OnboardingView extends StatefulWidget {
  static final String routeName = '/OnBoarding';

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}


class _OnboardingViewState extends State<OnboardingView> {
  final List<Widget> pages = [
    WakeUpTimeWidget(),
    EnergyLevelDescriptionWidget(),
    PrimaryLocationWidget(),
    WorkDayStartWidget(),
  ];
  late ScheduleApi scheduleApi;

  @override
  void initState() {
    super.initState();
    scheduleApi = ScheduleApi(
      getContextCallBack: () => context,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final localizationService = LocalizationService(AppLocalizations.of(context)!);
    NotificationOverlayMessage notificationOverlayMessage =
    NotificationOverlayMessage();
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.step == OnboardingStep.skipped ||
            state.step == OnboardingStep.submitted) {
          scheduleApi.buzzSchedule();
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => AuthorizedRoute()));
        }
        if (state.step == OnboardingStep.error && state.error != null) {
          notificationOverlayMessage.showToast(
            context,
            state.error!,
            NotificationOverlayMessageType.error,
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
              if (state.step == OnboardingStep.loading) PendingWidget(blurSigma: 10,),
            ],
          ),
        );
      },
    );
  }
}
