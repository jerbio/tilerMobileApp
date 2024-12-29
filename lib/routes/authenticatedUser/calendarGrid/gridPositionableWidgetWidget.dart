import 'package:flutter/material.dart';

abstract class GridPositionableWidget extends StatefulWidget {
  static const double defaultHeigtPerDuration = 80;
  static const Duration durationPerHeight = Duration(hours: 1);
  final TimeOfDay? start;
  final Duration durationPerCell;
  final double height;
  final double? top;
  final double? left;
  final Widget? child;
  GridPositionableWidget(
      {this.start,
      this.child,
      this.height = defaultHeigtPerDuration,
      this.top,
      this.left,
      this.durationPerCell = durationPerHeight});
}

abstract class GridPositionableState extends State<GridPositionableWidget> {
  double widgetHeight = GridPositionableWidget.defaultHeigtPerDuration;
  double widgetWidth = 70;
  late final double twentyFourFullHeight;
  double topPosition = 0;
  double? leftPosition = 0;

  @override
  void initState() {
    super.initState();
    this.widgetHeight = this.widget.height;
    twentyFourFullHeight = (Duration.millisecondsPerDay /
            this.widget.durationPerCell.inMilliseconds) *
        this.widgetHeight;

    if (this.widget.start != null) {
      this.topPosition = this.evalTopPosition(this.widget.start!);
    }
    if (this.widget.top != null) {
      this.topPosition = this.widget.top!;
    }
    if (this.widget.left != null) {
      this.leftPosition = this.widget.left!;
    }
  }

  double evalTopPosition(TimeOfDay start) {
    return this.twentyFourFullHeight *
        (start.hour * Duration.millisecondsPerHour +
            start.minute.toDouble() * Duration.millisecondsPerMinute) /
        Duration.millisecondsPerDay;
  }
}
