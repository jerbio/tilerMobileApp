import 'package:pie_chart/pie_chart.dart';
import 'package:fl_chart/fl_chart.dart' as flchart;

import 'package:flutter/material.dart';

//  as PieChart;
import 'package:tiler_app/data/analysis.dart';
import 'package:tiler_app/data/driveTime.dart';
import 'package:tiler_app/data/overview_item.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

class SummaryPage extends StatefulWidget {
  _SummaryPage createState() => _SummaryPage();
}

class _SummaryPage extends State<SummaryPage> {
  List<flchart.FlSpot> shots = [];
  Analysis? analysis;
  Map<String, double> dataOverView = {};
  Map<String, double> dataDriveTime = {};
  bool isLoading = true;
  int times = 10;
  List<Timeline> sleeplines = [];
  List<OverViewItem> overviewItems = [];
  List<DriveTime> driveTimes = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isLoading = true;
    setState(() {});
    ScheduleApi().getAnalysis().then((value) {
      analysis = value;
      if (analysis == null) {
        isLoading = false;
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
// times=times+20;
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

      isLoading = false;
      setState(() {});
    });
//  void
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      // appBar: AppBar(),
      body: Container(
        color: Color(0xffFAFAFA),
        child: SingleChildScrollView(
          child: (isLoading)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 50, left: 20),
                      child: Container(
                        child: Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(),
                    Padding(
                      padding: const EdgeInsets.only(top: 33, left: 20),
                      child: Container(
                        margin: EdgeInsets.only(
                          left: 2,
                        ),
                        child: Text(
                          "Today",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 5),
                      child: Text(
                        "Analysis",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 34),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                height: 180,
                                width: MediaQuery.of(context).size.width - 30,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: (dataOverView.isEmpty)
                                      ? Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Center(
                                            child: Text("No data available"),
                                          ),
                                        )
                                      : PieChart(
                                          dataMap: dataOverView,
                                          animationDuration:
                                              Duration(milliseconds: 800),
                                          chartLegendSpacing: 30,
                                          chartRadius: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3.2,
                                          initialAngleInDegree: 0,
                                          chartType: ChartType.ring,
                                          ringStrokeWidth: 6,
                                          centerText: "Overview \n Today",
                                          legendOptions: LegendOptions(
                                            showLegendsInRow: false,
                                            legendPosition:
                                                LegendPosition.right,
                                            showLegends: true,
                                            legendShape: BoxShape.rectangle,
                                            legendTextStyle: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                          ),
                                          chartValuesOptions:
                                              ChartValuesOptions(
                                            showChartValueBackground: true,
                                            showChartValues: false,
                                            showChartValuesInPercentage: false,
                                            showChartValuesOutside: false,
                                            decimalPlaces: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 36),
                      child: Text(
                        "Sleep",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 300,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: (isLoading)
                            ? CircularProgressIndicator(
                                color: Colors.blue,
                              )
                            : (shots.isEmpty)
                                ? Container(
                                    child: Center(
                                        child: Text("No data available")),
                                  )
                                : Stack(
                                    children: [
                                      Positioned(
                                        left: 20,
                                        top: 80,
                                        child: Container(
                                            height: 180,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            child: (shots.isEmpty)
                                                ? Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    child: Center(
                                                      child: Text(
                                                          "No data available"),
                                                    ),
                                                  )
                                                : _LineChart(
                                                    isShowingMainData: true,
                                                    spots: shots,
                                                  )),
                                      ),
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: Container(
                                            margin: EdgeInsets.only(
                                                left: 0, right: 20),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 100,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 12,
                                                ),
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xffFAFAFA),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                20)),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Image.asset(
                                                        "assets/images/image8.png"),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 12,
                                                ),
                                                Container(
                                                  // width:MediaQuery.of(context).size.width*0.4 ,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Today",
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xff1F1F1F),
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w400),
                                                      ),
                                                      Text(
                                                        "8h 8m",
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xff1F1F1F),
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(child: SizedBox()),
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.2,
                                                  child: Text(
                                                    "8% more than last week!",
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff1F1F1F),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 60,
                                                )
                                              ],
                                            )),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 36),
                      child: Text(
                        "Drive Time",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 300,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: Stack(
                          // mainAxisAlignment: MainAxisAlignment.start,
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              top: 20,
                              child: Container(
                                  height: 280,
                                  width: MediaQuery.of(context).size.width - 30,
                                  // child: LineChartSample2())),
                                  child:
                                      // _LineChart(isShowingMainData: true)),),
                                      SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: (dataDriveTime.isEmpty)
                                        ? Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: Center(
                                              child: Text("No data available"),
                                            ),
                                          )
                                        : PieChart(
                                            dataMap: dataDriveTime,
                                            animationDuration:
                                                Duration(milliseconds: 800),
                                            chartLegendSpacing: 32,
                                            chartRadius: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3.2,
                                            // colorList: [Color(0xff007BED),Color(0xff8F00FF),
                                            // Color(0xff0077AA)],
                                            initialAngleInDegree: 0,
                                            chartType: ChartType.disc,
                                            ringStrokeWidth: 6,
                                            centerText: "",
                                            legendOptions: LegendOptions(
                                              showLegendsInRow: false,
                                              legendPosition:
                                                  LegendPosition.right,
                                              showLegends: true,
                                              // legendLabels: {"24 Hour Fitness - Starbucks":"testing"},
                                              legendShape: BoxShape.rectangle,
                                              legendTextStyle: TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontSize: 12),
                                            ),
                                            chartValuesOptions:
                                                ChartValuesOptions(
                                              showChartValueBackground: true,
                                              showChartValues: false,
                                              showChartValuesInPercentage:
                                                  false,
                                              showChartValuesOutside: false,
                                              decimalPlaces: 1,
                                            ),
                                            // gradientList: ---To add gradient colors---
                                            // emptyColorGradient: ---Empty Color gradient---
                                          ),
                                  )),
                            ),
                            //      Positioned(
                            //         // padding: const EdgeInsets.all(8.0),
                            //         left:MediaQuery.of(context).orientation == Orientation.portrait? MediaQuery.of(context).size.width*0.8: MediaQuery.of(context).size.width*0.65,
                            //         top:(driveTimes.length==1)?153:(driveTimes.length==2)?140:(driveTimes.length==3)?130:(driveTimes.length==4)?120:(driveTimes.length==5)?110: (driveTimes.length==6)?100:
                            //          (driveTimes.length==7)?85: (driveTimes.length==8)?72: (driveTimes.length==9)?60:
                            //         45,
                            //         child:
                            //         //  Container(
                            //         //   width: 50,
                            //         //   height: 200,
                            //         //   child: ListView.builder(
                            //         //     itemCount: 5,
                            //         //     itemBuilder: (context,index){
                            //         // return  Text("9h 32m",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),);
                            //         //   }),
                            //         // )

                            //       Column(

                            //           children:driveTimes.map((e) =>Column(
                            //             children:[

                            //  Text("${Utility.toHuman(Duration(milliseconds:e.duration! ),abbreviations: true)}",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w300,fontSize: 12),),
                            //         SizedBox(height:10,),
                            //           ])).toList()
                            //       ))
                            //   Positioned(
                            //     // padding: const EdgeInsets.all(8.0),
                            //     right: 30,
                            //     top: 30,
                            //     child: Container(
                            //       width: 100,
                            //       height: 100,
                            //       child: ListView.builder(
                            //         itemCount:driveTimes.length ,
                            //         itemBuilder: (context,index){
                            //           final dateTime=DateTime.fromMillisecondsSinceEpoch(driveTimes[index].duration!);

                            //           final duration=Duration(milliseconds:driveTimes[index].duration! );
                            //      return Text("${duration.toHuman}",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),);

                            //         }),
                            //     )

                            //   //   Column(

                            //   //     children: [

                            //   //   Text("9h 32m",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                            //   //   SizedBox(height: 8,),
                            //   //  Text("6h 24",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                            //   //    SizedBox(height: 8,),
                            //   //   Text("8h 8m",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                            //   //     ],
                            //   //   ),

                            // )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 36),
                      child: Text(
                        "Your performance",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ),
                    SizedBox(
                      height: 13,
                    ),
                    itemWidget(Image.asset("assets/images/image7.png"),
                        "You complete over 76% tiles you create. Good job! Keep it up."),
                    SizedBox(
                      height: 34,
                    ),
                    itemWidget(Image.asset("assets/images/image8.png"),
                        "Your average sleep time last week is 6h 12m. That’s a bit too low!"),
                  ],
                ),
        ),
      ),
    );
  }

  Widget itemWidget(Widget item, String title) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      width: MediaQuery.of(context).size.width,
      height: 80,
      child: Row(
        children: [
          SizedBox(
            width: 12,
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xffFAFAFA),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: item,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text(
              title,
              maxLines: 2,
              style: TextStyle(
                  color: Color(0xff1F1F1F),
                  fontSize: 15,
                  fontWeight: FontWeight.w400),
            ),
          )
        ],
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
