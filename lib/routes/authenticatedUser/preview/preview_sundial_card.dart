import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/preview/day_preview_metrics.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/completion_tier.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/sundial_painter.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Carousel slide that shows today's "sundial" arc with its center
/// label and a swipe chevron. The natural-language summary sentence and
/// metric chips formerly lived here — they have been hoisted into
/// `PreviewDayDigest` so they stay in a fixed position as the user
/// swipes between carousel slides.
///
/// The card subscribes to [ScheduleSummaryBloc] so it can hydrate the
/// completion percentage as soon as the day summary is available, and
/// kicks off a fetch on mount when the bloc has never run.
class PreviewSundialCard extends StatefulWidget {
  /// All sub-events Tiler currently knows about for the preview window.
  final List<TilerEvent> subEvents;

  /// Timeline that defines "today" for the card. Defaults to
  /// `Utility.todayTimeline()` when null.
  final Timeline? timeline;

  /// Test seam — when provided, the card uses this summary directly and
  /// does not read from the bloc. Useful for widget tests that don't
  /// want to wire up the full bloc.
  final TimelineSummary? overrideTimelineSummary;

  /// When false, the card will not dispatch a
  /// [GetScheduleDaySummaryEvent] on mount. Test seam.
  final bool autoFetchSummary;

  const PreviewSundialCard({
    Key? key,
    required this.subEvents,
    this.timeline,
    this.overrideTimelineSummary,
    this.autoFetchSummary = true,
  }) : super(key: key);

  @override
  State<PreviewSundialCard> createState() => _PreviewSundialCardState();
}

class _PreviewSundialCardState extends State<PreviewSundialCard> {
  late Timeline _timeline;
  int? _dayIndex;

