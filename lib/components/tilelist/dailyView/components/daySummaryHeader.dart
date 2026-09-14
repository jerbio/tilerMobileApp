import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

/// Day summary header that displays "Today" with day of week badge, date,
/// and day metrics (non-viable, complete, tardy counts)
class DaySummaryHeader extends StatefulWidget {
  final DateTime? date;
  final TimelineSummary? dayData;
  final bool preview;
  const DaySummaryHeader(
      {Key? key, this.date, this.dayData, this.preview = false})
      : super(key: key);

  @override
  State<DaySummaryHeader> createState() => _DaySummaryHeaderState();
}

class _DaySummaryHeaderState extends State<DaySummaryHeader> {
  TimelineSummary? _dayData;

  /// True once a server-provided day summary (from the daySummarys request) has
  /// been applied for this day. The completed/tardy lists only ever come from
  /// that request, so once we have them we keep showing the numbers across
  /// refreshes instead of blanking them back to a loading shimmer.
  bool _hasAppliedServerSummary = false;

  late ThemeData theme;
  late TileThemeExtension tileThemeExtension;

  @override
  void initState() {
    super.initState();
    _dayData = widget.dayData;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
  }

  @override
  void didUpdateWidget(DaySummaryHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dayData != oldWidget.dayData) {
      _dayData = widget.dayData;
    }
  }

  /// Effective pending flag used to drive the shimmer. Show the shimmer until
  /// this day's server summary has been applied; once we have it, keep the real
  /// numbers even across refreshes so they never drop off. Stop shimmering on
  /// error rather than spinning forever.
  bool get _showPending {
    if (_hasAppliedServerSummary) {
      return false;
    }
    return context.read<ScheduleSummaryBloc>().state
        is! ScheduleSummaryErrorState;
  }

  /// Pulls the summary matching this day out of a bloc state. Both the loaded
  /// and loading states carry the retained day summaries (the loading state
  /// keeps the previously retrieved completion data), so we honour either. That
  /// lets the header render its last-known completion during a refresh instead
  /// of dropping it while the in-flight request settles.
  TimelineSummary? _matchingSummaryFromState(ScheduleSummaryState state) {
    List<TimelineSummary>? stateDayData;
    // Accept the day summaries regardless of requestId: they are keyed by
    // dayIndex and the emitted dayData is the full retained union, so it is
    // valid for any request. (The daily view dispatches summary requests with a
    // non-null requestId via TileListState.refreshScheduleSummary.)
    if (state is ScheduleDaySummaryLoaded) {
      stateDayData = state.dayData;
    } else if (state is ScheduleDaySummaryLoading) {
      stateDayData = state.dayData;
    }
    if (stateDayData == null) {
      return null;
    }
    return stateDayData
        .where(
            (timelineSummary) => timelineSummary.dayIndex == _dayData?.dayIndex)
        .firstOrNull;
  }

  void _navigateToSummary(BuildContext context) {
    if (_dayData?.dayIndex == null) return;

    DateTime start = Utility.getTimeFromIndex(_dayData!.dayIndex!);
    DateTime end = Utility.getTimeFromIndex(_dayData!.dayIndex!).endOfDay;
    Timeline timeline =
        Timeline(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TodayStatusScreen(
                  timeline: timeline,
                )));
  }

  Widget _buildShimmer(ColorScheme colorScheme) {
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
    required ColorScheme colorScheme,
    bool isPending = false,
  }) {
    if (isPending) {
      return _buildShimmer(colorScheme);
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

  @override
  Widget build(BuildContext context) {
    final now = widget.date ?? Utility.currentTime();
    final dayOfWeek = DateFormat('EEEE').format(now); // e.g., "Monday"
    final monthDay = DateFormat('MMMM d').format(now); // e.g., "December 1"
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ScheduleSummaryBloc, ScheduleSummaryState>(
      listener: (context, state) {
        final latestDayData = _matchingSummaryFromState(state);
        if (latestDayData != null) {
          setState(() {
            _dayData = latestDayData;
            _hasAppliedServerSummary = true;
          });
        }
      },
      child: BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          // Update from bloc state
          final latestDayData = _matchingSummaryFromState(state);
          if (latestDayData != null) {
            _dayData = latestDayData;
            _hasAppliedServerSummary = true;
          }

          final nonViableCount = _dayData?.nonViable?.length ?? 0;
          final completeCount = _dayData?.complete?.length ?? 0;
          final tardyCount = _dayData?.tardy?.length ?? 0;

          return ColorFiltered(
            colorFilter: ColorFilter.mode(
              widget.preview
                  ? tileThemeExtension.vibeChatPreviewDisableColor
                      .withValues(alpha: 0.6)
                  : Colors.transparent,
              BlendMode.srcATop,
            ),
            child: GestureDetector(
              onTap: widget.preview ? null : () => _navigateToSummary(context),
              child: Container(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side - Date information
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.today,
                              style: TextStyle(
                                fontFamily: TileTextStyles.rubikFontName,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Day metrics inline with "Today"
                            if (nonViableCount > 0 || _showPending) ...[
                              _buildMetricChip(
                                icon: Icons.error,
                                iconColor: colorScheme.error,
                                count: nonViableCount,
                                colorScheme: colorScheme,
                                isPending: _showPending,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (completeCount > 0 || _showPending) ...[
                              _buildMetricChip(
                                icon: Icons.check_circle,
                                iconColor: TileColors.completedTeal,
                                count: completeCount,
                                colorScheme: colorScheme,
                                isPending: _showPending,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (tardyCount > 0 || _showPending) ...[
                              _buildMetricChip(
                                icon: Icons.car_crash_outlined,
                                iconColor: TileColors.warning,
                                count: tardyCount,
                                colorScheme: colorScheme,
                                isPending: _showPending,
                              ),
                              const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              monthDay,
                              style: TextStyle(
                                fontFamily: TileTextStyles.rubikFontName,
                                fontSize: 15,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                dayOfWeek,
                                style: TextStyle(
                                  fontFamily: TileTextStyles.rubikFontName,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
