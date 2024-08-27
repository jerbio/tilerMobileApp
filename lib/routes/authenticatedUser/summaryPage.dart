import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
// import 'package:pie_chart/pie_chart.dart';
import 'package:fl_chart/fl_chart.dart' as flchart;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/elapsedTiles/confirmation_dialog.dart';

//  as PieChart;
import 'package:tiler_app/data/analysis.dart';
import 'package:tiler_app/data/driveTime.dart';
import 'package:tiler_app/data/overview_item.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import '../../bloc/scheduleSummary/schedule_summary_bloc.dart';
import '../../components/PendingWidget.dart';
import '../../components/summaryPage/TileToBeCompleted.dart';

class SummaryPage extends StatefulWidget {
  Timeline timeline;
  SummaryPage({required this.timeline});
  _SummaryPage createState() => _SummaryPage();
}

class _SummaryPage extends State<SummaryPage> {
  List<flchart.FlSpot> shots = [];
  Analysis? analysis;
  TimelineSummary? timelineSummary;
  Map<String, double> dataOverView = {};
  Map<String, double> dataDriveTime = {};
  bool isLoadingAnalysis = true;
  bool isLoadingTimelineSummary = true;
  bool isCheckStateActive = false;
  int times = 10;
  List<Timeline> sleeplines = [];
  List<OverViewItem> overviewItems = [];
  List<DriveTime> driveTimes = [];
  List<bool> unscheduledTilesCheckStates = [];
  List<bool> lateTilesCheckStates = [];
  List<SubCalendarEvent> selectedUnscheduledItems = [];
  ScheduleApi scheduleApi = ScheduleApi();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    isLoadingAnalysis = true;
    setState(() {});
    await scheduleApi.getTimelineSummary(this.widget.timeline).then((value) {
      timelineSummary = value;
      if (timelineSummary != null && timelineSummary!.timeline == null) {
        timelineSummary!.timeline = this.widget.timeline;
        setState(() {
          unscheduledTilesCheckStates = List.generate(
              timelineSummary?.nonViable?.length ?? 0, (index) => false);
        });
      }
      if (analysis == null) {
        isLoadingTimelineSummary = false;
        return;
      }

      final timeslines = analysis!.sleep!;
      sleeplines = timeslines;

      timeslines.forEach((element) {
        shots.add(flchart.FlSpot(
          element.startTime.weekday.toDouble(),
          element.duration.inMinutes.toDouble(),
        ));

        print(
            "value is  ${element.duration.inMinutes.toDouble()} weekday ${element.startTime.weekday.toDouble()}");

        print("total lenght of shots is ${shots.length}");
      });

      final overviewlist = analysis!.overview!;
      overviewItems = overviewlist;
      overviewlist.forEach((element) {
        Map<String, double> other = {
          element.name!.toUpperCase(): element.duration!.toDouble()
        };
        dataOverView.addAll(other);
      });
      final drivetimelist = analysis!.drivesTime!;

      driveTimes = drivetimelist;

      drivetimelist.forEach((element) {
        Map<String, double> other = {
          element.name!: element.duration!.toDouble()
        };
        dataDriveTime.addAll(other);
      });

      isLoadingTimelineSummary = false;
      setState(() {});
    }).catchError((onError) {
      timelineSummary = null;
    });

    // GET ANALYSIS FUNCTION
    await scheduleApi.getAnalysis().then((value) {
      analysis = value;
      if (analysis == null) {
        isLoadingAnalysis = false;
        setState(() {});
        return;
      }

      final timeslines = analysis!.sleep!;
      sleeplines = timeslines;

      timeslines.forEach((element) {
        shots.add(flchart.FlSpot(
          element.startTime.weekday.toDouble(),
          element.duration.inMinutes.toDouble(),
        ));

        print(
            "value is  ${element.duration.inMinutes.toDouble()} weekday ${element.startTime.weekday.toDouble()}");

        print("total lenght of shots is ${shots.length}");
      });

      final overviewlist = analysis!.overview!;
      overviewItems = overviewlist;
      overviewlist.forEach((element) {
        Map<String, double> other = {
          element.name!.toUpperCase(): element.duration!.toDouble()
        };
        dataOverView.addAll(other);
      });
      final drivetimelist = analysis!.drivesTime!;

      driveTimes = drivetimelist;

      drivetimelist.forEach((element) {
        Map<String, double> other = {
          element.name!: element.duration!.toDouble()
        };
        dataDriveTime.addAll(other);
      });

      isLoadingAnalysis = false;

      if (mounted) {
        setState(() {
          isLoadingAnalysis = false;
        });
      }
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal
      builder: (context) => PendingWidget(
        imageAsset: TileStyles.evaluatingScheduleAsset,
      ),
    );
  }

