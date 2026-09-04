// DayGrid C11 — Google-Calendar-style overlap columns.
//
// Pure, widget-independent layout math. Given the tiles rendered in a day and
// the horizontal region a single tile would otherwise fill, assign each tile a
// column so that overlapping tiles sit side by side instead of stacking.
//
// Clustering uses the strict `TimeRange.isInterfering` rule (tile A blocks tile
// B only when A.end > B.start && B.end > A.start), so *touching* intervals
// (A.end == B.start) never share a conflict — a later tile may reuse a column
// the instant the previous tile in it has ended.

import 'package:tiler_app/data/timeRangeMix.dart';

/// The horizontal placement of a single tile inside its overlap cluster.
class TileColumnLayout {
  /// Left edge (px) of the tile within the grid's content region.
  final double left;

  /// Width (px) the tile occupies — shared by every tile in its cluster.
  final double width;

  const TileColumnLayout({required this.left, required this.width});
}

/// C11: pure overlap-column layout.
///
/// [assign] groups [tiles] into maximal clusters of transitively overlapping
/// tiles, assigns each tile the leftmost free column in its cluster (classic
/// interval partitioning), and gives every tile in a cluster a shared width so
/// the cluster fills the region exactly. A tile with no overlaps is its own
/// one-column cluster and therefore keeps the full `[left, left + width]`
/// region — preserving the pre-C11 single-tile geometry.
///
/// Deferred (P2): per-tile "expand over ended columns" (a later-starting tile
/// becomes wider when the columns it overlaps have already ended). The
/// shared-width model here is the predictable v1 and matches the grid's
/// existing full-region width.
class OverlapColumns {
  OverlapColumns._();

  /// Breathing room (px) between adjacent columns in a cluster. Ignored for a
  /// one-column cluster (a lone tile spans the full region).
  static const double defaultGap = 2.0;

  /// Computes a [TileColumnLayout] for every tile, keyed by `keyOf(tile)`.
  ///
  /// [left] / [width] describe the full available horizontal region (the same
  /// region a single, non-overlapping tile currently fills). Returns a map
  /// covering every input tile; empty when [tiles] is empty or [width] <= 0
  /// (callers then fall back to the full region).
  static Map<K, TileColumnLayout> assign<K, T extends TimeRange>({
    required List<T> tiles,
    required K Function(T tile) keyOf,
    required double left,
    required double width,
    double gap = defaultGap,
  }) {
    final result = <K, TileColumnLayout>{};
    if (tiles.isEmpty || width <= 0) {
      return result;
    }

    // Deterministic order: earliest start, then earliest end, then key. Keeps
    // the layout stable for equal intervals regardless of input order.
    final ordered = List<T>.of(tiles);
    ordered.sort((a, b) {
      final byStart = _startMs(a).compareTo(_startMs(b));
      if (byStart != 0) return byStart;
      final byEnd = _endMs(a).compareTo(_endMs(b));
      if (byEnd != 0) return byEnd;
      return keyOf(a).toString().compareTo(keyOf(b).toString());
    });

    // Sweep into overlap clusters. A tile joins the running cluster while it
    // overlaps the cluster's furthest extent (start < maxEnd); otherwise —
    // including the touching case (start == maxEnd) — it opens a new one.
    final clusters = <List<T>>[];
    var clusterEnd = 0;
    for (final tile in ordered) {
      if (clusters.isEmpty || _startMs(tile) >= clusterEnd) {
        clusters.add(<T>[tile]);
        clusterEnd = _endMs(tile);
      } else {
        clusters.last.add(tile);
        if (_endMs(tile) > clusterEnd) {
          clusterEnd = _endMs(tile);
        }
      }
    }

    for (final cluster in clusters) {
      _assignCluster(result, cluster, keyOf, left, width, gap);
    }
    return result;
  }

  /// Greedy column assignment + shared width for one cluster (already sorted
  /// by start by the caller).
  static void _assignCluster<K, T extends TimeRange>(
    Map<K, TileColumnLayout> result,
    List<T> cluster,
    K Function(T) keyOf,
    double left,
    double width,
    double gap,
  ) {
    // `columns[i]` = the end-ms of the topmost (latest-ending) tile in col i.
    final columns = <int>[];
    final columnOf = <T, int>{};
    for (final tile in cluster) {
      final start = _startMs(tile);
      var col = -1;
      for (var i = 0; i < columns.length; i++) {
        if (columns[i] <= start) {
          col = i; // leftmost column free at this tile's start
          break;
        }
      }
      if (col == -1) {
        col = columns.length;
        columns.add(0);
      }
      columns[col] = _endMs(tile);
      columnOf[tile] = col;
    }

    final columnCount = columns.length;
    final colWidth = _sharedWidth(width, columnCount, gap);
    for (final tile in cluster) {
      final col = columnOf[tile]!;
      result[keyOf(tile)] = TileColumnLayout(
        left: left + col * (colWidth + gap),
        width: colWidth,
      );
    }
  }

  /// Shared column width for a [columnCount]-column cluster inside [width],
  /// leaving [gap] between neighbouring columns.
  static double _sharedWidth(double width, int columnCount, double gap) {
    if (columnCount <= 1) {
      return width;
    }
    return (width - (columnCount - 1) * gap) / columnCount;
  }

  static int _startMs(TimeRange tile) => tile.start ?? 0;
  static int _endMs(TimeRange tile) => tile.end ?? 0;
}