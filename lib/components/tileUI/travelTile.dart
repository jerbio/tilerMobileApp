import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

class TravelTimeWidget extends StatefulWidget {
  late Timeline timeline;

  @override
  TravelTimeWidgetState createState() {
    return new TravelTimeWidgetState();
  }
}

class TravelTimeWidgetState extends State<TravelTimeWidget> {
  final DateFormat formatter = DateFormat.jm();
  @override
  Widget build(BuildContext context) {
    String startString = formatter.format(DateTime.fromMillisecondsSinceEpoch(
        widget.timeline.startInMs!.toInt()));
    String endString = formatter.format(
        DateTime.fromMillisecondsSinceEpoch(widget.timeline.endInMs!.toInt()));

    return Column(
      children: [
        Container(),
        Row(
          children: [
            Text(startString),
            Container(
                child: Icon(
              Icons.directions_car,
              color: Colors.purple,
            )),
            Text(endString)
          ],
        ),
        Container(),
      ],
    );
  }
}
