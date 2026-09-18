import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/onBoarding/bottmNavigatorBar/onBoardingBottomBar.dart';
import 'package:tiler_app/components/onBoarding/onBoardingProgressIndicator.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/primaryLocationWidget.dart';
import 'package:tiler_app/components/onBoarding/subWidgets/professionWidget.dart';
import 'package:tiler_app/routes/authentication/AuthorizedRoute.dart';
import 'package:tiler_app/routes/authentication/onboardingExplainerRoute.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/util.dart';

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

  /// Optional schedule-bloc seam (stage 3.5). After a successful submit the
  /// buzz revises the schedule server-side, so the schedule prefetched
  /// during onboarding is stale; once the buzz completes the view asks this
  /// bloc for a quiet forced refresh. When absent the view reads the
  /// ancestor `ScheduleBloc` (the app root provides it) and, if there is
  /// none, skips the refresh — it is best-effort.
  final ScheduleBloc? scheduleBloc;

  const OnboardingView(
      {Key? key,
      this.bloc,
      this.skipDestinationBuilder,
      this.submitDestinationBuilder,
      this.scheduleApi,
      this.scheduleBloc})
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
  int _analyticsPage = 0;
  String get _pageId => _analyticsPage == 0 ? 'profession' : 'location';

  /// The schedule bloc the post-submit refresh targets, resolved while the
  /// onboarding context is still mounted (the route is replaced right
  /// after submit, so it cannot be looked up once the buzz completes).
  ScheduleBloc? _scheduleBlocOrNull() {
    if (widget.scheduleBloc != null) return widget.scheduleBloc;
    try {
      return context.read<ScheduleBloc>();
    } catch (_) {
      return null;
    }
  }

  /// Stage 3.5: the buzz revises the schedule with the new profession /
  /// location, so whatever was prefetched during onboarding is stale. Once
  /// the revise completes, re-read the schedule quietly (the user keeps
  /// seeing the prefetched tiles until the revised ones arrive). A failed
  /// buzz revised nothing: the prefetched schedule stays valid and no
  /// refresh is issued.
  void _buzzThenRefreshSchedule() {
    final ScheduleBloc? scheduleBloc = _scheduleBlocOrNull();
    scheduleApi.buzzSchedule(includeLocationParams: false).then((_) {
      scheduleBloc?.add(GetScheduleEvent()
        ..forceRefresh = true
        ..emitOnlyLoadedStated = true);
    }, onError: (Object error) {
      Utility.debugPrint(
          'Onboarding: buzz after submit failed, keeping prefetched '
          'schedule: $error');
    });
  }

  /// Stage 4.4: every exit from the essentials pages — Skip and Submit
  /// alike — passes through the animated "Tiles vs Blocks" demo, whose
  /// "Let's Go!" then replaces the stack with [destination] (the
  /// authorized app in production). The onboarding route itself is
  /// replaced, so Back never returns to the questions.
  void _exitThroughExplainer(BuildContext context, WidgetBuilder destination) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnboardingExplainerScreen(destinationBuilder: destination),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AnalysticsSignal.send('ESSENTIALS_ONBOARDING_STARTED');
      AnalysticsSignal.send('ESSENTIALS_ONBOARDING_PAGE',
          parameters: {'pageId': _pageId});
    });
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
        if (state.pageNumber != null && state.pageNumber != _analyticsPage) {
          _analyticsPage = state.pageNumber!;
          AnalysticsSignal.send('ESSENTIALS_ONBOARDING_PAGE',
              parameters: {'pageId': _pageId});
        }
        if (state.step == OnboardingStep.skipped) {
          AnalysticsSignal.send('ESSENTIALS_ONBOARDING_SKIPPED',
              parameters: {'pageId': _pageId});
          // Stage 3.3: skip navigation is terminal; the optional seam
          // lets tests substitute the destination builder.
          final Widget Function(BuildContext) skipBuilder =
              widget.skipDestinationBuilder ?? ((context) => AuthorizedRoute());
          _exitThroughExplainer(context, skipBuilder);
        }
        if (state.step == OnboardingStep.submitted) {
          AnalysticsSignal.send('ESSENTIALS_ONBOARDING_SUBMITTED');
          // Stage 3.4: atomic submit exit -- buzz the schedule, then
          // navigate directly to the authorized app (the intro slider is
          // cut from the essentials flow). The optional seam lets tests
          // substitute the destination builder. Navigation never waits on
          // the buzz; the schedule refreshes once it completes (3.5).
          _buzzThenRefreshSchedule();
          final Widget Function(BuildContext) submitBuilder =
              widget.submitDestinationBuilder ??
                  ((context) => AuthorizedRoute());
          _exitThroughExplainer(context, submitBuilder);
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
                            context.read<OnboardingBloc>().add(NextPageEvent());
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
                                      key: ValueKey<int>(state.pageNumber ?? 0),
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
