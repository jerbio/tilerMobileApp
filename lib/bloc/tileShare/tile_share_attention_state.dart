import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/designatedTile.dart';
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

/// What went wrong with an inline answer to an invitation.
enum AttentionRespondFailureKind {
  /// The server refused (or could not be reached for) some or all of the
  /// answers; those invitations are back on the list.
  answer,

  /// The answers were saved but the schedule could not be refreshed, so the
  /// new tiles may take a moment to appear.
  scheduleRefresh,
}

/// An inline answer that did not fully work.
class AttentionRespondFailure extends Equatable {
  final String itemId;

  /// What the user was doing: accepting or declining.
  final InvitationStatus status;
  final AttentionRespondFailureKind kind;

  const AttentionRespondFailure(this.itemId, this.status, this.kind);

  @override
  List<Object?> get props => [itemId, status, kind];
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
  final AttentionRespondFailure? respondFailure;

  const TileShareAttentionState({
    this.load = AttentionLoad.initial,
    this.isRefreshing = false,
    this.items = const <AttentionItem>[],
    this.failedSources = const <AttentionSource>{},
    this.dismissFailure,
    this.respondFailure,
    this.answerRevision = 0,
  });

  /// Goes up each time an inline answer has finished being sent (saved or
  /// refused), so another screen showing the same invitations knows to reload.
  final int answerRevision;

  TileShareAttentionState copyWith({
    AttentionLoad? load,
    bool? isRefreshing,
    List<AttentionItem>? items,
    Set<AttentionSource>? failedSources,
    AttentionDismissFailure? dismissFailure,
    bool clearDismissFailure = false,
    AttentionRespondFailure? respondFailure,
    bool clearRespondFailure = false,
    int? answerRevision,
  }) {
    return TileShareAttentionState(
      load: load ?? this.load,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      items: items ?? this.items,
      failedSources: failedSources ?? this.failedSources,
      dismissFailure:
          clearDismissFailure ? null : (dismissFailure ?? this.dismissFailure),
      respondFailure:
          clearRespondFailure ? null : (respondFailure ?? this.respondFailure),
      answerRevision: answerRevision ?? this.answerRevision,
    );
  }

  @override
  List<Object?> get props =>
      [
        load,
        isRefreshing,
        items,
        failedSources,
        dismissFailure,
        respondFailure,
        answerRevision
      ];
}
