import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/onBoarding/bottmNavigatorBar/onBoardingBottomBar.dart';
import 'package:tiler_app/components/onBoarding/onBoardingProgressIndicator.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/primaryLocationWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/professionWidget.dart';
import 'package:tiler_app/routes/authentication/AuthorizedRoute.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

class OnboardingView extends StatefulWidget {
  static final String routeName = '/OnBoarding';

  /// Optional bloc injection seam. When provided, the view renders with this
  /// bloc as-is (no fetch); when absent the production flow is created.
  final OnboardingBloc? bloc;

  /// Optional skip-destination seam (stage 3.3). When provided, the Skip
  /// navigation pushes a route whose page is built by this builder instead
  /// of the production AuthorizedRoute; widget tests use it to verify the
  /// navigation target without rendering AuthorizedRoute.
  final Widget Function(BuildContext)? skipDestinationBuilder;

  /// Optional submit-destination seam (stage 3.4). When provided, the
  /// submit navigation pushes a route whose page is built by this builder
  /// instead of the production AuthorizedRoute; widget tests use it to
  /// verify the navigation target without rendering AuthorizedRoute.
  final Widget Function(BuildContext)? submitDestinationBuilder;

  /// Optional schedule-API seam (stage 3.4). When provided, submit uses
  /// this instance for the buzz-schedule call; widget tests use a fake so
  /// the submit path never performs a real network request.
  final ScheduleApi? scheduleApi;

  const OnboardingView(
      {Key? key,
      this.bloc,
      this.skipDestinationBuilder,
      this.submitDestinationBuilder,
      this.scheduleApi})
      : super(key: key);

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  /// Essentials onboarding flow (stage 3.1): a two-page
  /// Profession -> Location flow.
  final List<Widget> pages = [
    ProfessionWidget(),
    PrimaryLocationWidget(),
  ];
  late ScheduleApi scheduleApi;

  @override
  void initState() {
    super.initState();
    // Stage 3.4: an injected schedule API (tests) takes precedence; the
    // production view creates its own with the build context.
    scheduleApi = widget.scheduleApi ??
        ScheduleApi(
          getContextCallBack: () => context,
        );
  }

  @override
  Widget build(BuildContext context) {
    // final localizationService = LocalizationService(AppLocalizations.of(context)!);
    NotificationOverlayMessage notificationOverlayMessage =
        NotificationOverlayMessage();
    final onboarding = BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state.step == OnboardingStep.skipped) {
            // Stage 3.3: skip navigation is terminal; the optional seam
            // lets tests substitute the destination builder.
            final Widget Function(BuildContext) skipBuilder =
                widget.skipDestinationBuilder ??
                    ((context) => AuthorizedRoute());
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: skipBuilder));
          }
          if (state.step == OnboardingStep.submitted) {
            // Stage 3.4: atomic submit exit -- buzz the schedule, then
            // navigate directly to the authorized app (the intro slider is
            // cut from the essentials flow). The optional seam lets tests
            // substitute the destination builder.
            scheduleApi.buzzSchedule();
            final Widget Function(BuildContext) submitBuilder =
                widget.submitDestinationBuilder ??
                    ((context) => AuthorizedRoute());
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: submitBuilder));
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
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity! < 0) {
                              context
                                  .read<OnboardingBloc>()
                                  .add(NextPageEvent());
                            } else if (details.primaryVelocity! > 0) {
                              context
                                  .read<OnboardingBloc>()
                                  .add(PreviousPageEvent());
                            }
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      child: Padding(
                                        key: ValueKey<int>(
                                            state.pageNumber ?? 0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30.0),
                                        child: pages[state.pageNumber ?? 0],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
                if (state.step == OnboardingStep.loading)
                  PendingWidget(
                    blurSigma: 10,
                  ),
              ],
            ),
          );
        },
    );
    return widget.bloc != null
        ? BlocProvider<OnboardingBloc>.value(
            value: widget.bloc!,
            child: onboarding,
          )
        : BlocProvider(
            create: (context) => OnboardingBloc(
                onBoardingApi: OnBoardingApi(),
                settingsApi: SettingsApi(getContextCallBack: () => context))
              ..add(FetchOnboardingDataEvent()),
            child: onboarding,
          );
  }
}
