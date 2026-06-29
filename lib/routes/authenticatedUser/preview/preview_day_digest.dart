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
import 'package:tiler_app/routes/authenticatedUser/preview/preview_sentence.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Static day digest rendered beneath the preview carousel. Holds the
/// natural-language summary sentence and the quick metric chips
/// (distance, places, sleep) so they stay anchored in one position as
/// the user swipes between carousel slides.
///
/// Lifted out of [PreviewSundialCard] so swiping does not redraw or
/// shift this content. Subscribes to [ScheduleSummaryBloc] the same way
/// the card does and exposes the same test seams.
class PreviewDayDigest extends StatefulWidget {
  final List<TilerEvent> subEvents;
  final Timeline? timeline;

  /// Test seam — when provided, skips the bloc and uses this summary
  /// directly.
  final TimelineSummary? overrideTimelineSummary;

  /// When false, skips the on-mount summary fetch. Test seam.
  final bool autoFetchSummary;

  const PreviewDayDigest({
    Key? key,
    required this.subEvents,
    this.timeline,
    this.overrideTimelineSummary,
    this.autoFetchSummary = true,
  }) : super(key: key);

  @override
  State<PreviewDayDigest> createState() => _PreviewDayDigestState();
}

class _PreviewDayDigestState extends State<PreviewDayDigest> {
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          key: const ValueKey('preview-day-digest'),
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The summary uses all available vertical space and scrolls
              // only when it is still too tall; the metric chips stay
              // pinned at the bottom and always visible.
              Expanded(
                child: _AutoScrollText(
                  child: _buildSentence(context, metrics, l10n),
                ),
              ),
              const SizedBox(height: 20),
              _buildChips(context, metrics, l10n, colorScheme, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentence(
      BuildContext context, DayPreviewMetrics metrics, AppLocalizations l10n) {
    final localeTag = Localizations.localeOf(context).toString();
    final hoursFmt = NumberFormat('#0.0', localeTag);
    final timeFmt = DateFormat.jm(localeTag);
    final labels = PreviewLabels(
      greeting: l10n.previewSundialGreeting,
      tilesClause: (n) => l10n.previewSundialTilesClause(n.toString()),
      blocksClause: (n) => l10n.previewSundialBlocksClause(n.toString()),
      tileSharesClause: (n) =>
          l10n.previewSundialTileSharesClause(n.toString()),
      workClause: (hours) => l10n.previewSundialWorkClause(hours),
      transitClause: (mins) =>
          l10n.previewSundialTransitClause(mins.toString()),
      clearsByClause: (time) => l10n.previewSundialClearsByClause(time),
      countsPrefix: l10n.previewSundialCountsPrefix,
      countsSuffix: l10n.previewSundialCountsSuffix,
      andSeparator: l10n.previewSundialAndSeparator,
      sentenceJoiner: '. ',
      noTiles: l10n.noTilesPreview,
      formatHours: (h) => hoursFmt.format(h),
      formatClearTime: (dt) => timeFmt.format(dt.toLocal()),
    );

    final sentence = buildPreviewSentence(metrics: metrics, labels: labels);
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = TextStyle(
      fontFamily: TileTextStyles.rubikFontName,
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface.withValues(alpha: 0.55),
      height: 1.4,
    );
    final emphasisStyle = baseStyle.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    return Text.rich(
      TextSpan(
        children: _splitWithNumberEmphasis(sentence, baseStyle, emphasisStyle),
      ),
      key: const ValueKey('preview-day-digest-sentence'),
    );
  }

  /// Walks [text] and yields alternating plain / emphasised [TextSpan]s
  /// so numerics (counts, decimals, clock times like "1:03 AM", "5pm")
  /// pop visually against the muted surrounding prose.
  List<TextSpan> _splitWithNumberEmphasis(
    String text,
    TextStyle baseStyle,
    TextStyle emphasisStyle,
  ) {
    final pattern = RegExp(r'\d+(?:[.:]\d+)*(?:\s?[AaPp][Mm])?');
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(text: match.group(0), style: emphasisStyle));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    return spans;
  }

