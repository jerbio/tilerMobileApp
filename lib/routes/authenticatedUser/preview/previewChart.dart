import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/previewGroup.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
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
  List<PreviewSection>? get previewGrouping {
    return this.widget.previewGrouping;
  }

  Icon? get icon {
    return this.widget.icon;
  }

  Timeline? get _timeline {
    return this.widget.timeline;
  }

  @override
  Widget build(BuildContext context) {
    if (this._timeline != null && this.previewGrouping != null) {
      List<PieChartSectionData> pieChartData = [];
      for (int i = 0; i < previewGrouping!.length; i++) {
        var eachPreviewGrouping = previewGrouping![i];
        Color hueColor = TileStyles.chartHues[i % TileStyles.chartHues.length];
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
                value: otherTiles.inMinutes.toDouble()));
          }
          if (blockedOutTiles.inMinutes > 0) {
            pieChartData.add(PieChartSectionData(
                title: AppLocalizations.of(context)!.previewBlockedOut,
                color: blockedOutColor,
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
              titleStyle: TextStyle(fontSize: 12, color: Colors.white),
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
                  PieChart(
                    PieChartData(sections: pieChartData),
                  ),
                  Center(
                    child: icon,
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
