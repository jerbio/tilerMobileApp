import 'dart:async';
import 'dart:convert';
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
import 'package:tiler_app/components/datePickers/monthlyDatePicker/monthlyPickerPage.dart';
import 'package:tiler_app/components/datePickers/weeklyDatePicker/weeklyPickerPage.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/ribbons/monthRibbon/monthRibbon.dart';
import 'package:tiler_app/components/ribbons/weekRibbon/weekRibbonCarousel.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/components/tilelist/monthlyView/monthlyTileList.dart';
import 'package:tiler_app/components/tilelist/weeklyView/weeklyTileList.dart';
import 'package:tiler_app/components/vibeChat/vibeChat.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/autoSwitchingWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/routes/authenticatedUser/previewAddWidget.dart';
import 'package:tiler_app/routes/authentication/RedirectHandler.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/chat.dart';
import 'package:tiler_app/services/api/previewApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

import '../../bloc/uiDateManager/ui_date_manager_bloc.dart';
import '../../bloc/vibeChat/vibe_chat_bloc.dart' show LoadVibeChatSessionEvent, VibeChatBloc;

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
  bool isLocationRequestTriggered = false;
  late AppLinks _appLinks;
  late ThemeData theme;
  late ColorScheme colorScheme;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
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

  void displayDialog(Size screenSize) {
    final deviceSettingBloc = BlocProvider.of<DeviceSettingBloc>(context);
    print("DeviceSettingBloc: ${deviceSettingBloc.state} - display dialog");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TileDimensions.borderRadius)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: PreviewAddWidget(
              previewSummary: previewSummary,
              onSubmit: (_) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }),
        );
      },
    );
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

  Widget _buildBottomNavBar() {
    return ClipRRect(
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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_month,
              ),
              label: ''),
        ],
        onTap: _onBottomNavigationTap,
      ),
    );
  }

  Widget _buildPreviewFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: colorScheme.surface,
      onPressed: () {
        AnalysticsSignal.send('GLOBAL_PLUS_BUTTON');
        displayDialog(MediaQuery.of(context).size);
      },
      child: AutoSwitchingWidget(
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

  Widget _buildChatFloatingActionButton() {
    return Padding(
      padding: EdgeInsets.only(left: 30),
      child: FloatingActionButton(
        backgroundColor: colorScheme.surface,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => BlocProvider(
              create: (context) => VibeChatBloc(
                chatApi: ChatApi(getContextCallBack: () => context),
              )..add(LoadVibeChatSessionEvent()),
              child: VibeChat(),
            ),
          );
        },
        child: Icon(
          Icons.chat_outlined,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildChatFloatingActionButton(),
        _buildPreviewFloatingActionButton(),
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
      bottomNavigator = _buildBottomNavBar();
    }
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Container(
          child: Stack(
            children: widgetChildren,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigator,
      floatingActionButton:_buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
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
        child:
            BlocBuilder<ScheduleBloc, ScheduleState>(builder: (context, state) {
          return renderAuthorizedUserPageView();
        }));
  }
}
