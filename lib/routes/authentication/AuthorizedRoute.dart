import 'dart:async';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
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
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/components/tilelist/weeklyView/weeklyTileList.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/routes/authentication/RedirectHandler.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../bloc/uiDateManager/ui_date_manager_bloc.dart';

enum ActivePage { tilelist, search, addTile, procrastinate, review }

class AuthorizedRoute extends StatefulWidget {
  AuthorizedRoute();
  @override
  AuthorizedRouteState createState() => AuthorizedRouteState();
}

class AuthorizedRouteState extends State<AuthorizedRoute>
    with TickerProviderStateMixin {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  final ScheduleApi scheduleApi = new ScheduleApi();
  final AccessManager accessManager = AccessManager();

  Tuple3<Position, bool, bool> locationAccess = Tuple3(
      Position(
        altitudeAccuracy: 777.0,
        headingAccuracy: 0.0,
        longitude: Location.fromDefault().longitude!,
        latitude: Location.fromDefault().latitude!,
        timestamp: Utility.currentTime(),
        heading: 0,
        accuracy: 0,
        altitude: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
      false,
      true);
  late final LocalNotificationService localNotificationService;
  bool isAddButtonClicked = false;
  ActivePage selecedBottomMenu = ActivePage.tilelist;
  bool isLocationRequestTriggered = false;
  late AppLinks _appLinks;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  @override
  void initState() {
    super.initState();
    initDeepLinks();
    localNotificationService = LocalNotificationService();
    localNotificationService.initializeRemoteNotification().then((value) {
      localNotificationService.subscribeToRemoteNotification(this.context);
    });
    localNotificationService.initialize(this.context);

    // accessManager.locationAccess(statusCheck: true).then((value) {
    //   if (this.mounted) {
    //     setState(() {
    //       if (value != null) {
    //         locationAccess = value;
    //         return;
    //       }
    //     });
    //   }
    // });
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
          // Navigator.pushNamed(context, '/AddTile');
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
        return DayRibbonCarousel(
          Utility.currentTime().dayDate,
          autoUpdateAnchorDate: false,
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

  bool _iskeyboardVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

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
    showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.white70,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(1, 1, 1, 1),
        insetPadding: EdgeInsets.fromLTRB(0, 250, 0, 0),
        titlePadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [
                TileStyles.primaryColorHSL.toColor().withOpacity(0.75),
                TileStyles.primaryColorHSL
                    .withLightness(TileStyles.primaryColorHSL.lightness + .2)
                    .toColor()
                    .withOpacity(0.75),
              ],
            ),
          ),
          child: SizedBox(
            height: screenSize.height * 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/ForecastPreview');
                  },
                  child: ListTile(
                    leading: SvgPicture.asset('assets/images/binocular.svg'),
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                      child: Text(
                        AppLocalizations.of(context)!.forecast,
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AnalysticsSignal.send('REVISE_BUTTON');
                    this
                        .context
                        .read<ScheduleBloc>()
                        .add(ReviseScheduleEvent());
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.refresh, color: Colors.white),
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                      child: Text(
                        AppLocalizations.of(context)!.revise,
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      AnalysticsSignal.send('PROCRASTINATE_ALL_BUTTON_PRESSED');
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/Procrastinate')
                          .whenComplete(() {
                        var scheduleBloc =
                            this.context.read<ScheduleBloc>().state;
                        Timeline? lookupTimeline;
                        if (scheduleBloc is ScheduleLoadedState) {
                          this.context.read<ScheduleBloc>().add(
                              GetScheduleEvent(
                                  previousSubEvents: scheduleBloc.subEvents,
                                  scheduleTimeline: scheduleBloc.lookupTimeline,
                                  isAlreadyLoaded: true));
                          lookupTimeline = scheduleBloc.lookupTimeline;
                        }
                        if (scheduleBloc is ScheduleInitialState) {
                          this.context.read<ScheduleBloc>().add(
                              GetScheduleEvent(
                                  previousSubEvents: [],
                                  scheduleTimeline:
                                      Utility.initialScheduleTimeline,
                                  isAlreadyLoaded: false));
                          lookupTimeline = Utility.initialScheduleTimeline;
                        }

                        refreshScheduleSummary(lookupTimeline);
                      });
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          child: Stack(
                            children: [
                              Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  left: -15,
                                  child: Icon(Icons.chevron_right,
                                      color: Colors.white)),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                left: 0,
                                child: Icon(Icons.chevron_right,
                                    color: Colors.white),
                              ),
                              Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  left: 15,
                                  child: Icon(Icons.chevron_right,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        contentPadding: EdgeInsets.all(5),
                        title: Container(
                          child: Text(
                            AppLocalizations.of(context)!.deferAll,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 20,
                                fontFamily: TileStyles.rubikFontName,
                                fontWeight: FontWeight.w300,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    )),
                GestureDetector(
                  onTap: () {
                    AnalysticsSignal.send('NEW_ADD_TILE');
                    Navigator.pop(context);
                    Map<String, dynamic> newTileParams = {'newTile': null};

                    Navigator.pushNamed(context, '/AddTile',
                        arguments: newTileParams);
                  },
                  child: ListTile(
                    leading: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
                      child: Text(
                        AppLocalizations.of(context)!.addTile,
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        elevation: 2,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: FadeTransition(
          child: child,
          opacity: anim1,
        ),
      ),
      context: context,
    );
  }

  void locationUpdate(Tuple3<Position, bool, bool> update) {
    setState(() {
      locationAccess = update;
      isLocationRequestTriggered = true;
    });
  }

  Widget renderLocationRequest(AccessManager accessManager) {
    return LocationAccessWidget(accessManager, locationUpdate);
  }

  @override
  Widget build(BuildContext context) {
    final uiDateManagerBloc = BlocProvider.of<UiDateManagerBloc>(context);
    double height = MediaQuery.of(context).size.height;
    if (!isLocationRequestTriggered &&
        !locationAccess.item2 &&
        locationAccess.item3) {
      return renderLocationRequest(accessManager);
    }

    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          return Stack(children: [
            _buildTileList(state.currentView),
            _ribbonCarousel(state.currentView),
            if (state.currentView == AuthorizedRouteTileListPage.Daily)
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    uiDateManagerBloc.onDateButtonTapped(DateTime.now());
                  },
                  child: Container(
                    height: 50,
                    width: 38,
                    color: TileStyles.primaryContrastColor,
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
                                color: TileStyles.primaryColor,
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
                                    style: TextStyle(
                                      fontFamily: TileStyles.rubikFontName,
                                    ),
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
              ),
          ]);
        },
      ),
    ];
    if (isAddButtonClicked) {
      widgetChildren.add(generatePredictiveAdd());
    }
    dayStatusWidget.onDayStatusChange(DateTime.now());

    // Bottom Navbar Widget
    Widget? bottomNavigator;
    if (selecedBottomMenu == ActivePage.search) {
      bottomNavigator = null;
      var eventNameSearch = this.generateSearchWidget();
      widgetChildren.add(eventNameSearch);
    } else {
      bottomNavigator = ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.share,
                    color: TileStyles.primaryColor,
                  ),
                  label: ''),
              BottomNavigationBarItem(
                icon: Icon(Icons.search, color: TileStyles.primaryColor),
                label: '',
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings, color: TileStyles.primaryColor),
                  label: ''),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month,
                      color: TileStyles.primaryColor),
                  label: ''),
            ],
            unselectedItemColor: Colors.white,
            selectedItemColor: Colors.black,
            backgroundColor: Colors.transparent,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: _onBottomNavigationTap,
          ),
        ),
      );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: TileStyles.primaryContrastColor,
        onPressed: () {
          AnalysticsSignal.send('GLOBAL_PLUS_BUTTON');
          displayDialog(MediaQuery.of(context).size);
        },
        child: Icon(
          Icons.add,
          size: 35,
          color: TileStyles.primaryColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
