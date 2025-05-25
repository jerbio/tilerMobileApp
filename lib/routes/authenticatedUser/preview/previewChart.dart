import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/previewGroup.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

class PreviewChart extends StatefulWidget {
  final List<PreviewSection>? previewGrouping;
  final Icon? icon;
  final Timeline? timeline;
  final Widget? description;
  PreviewChart(
      {this.previewGrouping, this.icon, this.timeline, this.description});

  @override
  State<StatefulWidget> createState() => _PreviewChartState();
}

class _PreviewChartState extends State<PreviewChart> {
  static final Color otherColor = Utility.randomColor;
  static final Color blockedOutColor = Utility.randomColor;
  bool showTime = true;
  List<PreviewSection>? get previewGrouping {
    return this.widget.previewGrouping;
  }

  Icon? get icon {
    return this.widget.icon;
  }

  Timeline? get _timeline {
    return this.widget.timeline;
  }

  Widget renderMiddleIconography() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(boxShadow: [
        const BoxShadow(
          color: Color.fromRGBO(220, 220, 220, 0.5),
        ),
        BoxShadow(
          color: Colors.white,
          spreadRadius: -4.0,
          blurRadius: 12.0,
        ),
      ], borderRadius: BorderRadius.circular(110)),
      child: Container(
          margin: EdgeInsets.fromLTRB(0, 70, 0, 0),
          child: this.icon ?? SizedBox.shrink()),
    );
  }

  Widget ratioImagery() {
    TimeRange? timeLine = this._timeline;
    if (timeLine != null) {
      timeLine = timeLine.interferingTimeRange(Utility.restOfTodayTimeline());
    }
    if (timeLine != null) {
      Duration timeLineDuration = timeLine.duration;
      Duration tileSumDuration = Duration.zero;
      List<TilerEvent> tiles = [];
      this.widget.previewGrouping?.forEach((grouping) {
        if (grouping.tiles != null) {
          tiles.addAll(grouping.tiles!);
        }
      });
      var conflictResult = Utility.getConflictingEvents(tiles);
      for (int i = 0; i < conflictResult.item1.length; i++) {
        var eachTile = tiles[i];
        if (eachTile.isInterfering(timeLine)) {
          tileSumDuration += eachTile.interferingTimeRange(timeLine)!.duration;
        }
      }

      for (int i = 0; i < conflictResult.item2.length; i++) {
        var eachTile = tiles[i];
        if (eachTile.isInterfering(timeLine)) {
          tileSumDuration += eachTile.interferingTimeRange(timeLine)!.duration;
        }
      }

      bool isHours = false;
      num numerator = tileSumDuration.inMinutes;
      num denominator = timeLineDuration.inMinutes;
      if (denominator == 0) {
        denominator = 1;
      }
      if (numerator > Duration.minutesPerHour &&
          denominator > Duration.minutesPerHour) {
        isHours = true;
        numerator = tileSumDuration.inHours;
        denominator = timeLineDuration.inHours;
      }
      String ratioText = "${numerator} / ${denominator}";
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(110)),
        child: Center(
          child: Text(
            isHours
                ? AppLocalizations.of(context)!.previewRatioTimeHours(ratioText)
                : AppLocalizations.of(context)!
                    .previewRatioTimeMinutes(ratioText),
            // textScaler: TextScaler.linear(0.75),
            textAlign: TextAlign.center,
            style:
                TextStyle(color: TileStyles.inputFieldTextColor, fontSize: 20),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget getCenterWidget() {
    return Stack(
      children: [renderMiddleIconography(), ratioImagery()],
    );
  }

  @override
  Widget build(BuildContext context) {
    double radius = 10;
    var borderSide = BorderSide(
        color: TileStyles.primaryColor, width: 0.5, style: BorderStyle.solid);
    if (this._timeline != null && this.previewGrouping != null) {
      List<PieChartSectionData> pieChartData = [];
      for (int i = 0; i < previewGrouping!.length; i++) {
        var eachPreviewGrouping = previewGrouping![i];
        Color hueColor = TileColors.chartHues[i % TileColors.chartHues.length];
        if (eachPreviewGrouping.isNullGrouping == true) {
          Duration otherTiles = Duration.zero;
          Duration blockedOutTiles = Duration.zero;
          List<TilerEvent> tiles = eachPreviewGrouping.tiles ?? [];
          for (int j = 0; j < tiles.length; j++) {
            var eachTile = tiles[j];
            if (eachTile.isInterfering(_timeline!)) {
              if (eachTile.isProcrastinate == true) {
                blockedOutTiles +=
                    eachTile.interferingTimeRange(_timeline!)?.duration ??
                        Duration.zero;
              } else {
                otherTiles +=
                    eachTile.interferingTimeRange(_timeline!)?.duration ??
                        Duration.zero;
              }
            }
          }

          if (otherTiles.inMinutes > 0) {
            pieChartData.add(PieChartSectionData(
                title: AppLocalizations.of(context)!.previewOthers,
                color: otherColor,
                radius: radius,
                borderSide: borderSide,
                titleStyle: TextStyle(
                    fontSize: 12, color: TileStyles.accentContrastColor),
                value: otherTiles.inMinutes.toDouble()));
          }
          if (blockedOutTiles.inMinutes > 0) {
            pieChartData.add(PieChartSectionData(
                title: AppLocalizations.of(context)!.previewBlockedOut,
                color: blockedOutColor,
                radius: radius,
                borderSide: borderSide,
                titleStyle: TextStyle(
                    fontSize: 12, color: TileStyles.accentContrastColor),
                value: blockedOutTiles.inMinutes.toDouble()));
          }
        } else {
          List relevalntTiles = (eachPreviewGrouping.tiles ?? [])
              .where((element) =>
                  element.isInterfering(_timeline!) && element.duration != null)
              .toList();
          Duration durationSum = Duration.zero;
          if (relevalntTiles.isNotEmpty) {
            durationSum =
                relevalntTiles.map((e) => e.duration).reduce((value, element) {
              return Duration(
                  milliseconds: value.inMilliseconds + element.inMilliseconds);
            });
          }
          String sectorName = eachPreviewGrouping.name ?? "";
          if (sectorName.length >= 10) {
            sectorName = AppLocalizations.of(context)!
                .previewEllipsisText(sectorName.substring(0, 10));
          }
          pieChartData.add(PieChartSectionData(
              color: hueColor,
              title: sectorName,
              radius: radius,
              borderSide: borderSide,
              badgePositionPercentageOffset: 10,
              titleStyle: TextStyle(
                  fontSize: 12, color: TileStyles.accentContrastColor),
              value: durationSum.inMinutes.toDouble()));
        }
      }
      return Container(
        margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
        width: 200,
        height: 200,
        child: Column(
          children: [
            Flexible(
              child: Stack(
                children: [
                  Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      child: getCenterWidget(),
                    ),
                  ),
                  PieChart(
                    PieChartData(sections: pieChartData),
                  )
                ],
              ),
            ),
            this.widget.description ?? SizedBox.shrink()
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }
}
