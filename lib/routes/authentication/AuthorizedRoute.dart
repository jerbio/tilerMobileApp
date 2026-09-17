import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/previewSummary/preview_summary_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/datePickers/monthlyDatePicker/monthlyPickerPage.dart';
import 'package:tiler_app/components/datePickers/weeklyDatePicker/weeklyPickerPage.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/ribbons/monthRibbon/monthRibbon.dart';
import 'package:tiler_app/components/ribbons/weekRibbon/weekRibbonCarousel.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/components/vibeChat/tileCast/tileCastCarousel.dart';
import 'package:tiler_app/components/vibeChat/tilerAiConsentSheet.dart';
import 'package:tiler_app/components/tilelist/monthlyView/monthlyTileList.dart';
import 'package:tiler_app/components/tilelist/weeklyView/weeklyTileList.dart';
import 'package:tiler_app/components/homeFab.dart';
import 'package:tiler_app/components/homeBottomNav.dart';
import 'package:tiler_app/components/calendarViewSwitcher/calendarViewSwitcherController.dart';
import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/routes/authenticatedUser/previewAddWidget.dart';
import 'package:tiler_app/routes/authentication/RedirectHandler.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/aiChatConsentGate.dart';
import 'package:tiler_app/services/aiConsentPreferencesHelper.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/chatApi.dart';
import 'package:tiler_app/services/api/previewApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/components/tutorial/tourHost.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';

enum ActivePage { tilelist, search, addTile, procrastinate, review }

class AuthorizedRoute extends StatefulWidget {
  AuthorizedRoute();
  @override
  AuthorizedRouteState createState() => AuthorizedRouteState();
}

