import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/summaryPage.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Day summary header that displays "Today" with day of week badge, date,
/// and day metrics (non-viable, complete, tardy counts)
class DaySummaryHeader extends StatefulWidget {
  final DateTime? date;
  final TimelineSummary? dayData;

  const DaySummaryHeader({
    Key? key,
    this.date,
    this.dayData,
  }) : super(key: key);

  @override
  State<DaySummaryHeader> createState() => _DaySummaryHeaderState();
}

class _DaySummaryHeaderState extends State<DaySummaryHeader> {
  TimelineSummary? _dayData;
  bool _isPending = false;

  @override
  void initState() {
    super.initState();
    _dayData = widget.dayData;
  }

  @override
  void didUpdateWidget(DaySummaryHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dayData != oldWidget.dayData) {
      _dayData = widget.dayData;
    }
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
            builder: (context) => SummaryPage(
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
        if (state is ScheduleDaySummaryLoaded && state.requestId == null) {
          if (state.dayData != null && _dayData != null) {
            TimelineSummary? latestDayData = state.dayData!
                .where((timelineSummary) =>
                    timelineSummary.dayIndex == _dayData?.dayIndex)
                .firstOrNull;
            if (latestDayData != null) {
              setState(() {
                _dayData = latestDayData;
                _isPending = false;
              });
            }
          }
        }
        if (state is ScheduleDaySummaryLoading && state.requestId == null) {
          setState(() {
            _isPending = true;
          });
        }
      },
      child: BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
        builder: (context, state) {
          // Update from bloc state
          if (state is ScheduleDaySummaryLoaded && state.requestId == null) {
            TimelineSummary? latestDayData = state.dayData
                ?.where((timelineSummary) =>
                    timelineSummary.dayIndex == _dayData?.dayIndex)
                .firstOrNull;
            if (latestDayData != null) {
              _dayData = latestDayData;
            }
          }

          final nonViableCount = _dayData?.nonViable?.length ?? 0;
          final completeCount = _dayData?.complete?.length ?? 0;
          final tardyCount = _dayData?.tardy?.length ?? 0;

          return GestureDetector(
            onTap: () => _navigateToSummary(context),
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
                          if (nonViableCount > 0 || _isPending) ...[
                            _buildMetricChip(
                              icon: Icons.error,
                              iconColor: colorScheme.error,
                              count: nonViableCount,
                              colorScheme: colorScheme,
                              isPending: _isPending,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (completeCount > 0 || _isPending) ...[
                            _buildMetricChip(
                              icon: Icons.check_circle,
                              iconColor: TileColors.completedTeal,
                              count: completeCount,
                              colorScheme: colorScheme,
                              isPending: _isPending,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (tardyCount > 0 || _isPending) ...[
                            _buildMetricChip(
                              icon: Icons.car_crash_outlined,
                              iconColor: TileColors.warning,
                              count: tardyCount,
                              colorScheme: colorScheme,
                              isPending: _isPending,
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
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
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
          );
        },
      ),
    );
  }
}
