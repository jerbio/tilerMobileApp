import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//ey: not used
class StartToEndWidget extends StatelessWidget {
  late DateTime Start;
  late DateTime End;
  String? label;
  StartToEndWidget({required this.Start, required this.End, this.label});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (label != null) {
      String labelString = this.label!;
      Text labelStringText = Text(labelString);
      children.add(labelStringText);
    }

    if (this.Start.millisecondsSinceEpoch < this.End.millisecondsSinceEpoch) {
      List<Widget> timeLineInfoChildren = [];

      Icon timeImage = Icon(
        Icons.access_time_filled,
        color: Color.fromRGBO(149, 151, 152, 0),
      );
      Widget iconContainer = Container(
        child: timeImage,
      );
      timeLineInfoChildren.add(iconContainer);

      String startString = DateFormat('h:mm a').format(this.Start);
      String endString = DateFormat('h:mm a').format(this.End);
      String fullString = startString + '-' + endString;
      Widget startAndEndWidget = Container(
        child: Text(fullString),
      );
      timeLineInfoChildren.add(startAndEndWidget);

      Widget timeInfoContainerWrapper = Container(
        child: Stack(
          children: timeLineInfoChildren,
        ),
      );

      children.add(timeInfoContainerWrapper);
    }

    return Container(
      child: Container(
        child: Stack(
          children: children,
        ),
      ),
    );
  }
}
