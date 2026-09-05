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
      {Key? key,
      this.start,
      this.child,
      this.height = defaultHeigtPerDuration,
      this.top,
      this.left,
      this.durationPerCell = durationPerHeight})
      : super(key: key);
}

abstract class GridPositionableState extends State<GridPositionableWidget> {
  double widgetHeight = GridPositionableWidget.defaultHeigtPerDuration;
  double widgetWidth = 70;
  late double twentyFourFullHeight;
  double topPosition = 0;
  double? leftPosition = 0;

  @override
  void initState() {
    super.initState();
    this.widgetHeight = this.widget.height;
    this.twentyFourFullHeight = (Duration.millisecondsPerDay /
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

  /// Positions derive from [GridPositionableWidget.height]
  /// (px per cell). Re-sync when the parent re-sources them (zoom change)
  /// instead of keeping the stale `initState` values.
  @override
  void didUpdateWidget(covariant GridPositionableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height == widget.height &&
        oldWidget.durationPerCell == widget.durationPerCell &&
        oldWidget.start == widget.start &&
        oldWidget.top == widget.top &&
        oldWidget.left == widget.left) {
      return;
    }
    this.widgetHeight = this.widget.height;
    this.twentyFourFullHeight = (Duration.millisecondsPerDay /
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
