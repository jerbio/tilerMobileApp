import 'package:flutter/material.dart';
import 'package:tiler_app/data/dayData.dart';
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
        fontSize: 25, color: const Color.fromRGBO(153, 153, 153, 1));
    Widget completeWidget = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
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
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
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
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
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

    rowSymbolElements.add(completeWidget);
    rowSymbolElements.add(warnWidget);
    rowSymbolElements.add(sleepWidget);
    Widget retValue = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: rowSymbolElements,
    );
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childElements = [renderDayMetricInfo()];

    if (this.widget.dayData.dayIndex != null) {
      Widget dayDateText = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 20, 40),
        alignment: Alignment.topRight,
        child: Text(
            Utility.getTimeFromIndex(this.widget.dayData.dayIndex!).humanDate,
            style: TextStyle(
                fontSize: 40,
                fontFamily: TileStyles.rubikFontName,
                color: TileStyles.primaryColorDarkHSL.toColor(),
                fontWeight: FontWeight.w700)),
      );
      childElements.insert(0, dayDateText);
    }

    Container retValue = Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: childElements,
      ),
    );
    return retValue;
  }
}
