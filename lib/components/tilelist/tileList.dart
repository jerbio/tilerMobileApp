import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';

/**
 * This renders the list of tiles on a given day
 */

class TileList extends StatefulWidget {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  TileList({Key? key}) : super(key: key) {}

  @override
  _TileListState createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: this.widget.subCalendarEventApi.getSubEvent(Utility.getUuid),
        builder: (context, AsyncSnapshot<SubCalendarEvent> snapshot) {
          Widget retValue;
          if (snapshot.hasData) {
            SubCalendarEvent? tileData = snapshot.data;
            if (tileData != null) {
              retValue = ListView(
                children: [
                  Tile(tileData),
                  Tile(tileData),
                  Tile(tileData),
                  Tile(tileData)
                ],
              );
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
