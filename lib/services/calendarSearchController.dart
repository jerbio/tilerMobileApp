import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tiler_app/data/calendarSearch.dart';

typedef CalendarSearchLoader = Future<CalendarSearchResult> Function(
  String query, {
  List<String>? sources,
  int? batchSize,
  int? index,
  int? start,
  int? end,
});

/// Owns the search lifecycle independently of the shared autocomplete widget.
/// Every query/filter/window change invalidates pending searches and batches
/// immediately, including the debounce interval and queries too short to send.
class CalendarSearchController extends ChangeNotifier {
  CalendarSearchController({
    required CalendarSearchLoader loader,
    this.batchSize = 10,
    this.minimumQueryLength = 4,
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : _loader = loader;

  final CalendarSearchLoader _loader;
  final int batchSize;
  final int minimumQueryLength;
  final Duration debounceDuration;
  Timer? _debounce;
  int _sequence = 0;
  bool _disposed = false;
  String _query = '';
  List<String>? _sources;
  int? _start;
  int? _end;
  List<CalendarSearchItem> _items = const [];
  List<CalendarSearchSourceStatus> _sourceStatuses = const [];
  CalendarSearchUnavailableError? _unavailable;
  String? _errorMessage;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasSearched = false;
  bool _hasMore = false;
  int? _nextIndex;
  int? _totalCount;

  String get query => _query;
  List<CalendarSearchItem> get items => _items;
  List<CalendarSearchSourceStatus> get sourceStatuses => _sourceStatuses;
  CalendarSearchUnavailableError? get unavailable => _unavailable;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasSearched => _hasSearched;
  bool get hasMore => _hasMore;
  int? get nextIndex => _nextIndex;
  int? get totalCount => _totalCount;
  bool get canSearch => _query.trim().length >= minimumQueryLength;
  bool get hasPartialFailure =>
      _sourceStatuses.any((s) => s.isFailed || s.isPartial);
  bool get hasError => _unavailable != null || _errorMessage != null;
  bool get showNoMatches =>
      _hasSearched &&
      !_loading &&
      _items.isEmpty &&
      !hasError &&
      !hasPartialFailure;

  int _begin(String query, List<String>? sources, int? start, int? end) {
    _debounce?.cancel();
    final token = ++_sequence;
    _query = query;
    _sources = sources == null ? null : List.unmodifiable(sources);
    _start = start;
    _end = end;
    _items = const [];
    _sourceStatuses = const [];
    _unavailable = null;
    _errorMessage = null;
    _loading = canSearch;
    _loadingMore = false;
    _hasSearched = false;
    _hasMore = false;
    _nextIndex = null;
    _totalCount = null;
    notifyListeners();
    return token;
  }

  void scheduleSearch(String query,
      {List<String>? sources, int? start, int? end}) {
    if (_disposed) return;
    final token = _begin(query, sources, start, end);
    if (!canSearch) return;
    _debounce = Timer(debounceDuration, () => _fetch(token, 0));
  }

  Future<void> search(String query,
      {List<String>? sources, int? start, int? end}) async {
    if (_disposed) return;
    final token = _begin(query, sources, start, end);
    if (canSearch) await _fetch(token, 0);
  }

  Future<void> retry() =>
      search(_query, sources: _sources, start: _start, end: _end);

  Future<void> loadMore() async {
    if (_disposed ||
        _loading ||
        _loadingMore ||
        !_hasMore ||
        _nextIndex == null) return;
    final token = ++_sequence;
    final index = _nextIndex!;
    _loadingMore = true;
    _unavailable = null;
    _errorMessage = null;
    notifyListeners();
    await _fetch(token, index, append: true);
  }

  Future<void> _fetch(int token, int index, {bool append = false}) async {
    if (_disposed || token != _sequence) return;
    try {
      final result = await _loader(_query,
          sources: _sources,
          batchSize: batchSize,
          index: index,
          start: _start,
          end: _end);
      if (_disposed || token != _sequence) return;
      final envelope = result.envelope;
      if (result.isSuccess && envelope != null) {
        final seen = <String>{};
        _items = List.unmodifiable([
          if (append) ..._items,
          ...envelope.items,
        ].where((item) => seen.add(item.identityKey)));
        _sourceStatuses = List.unmodifiable(envelope.sources);
        _totalCount = envelope.totalCount;
        _hasMore = envelope.hasMore &&
            envelope.nextIndex != null &&
            envelope.nextIndex! > index;
        _nextIndex = _hasMore ? envelope.nextIndex : null;
      } else {
        _unavailable = result.unavailable;
        _errorMessage = result.isUnavailable
            ? null
            : (result.errorMessage ?? 'Search failed');
      }
      _hasSearched = true;
    } catch (_) {
      if (_disposed || token != _sequence) return;
      _errorMessage = 'Search failed';
      _hasSearched = true;
    } finally {
      if (!_disposed && token == _sequence) {
        _loading = false;
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Dismissing or opening a result prevents a late response from reopening it.
  void cancelPending() {
    if (_disposed) return;
    _debounce?.cancel();
    ++_sequence;
    _loading = false;
    _loadingMore = false;
  }

  @override
  void dispose() {
    cancelPending();
    _disposed = true;
    super.dispose();
  }
}
