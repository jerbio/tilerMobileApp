import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/summaryPage.dart';
import 'package:tiler_app/data/dayData.dart';
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
            (this.widget.dayData.completeTiles?.length ?? 0).toString(),
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
            (this.widget.dayData.nonViableTiles?.length ?? 0).toString(),
            style: textStyle,
          )
        ],
      ),
    );
    Widget sleepWidget = Container(
      child: Row(
        children: [
          Icon(
            Icons.king_bed,
            size: 30.0,
          ),
          Text(
            (this.widget.dayData.sleepDuration?.inHours ?? 0).toString(),
            style: textStyle,
          )
        ],
      ),
    );

    rowSymbolElements.add(warnWidget);
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
    List<Widget> childElements = [renderDayMetricInfo()];

    if (this.widget.dayData.dayIndex != null) {
      Widget dayDateText = GestureDetector(
        onTap: () {
          DateTime start =
              Utility.getTimeFromIndex(this.widget.dayData.dayIndex!);
          DateTime end =
              Utility.getTimeFromIndex(this.widget.dayData.dayIndex!).endOfDay;
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
              Utility.getTimeFromIndex(this.widget.dayData.dayIndex!).humanDate,
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
  }
}
