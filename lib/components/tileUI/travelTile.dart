import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/timeline.dart';

//ey: not used
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
    String startString = formatter.format(
        DateTime.fromMillisecondsSinceEpoch(widget.timeline.start!.toInt()));
    String endString = formatter.format(
        DateTime.fromMillisecondsSinceEpoch(widget.timeline.end!.toInt()));

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
