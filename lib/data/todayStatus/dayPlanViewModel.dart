import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';
import 'package:tiler_app/util.dart';

/// Which row of the spec's §8.1 display state matrix the current day matches.
enum TodayStatusDisplayState {
  /// 0 placed / 0 attention / 0 late.
  clearDay,

  /// >0 placed / 0 attention / 0 late.
  allPlaced,

  /// Any placed / >0 attention / 0 late.
  attentionNeeded,

  /// Any late items at all. Takes precedence over every other row.
  recovery,
}

/// The two permitted on-track phrasings (spec §2.2). Localization of the actual
/// strings stays in the widget layer.
enum TrackStatusCopy { everythingOnTrack, everythingElseOnTrack }

/// Normalized Today Status screen state (spec §14).
///
/// This type owns every "which card do I show / what does the footer say"
/// decision so widgets branch on semantics rather than re-deriving scheduling
/// rules from raw [TimelineSummary] data.
class DayPlanViewModel {
  DayPlanViewModel({
    required this.date,
    required this.placedItems,
    required this.attentionItems,
    required this.lateItems,
    this.canPreviewPlan = false,
  });

  final DateTime date;
  final List<PlanItemViewModel> placedItems;
  final List<PlanItemViewModel> attentionItems;
  final List<PlanItemViewModel> lateItems;

  /// Whether a plan preview can currently be generated at all. The preview
  /// pipeline is not wired yet, so callers pass false until it is.
  final bool canPreviewPlan;

  int get placedCount => placedItems.length;
  int get attentionCount => attentionItems.length;
  int get lateCount => lateItems.length;

  TodayStatusDisplayState get displayState {
    if (lateCount > 0) {
      return TodayStatusDisplayState.recovery;
    }
    if (attentionCount > 0) {
      return TodayStatusDisplayState.attentionNeeded;
    }
    if (placedCount > 0) {
      return TodayStatusDisplayState.allPlaced;
    }
    return TodayStatusDisplayState.clearDay;
  }

  bool get showPlacedCard => placedCount > 0;
  bool get showAttentionCard => attentionCount > 0;
  bool get showLateCard => lateCount > 0;

  /// True when the day has something the user must act on. Used to demote the
  /// healthy "placed" section so the exception owns the screen.
  bool get hasException => lateCount > 0 || attentionCount > 0;

  /// §8.1: the recovery section outranks everything else when present, so it
  /// never lands below the fold beneath long placed/attention lists.
  bool get lateLeadsContent => showLateCard;

  /// Attention leads only when nothing is late and nothing is placed.
  bool get attentionLeadsContent =>
      showAttentionCard && !lateLeadsContent && placedCount == 0;

  /// Suppressed entirely while anything is late, so success copy can never mask
  /// `lateCount > 0`, and on a clear day where there is no content to confirm.
  bool get showTrackStatusCard =>
      lateCount == 0 && displayState != TodayStatusDisplayState.clearDay;

  TrackStatusCopy get trackStatusCopy => attentionCount > 0
      ? TrackStatusCopy.everythingElseOnTrack
      : TrackStatusCopy.everythingOnTrack;

  bool get showPreviewCta =>
      canPreviewPlan && (attentionCount > 0 || lateCount > 0);

  /// Builds the view model from the day's [TimelineSummary].
  ///
  /// Placed items come from `complete`: in Tiler a placed sub-event is
  /// technically a completed one, and the server already isolates that bucket
  /// per day (the same list `daySummary` renders its completed count from).
  factory DayPlanViewModel.fromTimelineSummary({
    required Timeline timeline,
    required TimelineSummary? summary,
    bool canPreviewPlan = false,
  }) {
    final List<PlanItemViewModel> attentionItems = _sortAttention(
      (summary?.nonViable ?? const <TilerEvent>[])
          .map((e) => PlanItemViewModel.fromTilerEvent(e,
              status: PlanItemStatus.needsAttention))
          .toList(),
    );
    final List<PlanItemViewModel> lateItems = _sortChronologically(
      (summary?.tardy ?? const <TilerEvent>[])
          .map((e) =>
              PlanItemViewModel.fromTilerEvent(e, status: PlanItemStatus.late))
          .toList(),
    );
    final List<PlanItemViewModel> placedItems = _sortChronologically(
      (summary?.complete ?? const <TilerEvent>[])
          .map((e) => PlanItemViewModel.fromTilerEvent(e,
              status: PlanItemStatus.placed))
          .toList(),
    );

    final DayPlanViewModel model = DayPlanViewModel(
      date: summary?.date ?? timeline.startTime,
      placedItems: placedItems,
      attentionItems: attentionItems,
      lateItems: lateItems,
      canPreviewPlan: canPreviewPlan,
    );

    Utility.debugPrint(
        '[TodayStatus] state=${model.displayState.name} placed=${model.placedCount} '
        'attention=${model.attentionCount} late=${model.lateCount} '
        'trackCopy=${model.showTrackStatusCard ? model.trackStatusCopy.name : "hidden"} '
        'cta=${model.showPreviewCta}');

    return model;
  }

  /// Stable sort: items without a start time keep their incoming order at the
  /// end of the list rather than jumping around between refreshes (spec §8.3).
  static List<PlanItemViewModel> _sortChronologically(
      List<PlanItemViewModel> items) {
    final List<PlanItemViewModel> sorted = List.of(items);
    _stableSort(sorted, (a, b) {
      final DateTime? aStart = a.scheduledStart;
      final DateTime? bStart = b.scheduledStart;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return aStart.compareTo(bStart);
    });
    return sorted;
  }

  /// Reason priority, then tile priority, then earliest date — ties keep their
  /// original order so equal-priority rows don't shuffle on refresh (spec §8.3).
  static List<PlanItemViewModel> _sortAttention(List<PlanItemViewModel> items) {
    final List<PlanItemViewModel> sorted = List.of(items);
    _stableSort(sorted, (a, b) {
      final int reason = _reasonRank(a).compareTo(_reasonRank(b));
      if (reason != 0) return reason;

      final int priority =
          _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
      if (priority != 0) return priority;

      final DateTime? aDate = a.displayDate;
      final DateTime? bDate = b.displayDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return sorted;
  }

  static int _reasonRank(PlanItemViewModel item) =>
      item.reasonCode?.displayPriority ?? AttentionReasonCode.values.length + 1;

  static int _priorityRank(TilePriority priority) {
    switch (priority) {
      case TilePriority.high:
        return 0;
      case TilePriority.medium:
        return 1;
      case TilePriority.low:
        return 2;
    }
  }

  /// Dart's [List.sort] is not stable, and §8.3 requires equal-ranked rows to
  /// keep their order between refreshes.
  static void _stableSort<T>(List<T> items, int Function(T, T) compare) {
    final List<MapEntry<int, T>> indexed = [
      for (int i = 0; i < items.length; i++) MapEntry(i, items[i])
    ];
    indexed.sort((a, b) {
      final int result = compare(a.value, b.value);
      return result != 0 ? result : a.key.compareTo(b.key);
    });
    for (int i = 0; i < items.length; i++) {
      items[i] = indexed[i].value;
    }
  }
}
