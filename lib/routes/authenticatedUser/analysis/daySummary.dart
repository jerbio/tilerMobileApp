import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/summaryPage.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

class DaySummary extends StatefulWidget {
  TimelineSummary dayTimelineSummary;
  DaySummary({required this.dayTimelineSummary});
  @override
  State createState() => _DaySummaryState();
}

class _DaySummaryState extends State<DaySummary> {
  TimelineSummary? dayData;
  bool pendingFlag = false;
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    dayData = this.widget.dayTimelineSummary;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  bool get isPending {
    bool retValue = false;
    retValue = retValue ||
        this.context.read<ScheduleSummaryBloc>().state
            is ScheduleDaySummaryLoading;
    retValue = pendingFlag || retValue;
    return retValue;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: colorScheme.primary.withAlpha(50),
      highlightColor: colorScheme.surfaceContainerLowest.withAlpha(100),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        width: 18.0,
        height: 18.0,
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required Color iconColor,
    required int count,
    bool isPending = false,
  }) {
    if (isPending) {
      return _buildShimmer();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget renderDayMetricInfo() {
    final nonViableCount = dayData?.nonViable?.length ?? 0;
    final completeCount = dayData?.complete?.length ?? 0;
    final tardyCount = dayData?.tardy?.length ?? 0;

    List<Widget> rowSymbolElements = <Widget>[];
    const iconMargin = EdgeInsets.fromLTRB(5, 0, 5, 0);

    if (nonViableCount > 0 || isPending) {
      rowSymbolElements.add(
        Container(
          margin: iconMargin,
          child: _buildMetricChip(
            icon: Icons.error,
            iconColor: colorScheme.error,
            count: nonViableCount,
            isPending: isPending,
          ),
        ),
      );
    }

    if (completeCount > 0 || isPending) {
      rowSymbolElements.add(
        Container(
          margin: iconMargin,
          child: _buildMetricChip(
            icon: Icons.check_circle,
            iconColor: TileColors.completedTeal,
            count: completeCount,
            isPending: isPending,
          ),
        ),
      );
    }

    if (tardyCount > 0 || isPending) {
      rowSymbolElements.add(
        Container(
          margin: iconMargin,
          child: _buildMetricChip(
            icon: Icons.car_crash_outlined,
            iconColor: TileColors.warning,
            count: tardyCount,
            isPending: isPending,
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: rowSymbolElements,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduleSummaryBloc, ScheduleSummaryState>(
          listener: (context, state) {
            if (state is ScheduleDaySummaryLoaded && state.requestId == null) {
              if (state.dayData != null && dayData != null) {
                TimelineSummary? latestDayData = state.dayData!
                    .where((timelineSummary) =>
                        timelineSummary.dayIndex == dayData?.dayIndex)
                    .firstOrNull;
                setState(() {
                  dayData = latestDayData;
                  pendingFlag = false;
                });
              }
            }
            if (state is ScheduleDaySummaryLoading && state.requestId == null) {
              setState(() {
                pendingFlag = true;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          if (state is ScheduleDaySummaryLoaded && state.requestId == null) {
            TimelineSummary? latestDayData = state.dayData!
                .where((timelineSummary) =>
                    timelineSummary.dayIndex == dayData?.dayIndex)
                .firstOrNull;
            if (latestDayData != null) {
              dayData = latestDayData;
            }
          }

          Widget dayDateText = Container(
            child: Text(
              Utility.getTimeFromIndex(dayData!.dayIndex!).humanDate(context),
              style: TextStyle(
                fontSize: 28,
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          );

          Widget buttonPress = GestureDetector(
            onTap: () {
              DateTime start = Utility.getTimeFromIndex(dayData!.dayIndex!);
              DateTime end =
                  Utility.getTimeFromIndex(dayData!.dayIndex!).endOfDay;
              Timeline timeline = Timeline(
                  start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SummaryPage(
                            timeline: timeline,
                          )));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [dayDateText, renderDayMetricInfo()],
                ),
              ],
            ),
          );

          Container retContainer = Container(
              padding: EdgeInsets.fromLTRB(10, 10, 20, 0),
              height: 120,
              child: buttonPress);

          return retContainer;
        },
      ),
    );
  }
}
