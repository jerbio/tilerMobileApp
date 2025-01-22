//
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/newTileShareSheetWidget.dart';
import 'package:tiler_app/data/previewGroup.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreviewWidget extends StatefulWidget {
  final PreviewSummary? previewSummary;
  final List<TilerEvent> subEvents;
  final Timeline? timeline;
  PreviewWidget({this.previewSummary, required this.subEvents, this.timeline});
  @override
  State<StatefulWidget> createState() => _PreviewState();
}

class _PreviewState extends State<PreviewWidget> {
  late Timeline _timeline;
  @override
  void initState() {
    super.initState();
    _timeline = this.widget.timeline ?? Utility.restOfTodayTimeline();
  }

  PreviewSummary? get _previewSummary {
    return this.widget.previewSummary;
  }

  String _generateMessageText() {
    Timeline dayTimeline = Utility.restOfTodayTimeline();
    List<TilerEvent> blockedTiles = [];
    List<TilerEvent> tiles = [];
    List<TilerEvent> tileShare = [];
    if (this.widget.subEvents.isNotEmpty) {
      this.widget.subEvents.forEach((eachSubEvent) {
        if (eachSubEvent.isInterfering(dayTimeline)) {
          if (eachSubEvent.isRigid == true) {
            blockedTiles.add(eachSubEvent);
          } else {
            tiles.add(eachSubEvent);
          }
          if (eachSubEvent.tileShareDesignatedId
              .isNot_NullEmptyOrWhiteSpace()) {
            tileShare.add(eachSubEvent);
          }
        }
      });
    }
    // return "";
    if (blockedTiles.isNotEmpty && tiles.isNotEmpty && tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveCountBlocksCountTilesAndCountTileShares(
              blockedTiles.length.toString(),
              tiles.length.toString(),
              tileShare.length.toString());
    } else if (blockedTiles.isNotEmpty && tiles.isNotEmpty) {
      return AppLocalizations.of(context)!.youHaveCountBlocksAndCountTiles(
          blockedTiles.length.toString(), tiles.length.toString());
    } else if (blockedTiles.isNotEmpty && tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!.youHaveCountBlocksAndCountTileShares(
          blockedTiles.length.toString(), tileShare.length.toString());
    } else if (tiles.isNotEmpty && tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!.youHaveCountTilesAndCountTileShares(
          tiles.length.toString(), tileShare.length.toString());
    } else if (blockedTiles.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveXBlocks(blockedTiles.length.toString());
    } else if (tiles.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveXTiles(tiles.length.toString());
    } else if (tileShare.isNotEmpty) {
      return AppLocalizations.of(context)!
          .youHaveXTileShares(tileShare.length.toString());
    }

    return AppLocalizations.of(context)!.noTilesPreview;
  }

  Widget renderMessage() {
    const TextStyle previewMessageStyle = TextStyle(
        fontSize: 15,
        color: TileStyles.primaryContrastTextColor,
        fontFamily: TileStyles.rubikFontName,
        fontWeight: FontWeight.w500);
    return Container(
        child: Text(
      _generateMessageText(),
      style: previewMessageStyle,
    ));
  }

  Widget renderEmpty() {
    return SizedBox.shrink();
  }

  Widget renderText() {
    return SizedBox.shrink();
  }

  Widget renderCharts() {
    if (_previewSummary != null) {
      PreviewSummary previewSummary = _previewSummary!;
      List<PieChartSectionData> pieChartData = [];
      List<List<PreviewSection>> orderdByGrouping =
          previewSummary.orderdByGrouping();
      if (orderdByGrouping.isNotEmpty) {
        orderdByGrouping.sort((a, b) => a.length.compareTo(b.length));
        List<PreviewSection> previewGrouping = orderdByGrouping.last;
        for (int i = 0; i < previewGrouping.length; i++) {
          var locationGrouping = previewGrouping[i];
          Color hueColor =
              TileStyles.chartHues[i % TileStyles.chartHues.length];
          if (locationGrouping.isNullGrouping == true) {
            pieChartData.add(PieChartSectionData(
                title: AppLocalizations.of(context)!.previewOthers,
                value: (locationGrouping.tiles ?? [])
                    .where((element) => element.isInterfering(_timeline))
                    .length
                    .toDouble()));
          } else {
            List relevalntTiles = (locationGrouping.tiles ?? [])
                .where((element) =>
                    element.isInterfering(_timeline) &&
                    element.duration != null)
                .toList();
            Duration durationSum = Duration.zero;
            if (relevalntTiles.isNotEmpty) {
              durationSum = relevalntTiles
                  .map((e) => e.duration)
                  .reduce((value, element) {
                return Duration(
                    milliseconds:
                        value.inMilliseconds + element.inMilliseconds);
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
          child: PieChart(
            PieChartData(sections: pieChartData),
          ),
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget renderStats() {
    return SizedBox.shrink();
  }

  Widget renderPreview() {
    return Container(child: NewTileShareSheetWidget());
  }

  Widget renderModal() {
    return Container(child: NewTileShareSheetWidget());
  }

  @override
  Widget build(BuildContext context) {
    Color colorSection = Colors.transparent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        renderCharts(),
        Container(
            margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
            alignment: Alignment.center,
            width: MediaQuery.sizeOf(context).width,
            padding: EdgeInsets.fromLTRB(20, 50, 20, 50),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.5,
                center: Alignment.bottomRight,
                colors: <Color>[
                  colorSection.withLightness(0.65),
                  colorSection.withLightness(0.675),
                  colorSection.withLightness(0.70),
                  colorSection.withLightness(0.75),
                  colorSection.withLightness(0.75),
                  colorSection.withLightness(0.75),
                  colorSection.withLightness(0.75),
                ],
              ),
            ),
            child: renderMessage()),
      ],
    );
  }
}
