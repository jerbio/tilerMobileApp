import 'dart:async';
import 'package:collection/collection.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'package:tiler_app/components/tilelist/dailyView/previewDailyTileList.dart';
import 'package:tiler_app/components/tilelist/monthlyView/monthlyTileList.dart';
import 'package:tiler_app/components/tilelist/weeklyView/weeklyTileList.dart';
import 'package:tiler_app/components/vibeChat/vibeChat.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/autoSwitchingWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/routes/authenticatedUser/previewAddWidget.dart';
import 'package:tiler_app/routes/authentication/RedirectHandler.dart';
import 'package:tiler_app/services/accessManager.dart';
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
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

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

  void _onBottomNavigationTap(int index) {
    switch (index) {
      case 0:
        {
          AnalysticsSignal.send('TILE_SHARE_BUTTON');
          Navigator.pushNamed(context, '/TileShare');
        }
        break;
      case 1:
        {
          AnalysticsSignal.send('SEARCH_PRESSED');
          Navigator.pushNamed(context, '/SearchTile');
        }
        break;
      case 2:
        {
          AnalysticsSignal.send('SETTING_PRESSED');
          Navigator.pushNamed(context, '/Setting');
        }
        break;
      case 3:
        {
          final currentState = context.read<ScheduleBloc>().state;
          AuthorizedRouteTileListPage newView;
          switch (currentState.currentView) {
            case AuthorizedRouteTileListPage.Daily:
              context.read<UiDateManagerBloc>().add(LogOutUiDateManagerEvent());
              newView = AuthorizedRouteTileListPage.Weekly;
              break;
            case AuthorizedRouteTileListPage.Weekly:
              newView = AuthorizedRouteTileListPage.Monthly;
              context
                  .read<MonthlyUiDateManagerBloc>()
                  .add(LogOutMonthlyUiDateManagerEvent());
              break;
            case AuthorizedRouteTileListPage.Monthly:
              context
                  .read<WeeklyUiDateManagerBloc>()
                  .add(LogOutWeeklyUiDateManagerEvent());
              newView = AuthorizedRouteTileListPage.Daily;
              break;
            default:
              newView = AuthorizedRouteTileListPage.Daily;
          }
          context.read<ScheduleBloc>().add(ChangeViewEvent(newView));
        }
        break;
    }
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

  Future<void> displayDialog(Size screenSize,
      {bool isTutorial = false, TutorialBloc? tutorialBloc}) async {
    if (_isAddTileSheetOpen) return;
    _isAddTileSheetOpen = true;
    final deviceSettingBloc = BlocProvider.of<DeviceSettingBloc>(context);
    print("DeviceSettingBloc: ${deviceSettingBloc.state} - display dialog");

    // If in tutorial mode, show the tutorial dialog on top after the sheet opens
    if (isTutorial) {
      // Use a post-frame callback so the sheet is rendered before the dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Determine which dialog to show based on current tutorial step.
        // Bloc step index 2 = quick_add (dialog 3), index 3 = smart_scheduling (dialog 4).
        final currentIndex = tutorialBloc?.state.currentStepIndex ?? 2;
        final dialogStep = currentIndex >= 3 ? 4 : 3;
        _showTutorialStepDialog(step: dialogStep, tutorialBloc: tutorialBloc);
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isTutorial,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TileDimensions.borderRadius)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          width: MediaQuery.of(sheetContext).size.width,
          child: PreviewAddWidget(
            previewSummary: previewSummary,
            onSubmit: (_) {
              if (Navigator.canPop(sheetContext)) {
                Navigator.pop(sheetContext);
              }
            },
          ),
        );
      },
    );
    _isAddTileSheetOpen = false;
  }

  /// Shows the appropriate tutorial dialog on top of the add-tile sheet.
  /// [step] 3 = Quick Create, [step] 4 = Tiler Works for You.
  void _showTutorialStepDialog({
    required int step,
    TutorialBloc? tutorialBloc,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        if (step == 3) {
          return _TutorialSheetDialog(
            tutorialBloc: tutorialBloc,
            onNext: () {
              Navigator.pop(dialogContext);
              tutorialBloc?.add(NextTutorialStepEvent());
              // Show step 4 dialog after a brief delay
              Future.delayed(Duration(milliseconds: 200), () {
                if (mounted) {
                  _showTutorialStepDialog(step: 4, tutorialBloc: tutorialBloc);
                }
              });
            },
          );
        } else {
          // Step 4: Tiler Works for You
          return _TutorialWorksForYouDialog(
            tutorialBloc: tutorialBloc,
            onNext: () {
              Navigator.pop(dialogContext);
              tutorialBloc?.add(NextTutorialStepEvent());
              // Sheet will be dismissed by the overlay's _handleStepTransition
              // since step 5 is NOT in _sheetSteps.
              _dismissAddTileSheet();
            },
            onBack: () {
              Navigator.pop(dialogContext);
              tutorialBloc?.add(PreviousTutorialStepEvent());
              // Go back to step 3 dialog
              Future.delayed(Duration(milliseconds: 200), () {
                if (mounted) {
                  _showTutorialStepDialog(step: 3, tutorialBloc: tutorialBloc);
                }
              });
            },
          );
        }
      },
    );
  }

  void _dismissAddTileSheet() {
    if (_isAddTileSheetOpen && Navigator.canPop(context)) {
      Navigator.pop(context);
      _isAddTileSheetOpen = false;
    }
  }

  void locationUpdate(LocationProfile locationProfile) {
    setState(() {
      locationAccess = locationProfile;
      isLocationRequestTriggered = true;
    });
  }

  Widget _buildDailyCurrentDayButton() {
    final uiDateManagerBloc = BlocProvider.of<UiDateManagerBloc>(context);
    return Positioned(
      right: 0,
      child: GestureDetector(
        onTap: () {
          uiDateManagerBloc.onDateButtonTapped(
              Utility.currentTime(minuteLimitAccuracy: false));
        },
        child: Container(
          height: 50,
          width: 38,
          padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: constraints.maxWidth * 0.9,
                    child: Icon(
                      FontAwesomeIcons.calendar,
                      size: constraints.maxWidth,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: constraints.maxHeight * 0.125,
                  left: (constraints.maxWidth * 0.05),
                  child: Center(
                    child: Container(
                      height: constraints.maxHeight * 0.55,
                      width: constraints.maxHeight * 0.55,
                      child: Center(
                        child: Text(
                          (Utility.currentTime().day).toString(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(VibeChatStep vibeChatStep) {
    return IgnorePointer(
        ignoring: vibeChatStep == VibeChatStep.previewLoaded ||
            vibeChatStep == VibeChatStep.loadingPreview ||
            vibeChatStep == VibeChatStep.error,
        child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              vibeChatStep == VibeChatStep.previewLoaded ||
                      vibeChatStep == VibeChatStep.loadingPreview ||
                      vibeChatStep == VibeChatStep.error
                  ? tileThemeExtension.vibeChatPreviewDisableColor
                      .withValues(alpha: 0.6)
                  : Colors.transparent,
              BlendMode.srcATop,
            ),
            child: ClipRRect(
              key: TutorialKeys.bottomNavKey,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
                topLeft: Radius.circular(30),
              ),
              child: BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                      icon: Icon(
                        Icons.share,
                      ),
                      label: ''),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.settings), label: ''),
                  BottomNavigationBarItem(
                      icon: Icon(
                        Icons.calendar_month,
                      ),
                      label: ''),
                ],
                onTap: _onBottomNavigationTap,
              ),
            )));
  }

  Widget _buildPreviewFloatingActionButton(VibeChatStep vibeChatStep) {
    final isPreview = vibeChatStep == VibeChatStep.previewLoaded ||
        vibeChatStep == VibeChatStep.loadingPreview ||
        vibeChatStep == VibeChatStep.error;
    return FloatingActionButton(
      key: TutorialKeys.fabKey,
      backgroundColor: colorScheme.surface,
      onPressed: () {
        if (isPreview) {
          Navigator.pushNamed(context, '/vibeChat');
        } else {
          AnalysticsSignal.send('GLOBAL_PLUS_BUTTON');
          displayDialog(MediaQuery.of(context).size);
        }
      },
      child: isPreview
          ? Icon(Icons.chat_outlined, color: colorScheme.primary)
          : AutoSwitchingWidget(
              duration: Duration(milliseconds: 1000),
              children: [
                Transform.scale(
                  scale: 0.618,
                  child: Image.asset(
                    'assets/images/wire_tilerLogo_BlueBottom.png',
                  ),
                ),
                Transform.scale(
                  scale: 0.618,
                  child: Image.asset(
                    'assets/images/wire_tilerLogo_RedBottom.png',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPreviewOverlay(VibeChatState vibeChatState) {
    final tiles = vibeChatState.previewTiles;
    final selectedTile = (tiles != null && tiles.isNotEmpty)
        ? tiles.firstWhereOrNull(
            (tile) =>
                tile.id != null &&
                vibeChatState.selectedActionEntityId != null &&
                tile.id!.contains(vibeChatState.selectedActionEntityId!),
          )
        : null;

    if (selectedTile == null &&
        vibeChatState.step == VibeChatStep.previewLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationOverlayMessage().showToast(
          context,
          AppLocalizations.of(this.context)!.entityIdNotFound,
          NotificationOverlayMessageType.warning,
        );
      });
    }

    final displayDate = selectedTile?.startTime ?? DateTime.now();
    return Stack(
      children: [
        PreviewDailyTileList(displayDate: displayDate),
        if (!displayDate.isToday)
          DayRibbonCarousel(
            displayDate,
            autoUpdateAnchorDate: false,
            preview: true,
          ),
      ],
    );
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
                if (scheduleState.currentView ==
                        AuthorizedRouteTileListPage.Daily &&
                    !isViewingToday)
                  _buildDailyCurrentDayButton()
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
      floatingActionButton: _buildPreviewFloatingActionButton(
          BlocProvider.of<VibeChatBloc>(context).state.step),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TutorialBloc(stepCount: 7),
      child: MultiBlocListener(
          listeners: [
            BlocListener<VibeChatBloc, VibeChatState>(
              listener: (context, state) {
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
                if (state is ScheduleLoadingState ||
                    state is ScheduleLoadedState) {
                  final previewSummaryBloc =
                      BlocProvider.of<PreviewSummaryBloc>(context);
                  if (!(previewSummaryBloc.state is PreviewSummaryLoading)) {
                    previewSummaryBloc.add(GetPreviewSummaryEvent(
                        timeline: Utility.todayTimeline()));
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
          child: _TutorialWrapper(
            onShowAddTileSheet: (tutorialBloc) => displayDialog(
              MediaQuery.of(context).size,
              isTutorial: true,
              tutorialBloc: tutorialBloc,
            ),
            onDismissAddTileSheet: _dismissAddTileSheet,
            child: BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
              return renderAuthorizedUserPageView();
            }),
          )),
    );
  }
}

/// Auto-triggers the tutorial on first visit when the user
/// hasn't completed it yet. Also re-triggers after a reset
/// from Settings → "How to use Tiler".
class _TutorialWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function(TutorialBloc bloc)? onShowAddTileSheet;
  final VoidCallback? onDismissAddTileSheet;
  const _TutorialWrapper({
    required this.child,
    this.onShowAddTileSheet,
    this.onDismissAddTileSheet,
  });

  @override
  State<_TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<_TutorialWrapper> {
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTutorial();
  }

  void _checkAndStartTutorial() {
    TutorialPreferencesHelper.hasCompletedTutorial().then((completed) {
      if (!completed && mounted && !_tutorialChecked) {
        _tutorialChecked = true;
        // Delay to let the schedule render first
        Future.delayed(Duration(milliseconds: 1200), () {
          if (mounted) {
            context.read<TutorialBloc>().add(StartTutorialEvent());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TutorialOverlay(
      onShowAddTileSheet: widget.onShowAddTileSheet,
      onDismissAddTileSheet: widget.onDismissAddTileSheet,
      child: widget.child,
    );
  }
}

/// A floating tutorial dialog shown centered on top of the add-tile sheet
/// during Step 3 of the tutorial walkthrough.
class _TutorialSheetDialog extends StatelessWidget {
  final VoidCallback onNext;
  final TutorialBloc? tutorialBloc;

  const _TutorialSheetDialog({required this.onNext, this.tutorialBloc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentStep = (tutorialBloc?.state.currentStepIndex ?? 2) + 1;
    final totalSteps = tutorialBloc?.state.totalSteps ?? 7;

    return Align(
      alignment: Alignment(0.0, -0.75),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        constraints: BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 16, 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: colorScheme.onPrimary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tutorialStepQuickCreateTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.tutorialStepCounter(currentStep, totalSteps),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body text
              Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  l10n.tutorialStepQuickCreateSheetBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),

              // Callout items
              Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  children: [
                    _calloutRow(
                        Icons.edit,
                        l10n.tutorialCalloutNameYourTile,
                        l10n.tutorialCalloutNameYourTileDesc,
                        theme,
                        colorScheme),
                    SizedBox(height: 8),
                    _calloutRow(
                        Icons.timer,
                        l10n.tutorialCalloutSetDuration,
                        l10n.tutorialCalloutSetDurationDesc,
                        theme,
                        colorScheme),
                    SizedBox(height: 8),
                    _calloutRow(
                        Icons.tune,
                        l10n.tutorialCalloutMoreOptions,
                        l10n.tutorialCalloutMoreOptionsSheetDesc,
                        theme,
                        colorScheme),
                  ],
                ),
              ),

              // Next button
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Text(
                      l10n.tutorialNavNextArrow,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calloutRow(IconData icon, String label, String description,
      ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A floating tutorial dialog for Step 4: "Tiler Works for You"
/// shown on top of the still-open add-tile sheet.
class _TutorialWorksForYouDialog extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final TutorialBloc? tutorialBloc;

  const _TutorialWorksForYouDialog({
    required this.onNext,
    required this.onBack,
    this.tutorialBloc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentStep = (tutorialBloc?.state.currentStepIndex ?? 3) + 1;
    final totalSteps = tutorialBloc?.state.totalSteps ?? 7;

    return Align(
      alignment: Alignment(0.0, -0.75),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        constraints: BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 16, 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: colorScheme.onPrimary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tutorialStepTilerWorksTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.tutorialStepCounter(currentStep, totalSteps),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body text
              Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  l10n.tutorialStepTilerWorksBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),

              // Callout items
              Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  children: [
                    _calloutRow(Icons.preview, l10n.tutorialCalloutForecast,
                        l10n.tutorialCalloutForecastDesc, theme, colorScheme),
                    SizedBox(height: 8),
                    _calloutRow(Icons.shuffle, l10n.tutorialCalloutShuffle,
                        l10n.tutorialCalloutShuffleDesc, theme, colorScheme),
                    SizedBox(height: 8),
                    _calloutRow(
                        Icons.fast_forward,
                        l10n.tutorialCalloutDeferAll,
                        l10n.tutorialCalloutDeferAllDesc,
                        theme,
                        colorScheme),
                  ],
                ),
              ),

              // Navigation buttons
              Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: onBack,
                      child: Text(
                        l10n.tutorialNavBackArrow,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      child: Text(
                        l10n.tutorialNavNextArrow,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calloutRow(IconData icon, String label, String description,
      ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
