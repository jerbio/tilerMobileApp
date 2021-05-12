import 'package:flutter/material.dart';
import 'package:tiler_app/data/dayStatus.dart';
import 'package:tiler_app/services/api/DayStatusApi.dart';
import 'package:tiler_app/util.dart';

class DayStatusWidget extends StatefulWidget {
  DayStatusWidgetState? _state;
  DateTime? date;
  @override
  DayStatusWidgetState createState() {
    this._state = DayStatusWidgetState();
    return this._state!;
  }

  void onDayStatusChange(DateTime date) {
    if (this._state != null) {
      this._state!.onStatusUpdate(date);
    } else {
      this.date = date;
    }
  }
}

class DayStatusWidgetState extends State<DayStatusWidget> {
  final DayStatusApi dayStatusApi = new DayStatusApi();
  DayStatus? dayStatus;

  void onStatusUpdate(DateTime date) async {
    DayStatus? retValue =
        await this.dayStatusApi.getDayStatus(date.millisecondsSinceEpoch);
    if (retValue != null) {
      setState(() {
        dayStatus = retValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (this.dayStatus == null && this.widget.date != null) {
      this.onStatusUpdate(this.widget.date!);
    }
    if (this.dayStatus != null) {
      String dayString = this.dayStatus!.dayDate!.humanDate;
      Widget dayStringWidget = Container(
        alignment: Alignment.topRight,
        margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
        child: Text(dayString,
            style: TextStyle(
                fontSize: 30,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(31, 31, 31, 1))),
      );
      List<Widget> iconTrayWidgets = [];
      if (this.dayStatus?.completedSubEvents?.length != null) {
        if (this.dayStatus!.completedSubEvents!.length > 0) {
          int completedCount = this.dayStatus!.completedSubEvents!.length;
          Widget completedCountWidget = Container(
              width: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                  Text(completedCount.toString(),
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey))
                ],
              ));
          iconTrayWidgets.add(completedCountWidget);
        }
      }

      if (this.dayStatus?.warningSubEvents?.length != null) {
        if (this.dayStatus!.warningSubEvents!.length > 0) {
          int warningCount = this.dayStatus!.warningSubEvents!.length;
          Widget warningCountWidget = Container(
              width: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 30),
                  Text(warningCount.toString(),
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey))
                ],
              ));
          iconTrayWidgets.add(warningCountWidget);
        }
      }

      if (this.dayStatus?.sleepHours != null) {
        if (this.dayStatus!.sleepHours! > 0) {
          int totalMinutes = ((this.dayStatus!.sleepHours!) * 60).toInt();
          Duration sleepDuration = Duration(minutes: totalMinutes);
          Widget sleepIconWidget = Container(
              width: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.single_bed_rounded, color: Colors.black, size: 30),
                  Text(Utility.toHuman(sleepDuration, abbreviations: true),
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey))
                ],
              ));
          iconTrayWidgets.add(sleepIconWidget);
        }
      }
      Widget iconTrayWidget = Align(
        alignment: Alignment.bottomRight,
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 5),
          width: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: iconTrayWidgets,
          ),
        ),
      );

      return Container(
        padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
        height: 105,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [dayStringWidget, iconTrayWidget],
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }
}
