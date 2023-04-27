import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  });
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
    List<Widget> childWidgets = [
      Text(this.dateTime.day.toString()),
      Text(DateFormat(DateFormat.ABBR_WEEKDAY).format(this.dateTime))
    ];
    if (this.widget.showMonth) {
      childWidgets
          .add(Text(DateFormat(DateFormat.ABBR_MONTH).format(this.dateTime)));
    }
    return GestureDetector(
      onTap: () {
        if (this.widget.onTapped != null) {
          this.widget.onTapped!(this.dateTime);
        }
      },
      child: Container(
        color: this.widget.isSelected ? Colors.amber : null,
        child: Column(
          children: childWidgets,
        ),
      ),
    );
  }
}