  @override
  void initState() {
    super.initState();
    _timeline = widget.timeline ?? Utility.todayTimeline();
    _dayIndex = Utility.getDayIndex(DateTime.fromMillisecondsSinceEpoch(
        _timeline.startTime.millisecondsSinceEpoch));
    if (widget.overrideTimelineSummary == null && widget.autoFetchSummary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeFetchSummary();
      });
    }
  }

  void _maybeFetchSummary() {
    if (!mounted) return;
    final bloc = context.read<ScheduleSummaryBloc>();
    final state = bloc.state;
    if (state is ScheduleSummaryInitial) {
      bloc.add(GetScheduleDaySummaryEvent(timeline: _timeline));
    }
  }

  TimelineSummary? _pickSummary(ScheduleSummaryState state) {
    if (widget.overrideTimelineSummary != null) {
      return widget.overrideTimelineSummary;
    }
    List<TimelineSummary>? days;
    if (state is ScheduleDaySummaryLoaded) {
      days = state.dayData;
    } else if (state is ScheduleDaySummaryLoading) {
      days = state.dayData;
    }
    if (days == null || _dayIndex == null) return null;
    for (final s in days) {
      if (s.dayIndex == _dayIndex) return s;
    }
    return null;
  }

  bool _isLoading(ScheduleSummaryState state) {
    if (widget.overrideTimelineSummary != null) return false;
    return state is ScheduleDaySummaryLoading ||
        state is ScheduleSummaryInitial;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overrideTimelineSummary != null) {
      // No bloc needed in test/override mode.
      return _buildBody(
        context,
        summary: widget.overrideTimelineSummary,
        isLoading: false,
      );
    }
    return BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
      builder: (context, state) {
        return _buildBody(
          context,
          summary: _pickSummary(state),
          isLoading: _isLoading(state),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required TimelineSummary? summary,
    required bool isLoading,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final metrics = DayPreviewMetrics.from(
      subEvents: widget.subEvents,
      dayTimeline: _timeline,
      timelineSummary: summary,
    );

    final hasAnyTiles = metrics.tilesCount > 0 ||
        metrics.blocksCount > 0 ||
        metrics.tileSharesCount > 0 ||
        metrics.nonViableCount > 0;
    final isEmptyState = !hasAnyTiles;

    final percent = metrics.completionPct;
    final tier =
        percent != null ? completionTier(percent) : CompletionTier.tier0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          key: const ValueKey('preview-sundial-card'),
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildArc(
                context,
                colorScheme: colorScheme,
                metrics: metrics,
                percent: percent,
                tier: tier,
                isEmptyState: isEmptyState,
                isLoading: isLoading,
                l10n: l10n,
              ),
              const SizedBox(height: 4),
              _buildSeeMoreChevron(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  /// Small drill-down affordance rendered just below the arc, mirroring
  /// the `»` glyph from the Figma comp. v1 is non-interactive; the
  /// `InkWell.onTap` is wired up by callers in a future revision.
  Widget _buildSeeMoreChevron(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: InkWell(
        key: const ValueKey('preview-sundial-chevron'),
        onTap: null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Icon(
            Icons.keyboard_double_arrow_right,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildArc(
    BuildContext context, {
    required ColorScheme colorScheme,
    required DayPreviewMetrics metrics,
    required double? percent,
    required CompletionTier tier,
    required bool isEmptyState,
    required bool isLoading,
    required AppLocalizations l10n,
  }) {
    final tilesColor = TileColors.primary;
    final blocksColor = colorScheme.tertiary;
    final nonViableColor = colorScheme.outline;
    final trackColor = colorScheme.surfaceContainerHighest;
    final progressColor = TileColors.completedTeal;

    final painter = SundialPainter(
      progress: percent ?? 0.0,
      isCompositionMode: isEmptyState || percent == null,
      tilesCount: metrics.tilesCount,
      blocksCount: metrics.blocksCount,
      nonViableCount: metrics.nonViableCount,
      trackColor: trackColor,
      progressColor: progressColor,
      tilesColor: tilesColor,
      blocksColor: blocksColor,
      nonViableColor: nonViableColor,
    );

    final centerLabel = _buildArcCenterLabel(
      context,
      colorScheme: colorScheme,
      percent: percent,
      metrics: metrics,
      isEmptyState: isEmptyState,
      tier: tier,
      l10n: l10n,
    );

    final arc = Center(
      child: SizedBox(
        width: 240,
        height: 120,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('preview-sundial-painter'),
                painter: painter,
              ),
            ),
            // Lift the label so it visually sits inside the dome rather
            // than below the diameter line.
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: centerLabel,
            ),
          ],
        ),
      ),
    );

    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: colorScheme.primary.withAlpha(50),
        highlightColor: colorScheme.surfaceContainerLowest.withAlpha(100),
        child: arc,
      );
    }
    return arc;
  }

  Widget _buildArcCenterLabel(
    BuildContext context, {
    required ColorScheme colorScheme,
    required double? percent,
    required DayPreviewMetrics metrics,
    required bool isEmptyState,
    required CompletionTier tier,
    required AppLocalizations l10n,
  }) {
    String big;
    String small;
    if (isEmptyState || percent == null) {
      big = l10n.previewSundialTodayLabel;
      small =
          '${metrics.tilesCount} · ${metrics.blocksCount} · ${metrics.nonViableCount}';
    } else {
      final pctFmt = NumberFormat.percentPattern(
          Localizations.localeOf(context).toString());
      big = pctFmt.format(percent);
      small = _tierLabel(l10n, tier);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          big,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          small,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  String _tierLabel(AppLocalizations l10n, CompletionTier tier) {
    switch (tier) {
      case CompletionTier.tier0:
        return l10n.previewSundialTier0;
      case CompletionTier.tier1:
        return l10n.previewSundialTier1;
      case CompletionTier.tier2:
        return l10n.previewSundialTier2;
      case CompletionTier.tier3:
        return l10n.previewSundialTier3;
      case CompletionTier.tier4:
        return l10n.previewSundialTier4;
    }
  }
}
