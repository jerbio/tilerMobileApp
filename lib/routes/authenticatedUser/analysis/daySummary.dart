import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

class DaySummary extends StatefulWidget {
  TimelineSummary dayTimelineSummary;
  final bool preview;
  DaySummary({required this.dayTimelineSummary, this.preview = false});
  @override
  State createState() => _DaySummaryState();
}

class _DaySummaryState extends State<DaySummary> {
  TimelineSummary? dayData;

  /// True once a server-provided day summary (from the daySummarys request) has
  /// been applied for this day. The completed/tardy lists only ever come from
  /// that request, so once we have them we keep showing the numbers across
  /// refreshes instead of blanking back to a loading shimmer.
  bool _hasAppliedServerSummary = false;

  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;

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
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
  }

  /// Pulls the summary matching this day out of a bloc state. Both the loaded
  /// and loading states carry the retained day summaries (the loading state
  /// keeps the previously retrieved completion data), so we honour either. That
  /// lets a DaySummary that is recreated during a refresh (e.g. while swiping
  /// between days) render its last-known completion immediately instead of
  /// dropping it while the in-flight request settles.
  TimelineSummary? _matchingSummaryFromState(ScheduleSummaryState state) {
    List<TimelineSummary>? stateDayData;
    // Accept the day summaries regardless of requestId: they are keyed by
    // dayIndex and the emitted dayData is the full retained union, so it is
    // valid for any request. (The daily view dispatches summary requests with a
    // non-null requestId via TileListState.refreshScheduleSummary, so gating on
    // requestId == null here meant Loaded states were never applied.)
    if (state is ScheduleDaySummaryLoaded) {
      stateDayData = state.dayData;
    } else if (state is ScheduleDaySummaryLoading) {
      stateDayData = state.dayData;
    }
    if (stateDayData == null) {
      return null;
    }
    final match = stateDayData
        .where(
            (timelineSummary) => timelineSummary.dayIndex == dayData?.dayIndex)
        .firstOrNull;
    return match;
  }

  bool get isPending {
    // Show the loading shimmer whenever this day's server summary hasn't been
    // retrieved yet. Once applied, keep the real numbers even across refreshes
    // so they never drop off. Stop shimmering on error rather than spinning
    // forever.
    if (_hasAppliedServerSummary) {
      return false;
    }
    return this.context.read<ScheduleSummaryBloc>().state
        is! ScheduleSummaryErrorState;
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
            iconColor: tileThemeExtension.statusSuccess,
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
            iconColor: tileThemeExtension.statusDanger,
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
            final latestDayData = _matchingSummaryFromState(state);
            if (latestDayData != null) {
              setState(() {
                dayData = latestDayData;
                _hasAppliedServerSummary = true;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          final latestDayData = _matchingSummaryFromState(state);
          if (latestDayData != null) {
            dayData = latestDayData;
            _hasAppliedServerSummary = true;
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
            onTap: widget.preview
                ? null
                : () {
                    DateTime start =
                        Utility.getTimeFromIndex(dayData!.dayIndex!);
                    DateTime end =
                        Utility.getTimeFromIndex(dayData!.dayIndex!).endOfDay;
                    Timeline timeline = Timeline(start.millisecondsSinceEpoch,
                        end.millisecondsSinceEpoch);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TodayStatusScreen(
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
              color: colorScheme.surface,
              child: buttonPress);

          return ColorFiltered(
              colorFilter: ColorFilter.mode(
                widget.preview
                    ? tileThemeExtension.vibeChatPreviewDisableColor
                        .withValues(alpha: 0.6)
                    : Colors.transparent,
                BlendMode.srcATop,
              ),
              child: retContainer);
        },
      ),
    );
  }
}
