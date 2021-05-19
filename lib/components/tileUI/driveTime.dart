import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/tileUI/StartToEnd.dart';

class DriveTimeWidget extends StatelessWidget {
  late DateTime Start;
  late DateTime End;
  DriveTimeWidget({required this.Start, required this.End});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    Widget travelLineTop = Container(height: 20, width: 2, color: Colors.black);
    children.add(travelLineTop);

    if (this.Start.millisecondsSinceEpoch < this.End.millisecondsSinceEpoch) {
      List<Widget> timeLineInfoChildren = [];

      Icon carImage = Icon(
        Icons.directions_car_filled,
        color: Color.fromRGBO(217, 60, 220, 0),
      );

      Widget carIconContainer = Container(
        child: carImage,
      );
      timeLineInfoChildren.add(carIconContainer);

      String startString = DateFormat('h:mm a').format(this.Start);
      String endString = DateFormat('h:mm a').format(this.End);
      Widget startAndEndWidget = Container(
        child: Row(
          children: [Text(startString), carIconContainer, Text(endString)],
        ),
      );
      timeLineInfoChildren.add(startAndEndWidget);

      Widget timeInfoContainerWrapper = Container(
        child: Stack(
          children: timeLineInfoChildren,
        ),
      );

      children.add(timeInfoContainerWrapper);
    }

    Widget travelLineBottom =
        Container(height: 20, width: 2, color: Colors.black);
    children.add(travelLineBottom);

    return Container(
      child: Container(
        child: Stack(
          children: children,
        ),
      ),
    );
  }
}
