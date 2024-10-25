import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class WeekDayButton extends StatefulWidget {
  bool showMonth = false;
  DateTime dateTime;
  WeekDayButton({
    required this.dateTime,
    this.showMonth = false,
  }) : super(
      key: ValueKey(
          dateTime.toString() + Utility.currentTime().day.toString()));
  @override
  State<StatefulWidget> createState() => _WeekDayButtonState();
}

class _WeekDayButtonState extends State<WeekDayButton> {
  late DateTime dateTime;
  @override
  void initState() {
    super.initState();
    this.dateTime = this.widget.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childWidgets = [
      Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        decoration: TileStyles.ribbonsButtonDefaultDecoration,
        alignment: Alignment.center,
        height: 40,
        width: 40,
        child: Text(
          DateFormat(DateFormat.DAY).format(this.dateTime),
          style:TextStyle(
              fontSize: 20,
              fontFamily: TileStyles.rubikFontName,
              color: Colors.black
          ),
        ),
      ),
      Container(
          padding: EdgeInsets.all(17),
          child: Text(
                DateFormat(DateFormat.ABBR_WEEKDAY).format(this.dateTime),
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: TileStyles.rubikFontName,
                    color: Colors.grey)
              ),
      )
    ];
    if (this.widget.showMonth) {
      childWidgets.add(Container(
        child: Text(
          DateFormat(DateFormat.ABBR_MONTH).format(this.dateTime),
          style:  TextStyle(
              color: Colors.grey
          ),
        ),
      ));
    }

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: childWidgets,
      ),
    );
  }
}
