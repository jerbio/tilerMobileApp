import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

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

  @override
  void initState() {
    super.initState();
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

  void _onBottomNavigationTap(int index) {
    ActivePage selectedPage = ActivePage.tilelist;
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
            child: Stack(children: <Widget>[
              AutoAddTile(),
            ])));

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
                // GestureDetector(
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.of(context).pushNamed('/ForecastPreview');
                //   },
                //   child: ListTile(
                //     leading: Image.asset('assets/images/binocular.png'),
                //     title: Text(
                //       AppLocalizations.of(context)!.forecast,
                //       style: TextStyle(
                //           fontSize: 20,
                //           fontFamily: TileStyles.rubikFontName,
                //           fontWeight: FontWeight.w300,
                //           color: Colors.white),
                //     ),
                //   ),
                // ),
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
    // print('isLocationRequestTriggered $isLocationRequestTriggered');
    // print('locationAccess $locationAccess');
    // if (!isLocationRequestTriggered &&
    //     !locationAccess.item2 &&
    //     locationAccess.item3) {
    //   return renderLocationRequest(accessManager);
    // }

    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      TileList(), //this is the default and we need to switch these to routes and so we dont loose back button support
      // TileClusterWidget(),
      // DesignatedTileList(),
      Container(
        margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 7,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: DayRibbonCarousel(
          Utility.currentTime().dayDate,
          autoUpdateAnchorDate: true,
        ),
      ),
    ];
    // if (isAddButtonClicked) {
    //   widgetChildren.add(generatePredictiveAdd());
    // }
    dayStatusWidget.onDayStatusChange(DateTime.now());

    Widget? bottomNavigator;
    if (selecedBottomMenu == ActivePage.search) {
      bottomNavigator = null;
      var eventNameSearch = this.generateSearchWidget();
      // widgetChildren.add(eventNameSearch);
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
              ])),
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
