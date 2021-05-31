import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

/**
 * This renders the list of tiles on a given day
 */

class TileList extends StatefulWidget {
  final ScheduleApi scheduleApi = new ScheduleApi();
  TileList({Key? key}) : super(key: key) {}

  @override
  _TileListState createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: this.widget.scheduleApi.getSubEvents(Utility.todayTimeline()),
        builder: (context, AsyncSnapshot<List<SubCalendarEvent>> snapshot) {
          Widget retValue;
          if (snapshot.hasData) {
            List<SubCalendarEvent>? tileData = snapshot.data;
            if (tileData != null) {
              tileData.sort((eachSubEventA, eachSubEventB) => eachSubEventA.start!.compareTo(eachSubEventB.start!));
              TileBatch tileBatch = new TileBatch();
              retValue = tileBatch;
            } else {
              retValue = ListView(children: []);
            }
          } else {
            retValue = CircularProgressIndicator();
          }
          return retValue;
        });
  }
}
