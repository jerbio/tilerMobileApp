import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/util.dart';

abstract class TimeCellWidget extends GridPositionableWidget {
  final TimeOfDay? start;
  final Duration durationPerCell;
  final double? timeCellHeight;
  final double? top;
  final double? left;
  final BoxDecoration? decoration;
  final Widget? child;
  TimeCellWidget(
      {this.start,
      this.child,
      this.timeCellHeight = GridPositionableWidget.defaultHeigtPerDuration,
      this.top,
      this.left,
      this.decoration,
      this.durationPerCell = const Duration(hours: 1)})
      : super(
          left: left,
           height: timeCellHeight ??
          GridPositionableWidget.defaultHeigtPerDuration,
          top: top
      );
}

abstract class TimeCellWidgetState extends GridPositionableState {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return renderCell();
  }

  Widget renderInnerCell() {
    return SizedBox.shrink();
  }

  Widget renderCell() {
    return Positioned(
      top: topPosition,
      left: this.leftPosition,
      child: Container(
        height: widgetHeight,
        decoration: (this.widget as TimeCellWidget).decoration ??
            BoxDecoration(
              color: Utility.randomColor,
            ),
        width: widgetWidth,
        child: this.widget.child,
      ),
    );
  }
}
