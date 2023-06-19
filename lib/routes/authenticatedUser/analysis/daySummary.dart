import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/timeLineSummary/time_line_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/summaryPage.dart';
import 'package:tiler_app/data/dayData.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DaySummary extends StatefulWidget {
  DayData dayData;
  DaySummary({required this.dayData});
  @override
  State createState() => _DaySummaryState();
}

class _DaySummaryState extends State<DaySummary> {
  late DayData dayData;
  @override
  void initState() {
    super.initState();
    dayData = this.widget.dayData;
  }

  Widget renderDayMetricInfo() {
    List<Widget> rowSymbolElements = <Widget>[];
    const textStyle = const TextStyle(
        fontSize: 30, color: const Color.fromRGBO(153, 153, 153, 1));
    Widget completeWidget = Container(
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: TileStyles.greenCheck,
            size: 30.0,
          ),
          Text(
            (this.dayData.completeTiles?.length ?? 0).toString(),
            style: textStyle,
          )
        ],
      ),
    );
    Widget warnWidget = Container(
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: TileStyles.warningAmber,
            size: 30.0,
          ),
          Text(
            (this.dayData.nonViableTiles?.length ?? 0).toString(),
            style: textStyle,
          )
        ],
      ),
    );
    Widget lateWidget = Container(
      child: Row(
        children: [
          Icon(
            Icons.car_crash_sharp,
            size: 30.0,
          ),
          Text(
            (this.dayData.tardyTiles?.length ?? 0).toString(),
            style: textStyle,
          )
        ],
      ),
    );

    if (this.dayData.completeTiles != null &&
        this.dayData.completeTiles!.length > 0) {
      rowSymbolElements.add(completeWidget);
    }

    if (this.dayData.tardyTiles != null &&
        this.dayData.tardyTiles!.length > 0) {
      rowSymbolElements.add(lateWidget);
    }

    if (this.dayData.nonViableTiles != null &&
        this.dayData.nonViableTiles!.length > 0) {
      rowSymbolElements.add(warnWidget);
    }

    Widget retValue = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: rowSymbolElements,
      ),
    );
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<TimeLineSummaryBloc, TimeLineSummaryState>(
              listener: (context, state) {
            if (state is TimeLineSummaryLoaded) {
              DayData updatedDayData = DayData();
              updatedDayData.completeTiles = state.timelineSummary?.complete
                  ?.map<TilerEvent>((e) => e)
                  .toList();
              updatedDayData.deletedTiles = state.timelineSummary?.deleted
                  ?.map<TilerEvent>((e) => e)
                  .toList();
              updatedDayData.nonViableTiles = state.timelineSummary?.nonViable
                  ?.map<TilerEvent>((e) => e)
                  .toList();
              updatedDayData.tardyTiles = state.timelineSummary?.tardy
                  ?.map<TilerEvent>((e) => e)
                  .toList();
              setState(() {
                dayData = updatedDayData;
              });
            }
          })
        ],
        child: BlocBuilder<TimeLineSummaryBloc, TimeLineSummaryState>(
          builder: (context, state) {
            List<Widget> childElements = [renderDayMetricInfo()];

            if (this.dayData.dayIndex != null) {
              Widget dayDateText = GestureDetector(
                onTap: () {
                  DateTime start =
                      Utility.getTimeFromIndex(this.dayData.dayIndex!);
                  DateTime end =
                      Utility.getTimeFromIndex(this.dayData.dayIndex!).endOfDay;
                  Timeline timeline = Timeline(
                      start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SummaryPage(
                                timeline: timeline,
                              )));
                },
                child: Container(
                  child: Text(
                      Utility.getTimeFromIndex(this.dayData.dayIndex!)
                          .humanDate,
                      style: TextStyle(
                          fontSize: 30,
                          fontFamily: TileStyles.rubikFontName,
                          color: TileStyles.primaryColorDarkHSL.toColor(),
                          fontWeight: FontWeight.w700)),
                ),
              );
              childElements.add(dayDateText);
            }

            Container retValue = Container(
              padding: EdgeInsets.fromLTRB(10, 10, 20, 0),
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: childElements,
              ),
            );
            return retValue;
          },
        ));
  }
}