  Widget _buildChips(
    BuildContext context,
    DayPreviewMetrics metrics,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: colorScheme.primary.withAlpha(50),
        highlightColor: colorScheme.surfaceContainerLowest.withAlpha(100),
        child: SizedBox(
          height: 22,
          child: Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 60,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final localeTag = Localizations.localeOf(context).toString();
    final numberFmt = NumberFormat.decimalPattern(localeTag);
    final sleepFmt = NumberFormat('#0.0', localeTag);

    const distanceColor = Color(0xFF3B82F6); // blue
    final locationColor = TileColors.primary; // brand red
    final sleepColor = TileColors.completedTeal; // brand teal
    final freeColor = TileColors.completedTeal; // brand teal

    final chips = <Widget>[];

    if (metrics.distance != null && metrics.distance! > 0) {
      chips.add(_chip(
        key: const ValueKey('preview-day-digest-chip-distance'),
        icon: Icons.directions_walk,
        iconColor: distanceColor,
        text: l10n.previewSundialDistance(
          numberFmt.format(metrics.distance),
          metrics.distanceUnit,
        ),
        colorScheme: colorScheme,
      ));
    }

    if (metrics.locationsCount > 0) {
      chips.add(_chip(
        key: const ValueKey('preview-day-digest-chip-locations'),
        icon: Icons.place,
        iconColor: locationColor,
        text: l10n.previewSundialLocations(metrics.locationsCount.toString()),
        colorScheme: colorScheme,
      ));
    }

    if (metrics.sleepDuration != null && metrics.sleepDuration!.inMinutes > 0) {
      final hours = metrics.sleepDuration!.inMinutes / 60.0;
      chips.add(_chip(
        key: const ValueKey('preview-day-digest-chip-sleep'),
        icon: Icons.bedtime,
        iconColor: sleepColor,
        text: l10n.previewSundialSleepHours(sleepFmt.format(hours)),
        colorScheme: colorScheme,
      ));
    }

    chips.add(_chip(
      key: const ValueKey('preview-day-digest-chip-free'),
      icon: Icons.hourglass_bottom,
      iconColor: freeColor,
      text: metrics.freeDuration.inMinutes > 0
          ? l10n.previewSundialFreeHours(
              sleepFmt.format(metrics.freeDuration.inMinutes / 60.0))
          : l10n.previewSundialFullyBooked,
      colorScheme: colorScheme,
    ));

    if (chips.isEmpty) {
      return const SizedBox.shrink(
          key: ValueKey('preview-day-digest-chip-row-empty'));
    }

    return Wrap(
      key: const ValueKey('preview-day-digest-chip-row'),
      spacing: 20,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _chip({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String text,
    required ColorScheme colorScheme,
  }) {
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// Vertically scrolls [child] like film credits when it is taller than the
/// available space, looping forever. When the content fits, it stays put
/// and the user can still scroll manually.
class _AutoScrollText extends StatefulWidget {
  const _AutoScrollText({required this.child});

  final Widget child;

  @override
  State<_AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<_AutoScrollText> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  Future<void> _startScroll() async {
    if (!mounted || !_controller.hasClients) return;
    final maxExtent = _controller.position.maxScrollExtent;
    if (maxExtent <= 0) return; // Content fits — no auto-scroll needed.

    // ~30 logical px/sec credits crawl, with brief holds at each end.
    final duration = Duration(milliseconds: (maxExtent / 30 * 1000).round());
    while (mounted && _controller.hasClients) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted || !_controller.hasClients) return;
      await _controller.animateTo(_controller.position.maxScrollExtent,
          duration: duration, curve: Curves.linear);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted || !_controller.hasClients) return;
      await _controller.animateTo(0,
          duration: duration, curve: Curves.linear);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      physics: const ClampingScrollPhysics(),
      child: widget.child,
    );
  }
}
