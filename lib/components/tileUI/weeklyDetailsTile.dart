import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';

enum TileSource { tiler, google, outlook }

class WeeklyDetailsTile extends StatefulWidget {
  late SubCalendarEvent subEvent;
  WeeklyDetailsTileState? _state;

  WeeklyDetailsTile(subEvent) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }

  @override
  WeeklyDetailsTileState createState() {
    _state = WeeklyDetailsTileState();
    return _state!;
  }
}

class WeeklyDetailsTileState extends State<WeeklyDetailsTile> {
  @override
  Widget build(BuildContext context) {
    return renderTileElement();
  }

  Widget renderTileElement() {
    var subEvent = widget.subEvent;
    int redColor = subEvent.colorRed ?? 127;
    int blueColor = subEvent.colorBlue ?? 127;
    int greenColor = subEvent.colorGreen ?? 127;
    var tileBackGroundColor = Color.fromRGBO(redColor, greenColor, blueColor, 0.2);

    List<Widget> allElements = [
      Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
        child: Stack(
          children: [
            TileName(widget.subEvent),
            Positioned(
              top: 0,
              right: 0,
              child: _buildSourceIndicator(),
            )
          ],
        ),
      )
    ];

    if (widget.subEvent.address != null && widget.subEvent.address!.isNotEmpty) {
      var addressWidget = Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: TileAddress(widget.subEvent));
      allElements.insert(1, addressWidget);
    }

    Widget tileTimeFrame = Container(

      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
            width: 25,
            height: 25,
            decoration: TileStyles.tileIconContainerBoxDecoration,
            child: Icon(
              (widget.subEvent.isRigid ?? false) ? Icons.lock_outline : Icons.access_time_sharp,
              color: (widget.subEvent.isTardy ?? false) ? TileStyles.lateTextColor : TileStyles.defaultTextColor,
              size: TileStyles.tileIconSize,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: TimeFrameWidget(
              timeRange: widget.subEvent,
              textColor: (widget.subEvent.isTardy ?? false) ? TileStyles.lateTextColor : TileStyles.defaultTextColor,
            ),
          ),
        ],
      ),
    );
    allElements.add(tileTimeFrame);

    allElements.add(FractionallySizedBox(
        widthFactor: TileStyles.tileWidthRatio,
        child: Container(
            margin: const EdgeInsets.fromLTRB(0, 15, 0, 10),
            child: TimeScrubWidget(
              timeline: widget.subEvent,
              isTardy: widget.subEvent.isTardy ?? false,
            )
        )
    ));

    allElements.add(Container(
        margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
        child: PlayBack(
          widget.subEvent,
          isWeeklyView: true,
          forcedOption: (widget.subEvent.isRigid == true
              ? [PlaybackOptions.Delete]
              : null),
        )
    ));

    return Container(
      margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: widget.subEvent.isViable! ? Colors.white : Colors.black,
              width: widget.subEvent.isViable! ? 0 : 5,
            ),
            borderRadius: BorderRadius.circular(TileStyles.borderRadius),
            boxShadow: [
              BoxShadow(
                color: tileBackGroundColor.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
            decoration: BoxDecoration(
              color: tileBackGroundColor,
              border: Border.all(color: Colors.white, width: 0.5),
              borderRadius: BorderRadius.circular(TileStyles.borderRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: allElements,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceIndicator() {
    IconData icon;
    String text;

    switch (widget.subEvent.thirdpartyType) {
      case TileSource.google:
        icon =  FontAwesomeIcons.google;;
        text = 'Google';
        break;
      case TileSource.outlook:
        icon = FontAwesomeIcons.microsoft;
        text = 'Outlook';
        break;
      case TileSource.tiler:
      default:
        icon = Icons.calendar_today;
        text = 'Event';
    }

    return GestureDetector(
        onTap: (){
          Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => EditTile(
                tileId: (widget.subEvent.isFromTiler
                    ? widget.subEvent.id
                    : widget.subEvent.thirdpartyId) ??
                    "",
                tileSource: widget.subEvent.thirdpartyType,
                thirdPartyUserId: widget.subEvent.thirdPartyUserId,
              )));
        },
        child:Container(
          width: 68,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              SizedBox(width: 4),
              Text(
                  text,
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: TileStyles.rubikFontName,
                  ),
              ),
            ],
          ),
        )
    );
  }
}
