import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatch.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart' as TilerTimeline;
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:timelines_plus/timelines_plus.dart';

class WithinNowBatch extends TileBatch {
  TimelineSummary? dayData;

  WithinNowBatch({List<TilerEvent>? tiles, TimelineSummary? dayData, Key? key})
      : super(
            key: key,
            tiles: tiles,
            dayData: dayData,
            dayIndex: Utility.currentTime().universalDayIndex);

  @override
  WithinNowBatchState createState() => WithinNowBatchState();
}

class WithinNowBatchState extends TileBatchState {
  double heightMargin = 262;
  double heightOfTimeBanner = 245;

  @override
  Widget build(BuildContext context) {
    List<TilerEvent> tiles = (widget.tiles ?? [])
        .where((tile) =>
            tile is SubCalendarEvent &&
            tile.start != null &&
            tile.end != null &&
            (tile).isViable != false)
        .toList();
    tiles.sort((a, b) => a.start!.compareTo(b.start!));

    if (tiles.isEmpty) {
      return _buildEmptyDayTile(context);
    }

    List<Widget> children = [];
    if (widget.dayData != null) {
      children.add(Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
          child: DaySummary(dayTimelineSummary: widget.dayData!)));
    }

    if (widget.sleepTimeline != null) {
      TilerTimeline.Timeline sleepTimeline = widget.sleepTimeline!;
      Widget sleepWidget = SleepTileWidget(sleepTimeline);
      children.add(sleepWidget);
    }

    children.add(
      Container(
        margin: EdgeInsets.fromLTRB(0, 125, 0, 0),
        height: MediaQuery.of(context).size.height - heightOfTimeBanner,
        width: MediaQuery.of(context).size.width,
        child: Timeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0,
            color: Colors.blue,
            indicatorTheme: IndicatorThemeData(
              position: 0,
              size: 20.0,
            ),
            connectorTheme: ConnectorThemeData(
              thickness: 2.0,
            ),
          ),
          builder: TimelineTileBuilder.connected(
            itemCount: tiles.length,
            contentsBuilder: (context, index) {
              final tile = tiles[index];
              String timeString = MaterialLocalizations.of(context)
                  .formatTimeOfDay(TimeOfDay.fromDateTime(tile.startTime),
                      alwaysUse24HourFormat: false);

              // Widget indicator;
              // if (tile.start! <= now) {
              //   indicator = DotIndicator(color: Colors.red);
              // } else {
              //   indicator = OutlinedDotIndicator();
              // }

              // Widget timeInfo = Row(
              //   mainAxisSize: MainAxisSize.min,
              //   children: [
              //     indicator,
              //     SizedBox(width: 8),
              //     Text(
              //       timeString,
              //       style: TextStyle(fontSize: 12, color: Colors.black54),
              //     ),
              //   ],
              // );

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // indicator,
                        // SizedBox(width: 8),
                        Text(
                          timeString,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    TileWidget(tile),
                  ],
                ),
              );
            },
            indicatorBuilder: (context, index) {
              Widget indicator;
              final tile = tiles[index];
              final now = Utility.msCurrentTime;
              if (tile.isCurrentTimeWithin) {
                indicator = DotIndicator(color: TileStyles.greenCheck);
              } else if (tile.start! <= now) {
                indicator =
                    DotIndicator(color: TileStyles.disabledBackgroundColor);
              } else {
                indicator = OutlinedDotIndicator();
              }
              return indicator;
            },
            connectorBuilder: (context, index, type) {
              return SolidLineConnector(
                thickness: 5,
              );
            },
          ),
        ),
      ),
    );

    return Column(
      children: children,
    );
  }

  Widget _buildEmptyDayTile(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      children: [
        AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 500),
          child: Container(
            height: MediaQuery.of(context).size.height - heightMargin,
            child: EmptyDayTile(
              deadline: Utility.getTimeFromIndex(widget.dayIndex!).endOfDay,
              dayIndex: widget.dayIndex!,
            ),
          ),
        )
      ],
    );
  }
}
