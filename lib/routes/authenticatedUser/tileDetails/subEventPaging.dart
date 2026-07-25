import 'package:tiler_app/data/subCalendarEvent.dart';

/// Default page size for sub-event pagination, shared by the initial
/// `ProximityToNow` fetch and the cursor-based `Id` follow-up pages.
const int kSubEventBatchSize = 20;

/// Framework-free paging state for the sub-event carousel.
///
/// Mirrors the web `SubEventsSection` state machine: an initial
/// `ProximityToNow` batch establishes both cursors, then `Id`-ordered pages
/// extend the trailing (after) and leading (before) edges. Items are retained
/// in arrival order but de-duplicated by id; [orderedItems] / [visibleItems]
/// expose a stable, display-ready view sorted by (start asc, id).
///
/// The controller holds only state and pure mutations — the async fetch and
/// its error handling live in the widget that owns the instance.
class SubEventPaging {
  SubEventPaging({this.batchSize = kSubEventBatchSize});

  final int batchSize;

  final List<SubCalendarEvent> _items = [];
  final Set<String> _seenIds = {};

  /// Id of the earliest retained sub-event (leading edge cursor).
  String? leftCursorId;

  /// Id of the latest retained sub-event (trailing edge cursor).
  String? rightCursorId;

  /// Whether more sub-events may exist before the leading edge.
  bool hasMoreBefore = false;

  /// Whether more sub-events may exist after the trailing edge.
  bool hasMoreAfter = false;

  /// Whether a leading-edge (`before`) page is currently in flight. Drives the
  /// directional spinner so only the fetching edge shows a loader.
  bool isLoadingBefore = false;

  /// Whether a trailing-edge (`after`) page is currently in flight.
  bool isLoadingAfter = false;

  /// True while a follow-up page is in flight in either direction. Used as the
  /// single-flight guard so the two edges never fetch concurrently.
  bool get isLoadingMore => isLoadingBefore || isLoadingAfter;

  bool get isEmpty => _items.isEmpty;

  /// Retained sub-events sorted by (start ascending, id).
  List<SubCalendarEvent> get orderedItems {
    final sorted = List<SubCalendarEvent>.from(_items);
    sorted.sort(_byTimeThenId);
    return sorted;
  }

  /// Display view: [orderedItems] with completed/disabled entries hidden
  /// unless [showCompleted] is set.
  List<SubCalendarEvent> visibleItems({bool showCompleted = false}) {
    final ordered = orderedItems;
    if (showCompleted) return ordered;
    return ordered.where((sub) => sub.isActive).toList(growable: false);
  }

  /// True when the trailing edge can be extended right now.
  bool get canLoadAfter =>
      !isLoadingMore && hasMoreAfter && rightCursorId != null;

  /// True when the leading edge can be extended right now.
  bool get canLoadBefore =>
      !isLoadingMore && hasMoreBefore && leftCursorId != null;

  /// Seeds state from the initial `ProximityToNow` page.
  void setInitial(List<SubCalendarEvent> page) {
    _items.clear();
    _seenIds.clear();
    for (final sub in page) {
      _addUnique(sub, append: true);
    }
    leftCursorId = page.isNotEmpty ? page.first.id : null;
    rightCursorId = page.isNotEmpty ? page.last.id : null;
    hasMoreAfter = page.length >= batchSize;
    hasMoreBefore = page.length >= batchSize;
  }

  /// Merges a trailing-edge (`afterSubEventId`) page.
  void appendPage(List<SubCalendarEvent> page) {
    for (final sub in page) {
      _addUnique(sub, append: true);
    }
    if (page.isNotEmpty) rightCursorId = page.last.id;
    hasMoreAfter = page.length >= batchSize;
  }

  /// Merges a leading-edge (`beforeSubEventId`) page.
  void prependPage(List<SubCalendarEvent> page) {
    // Prepend in reverse so the incoming page keeps its relative order.
    for (final sub in page.reversed) {
      _addUnique(sub, append: false);
    }
    if (page.isNotEmpty) leftCursorId = page.first.id;
    hasMoreBefore = page.length >= batchSize;
  }

  void _addUnique(SubCalendarEvent sub, {required bool append}) {
    final id = sub.id ?? '';
    if (_seenIds.contains(id)) return;
    _seenIds.add(id);
    if (append) {
      _items.add(sub);
    } else {
      _items.insert(0, sub);
    }
  }

  static int _byTimeThenId(SubCalendarEvent a, SubCalendarEvent b) {
    final startA = a.start ?? 0;
    final startB = b.start ?? 0;
    if (startA != startB) return startA.compareTo(startB);
    return (a.id ?? '').compareTo(b.id ?? '');
  }
}
