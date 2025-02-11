import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/previewGroup.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';

class PreviewChart extends StatefulWidget {
  final List<PreviewSection>? previewGrouping;
  final Icon? icon;
  final Timeline? timeline;
  PreviewChart({this.previewGrouping, this.icon, this.timeline});

  @override
  State<StatefulWidget> createState() => _PreviewChartState();
}

class _PreviewChartState extends State<PreviewChart> {
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
        var locationGrouping = previewGrouping![i];
        Color hueColor = TileStyles.chartHues[i % TileStyles.chartHues.length];
        if (locationGrouping.isNullGrouping == true) {
          pieChartData.add(PieChartSectionData(
              title: AppLocalizations.of(context)!.previewOthers,
              value: (locationGrouping.tiles ?? [])
                  .where((element) => element.isInterfering(_timeline!))
                  .length
                  .toDouble()));
        } else {
          List relevalntTiles = (locationGrouping.tiles ?? [])
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
          String secotrName = locationGrouping.name ?? "";
          if (secotrName.length >= 10) {
            secotrName = AppLocalizations.of(context)!
                .previewEllipsisText(secotrName.substring(0, 10));
          }
          pieChartData.add(PieChartSectionData(
              color: hueColor,
              title: secotrName,
              titleStyle: TextStyle(fontSize: 12, color: Colors.white),
              value: durationSum.inMinutes.toDouble()));
        }
      }
      return Container(
        margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
        width: 150,
        height: 150,
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
      );
    }
    return SizedBox.shrink();
  }
}
