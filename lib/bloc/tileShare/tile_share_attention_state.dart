import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/tileShareAttention.dart';

/// Where the inbox is in its life.
enum AttentionLoad {
  /// Nothing requested yet.
  initial,

  /// The first load is in flight (there is nothing to show yet).
  loading,

  /// At least one load has finished; [TileShareAttentionState.items] is what
  /// the sources gave (possibly stale for a source that failed).
  ready,
}

/// The three places the inbox reads from.
enum AttentionSource { invitations, activity, received }

/// A dismissal (or an undo of one) the server refused; the item was put back
/// (or hidden again) and the UI can say so.
class AttentionDismissFailure extends Equatable {
  final String itemId;

  /// The failed action was an undo (the item is hidden again), not a dismissal
  /// (the item is back).
  final bool wasUndo;

  const AttentionDismissFailure(this.itemId, {this.wasUndo = false});

  @override
  List<Object?> get props => [itemId, wasUndo];
}

class TileShareAttentionState extends Equatable {
  final AttentionLoad load;

  /// A reload is in flight while [items] stays on screen.
  final bool isRefreshing;
  final List<AttentionItem> items;

  /// Sources whose last load failed. Their last-known data is still used, so
  /// one source failing never hides the others.
  final Set<AttentionSource> failedSources;
  final AttentionDismissFailure? dismissFailure;

  const TileShareAttentionState({
    this.load = AttentionLoad.initial,
    this.isRefreshing = false,
    this.items = const <AttentionItem>[],
    this.failedSources = const <AttentionSource>{},
    this.dismissFailure,
  });

  TileShareAttentionState copyWith({
    AttentionLoad? load,
    bool? isRefreshing,
    List<AttentionItem>? items,
    Set<AttentionSource>? failedSources,
    AttentionDismissFailure? dismissFailure,
    bool clearDismissFailure = false,
  }) {
    return TileShareAttentionState(
      load: load ?? this.load,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      items: items ?? this.items,
      failedSources: failedSources ?? this.failedSources,
      dismissFailure:
          clearDismissFailure ? null : (dismissFailure ?? this.dismissFailure),
    );
  }

  @override
  List<Object?> get props =>
      [load, isRefreshing, items, failedSources, dismissFailure];
}