class AuthorizedRouteState extends State<AuthorizedRoute>
    with TickerProviderStateMixin {
  late final PreviewApi previewApi;
  late final SubCalendarEventApi subCalendarEventApi;
  late final ScheduleApi scheduleApi;
  PreviewSummary? previewSummary;
  final AccessManager accessManager = AccessManager();
  bool renderLocationPermissionOverLay = false;

  LocationProfile locationAccess = LocationProfile.empty();
  late final LocalNotificationService localNotificationService;
  bool isAddButtonClicked = false;
  ActivePage selecedBottomMenu = ActivePage.tilelist;
  bool _isAddTileSheetOpen = false;
  bool isLocationRequestTriggered = false;
  late AppLinks _appLinks;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  StreamSubscription<Uri>? _linkSubscription;
  @override
  void initState() {
    super.initState();
    scheduleApi = new ScheduleApi(getContextCallBack: () {
      return this.context;
    });
    subCalendarEventApi = SubCalendarEventApi(getContextCallBack: () {
      return this.context;
    });
    previewApi = PreviewApi(getContextCallBack: () {
      return this.context;
    });

    initDeepLinks();
    localNotificationService = LocalNotificationService();
    localNotificationService.initializeRemoteNotification().then((value) {
      localNotificationService.subscribeToRemoteNotification(this.context);
    });
    localNotificationService.initialize(this.context);
    previewApi.getSummary(Utility.todayTimeline()).then((value) {
      this.previewSummary = value;
    });
    final scheduleBloc = BlocProvider.of<ScheduleBloc>(context);
    final deviceSettingBloc = BlocProvider.of<DeviceSettingBloc>(context);
    final forecastBloc = BlocProvider.of<ForecastBloc>(context);
    final vibeChatBloc = BlocProvider.of<VibeChatBloc>(context);
    final previewSummaryBloc = BlocProvider.of<PreviewSummaryBloc>(context);
    final scheduleSummaryBloc = BlocProvider.of<ScheduleSummaryBloc>(context);

    forecastBloc.whatIfApi = WhatIfApi(getContextCallBack: () {
      return this.context;
    });
    print(
        "DeviceSettingBloc: ${deviceSettingBloc.state}" + "- authorizedRoute");
    deviceSettingBloc.add(InitializeDeviceSettingEvent(
        id: "initializeDeviceSettingBloc",
        getContextCallBack: () {
          return this.context;
        }));
    scheduleBloc.scheduleApi = ScheduleApi(getContextCallBack: () {
      return this.context;
    });
    vibeChatBloc.chatApi = ChatApi(getContextCallBack: () {
      return this.context;
    });
    previewSummaryBloc.previewApi = PreviewApi(getContextCallBack: () {
      return this.context;
    });
    scheduleSummaryBloc.scheduleApi = ScheduleApi(getContextCallBack: () {
      return this.context;
    });
    scheduleSummaryBloc.subCalendarEventApi =
        SubCalendarEventApi(getContextCallBack: () {
      return this.context;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = Theme.of(context).extension<TileThemeExtension>()!;
  }

  void openAppLink(Uri uri) {
    RedirectHandler.routePage(context, uri);
  }

  Future<void> initDeepLinks() async {
    // return;
    _appLinks = AppLinks();

    // Handle links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
      openAppLink(uri);
    });
  }

  void _onShareTap() {
    AnalysticsSignal.send('TILE_SHARE_BUTTON');
    Navigator.pushNamed(context, '/TileShare');
  }

  void _onSearchTap() {
    AnalysticsSignal.send('SEARCH_PRESSED');
    Navigator.pushNamed(context, '/SearchTile');
  }

  void _onSettingsTap() {
    AnalysticsSignal.send('SETTING_PRESSED');
    Navigator.pushNamed(context, '/Setting');
  }

  void _onSelectCalendarView(AuthorizedRouteTileListPage newView) {
    selectCalendarView(
      newView: newView,
      scheduleBloc: context.read<ScheduleBloc>(),
      dailyDateBloc: context.read<UiDateManagerBloc>(),
      weeklyDateBloc: context.read<WeeklyUiDateManagerBloc>(),
      monthlyDateBloc: context.read<MonthlyUiDateManagerBloc>(),
    );
  }

  Widget _buildTileList(AuthorizedRouteTileListPage selectedListPage) {
    switch (selectedListPage) {
      case AuthorizedRouteTileListPage.Daily:
        return DailyTileList();
      case AuthorizedRouteTileListPage.Weekly:
        return WeeklyTileList();
      case AuthorizedRouteTileListPage.Monthly:
        return MonthlyTileList();
    }
  }

  Widget _ribbonCarousel(AuthorizedRouteTileListPage selectedListPage) {
    switch (selectedListPage) {
      case AuthorizedRouteTileListPage.Daily:
        // Wrap in BlocBuilder to respond to date changes
        return BlocBuilder<UiDateManagerBloc, UiDateManagerState>(
          builder: (context, uiDateState) {
            DateTime dayRibbonDate = Utility.currentTime().dayDate;
            if (uiDateState is UiDateManagerUpdated) {
              dayRibbonDate = uiDateState.currentDate;
            }
            // Hide ribbon when viewing current day - day summary is embedded in EnhancedWithinNowBatch
            if (dayRibbonDate.isToday) {
              return const SizedBox.shrink();
            }
            return DayRibbonCarousel(
              dayRibbonDate,
              autoUpdateAnchorDate: false,
            );
          },
        );
      case AuthorizedRouteTileListPage.Weekly:
        return Stack(children: [
          Align(
            alignment: Alignment.topCenter,
            child: WeekPickerPage(),
          ),
          WeeklyRibbonCarousel()
        ]);
      case AuthorizedRouteTileListPage.Monthly:
        return Stack(children: [
          Align(
            alignment: Alignment.topCenter,
            child: MonthPickerPage(),
          ),
          MonthlyRibbon(),
        ]);
    }
  }

  void disableSearch() {
    this.setState(() {
      selecedBottomMenu = ActivePage.tilelist;
    });
  }

  Widget generateSearchWidget() {
    var eventNameSearch = Scaffold(
      extendBody: true,
      body: Container(
        child: EventNameSearchWidget(onInputCompletion: this.disableSearch),
      ),
    );

    return eventNameSearch;
  }

  //ey: not used since isAddButtonClicked is always false
  Widget generatePredictiveAdd() {
    Widget containerWrapper = GestureDetector(
      onTap: () {
        setState(() {
          isAddButtonClicked = false;
        });
      },
      child: Container(
        height: MediaQuery.of(this.context).size.height,
        width: MediaQuery.of(this.context).size.width,
        color: Colors.amber,
        child: Stack(
          children: <Widget>[
            AutoAddTile(),
          ],
        ),
      ),
    );

    return containerWrapper;
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  Future<void> displayDialog(Size screenSize) async {
    if (_isAddTileSheetOpen) return;
    _isAddTileSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(TileDimensions.borderRadius)),
        ),
        builder: (sheetContext) => SizedBox(
          height: screenSize.height,
          child: TourHost(
            tourId: TourPreferencesHelper.addTileTourId,
            stepCount: kAddTileTourStepCount,
            stepsBuilder: buildAddTileTourSteps,
            child: PreviewAddWidget(
              previewSummary: previewSummary,
              onSubmit: (_) => Navigator.pop(sheetContext),
            ),
          ),
        ),
      );
    } finally {
      _isAddTileSheetOpen = false;
    }
  }

  void locationUpdate(LocationProfile locationProfile) {
    setState(() {
      locationAccess = locationProfile;
      isLocationRequestTriggered = true;
    });
  }

  Widget _buildBottomNavBar(VibeChatStep vibeChatStep) {
    final isPreviewActive = vibeChatStep == VibeChatStep.previewLoaded ||
        vibeChatStep == VibeChatStep.loadingPreview ||
        vibeChatStep == VibeChatStep.error;
    return IgnorePointer(
      ignoring: isPreviewActive,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          isPreviewActive
              ? tileThemeExtension.vibeChatPreviewDisableColor
                  .withValues(alpha: 0.6)
              : Colors.transparent,
          BlendMode.srcATop,
        ),
        child: BlocBuilder<ScheduleBloc, ScheduleState>(
          buildWhen: (previous, current) =>
              previous.currentView != current.currentView,
          builder: (context, scheduleState) {
            return HomeBottomNav(
              onShare: _onShareTap,
              onAddTile: () => displayDialog(MediaQuery.of(context).size),
              currentView: scheduleState.currentView,
              onSelectView: _onSelectCalendarView,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFab() {
    return HomeFab(
      onPressed: () {
        AnalysticsSignal.send('OPEN_CHAT_BUTTON');
        runAiChatConsentGate(
          isIOS: () => Platform.isIOS,
          hasConsent: AiConsentPreferencesHelper.hasGrantedAiConsent,
          requestConsent: () => showTilerAiConsentSheet(context),
          persistConsent: AiConsentPreferencesHelper.setAiConsentGranted,
          onProceed: () => Navigator.pushNamed(context, '/vibeChat'),
        );
      },
    );
  }

  Widget _buildPreviewOverlay(VibeChatState vibeChatState) {
    return const TileCastCarousel();
  }

  Widget renderAuthorizedUserPageView() {
    //ey: dayStatusWidget not used
    //ey: never added to widget tree
    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, scheduleState) {
          return BlocBuilder<UiDateManagerBloc, UiDateManagerState>(
            builder: (context, uiDateState) {
              DateTime currentViewDate = Utility.currentTime().dayDate;
              if (uiDateState is UiDateManagerUpdated) {
                currentViewDate = uiDateState.currentDate;
              }
              final bool isViewingToday = currentViewDate.isToday;

              return Stack(children: [
                _buildTileList(scheduleState.currentView),
                _ribbonCarousel(scheduleState.currentView),
                HomeTopRightActions(
                  isViewingToday: scheduleState.currentView !=
                          AuthorizedRouteTileListPage.Daily ||
                      isViewingToday,
                  onSearch: _onSearchTap,
                  onSettings: _onSettingsTap,
                  onGoToToday: () {
                    BlocProvider.of<UiDateManagerBloc>(context)
                        .onDateButtonTapped(
                      Utility.currentTime(minuteLimitAccuracy: false),
                    );
                  },
                ),
              ]);
            },
          );
        },
      ),
      BlocBuilder<VibeChatBloc, VibeChatState>(
        builder: (context, vibeChatState) {
          final isPreview = vibeChatState.step == VibeChatStep.previewLoaded ||
              vibeChatState.step == VibeChatStep.loadingPreview ||
              vibeChatState.step == VibeChatStep.error;
          if (!isPreview) return const SizedBox.shrink();
          return _buildPreviewOverlay(vibeChatState);
        },
      ),
    ];

    //ey: not used since isAddButtonClicked always false
    if (isAddButtonClicked) {
      widgetChildren.add(generatePredictiveAdd());
    }

    //ey: not really used
    dayStatusWidget
        .onDayStatusChange(Utility.currentTime(minuteLimitAccuracy: false));

    Widget? bottomNavigator;
    if (selecedBottomMenu == ActivePage.search) {
      bottomNavigator = null;
      var eventNameSearch = this.generateSearchWidget();
      widgetChildren.add(eventNameSearch);
    } else {
      bottomNavigator =
          _buildBottomNavBar(BlocProvider.of<VibeChatBloc>(context).state.step);
    }
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Container(
          key: TutorialKeys.scheduleViewKey,
          child: Stack(
            children: widgetChildren,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigator,
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<VibeChatBloc, VibeChatState>(
          listener: (context, state) {
            setState(() {});
            if (state.step == VibeChatStep.error && state.error != null) {
              NotificationOverlayMessage().showToast(
                context,
                state.error!,
                NotificationOverlayMessageType.error,
              );
            }
          },
        ),
        BlocListener<DeviceSettingBloc, DeviceSettingState>(
          listener: (context, state) {
            if (state is DeviceLocationSettingUIPending) {
              if (state.renderLoadingUI == true) {
                setState(() {
                  renderLocationPermissionOverLay = true;
                });
              }
            }

            if (state is DeviceSettingLoaded) {
              setState(() {
                renderLocationPermissionOverLay = false;
              });
            }
          },
        ),
        BlocListener<ScheduleBloc, ScheduleState>(
          listener: (context, state) {
            if (state is ScheduleLoadingState || state is ScheduleLoadedState) {
              final previewSummaryBloc =
                  BlocProvider.of<PreviewSummaryBloc>(context);
              if (!(previewSummaryBloc.state is PreviewSummaryLoading)) {
                previewSummaryBloc.add(
                    GetPreviewSummaryEvent(timeline: Utility.todayTimeline()));
              }
            }
          },
        ),
        BlocListener<PreviewSummaryBloc, PreviewSummaryState>(
          listener: (context, state) {
            if (state is PreviewSummaryLoaded) {
              setState(() {
                previewSummary = state.previewSummary;
              });
            }
          },
        )
      ],
      child: TourHost(
        tourId: TourPreferencesHelper.homeTourId,
        stepCount: kTutorialStepCount,
        child:
            BlocBuilder<ScheduleBloc, ScheduleState>(builder: (context, state) {
          return renderAuthorizedUserPageView();
        }),
      ),
    );
  }
}
