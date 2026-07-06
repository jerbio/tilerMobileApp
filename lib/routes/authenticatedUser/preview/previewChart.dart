import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/previewGroup.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

class PreviewChart extends StatefulWidget {
  final List<PreviewSection>? previewGrouping;
  final Icon? icon;
  final Timeline? timeline;

  /// Header rendered ABOVE the chart (e.g. "Classification", "Location").
  /// Renamed from `description` to reflect its new position; constructor
  /// keeps `description` as a deprecated alias for incremental migration.
  final Widget? header;

  PreviewChart({
    this.previewGrouping,
    this.icon,
    this.timeline,
    this.header,
    @Deprecated('Use header; kept for source compatibility') Widget? description,
  }) : assert(header == null || description == null,
            'Provide header OR description, not both');

  @override
  State<StatefulWidget> createState() => _PreviewChartState();
}

class _PreviewChartState extends State<PreviewChart> {
  static final Color otherColor = Utility.randomColor;
  static final Color blockedOutColor = Utility.randomColor;
  bool showTime = true;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  List<PreviewSection>? get previewGrouping {
    return this.widget.previewGrouping;
  }

  Timeline? get _timeline {
    return this.widget.timeline;
  }

  /// Center label showing "consumed / total hrs" (or minutes) for the
  /// timeline. Replaces the former shadowed iconography stack which
  /// rendered as a dark void over the ring.
  Widget _centerRatio() {
    TimeRange? timeLine = this._timeline;
    if (timeLine != null) {
      timeLine = timeLine.interferingTimeRange(Utility.restOfTodayTimeline());
    }
    if (timeLine == null) {
      return const SizedBox.shrink();
    }
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
    return Text(
      isHours
          ? AppLocalizations.of(context)!.previewRatioTimeHours(ratioText)
          : AppLocalizations.of(context)!.previewRatioTimeMinutes(ratioText),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double radius = 18;
    var borderSide = BorderSide(
        color: colorScheme.primary, width: 0.5, style: BorderStyle.solid);
    if (this._timeline == null || this.previewGrouping == null) {
      return const SizedBox.shrink();
    }
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
              titlePositionPercentageOffset: 1.4,
              titleStyle: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontFamily: 'Rubik'),
              value: otherTiles.inMinutes.toDouble()));
        }
        if (blockedOutTiles.inMinutes > 0) {
          pieChartData.add(PieChartSectionData(
              title: AppLocalizations.of(context)!.previewBlockedOut,
              color: blockedOutColor,
              radius: radius,
              borderSide: borderSide,
              titlePositionPercentageOffset: 1.4,
              titleStyle: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontFamily: 'Rubik'),
              value: blockedOutTiles.inMinutes.toDouble()));
        }
      } else {
        List relevalntTiles = (eachPreviewGrouping.tiles ?? [])
            .where((element) => element.isInterfering(_timeline!))
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
            titlePositionPercentageOffset: 1.4,
            titleStyle: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontFamily: 'Rubik'),
            value: durationSum.inMinutes.toDouble()));
      }
    }

    // Layout mirrors PreviewSundialCard: centred 360pt constrained
    // column, header above the visual, no inline message text (that
    // lives in PreviewDayDigest beneath the carousel).
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          key: const ValueKey('preview-chart'),
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (this.widget.header != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: this.widget.header!,
                ),
              // Box must accommodate outside-ring labels: with
              // centerSpaceRadius 70 + section radius 18 and
              // titlePositionPercentageOffset 1.4, labels sit ~95 px from
              // centre. We size for 110 px half-height so top + bottom
              // labels have ~15 px breathing room before clipping.
              SizedBox(
                key: const ValueKey('preview-chart-ring'),
                width: 260,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: pieChartData,
                        sectionsSpace: 1,
                        centerSpaceRadius: 70,
                        startDegreeOffset: -90,
                      ),
                    ),
                    _centerRatio(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

