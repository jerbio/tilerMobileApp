import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tileUI/newTileUIPreview.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/autoAddTile.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart';

enum ActivePage { tilelist, search, addTile, procrastinate, review }

class AuthorizedRoute extends StatefulWidget {
  @override
  AuthorizedRouteState createState() => AuthorizedRouteState();
}

class AuthorizedRouteState extends State<StatefulWidget>
    with TickerProviderStateMixin {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  final ScheduleApi scheduleApi = new ScheduleApi();
  bool isAddButtonClicked = false;
  ActivePage selecedBottomMenu = ActivePage.tilelist;

  void _onBottomNavigationTap(int index) {
    ActivePage selectedPage = ActivePage.tilelist;
    switch (index) {
      case 0:
        {
          Navigator.pushNamed(context, '/SearchTile');
        }
        break;
      case 1:
        {
          Navigator.pushNamed(context, '/AddTile');
        }
        break;
      case 2:
        {
          selectedPage = ActivePage.review;
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
    double topValue = MediaQuery.of(this.context).size.height / 4;
    var future = new Future.delayed(const Duration(milliseconds: 1000), () {
      topValue = topValue * 2;
    });

    double autoAddTileBottom = MediaQuery.of(context).viewInsets.bottom;
    if (_iskeyboardVisible()) {
      autoAddTileBottom -= 300;
    }

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
                Color.fromRGBO(0, 119, 170, 0.75),
                Color.fromRGBO(0, 194, 237, 0.75)
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
                    final currentState =
                        this.context.read<ScheduleBloc>().state;
                    if (currentState is ScheduleLoadedState) {
                      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
                            isAlreadyLoaded: true,
                            renderedScheduleTimeline:
                                currentState.lookupTimeline,
                            renderedSubEvents: currentState.subEvents,
                            renderedTimelines: currentState.timelines,
                            message:
                                AppLocalizations.of(context)!.revisingSchedule,
                          ));
                    }
                    ScheduleApi().reviseSchedule().then((value) {
                      final currentState =
                          this.context.read<ScheduleBloc>().state;
                      if (currentState is ScheduleEvaluationState) {
                        this.context.read<ScheduleBloc>().add(GetSchedule(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                      }
                    }).catchError((onError) {
                      final currentState =
                          this.context.read<ScheduleBloc>().state;
                      Fluttertoast.showToast(
                          msg: onError!.message,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.black45,
                          textColor: Colors.white,
                          fontSize: 16.0);
                      if (currentState is ScheduleEvaluationState) {
                        this.context.read<ScheduleBloc>().add(GetSchedule(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.refresh, color: Colors.white),
                    title: Text(
                      AppLocalizations.of(context)!.revise,
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: TileStyles.rubikFontName,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/Procrastinate')
                          .whenComplete(() {
                        var scheduleBloc =
                            this.context.read<ScheduleBloc>().state;
                        if (scheduleBloc is ScheduleLoadedState) {
                          this.context.read<ScheduleBloc>().add(GetSchedule(
                              previousSubEvents: scheduleBloc.subEvents,
                              scheduleTimeline: scheduleBloc.lookupTimeline,
                              isAlreadyLoaded: true));
                        }
                        if (scheduleBloc is ScheduleInitialState) {
                          this.context.read<ScheduleBloc>().add(GetSchedule(
                              previousSubEvents: [],
                              scheduleTimeline: Utility.initialScheduleTimeline,
                              isAlreadyLoaded: false));
                        }
                      });
                    },
                    child: ListTile(
                      leading: Image.asset('assets/images/move_forward.png'),
                      title: Text(
                        AppLocalizations.of(context)!.procrastinate,
                        style: TextStyle(
                            fontSize: 20,
                            fontFamily: TileStyles.rubikFontName,
                            fontWeight: FontWeight.w300,
                            color: Colors.white),
                      ),
                    )),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Map<String, dynamic> newTileParams = {'newTile': null};

                    Navigator.pushNamed(context, '/AddTile',
                            arguments: newTileParams)
                        .whenComplete(() {
                      var newSubEventParams = newTileParams['newTile'];
                      if (newSubEventParams != null) {
                        print('Newly created tile');
                        print(newTileParams);
                        var subEvent = newSubEventParams.item1;
                        // this
                        //     .context
                        //     .read<SubCalendarTilesBloc>()
                        //     .add(AddSubCalendarTile(subEvent: subEvent));
                        int redColor = subEvent.colorRed == null
                            ? 125
                            : subEvent.colorRed!;
                        int blueColor = subEvent.colorBlue == null
                            ? 125
                            : subEvent.colorBlue!;
                        int greenColor = subEvent.colorGreen == null
                            ? 125
                            : subEvent.colorGreen!;
                        double opacity = subEvent.colorOpacity == null
                            ? 1
                            : subEvent.colorOpacity!;
                        var nameColor = Color.fromRGBO(
                            redColor, greenColor, blueColor, opacity);

                        var hslColor = HSLColor.fromColor(nameColor);
                        Color bgroundColor = hslColor
                            .withLightness(hslColor.lightness)
                            .toColor()
                            .withOpacity(0.7);
                        showModalBottomSheet<void>(
                          context: context,
                          constraints: BoxConstraints(
                            maxWidth: 400,
                          ),
                          builder: (BuildContext context) {
                            var future = new Future.delayed(
                                const Duration(milliseconds: autoHideInMs));
                            future.asStream().listen((input) {
                              Navigator.pop(context);
                            });
                            return Container(
                              padding: const EdgeInsets.all(20),
                              height: 250,
                              width: 300,
                              decoration: BoxDecoration(
                                color: bgroundColor,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    NewTileSheet(subEvent: subEvent),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }).catchError((errorThrown) {
                      print('we have error');
                      print(errorThrown);
                      return errorThrown;
                    });
                  },
                  child: ListTile(
                    leading: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.addTile,
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: TileStyles.rubikFontName,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                  ),
                ),
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

  @override
  Widget build(BuildContext context) {
    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      TileList(), //this is the deafault and we need to switch these to routes and so we dont loose back button support
    ];
    if (isAddButtonClicked) {
      widgetChildren.add(generatePredictiveAdd());
    }
    dayStatusWidget.onDayStatusChange(DateTime.now());

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
              color: Color.fromRGBO(250, 254, 255, 1),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color.fromRGBO(0, 119, 170, 1),
                    Color.fromRGBO(0, 194, 237, 1)
                  ])),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.search, color: Colors.white),
                label: '',
              ),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.add,
                    color: Color.fromRGBO(0, 0, 0, 0),
                  ),
                  label: ''),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined), label: ''),
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
      backgroundColor: Color.fromRGBO(250, 254, 255, 1),
      body: Stack(
        children: widgetChildren,
      ),
      bottomNavigationBar: bottomNavigator,
      floatingActionButton: isAddButtonClicked
          ? null
          : FloatingActionButton(
              backgroundColor: Color.fromRGBO(243, 243, 243, 1),
              onPressed: () {
                displayDialog(MediaQuery.of(context).size);
                // setState(() {
                //   isAddButtonClicked = true;
                // });
              },
              child: Icon(
                Icons.add,
                size: 35,
                color: Color.fromRGBO(0, 194, 237, 1),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
