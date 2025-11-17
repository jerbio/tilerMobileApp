import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

class PreviewDetailsTileWidget extends StatefulWidget {
  late SubCalendarEvent subEvent;
  PreviewDetailsTileWidgetState? _state;

  PreviewDetailsTileWidget(subEvent) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }

  @override
  PreviewDetailsTileWidgetState createState() {
    _state = PreviewDetailsTileWidgetState();
    return _state!;
  }
}

class PreviewDetailsTileWidgetState extends State<PreviewDetailsTileWidget> {
  late ThemeData theme;
  late ColorScheme colorScheme;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }
  @override
  Widget build(BuildContext context) {
    return renderTileElement();
  }

  Widget renderTileElement() {
    var subEvent = widget.subEvent;
    bool isEditable = (!(this.widget.subEvent.isReadOnly ?? true));
    int redColor = subEvent.colorRed ?? 127;
    int blueColor = subEvent.colorBlue ?? 127;
    int greenColor = subEvent.colorGreen ?? 127;
    var tileBackGroundColor =
        Color.fromRGBO(redColor, greenColor, blueColor, 0.2);
    List<Widget> allElements = [
      Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: TileName(widget.subEvent),
            ),
          ],
        ),
      )
    ];

    if (widget.subEvent.address != null &&
        widget.subEvent.address!.isNotEmpty) {
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
            decoration: TileDecorations.tileIconContainerBoxDecoration(colorScheme.onSurface),
            child: Icon(
              (widget.subEvent.isRigid ?? false)
                  ? Icons.lock_outline
                  : Icons.access_time_sharp,
              color: (widget.subEvent.isTardy ?? false)
                  ? TileColors.late
                  : colorScheme.onSurface,
              size: TileDimensions.tileIconSize,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: TimeFrameWidget(
              timeRange: widget.subEvent,
              textColor: (widget.subEvent.isTardy ?? false)
                  ? TileColors.late
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
    allElements.add(tileTimeFrame);

    allElements.add(FractionallySizedBox(
        widthFactor: TileDimensions.tileWidthRatio,
        child: Container(
            margin: const EdgeInsets.fromLTRB(0, 15, 0, 10),
            child: TimeScrubWidget(
              timeline: widget.subEvent,
              isTardy: widget.subEvent.isTardy ?? false,
            ))));

    // allElements.add(Container(
    //     margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
    //     child: PlayBack(
    //       widget.subEvent,
    //       isWeeklyView: true,
    //       forcedOption: (widget.subEvent.isRigid == true
    //           ? [PlaybackOptions.Delete]
    //           : null),
    //     )));

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
        decoration: BoxDecoration(
          color: tileBackGroundColor,
          borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: allElements,
        ),
      ),
    );
  }
}
