// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/tileUI/previewDetailsTileWidget.dart';
import 'package:tiler_app/components/tileUI/weeklyDetailsTile.dart';

import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/constants.dart' as constant;
import 'package:tiler_app/styles.dart';

class TileGridWidget extends GridPositionableWidget {
  final TilerEvent tilerEvent;
  final double? tileGridHeight;
  TileGridWidget(
      {required this.tilerEvent,
      double? left,
      this.tileGridHeight,
      Duration durationPerUnitTime = GridPositionableWidget.durationPerHeight})
      : super(
            left: left,
            height: tileGridHeight ??
                GridPositionableWidget.defaultHeigtPerDuration,
            durationPerCell: durationPerUnitTime);

  @override
  TileGridWidgetState createState() => TileGridWidgetState();
}

class TileGridWidgetState extends GridPositionableState {
  late TilerEvent? tilerEvent;
  static final Duration minDuration = Duration(minutes: 15);
  @override
  void initState() {
    super.initState();
    if (this.widget is TileGridWidget) {
      tilerEvent = (this.widget as TileGridWidget).tilerEvent;
    }
    if (this.tilerEvent != null) {
      this.topPosition = this
          .evalTopPosition(TimeOfDay.fromDateTime(this.tilerEvent!.startTime));
    }
    this.widgetHeight = durationToHeight();
    if (this.widget is TileGridWidget) {
      this.widgetHeight =
          (this.widget as TileGridWidget).tileGridHeight ?? this.widgetHeight;
    }

    this.leftPosition = 80.0;
    this.widgetWidth = 270;
  }

  double durationToHeight() {
    Duration duration = minDuration;
    if (this.tilerEvent?.duration != null &&
        this.tilerEvent!.duration.inMilliseconds > duration.inMilliseconds) {
      duration = this.tilerEvent!.duration;
    }

    return (duration.inMilliseconds /
            this.widget.durationPerCell.inMilliseconds) *
        this.widget.height;
  }

  void onTapPreviewTile(TilerEvent tile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TileStyles.borderRadius)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: PreviewDetailsTileWidget(tile),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (this.tilerEvent != null) {
      return Positioned(
        top: topPosition,
        left: leftPosition,
        child: Container(
          height: this.widgetHeight,
          width: widgetWidth,
          child: InkWell(
              onTap: () {
                onTapPreviewTile(tilerEvent!);
              },
              child: _TilerEventInnerGridWidget(tilerEvent: tilerEvent!)),
        ),
      );
    }
    if (constant.isDebug) {
      return Container(
        color: Colors.red,
        child: Text("failed to render tiler grid widget"),
      );
    }
    return SizedBox.shrink();
  }
}

class _TilerEventInnerGridWidget extends StatelessWidget {
  final TilerEvent tilerEvent;
  _TilerEventInnerGridWidget({required this.tilerEvent});

  @override
  Widget build(BuildContext context) {
    EdgeInsets gridPadding = EdgeInsets.all(10);
    if (this.tilerEvent.duration.inMilliseconds <=
        TileGridWidgetState.minDuration.inMilliseconds) {
      gridPadding = EdgeInsets.fromLTRB(10, 0.5, 0, 0);
    }
    return Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(tilerEvent.colorRed ?? 255,
              tilerEvent.colorGreen ?? 255, tilerEvent.colorGreen ?? 255, 1),
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: gridPadding,
        child: Text(
          (this.tilerEvent.name ?? "--no--name"),
          overflow: TextOverflow.ellipsis,
          style: new TextStyle(
            fontSize: 13.0,
            fontFamily: TileStyles.rubikFontName,
            color: new Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ));
  }
}
