import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeCellWidget.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

class TileTimeCellWidget extends TimeCellWidget {
  TileTimeCellWidget(
      {TimeOfDay? start,
      double? height,
      double? top,
      double? left,
      BoxDecoration? decoration,
      Duration durationPerCell = const Duration(hours: 1)})
      : super(
            start: start,
            left: left,
            top: top,
            durationPerCell: durationPerCell,
            decoration: decoration,
            timeCellHeight: height);
  @override
  _TileTimeCellState createState() => _TileTimeCellState();
}

class _TileTimeCellState extends TimeCellWidgetState {
  @override
  void initState() {
    super.initState();
    this.widgetWidth = 280;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Positioned(
      top: topPosition,
      left: this.leftPosition,
      // P1 (step 1.4): width comes from the available constraints instead
      // of MediaQuery, so the line tracks the grid's real viewport width.
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = MediaQuery.sizeOf(context).width -
              TileDimensions.timeOfDayCellWidth;
          if (constraints.maxWidth.isFinite) {
            width = constraints.maxWidth;
          }
          // P1 (step 1.4): width comes from the available constraints instead
          // of MediaQuery, so the line tracks the grid's real viewport width.
          // IgnorePointer: the hour row is a purely decorative guide line
          // (a Container with a Border decoration is hit-test-opaque).
          // Without this it swallows taps in the empty grid area and blocks
          // the DayGrid background tap-to-add detector (C12). No visual change.
          return IgnorePointer(
            child: Container(
              decoration: (this.widget as TileTimeCellWidget).decoration ??
                  BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: colorScheme.primary,
                            width: TileDimensions.thickness)),
                  ),
              height: this.widgetHeight,
              width: width,
              child: this.widget.child,
            ),
          );
        },
      ),
    );
  }
}