  List<SubCalendarEvent> getSelectedUnscheduledItems() {
    List<SubCalendarEvent> selectedItems = [];
    for (int i = 0; i < unscheduledTilesCheckStates.length; i++) {
      if (unscheduledTilesCheckStates[i]) {
        selectedItems.add(timelineSummary?.nonViable?[i] as SubCalendarEvent);
      }
    }
    return selectedItems;
  }

  Widget renderDate(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      width: 110,
      height: 30,
      decoration: BoxDecoration(
          color: Color.fromRGBO(31, 31, 31, 0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Icon(
              Icons.calendar_month,
              size: 15,
              color: Color.fromRGBO(31, 31, 31, 0.8),
            ),
          ),
          Container(
            child: Text(
              (subCalendarEventTile.calendarEventEndTime ??
                      subCalendarEventTile.startTime)
                  .humanDate,
              style: TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(31, 31, 31, 0.8),
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          ),
        ],
      ),
    );

    return retValue;
  }

  Widget renderTile(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = OutlinedButton(
      style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.transparent,
          ),
          padding: EdgeInsets.all(0)),
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditTile(
                      tileId: (subCalendarEventTile.isFromTiler
                              ? subCalendarEventTile.id
                              : subCalendarEventTile.thirdpartyId) ??
                          "",
                      tileSource: subCalendarEventTile.thirdpartyType,
                      thirdPartyUserId: subCalendarEventTile.thirdPartyUserId,
                    )));
      },
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                width: 0.5,
                color: subCalendarEventTile.priority == TilePriority.high
                    ? Colors.red
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(5)),
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    height: 20,
                    width: 20,
                    margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                    decoration: BoxDecoration(
                        color: subCalendarEventTile.color ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(5))),
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width *
                          TileStyles.widthRatio -
                      205,
                  child: Text(
                    subCalendarEventTile.isProcrastinate == true
                        ? AppLocalizations.of(context)!.procrastinateBlockOut
                        : subCalendarEventTile.name ?? "",
                    style: TextStyle(
                      fontFamily: TileStyles.rubikFontName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [renderDate(subCalendarEventTile)],
            ),
          ],
        ),
      ),
    );

    return retValue;
  }

  Widget renderTileToBeCompleted(
      SubCalendarEvent subCalendarEventTile, bool tapValue) {
    Widget retValue = Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.5,
          color: subCalendarEventTile.priority == TilePriority.high
              ? Colors.red
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Checkbox For completion
          GestureDetector(
            onTap: () {
              print("Tapped for completion");
              print("before tap: $tapValue");
              setState(() {
                tapValue = !tapValue;
                print(tapValue);
              });
            },
            child: Container(
              height: 20,
              width: 20,
              margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
              decoration: BoxDecoration(
                color: subCalendarEventTile.color ?? Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  tapValue == true
                      ? Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.check,
                            size: 15,
                          ),
                        )
                      : SizedBox.shrink()
                ],
              ),
            ),
          ),

          //
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width *
                          TileStyles.widthRatio -
                      205,
                  child: Text(
                    subCalendarEventTile.isProcrastinate == true
                        ? AppLocalizations.of(context)!.procrastinateBlockOut
                        : subCalendarEventTile.name ?? "",
                    style: TextStyle(
                      fontFamily: TileStyles.rubikFontName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [renderDate(subCalendarEventTile)],
                ),
              ],
            ),
          )
        ],
      ),
    );

    return retValue;
  }

  Widget renderListOfTiles(
    double height,
    List<SubCalendarEvent> tiles,
  ) {
    List<GlobalKey<_TileToBeCompletedState>> tileKeys = List.generate(
      tiles.length,
      (_) => GlobalKey<_TileToBeCompletedState>(),
    );
    return Column(
      children: tiles.asMap().entries.map<Widget>((entry) {
        int index = entry.key;
        SubCalendarEvent e = entry.value;
        return renderTile(e);
      }).toList(),
    );
  }

  // Completed section
  Widget renderCompleteTiles(double height, List<SubCalendarEvent> tiles) {
    Widget completeHeader = Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(AppLocalizations.of(context)!.complete,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            fontFamily: TileStyles.rubikFontName,
          )),
    );
    if (tiles.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
          child: Column(
            children: [
              completeHeader,
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Container(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset('assets/lottie/abstract-waves-lines.json',
                            height: 100),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromRGBO(255, 255, 255, 0.25),
                                    Color.fromRGBO(255, 255, 255, 0.9),
                                  ])),
                          width: MediaQuery.of(context).size.width *
                              TileStyles.widthRatio,
                          height: 100,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(AppLocalizations.of(context)!.getOnIt,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 50,
                                fontFamily: TileStyles.rubikFontName,
                              )),
                        ),
                      ],
                    )),
              )
            ],
          ),
        ),
      );
    }

    Widget completeBodyHeader = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.05),
                borderRadius: BorderRadius.circular(20)),
            child:
                Icon(Icons.check_circle, color: Color.fromRGBO(9, 203, 156, 1)),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.countTile(tiles.length.toString()),
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          )
        ],
      ),
    );

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
        child: Column(
          children: [
            completeHeader,
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                completeBodyHeader,
                Column(
                  children: [
                    renderListOfTiles(
                      height,
                      tiles,
                    )
                  ],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  // Unscheduled section
  Widget renderUnscheduledTiles(
    double height,
    List<SubCalendarEvent> tiles,
    bool switchCondition, {
    required VoidCallback switchTapFunction,
    required List<bool> checkBoxStates,
    required VoidCallback completeFunction,
  }) {
    tiles = tiles ?? [];
    Widget unscheduledHeader = Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(AppLocalizations.of(context)!.unScheduled,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            fontFamily: TileStyles.rubikFontName,
          )),
    );

    Widget unscheduledBodyHeader = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.05),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.error, color: Colors.redAccent),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.countTile(tiles.length.toString()),
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          )
        ],
      ),
    );

    if (tiles.isEmpty) {
      return SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
        child: Column(
          children: [
            unscheduledHeader,
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                unscheduledBodyHeader,

                switchCondition == true
                    ? Column(
                        children: tiles.asMap().entries.map<Widget>((entry) {
                        int index = entry.key;
                        SubCalendarEvent e = entry.value;
                        return Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  width: 0.5,
                                  color: e.priority == TilePriority.high
                                      ? Colors.red
                                      : Colors.transparent),
                              borderRadius: BorderRadius.circular(5)),
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox.adaptive(
                                      value: //false,
                                          checkBoxStates[index],
                                      onChanged: (value) {
                                        print(
                                            "checkBoxStates: $checkBoxStates");
                                        print("Tap value is $value");
                                        // print('index is $index');
                                        setState(() {
                                          checkBoxStates[index] = value!;
                                          selectedUnscheduledItems =
                                              getSelectedUnscheduledItems();
                                        });
                                      },
                                      activeColor: Colors.transparent,
                                      checkColor: Colors.black,
                                    ),
                                  ),

                                  //Sizedbox for spacing
                                  SizedBox(
                                    width: height / (height / 10),
                                  ),

                                  // Container(
                                  //     height: 20,
                                  //     width: 20,
                                  //     margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  //     decoration: BoxDecoration(
                                  //         color: e.color ?? Colors.transparent,
                                  //         borderRadius:
                                  //             BorderRadius.circular(5))),
                                  Container(
                                    height: 20,
                                    width: MediaQuery.of(context).size.width *
                                            TileStyles.widthRatio -
                                        205,
                                    child: Text(
                                      e.isProcrastinate == true
                                          ? AppLocalizations.of(context)!
                                              .procrastinateBlockOut
                                          : e.name ?? "",
                                      style: TextStyle(
                                        fontFamily: TileStyles.rubikFontName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [renderDate(e)],
                              ),
                            ],
                          ),
                        );
                      }).toList())
                    : Column(
                        children: tiles.asMap().entries.map<Widget>((entry) {
                          int index = entry.key;
                          SubCalendarEvent e = entry.value;
                          return GestureDetector(
                              onTap: switchTapFunction,
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 0.5,
                                        color: e.priority == TilePriority.high
                                            ? Colors.red
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(5)),
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                            height: 20,
                                            width: 20,
                                            margin: EdgeInsets.fromLTRB(
                                                0, 0, 10, 0),
                                            decoration: BoxDecoration(
                                                color: e.color ??
                                                    Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(5))),
                                        Container(
                                          height: 20,
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  TileStyles.widthRatio -
                                              205,
                                          child: Text(
                                            e.isProcrastinate == true
                                                ? AppLocalizations.of(context)!
                                                    .procrastinateBlockOut
                                                : e.name ?? "",
                                            style: TextStyle(
                                              fontFamily:
                                                  TileStyles.rubikFontName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [renderDate(e)],
                                    ),
                                  ],
                                ),
                              ));
                        }).toList(),
                      ),

                // Sizedbox for spacing
                checkBoxStates.where((value) => value == true).length >= 1
                    ? SizedBox(
                        height: height / (height / 20),
                      )
                    : SizedBox.shrink(),

                // Display currently selected tiles
                checkBoxStates.where((value) => value == true).length >= 1
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "${checkBoxStates.where((value) => value == true).length} Tiles Selected",
                            style: TextStyle(
                              fontFamily: TileStyles.rubikFontName,
                              color: TileStyles.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: completeFunction,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: height / (height / 10),
                                vertical: height / (height / 5),
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: TileStyles.primaryColor,
                                  width: height / height,
                                ),
                                borderRadius: BorderRadius.circular(
                                  height / (height / 4),
                                ),
                              ),
                              child: Text(
                                'Complete Tiles',
                                style: TextStyle(
                                  fontFamily: TileStyles.rubikFontName,
                                  color: TileStyles.primaryColor,
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    : SizedBox.shrink(),
                // Column(
                //   children: [
                //     renderListOfTiles(
                //       height,
                //       tiles,
                //       unscheduledTilesCheckStates,
                //     )
                //   ],
                // )
              ]),
            )
          ],
        ),
      ),
    );
  }

  // Late section
  Widget renderTardyTiles(double height, List<SubCalendarEvent> tiles) {
    Widget tardyHeader = Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(AppLocalizations.of(context)!.late,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            fontFamily: TileStyles.rubikFontName,
          )),
    );

    if (tiles.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
          child: Column(
            children: [
              tardyHeader,
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Container(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset(
                            'assets/lottie/abstract-waves-circles.json',
                            height: 100),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromRGBO(255, 255, 255, 0.25),
                                    Color.fromRGBO(255, 255, 255, 0.9),
                                  ])),
                          width: MediaQuery.of(context).size.width *
                              TileStyles.widthRatio,
                          height: 100,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(AppLocalizations.of(context)!.onTime,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 50,
                                fontFamily: TileStyles.rubikFontName,
                              )),
                        ),
                      ],
                    )),
              )
            ],
          ),
        ),
      );
    }

    Widget tardyBodyHeader = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.05),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.warning, color: Colors.amberAccent),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.countTile(tiles.length.toString()),
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          )
        ],
      ),
    );

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
        child: Column(
          children: [
            tardyHeader,
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                tardyBodyHeader,
                Column(
                  children: [
                    renderListOfTiles(
                      height,
                      tiles,
                    )
                  ],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  // Widget renderSleepData() {
  //   return Column(
  //     children: [
  //       Text(
  //         AppLocalizations.of(context)!.sleep,
  //         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
  //       ),
  //       Container(
  //         height: 300,
  //         decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.all(Radius.circular(10))),
  //         child: (isLoadingAnalysis)
  //             ? CircularProgressIndicator(
  //                 color: Colors.blue,
  //               )
  //             : (shots.isEmpty)
  //                 ? Container(
  //                     child: Center(
  //                         child: Text(
  //                             AppLocalizations.of(context)!.noDataAvailable)),
  //                   )
  //                 : Stack(
  //                     children: [
  //                       Positioned(
  //                         left: 20,
  //                         top: 80,
  //                         child: Container(
  //                             height: 180,
  //                             width: MediaQuery.of(context).size.width * 0.8,
  //                             child: (shots.isEmpty)
  //                                 ? Container(
  //                                     width: MediaQuery.of(context).size.width,
  //                                     child: Center(
  //                                       child: Text(
  //                                           AppLocalizations.of(context)!
  //                                               .noDataAvailable),
  //                                     ),
  //                                   )
  //                                 : _LineChart(
  //                                     isShowingMainData: true,
  //                                     spots: shots,
  //                                   )),
  //                       ),
  //                       Positioned(
  //                         top: 0,
  //                         left: 0,
  //                         child: Container(
  //                             margin: EdgeInsets.only(left: 0, right: 20),
  //                             decoration: BoxDecoration(
  //                                 color: Colors.white,
  //                                 borderRadius: BorderRadius.circular(12)),
  //                             width: MediaQuery.of(context).size.width,
  //                             height: 100,
  //                             child: Row(
  //                               mainAxisAlignment: MainAxisAlignment.start,
  //                               crossAxisAlignment: CrossAxisAlignment.center,
  //                               children: [
  //                                 SizedBox(
  //                                   width: 12,
  //                                 ),
  //                                 Container(
  //                                   width: 50,
  //                                   height: 50,
  //                                   decoration: BoxDecoration(
  //                                     color: Color(0xffFAFAFA),
  //                                     borderRadius:
  //                                         BorderRadius.all(Radius.circular(20)),
  //                                   ),
  //                                   child: Padding(
  //                                     padding: const EdgeInsets.all(8.0),
  //                                     child: Image.asset(
  //                                         "assets/images/image8.png"),
  //                                   ),
  //                                 ),
  //                                 SizedBox(
  //                                   width: 12,
  //                                 ),
  //                                 Container(
  //                                   child: Column(
  //                                     mainAxisAlignment:
  //                                         MainAxisAlignment.center,
  //                                     crossAxisAlignment:
  //                                         CrossAxisAlignment.start,
  //                                     children: [
  //                                       Text(
  //                                         "Today",
  //                                         maxLines: 2,
  //                                         style: TextStyle(
  //                                             color: Color(0xff1F1F1F),
  //                                             fontSize: 13,
  //                                             fontWeight: FontWeight.w400),
  //                                       ),
  //                                       Text(
  //                                         "8h 8m",
  //                                         maxLines: 2,
  //                                         style: TextStyle(
  //                                             color: Color(0xff1F1F1F),
  //                                             fontSize: 20,
  //                                             fontWeight: FontWeight.bold),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                                 Expanded(child: SizedBox()),
  //                                 Container(
  //                                   width:
  //                                       MediaQuery.of(context).size.width * 0.2,
  //                                   child: Text(
  //                                     "8% more than last week!",
  //                                     maxLines: 2,
  //                                     style: TextStyle(
  //                                         color: Color(0xff1F1F1F),
  //                                         fontSize: 13,
  //                                         fontWeight: FontWeight.w400),
  //                                   ),
  //                                 ),
  //                                 SizedBox(
  //                                   width: 60,
  //                                 )
  //                               ],
  //                             )),
  //                       ),
  //                     ],
  //                   ),
  //       ),
  //     ],
  //   );
  // }

  // Widget renderDriveData() {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
  //     alignment: Alignment.center,
  //     width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
  //     child: Column(
  //       children: [
  //         Container(
  //           alignment: Alignment.topLeft,
  //           padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
  //           child: Text(
  //             AppLocalizations.of(context)!.driveTime,
  //             style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
  //           ),
  //         ),
  //         Container(
  //           width: MediaQuery.of(context).size.width,
  //           height: 300,
  //           decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.all(Radius.circular(10))),
  //           child: Stack(
  //             children: [
  //               Positioned(
  //                 left: 0,
  //                 top: 20,
  //                 child: Container(
  //                     height: 280,
  //                     width: MediaQuery.of(context).size.width - 30,
  //                     child: SingleChildScrollView(
  //                       scrollDirection: Axis.horizontal,
  //                       child: (dataDriveTime.isEmpty)
  //                           ? Container(
  //                               width: MediaQuery.of(context).size.width,
  //                               child: Center(
  //                                 child: Text(AppLocalizations.of(context)!
  //                                     .noDataAvailable),
  //                               ),
  //                             )
  //                           : PieChart(
  //                               dataMap: dataDriveTime,
  //                               animationDuration: Duration(milliseconds: 800),
  //                               chartLegendSpacing: 32,
  //                               chartRadius:
  //                                   MediaQuery.of(context).size.width / 3.2,
  //                               initialAngleInDegree: 0,
  //                               chartType: ChartType.disc,
  //                               ringStrokeWidth: 6,
  //                               centerText: "",
  //                               legendOptions: LegendOptions(
  //                                 showLegendsInRow: false,
  //                                 legendPosition: LegendPosition.right,
  //                                 showLegends: true,
  //                                 legendShape: BoxShape.rectangle,
  //                                 legendTextStyle: TextStyle(
  //                                     fontWeight: FontWeight.w400,
  //                                     overflow: TextOverflow.ellipsis,
  //                                     fontSize: 12),
  //                               ),
  //                               chartValuesOptions: ChartValuesOptions(
  //                                 showChartValueBackground: true,
  //                                 showChartValues: false,
  //                                 showChartValuesInPercentage: false,
  //                                 showChartValuesOutside: false,
  //                                 decimalPlaces: 1,
  //                               ),
  //                             ),
  //                     )),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget renderAnalysisData() {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
  //     alignment: Alignment.center,
  //     width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Container(
  //             alignment: Alignment.topLeft,
  //             padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
  //             child: Text(
  //               AppLocalizations.of(context)!.analysis,
  //               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
  //             )),
  //         Container(
  //           height: 200,
  //           padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
  //           decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.all(Radius.circular(10))),
  //           child: Stack(
  //             children: [
  //               Container(
  //                 height: 180,
  //                 width: MediaQuery.of(context).size.width - 30,
  //                 child: SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   child: (dataOverView.isEmpty)
  //                       ? Container(
  //                           width: MediaQuery.of(context).size.width,
  //                           child: Center(
  //                             child: Text(AppLocalizations.of(context)!
  //                                 .noDataAvailable),
  //                           ),
  //                         )
  //                       : PieChart(
  //                           dataMap: dataOverView,
  //                           animationDuration: Duration(milliseconds: 800),
  //                           chartLegendSpacing: 30,
  //                           chartRadius:
  //                               MediaQuery.of(context).size.width / 3.2,
  //                           initialAngleInDegree: 0,
  //                           chartType: ChartType.ring,
  //                           ringStrokeWidth: 6,
  //                           centerText: AppLocalizations.of(context)!.overview,
  //                           legendOptions: LegendOptions(
  //                             showLegendsInRow: false,
  //                             legendPosition: LegendPosition.right,
  //                             showLegends: true,
  //                             legendShape: BoxShape.rectangle,
  //                             legendTextStyle: TextStyle(
  //                                 fontWeight: FontWeight.bold, fontSize: 12),
  //                           ),
  //                           chartValuesOptions: ChartValuesOptions(
  //                             showChartValueBackground: true,
  //                             showChartValues: false,
  //                             showChartValuesInPercentage: false,
  //                             showChartValuesOutside: false,
  //                             decimalPlaces: 1,
  //                           ),
  //                         ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    bool isFuture = false;
    double height = MediaQuery.of(context).size.height;

    if (this.timelineSummary != null) {
      if (!isFuture && this.timelineSummary!.date != null) {
        isFuture = this
            .timelineSummary!
            .date!
            .isAfter(Utility.todayTimeline().endTime);
      }

      if (!isFuture && this.timelineSummary!.timeline != null) {
        isFuture = this
            .timelineSummary!
            .timeline!
            .endTime
            .isAfter(Utility.todayTimeline().endTime);
      }
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: TileStyles.primaryColor,
          title: Text(
            this.widget.timeline.startTime.humanDate,
            style: TextStyle(
                color: TileStyles.appBarTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 22),
          ),
          iconTheme: IconThemeData(
            color: TileStyles.appBarTextColor,
          ),
          leading: CloseButton(),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: TileStyles.primaryColorLightHSL.toColor(),
          child: SingleChildScrollView(
            child: (isLoadingTimelineSummary)
                ? Container(
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                      child: Container(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator()),
                    ))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width *
                            TileStyles.widthRatio,
                        alignment: Alignment.topLeft,
                        margin: EdgeInsets.only(
                          top: 15,
                          bottom: 15,
                        ),
                        // child: Text(
                        //   this.widget.timeline.startTime.humanDate,
                        //   style: TextStyle(
                        //       fontSize: 40,
                        //       fontWeight: FontWeight.w600,
                        //       fontFamily: TileStyles.rubikFontName),
                        // ),
                      ),
                      // renderAnalysisData(),
                      this.timelineSummary == null || isFuture
                          ? SizedBox.shrink()
                          : renderCompleteTiles(height, <SubCalendarEvent>[
                              ...((this.timelineSummary!.complete ?? [])
                                  .map<SubCalendarEvent>((eachSubEvent) {
                                return eachSubEvent as SubCalendarEvent;
                              }))
                            ]),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderUnscheduledTiles(
                              height,
                              // <SubCalendarEvent>[
                              //   ...((this.timelineSummary!.nonViable ?? [])
                              //       .map<SubCalendarEvent>((eachSubEvent) {
                              //     return eachSubEvent as SubCalendarEvent;
                              //   }))
                              // ],
                              this
                                      .timelineSummary
                                      ?.nonViable
                                      ?.cast<SubCalendarEvent>() ??
                                  [],
                              this.isCheckStateActive,
                              switchTapFunction: () => setState(() {
                                this.isCheckStateActive =
                                    !this.isCheckStateActive;
                                print(
                                    "checkboxstate: $unscheduledTilesCheckStates");
                                print(
                                    "timeline is of lenght: ${timelineSummary?.nonViable?.length}");
                                // print(
                                //     'LENGTH ${this.timelineSummary!.nonViable!.length}');
                                // print('List is $unscheduledTilesCheckStates');
                              }),
                              checkBoxStates: unscheduledTilesCheckStates,
                              completeFunction: () async {
                                List<String> eventIds = selectedUnscheduledItems
                                    .map((element) => element.id)
                                    .where((id) => id != null)
                                    .cast<String>()
                                    .toList();
                                List<String> eventThirdPartyTypes =
                                    selectedUnscheduledItems
                                        .map((element) => element
                                            .thirdpartyType?.name
                                            .toLowerCase())
                                        .where((id) => id != null)
                                        .cast<String>()
                                        .toList();
                                List<String> eventThirdPartyUserIds =
                                    selectedUnscheduledItems
                                        .map((element) {
                                          if (element
                                                  .thirdPartyUserId.isEmpty ||
                                              element.thirdPartyUserId == '') {
                                            return 'tiler-account';
                                          } else {
                                            return element.thirdPartyUserId;
                                          }
                                        })
                                        .where((id) => id.isNotEmpty)
                                        .cast<String>()
                                        .toList();
                                List<String> eventThirdPartyEventId =
                                    selectedUnscheduledItems
                                        .map((element) {
                                          if (element.thirdpartyId!.isEmpty ||
                                              element.thirdpartyId == '') {
                                            return '';
                                          } else {
                                            return element.thirdpartyId;
                                          }
                                        })
                                        .where((id) => id != null)
                                        .cast<String>()
                                        .toList();

                                String eventIdString = eventIds
                                    .where(
                                      (element) => element != null,
                                    )
                                    .join(',');
                                String eventThirdPartyTypeString =
                                    eventThirdPartyTypes.join(',');
                                String eventThirdPartyUserIdString =
                                    eventThirdPartyUserIds.join(',');
                                String eventThirdPartyEventIdString =
                                    eventThirdPartyEventId.join(',');
                                print(eventIdString);
                                print(eventThirdPartyTypeString);
                                print(eventThirdPartyUserIdString);
                                print(eventThirdPartyEventIdString);

                                print(
                                    'First item is: ${selectedUnscheduledItems[0].thirdPartyUserId}');
                                print(
                                    'First item is: ${selectedUnscheduledItems[0].thirdpartyId}');

                                _showLoadingDialog();

                                // Wait for the task completion
                                bool success =
                                    await BlocProvider.of<ScheduleSummaryBloc>(
                                            context)
                                        .completeTasks(
                                            eventIdString,
                                            eventThirdPartyTypeString,
                                            eventThirdPartyUserIdString);

                                if (success) {
                                  print("Success: $success");
                                  await initialize();
                                  Future.delayed(Duration(seconds: 2), () {
                                    Navigator.pop(context);
                                  });
                                }
                              },
                            ),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderTardyTiles(height, <SubCalendarEvent>[
                              ...((this.timelineSummary!.tardy ?? [])
                                  .map<SubCalendarEvent>((eachSubEvent) {
                                return eachSubEvent as SubCalendarEvent;
                              }))
                            ]),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// class _LineChart extends StatelessWidget {
//   const _LineChart({required this.isShowingMainData, required this.spots});

//   final bool isShowingMainData;
//   final List<flchart.FlSpot> spots;

//   @override
//   Widget build(BuildContext context) {
//     return flchart.LineChart(
//       data,
//       swapAnimationDuration: const Duration(milliseconds: 250),
//     );
//   }

//   flchart.LineChartData get data => flchart.LineChartData(
//         lineTouchData: lineTouchData,
//         gridData: gridData,
//         titlesData: titlesData,
//         borderData: borderData,
//         lineBarsData: lineBarsData,
//         // minX: 0,
//         // maxX: 7,
//         maxY: spots.last.y + 120,
//         minY: 0,
//       );

//   flchart.LineTouchData get lineTouchData => flchart.LineTouchData(
//         handleBuiltInTouches: true,
//         touchTooltipData: flchart.LineTouchTooltipData(
//           tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
//         ),
//       );

//   flchart.FlTitlesData get titlesData => flchart.FlTitlesData(
//         bottomTitles: flchart.AxisTitles(
//           sideTitles: bottomTitles,
//         ),
//         rightTitles: flchart.AxisTitles(
//           sideTitles: flchart.SideTitles(showTitles: false),
//         ),
//         topTitles: flchart.AxisTitles(
//           sideTitles: flchart.SideTitles(showTitles: false),
//         ),
//         leftTitles: flchart.AxisTitles(
//           axisNameWidget: Text("Hrs"),
//           sideTitles: leftTitles(),
//         ),
//       );

//   List<flchart.LineChartBarData> get lineBarsData => [
//         lineChartBarData1_2,
//       ];

//   Widget leftTitleWidgets(double value, flchart.TitleMeta meta) {
//     const style = TextStyle(
//       fontWeight: FontWeight.w400,
//       fontSize: 10,
//     );
//     final time = Duration(minutes: value.toInt());

//     final text = Utility.toHuman(time, abbreviations: true);

//     return Text(text, style: style, textAlign: TextAlign.center);
//   }

//   flchart.SideTitles leftTitles() => flchart.SideTitles(
//         getTitlesWidget: leftTitleWidgets,
//         showTitles: true,
//         interval: 60,
//         reservedSize: 40,
//       );

//   Widget bottomTitleWidgets(double value, flchart.TitleMeta meta) {
//     const style = TextStyle(
//       fontWeight: FontWeight.w400,
//       fontSize: 10,
//     );

//     Widget text;

//     switch (value.toInt()) {
//       case 1:
//         text = const Text('Sun', style: style);
//         break;
//       case 2:
//         text = const Text('Mon', style: style);
//         break;
//       case 3:
//         text = const Text('Tue', style: style);
//         break;
//       case 4:
//         text = const Text('Wed', style: style);
//         break;
//       case 5:
//         text = const Text('Thur', style: style);
//         break;
//       case 6:
//         text = const Text('Fri', style: style);
//         break;
//       case 7:
//         text = const Text('Sat', style: style);
//         break;

//       default:
//         text = const Text('  ');
//         break;
//     }

//     return flchart.SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 10,
//       child: text,
//     );
//   }

//   flchart.SideTitles get bottomTitles => flchart.SideTitles(
//         showTitles: true,
//         reservedSize: 32,
//         interval: 1,
//         getTitlesWidget: bottomTitleWidgets,
//       );

//   flchart.FlGridData get gridData => flchart.FlGridData(
//       show: true, horizontalInterval: 60, verticalInterval: 1);

//   flchart.FlBorderData get borderData => flchart.FlBorderData(
//         show: true,
//         border: Border(
//           bottom: const BorderSide(color: AppColors.borderColor),
//           right: const BorderSide(color: Colors.transparent),
//           top: const BorderSide(color: Colors.transparent),
//         ),
//       );

//   flchart.LineChartBarData get lineChartBarData1_2 => flchart.LineChartBarData(
//       isCurved: true,
//       color: Color(0xff0077FF),
//       barWidth: 3,
//       isStrokeCapRound: true,
//       dotData: flchart.FlDotData(show: false),
//       belowBarData: flchart.BarAreaData(
//         show: false,
//         color: Color(0xff0077FF).withOpacity(0),
//       ),
//       spots: spots);
// }

// class AppColors {
//   static const Color primary = contentColorCyan;
//   static const Color menuBackground = Color(0xFF090912);
//   static const Color itemsBackground = Color(0xFF1B2339);
//   static const Color pageBackground = Color(0xFF282E45);
//   static const Color mainTextColor1 = Colors.white;
//   static const Color mainTextColor2 = Colors.white70;
//   static const Color mainTextColor3 = Colors.white38;
//   static const Color mainGridLineColor = Colors.white10;
//   static const Color borderColor = Colors.white54;
//   static const Color gridLinesColor = Color(0x11FFFFFF);

//   static const Color contentColorBlack = Colors.black;
//   static const Color contentColorWhite = Colors.white;
//   static const Color contentColorBlue = Color(0xFF2196F3);
//   static const Color contentColorYellow = Color(0xFFFFC300);
//   static const Color contentColorOrange = Color(0xFFFF683B);
//   static const Color contentColorGreen = Color(0xFF3BFF49);
//   static const Color contentColorPurple = Color(0xFF6E1BFF);
//   static const Color contentColorPink = Color(0xFFFF3AF2);
//   static const Color contentColorRed = Color(0xFFE80054);
//   static const Color contentColorCyan = Color(0xFF50E4FF);
// }

class TileToBeCompleted extends StatefulWidget {
  final SubCalendarEvent subCalendarEventTile;
  final bool initialTapValue;
  final Function(bool) onChanged;

  TileToBeCompleted({
    Key? key,
    required this.subCalendarEventTile,
    this.initialTapValue = false,
    required this.onChanged,
  }) : super(key: key);

  @override
  _TileToBeCompletedState createState() => _TileToBeCompletedState();
}

class _TileToBeCompletedState extends State<TileToBeCompleted> {
  late bool tapValue;

  @override
  void initState() {
    super.initState();
    tapValue = widget.initialTapValue;
  }

  void updateTapValue(bool newValue) {
    setState(() {
      tapValue = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.5,
          color: widget.subCalendarEventTile.priority == TilePriority.high
              ? Colors.red
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                tapValue = !tapValue;
              });
              widget.onChanged(tapValue);
            },
            child: Container(
              height: 20,
              width: 20,
              margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
              decoration: BoxDecoration(
                color: widget.subCalendarEventTile.color ?? Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  tapValue
                      ? Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.check,
                            size: 15,
                          ),
                        )
                      : SizedBox.shrink()
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width *
                          TileStyles.widthRatio -
                      205,
                  child: Text(
                    widget.subCalendarEventTile.isProcrastinate == true
                        ? AppLocalizations.of(context)!.procrastinateBlockOut
                        : widget.subCalendarEventTile.name ?? "",
                    style: TextStyle(
                      fontFamily: TileStyles.rubikFontName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [renderDate(widget.subCalendarEventTile)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget renderDate(SubCalendarEvent subCalendarEventTile) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      width: 110,
      height: 30,
      decoration: BoxDecoration(
          color: Color.fromRGBO(31, 31, 31, 0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Icon(
              Icons.calendar_month,
              size: 15,
              color: Color.fromRGBO(31, 31, 31, 0.8),
            ),
          ),
          Container(
            child: Text(
              (subCalendarEventTile.calendarEventEndTime ??
                      subCalendarEventTile.startTime)
                  .humanDate,
              style: TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(31, 31, 31, 0.8),
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
