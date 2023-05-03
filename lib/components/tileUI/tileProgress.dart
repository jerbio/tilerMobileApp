import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    return Row(
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

enum tileStatus { Complete, Delete, Scheduled }

class _TileProgressState extends State<TileProgress> {
  int touchedIndex = -1;
  final Map<tileStatus, Color> colorMapping = {
    tileStatus.Complete: Colors.green,
    tileStatus.Delete: Colors.redAccent,
    tileStatus.Scheduled: Colors.blueAccent,
  };

  List<PieChartSectionData> showingSections() {
    return List.generate(
      3,
      (i) {
        final isTouched = i == touchedIndex;
        switch (i) {
          case 0:
            return PieChartSectionData(
              color: colorMapping[tileStatus.Complete],
              value: (this.widget.calendarEvent.completeCount ?? 0).toDouble(),
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? const BorderSide(color: Colors.greenAccent, width: 6)
                  : BorderSide(color: Colors.greenAccent.withOpacity(0)),
            );
          case 1:
            return PieChartSectionData(
              color: colorMapping[tileStatus.Delete],
              value: (this.widget.calendarEvent.deleteCount ?? 0).toDouble(),
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
              borderSide: isTouched
                  ? const BorderSide(color: Colors.greenAccent, width: 6)
                  : BorderSide(color: Colors.greenAccent.withOpacity(0)),
            );
          case 2:
            return PieChartSectionData(
              color: colorMapping[tileStatus.Scheduled],
              value: (this.widget.calendarEvent.split! -
                      (this.widget.calendarEvent.completeCount ?? 0) -
                      (this.widget.calendarEvent.deleteCount ?? 0))
                  .toDouble(),
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.6,
              borderSide: isTouched
                  ? const BorderSide(color: Colors.greenAccent, width: 6)
                  : BorderSide(color: Colors.greenAccent.withOpacity(0)),
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
      aspectRatio: 1.3,
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 28,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Indicator(
                color: colorMapping[tileStatus.Complete]!,
                text: AppLocalizations.of(context)!.completed,
                isSquare: false,
                size: touchedIndex == 0 ? 18 : 16,
                textColor: touchedIndex == 0
                    ? colorMapping[tileStatus.Complete]
                    : Colors.purple,
              ),
              Indicator(
                color: colorMapping[tileStatus.Delete]!,
                text: AppLocalizations.of(context)!.deleted,
                isSquare: false,
                size: touchedIndex == 1 ? 18 : 16,
                textColor: touchedIndex == 1
                    ? colorMapping[tileStatus.Delete]
                    : Colors.purple,
              ),
              Indicator(
                color: colorMapping[tileStatus.Scheduled]!,
                text: AppLocalizations.of(context)!.scheduled,
                isSquare: false,
                size: touchedIndex == 2 ? 18 : 16,
                textColor: touchedIndex == 2
                    ? colorMapping[tileStatus.Scheduled]
                    : Colors.purple,
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
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
                swapAnimationDuration: Duration(milliseconds: 150), // Optional
                swapAnimationCurve: Curves.linear, // O
              ),
            ),
          ),
        ],
      ),
    );
  }
}
