import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DayButton extends StatefulWidget {
  bool showMonth = false;
  bool isSelected;
  DateTime dateTime;
  Function? onTapped;
  DayButton({
    required this.dateTime,
    this.onTapped,
    this.showMonth = false,
    this.isSelected = false,
  }) : super(
            key: ValueKey(
                dateTime.toString() + Utility.currentTime().day.toString()));
  @override
  State<StatefulWidget> createState() => _DayButtonState();
}

class _DayButtonState extends State<DayButton> {
  late DateTime dateTime;
  @override
  void initState() {
    super.initState();
    this.dateTime = this.widget.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    var decoration =
        this.widget.isSelected ? TileStyles.ribbonsButtonSelectedDecoration : TileStyles.ribbonsButtonDefaultDecoration;
    double buttonHeight = 40 * (this.widget.isSelected ? 1.3 : 1);
    double buttonWidth = 40 * (this.widget.isSelected ? 1.3 : 1);

    List<Widget> childWidgets = [
      Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        alignment: Alignment.center,
        height: buttonHeight,
        width: buttonWidth,
        decoration: decoration,
        child: Text(
          DateFormat(DateFormat.DAY).format(this.dateTime),
          style: TextStyle(
              fontSize: 20,
              fontFamily: TileStyles.rubikFontName,
              fontWeight: this.widget.isSelected ? FontWeight.w500 : null,
              color: this.widget.isSelected ? Colors.white : Colors.grey),
        ),
      ),
      Container(
          padding:
              this.widget.isSelected ? EdgeInsets.all(11) : EdgeInsets.all(17),
          child: Text(DateFormat(DateFormat.ABBR_WEEKDAY).format(this.dateTime),
              style: TextStyle(
                  fontFamily: TileStyles.rubikFontName,
                  color: this.widget.isSelected ? Colors.black : Colors.grey)))
    ];
    if (this.widget.showMonth) {
      childWidgets.add(Container(
        child: Text(
          DateFormat(DateFormat.ABBR_MONTH).format(this.dateTime),
          style: TextStyle(
              color: this.widget.isSelected ? Colors.black : Colors.grey),
        ),
      ));
    }

    return GestureDetector(
      onTap: () {
        if (this.widget.onTapped != null) {
          this.widget.onTapped!(this.dateTime);
        }
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: childWidgets,
        ),
      ),
    );
  }
}
