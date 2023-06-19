import 'package:lottie/lottie.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:fl_chart/fl_chart.dart' as flchart;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
  int times = 10;
  List<Timeline> sleeplines = [];
  List<OverViewItem> overviewItems = [];
  List<DriveTime> driveTimes = [];
  ScheduleApi scheduleApi = ScheduleApi();

  @override
  void initState() {
    super.initState();
    isLoadingAnalysis = true;
    setState(() {});
    scheduleApi.getTimelineSummary(this.widget.timeline).then((value) {
      timelineSummary = value;
      if (analysis == null) {
        isLoadingTimelineSummary = false;
        setState(() {
          isLoadingTimelineSummary = false;
        });
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

    // scheduleApi.getAnalysis().then((value) {
    //   analysis = value;
    //   if (analysis == null) {
    //     isLoadingAnalysis = false;
    //     setState(() {});
    //     return;
    //   }

    //   final timeslines = analysis!.sleep!;
    //   sleeplines = timeslines;

    //   timeslines.forEach((element) {
    //     shots.add(flchart.FlSpot(
    //       element.startTime.weekday.toDouble(),
    //       element.duration.inMinutes.toDouble(),
    //     ));

    //     print(
    //         "value is  ${element.duration.inMinutes.toDouble()} weekday ${element.startTime.weekday.toDouble()}");

    //     print("total lenght of shots is ${shots.length}");
    //   });

    //   final overviewlist = analysis!.overview!;
    //   overviewItems = overviewlist;
    //   overviewlist.forEach((element) {
    //     Map<String, double> other = {
    //       element.name!.toUpperCase(): element.duration!.toDouble()
    //     };
    //     dataOverView.addAll(other);
    //   });
    //   final drivetimelist = analysis!.drivesTime!;

    //   driveTimes = drivetimelist;

    //   drivetimelist.forEach((element) {
    //     Map<String, double> other = {
    //       element.name!: element.duration!.toDouble()
    //     };
    //     dataDriveTime.addAll(other);
    //   });

    //   isLoadingAnalysis = false;
    //   setState(() {});
    // });
  }

  Widget renderDate(TilerEvent subCalendarEventTile) {
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
              subCalendarEventTile.startTime.humanDate,
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

  Widget renderTile(TilerEvent subCalendarEventTile) {
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
                builder: (context) =>
                    EditTile(tileId: subCalendarEventTile.id!)));
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
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
                      190,
                  child: Text(
                    subCalendarEventTile.name!,
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

  Widget renderListOfTiles(List<SubCalendarEvent> tiles) {
    return Column(
      children: tiles.map<Widget>((e) => renderTile(e)).toList(),
    );
  }

  Widget renderCompleteTiles(List<SubCalendarEvent> tiles) {
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
                  children: [renderListOfTiles(tiles)],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget renderUnscheduledTiles(List<SubCalendarEvent> tiles) {
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

    if (tiles.isEmpty) {
      return SizedBox.shrink();
    }

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
                Column(
                  children: [renderListOfTiles(tiles)],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget renderTardyTiles(List<SubCalendarEvent> tiles) {
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
                  children: [renderListOfTiles(tiles)],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                        child: Text(
                          this.widget.timeline.startTime.humanDate,
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              fontFamily: TileStyles.rubikFontName),
                        ),
                      ),
                      // renderAnalysisData(),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderCompleteTiles(
                              this.timelineSummary!.complete ?? []),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderUnscheduledTiles(
                              this.timelineSummary!.nonViable ?? []),
                      this.timelineSummary == null
                          ? SizedBox.shrink()
                          : renderTardyTiles(this.timelineSummary!.tardy ?? []),
                      // renderDriveData(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.isShowingMainData, required this.spots});

  final bool isShowingMainData;
  final List<flchart.FlSpot> spots;

  @override
  Widget build(BuildContext context) {
    return flchart.LineChart(
      data,
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }

  flchart.LineChartData get data => flchart.LineChartData(
        lineTouchData: lineTouchData,
        gridData: gridData,
        titlesData: titlesData,
        borderData: borderData,
        lineBarsData: lineBarsData,
        // minX: 0,
        // maxX: 7,
        maxY: spots.last.y + 120,
        minY: 0,
      );

  flchart.LineTouchData get lineTouchData => flchart.LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: flchart.LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
      );

  flchart.FlTitlesData get titlesData => flchart.FlTitlesData(
        bottomTitles: flchart.AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: flchart.AxisTitles(
          sideTitles: flchart.SideTitles(showTitles: false),
        ),
        topTitles: flchart.AxisTitles(
          sideTitles: flchart.SideTitles(showTitles: false),
        ),
        leftTitles: flchart.AxisTitles(
          axisNameWidget: Text("Hrs"),
          sideTitles: leftTitles(),
        ),
      );

  List<flchart.LineChartBarData> get lineBarsData => [
        lineChartBarData1_2,
      ];

  Widget leftTitleWidgets(double value, flchart.TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10,
    );
    final time = Duration(minutes: value.toInt());

    final text = Utility.toHuman(time, abbreviations: true);

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  flchart.SideTitles leftTitles() => flchart.SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 60,
        reservedSize: 40,
      );

  Widget bottomTitleWidgets(double value, flchart.TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10,
    );

    Widget text;

    switch (value.toInt()) {
      case 1:
        text = const Text('Sun', style: style);
        break;
      case 2:
        text = const Text('Mon', style: style);
        break;
      case 3:
        text = const Text('Tue', style: style);
        break;
      case 4:
        text = const Text('Wed', style: style);
        break;
      case 5:
        text = const Text('Thur', style: style);
        break;
      case 6:
        text = const Text('Fri', style: style);
        break;
      case 7:
        text = const Text('Sat', style: style);
        break;

      default:
        text = const Text('  ');
        break;
    }

    return flchart.SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  flchart.SideTitles get bottomTitles => flchart.SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  flchart.FlGridData get gridData => flchart.FlGridData(
      show: true, horizontalInterval: 60, verticalInterval: 1);

  flchart.FlBorderData get borderData => flchart.FlBorderData(
        show: true,
        border: Border(
          bottom: const BorderSide(color: AppColors.borderColor),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );

  flchart.LineChartBarData get lineChartBarData1_2 => flchart.LineChartBarData(
      isCurved: true,
      color: Color(0xff0077FF),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: flchart.FlDotData(show: false),
      belowBarData: flchart.BarAreaData(
        show: false,
        color: Color(0xff0077FF).withOpacity(0),
      ),
      spots: spots);
}

class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}
