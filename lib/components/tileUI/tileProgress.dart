import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class Indicator extends StatelessWidget {
  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  }) : super(key: key);
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}

class TileProgress extends StatefulWidget {
  CalendarEvent calendarEvent;
  TileProgress({required this.calendarEvent});
  @override
  State<StatefulWidget> createState() => _TileProgressState();
}

enum TileStatus { Complete, Delete, Scheduled }

class _TileProgressState extends State<TileProgress> {
  int completeCount = 0;
  int tiledCount = 0;
  int deletedCount = 0;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    completeCount = this.widget.calendarEvent.completeCount ?? 0;
    deletedCount = this.widget.calendarEvent.deleteCount ?? 0;
    tiledCount =
        this.widget.calendarEvent.split! - (completeCount) - (deletedCount);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
  }

  int touchedIndex = -1;
  final Map<TileStatus, Color> colorMapping = {
    TileStatus.Complete: TileColors.completedTeal,
    TileStatus.Delete: TileColors.deleted,
    TileStatus.Scheduled: TileColors.scheduled,
  };

  List<PieChartSectionData> showingSections() {
    return List.generate(
      3,
      (i) {
        final isTouched = i == touchedIndex;
        switch (i) {
          case 0:
            return PieChartSectionData(
              color: colorMapping[TileStatus.Complete],
              value: (completeCount).toDouble(),
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? BorderSide(color: TileColors.success, width: 6)
                  : BorderSide(color: TileColors.success.withValues(alpha: 0)),
            );
          case 1:
            return PieChartSectionData(
              color: colorMapping[TileStatus.Scheduled],
              value: tiledCount.toDouble(),
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? const BorderSide(color: TileColors.left, width: 6)
                  : BorderSide(color: TileColors.left.withOpacity(0)),
            );
          case 2:
            return PieChartSectionData(
              color: colorMapping[TileStatus.Delete],
              value: (deletedCount).toDouble(),
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? BorderSide(color: TileColors.deletion, width: 6)
                  : BorderSide(color: TileColors.deletion.withValues(alpha: 0)),
            );
          default:
            throw Error();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.2,
      child: Column(
        children: <Widget>[
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  startDegreeOffset: 180,
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 1,
                  centerSpaceRadius: 40,
                  sections: showingSections(),
                ),
                swapAnimationDuration: Duration(milliseconds: 1000), // Optional
                swapAnimationCurve: Curves.bounceInOut, // O
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 5,
              children: <Widget>[
                Indicator(
                  color: colorMapping[TileStatus.Complete]!,
                  text: AppLocalizations.of(context)!
                      .completedCount(completeCount.toString()),
                  isSquare: false,
                  size: touchedIndex == 0 ? 18 : 16,
                  textColor: touchedIndex == 0
                      ? colorMapping[TileStatus.Complete]
                      : colorScheme.onSurface,
                ),
                Indicator(
                  color: colorMapping[TileStatus.Scheduled]!,
                  text: AppLocalizations.of(context)!
                      .tiledCount(tiledCount.toString()),
                  isSquare: false,
                  size: touchedIndex == 1 ? 18 : 16,
                  textColor: touchedIndex == 1
                      ? colorMapping[TileStatus.Scheduled]
                      : colorScheme.onSurface,
                ),
                Indicator(
                  color: colorMapping[TileStatus.Delete]!,
                  text: AppLocalizations.of(context)!
                      .deletedCount(deletedCount.toString()),
                  isSquare: false,
                  size: touchedIndex == 2 ? 18 : 16,
                  textColor: touchedIndex == 2
                      ? colorMapping[TileStatus.Delete]
                      : colorScheme.onSurface,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 80,
          ),
        ],
      ),
    );
  }
}
