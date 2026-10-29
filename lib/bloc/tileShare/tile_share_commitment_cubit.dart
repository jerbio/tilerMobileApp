import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

/// An answer that did not all go through.
class CommitmentFailure extends Equatable {
  final InvitationStatus status;

  /// How many of the tasks in that answer went through.
  final int answered;
  final int total;

  /// The tasks still to answer, in order (the one that failed first).
  final List<String> remaining;

  const CommitmentFailure({
    required this.status,
    required this.answered,
    required this.total,
    required this.remaining,
  });

  @override
  List<Object?> get props => [status, answered, total, remaining];
}

class TileShareCommitmentState extends Equatable {
  /// My answer on each of my tasks (designated tile templates), in order.
  final Map<String, InvitationStatus> statuses;

  /// Tasks whose answer is going out.
  final Set<String> sending;
  final CommitmentFailure? failure;

  /// An accept went through but the schedule could not refresh yet.
  final bool scheduleRefreshFailed;

  const TileShareCommitmentState({
    this.statuses = const <String, InvitationStatus>{},
    this.sending = const <String>{},
    this.failure,
    this.scheduleRefreshFailed = false,
  });

  /// My tasks not answered yet, in order.
  List<String> get pending => <String>[
        for (final MapEntry<String, InvitationStatus> e in statuses.entries)
          if (e.value == InvitationStatus.none) e.key,
      ];

  @override
  List<Object?> get props =>
      [statuses, sending, failure, scheduleRefreshFailed];
}

/// Answering a share I was invited to, from its detail (redesign §5.8, T20):
/// accept or decline one task, or every task I hold at once (a Class).
///
/// * Answers go out **one task at a time, in order**; a task that refuses
///   stops there - it and the rest stay pending, the failure says how many
///   went through, and [retry] sends only those (never reported as done).
/// * An accept that went through refreshes the schedule once, after the
///   answers; a refresh that fails is said separately and never undoes them.
/// * An answer already going out is not sent again.
class TileShareCommitmentCubit extends Cubit<TileShareCommitmentState> {
  static const String _tag = 'TileShareCommitment';

  final TileShareAssignmentsSource _assignments;

  /// Called after answers went out, so the share can reload.
  final void Function()? onAnswered;

  TileShareCommitmentCubit({
    required TileShareAssignmentsSource assignments,
    required List<DesignatedTile> mine,
    this.onAnswered,
  })  : _assignments = assignments,
        super(TileShareCommitmentState(statuses: _statusesOf(mine)));

  static Map<String, InvitationStatus> _statusesOf(
          List<DesignatedTile> tiles) =>
      <String, InvitationStatus>{
        for (final DesignatedTile t in tiles)
          if ((t.id ?? '').isNotEmpty)
            t.id!: DesignatedTile.stringToInvitationStatus(
                    t.invitationStatus ?? '') ??
                InvitationStatus.none,
      };

  /// The share reloaded: the server's answers, keeping what is going out.
  void sync(List<DesignatedTile> mine) {
    final Map<String, InvitationStatus> fresh = _statusesOf(mine);
    for (final String id in state.sending) {
      final InvitationStatus? kept = state.statuses[id];
      if (kept != null && fresh.containsKey(id)) fresh[id] = kept;
    }
    _emit(TileShareCommitmentState(
      statuses: fresh,
      sending: state.sending,
      failure: state.failure,
      scheduleRefreshFailed: state.scheduleRefreshFailed,
    ));
  }

  /// Sends [status] for [ids], in order. Ids already going out are skipped.
  Future<void> respond(List<String> ids, InvitationStatus status) async {
    final List<String> todo =
        ids.where((id) => !state.sending.contains(id)).toList();
    TileShareLog.d(
        _tag,
        'response requested status=${status.name} ids=$ids '
        'toSend=$todo alreadySending=${state.sending.toList()}');
    if (todo.isEmpty) return;
    _emit(TileShareCommitmentState(
      statuses: state.statuses,
      sending: <String>{...state.sending, ...todo},
      scheduleRefreshFailed: false,
    ));
    int answered = 0;
    CommitmentFailure? failure;
    for (int i = 0; i < todo.length; i++) {
      final String id = todo[i];
      try {
        TileShareLog.d(_tag, 'sending $id: ${status.name}');
        final DesignatedTile? result = await _assignments.respond(id, status);
        answered++;
        TileShareLog.d(
            _tag,
            'answered $id: ${status.name}; '
            'returnedId=${result?.id ?? '-'} '
            'returnedStatus=${result?.invitationStatus ?? '-'}');
        _emit(TileShareCommitmentState(
          statuses: <String, InvitationStatus>{...state.statuses, id: status},
          sending: <String>{...state.sending}..remove(id),
        ));
      } catch (error) {
        TileShareLog.d(_tag,
            'answering $id status=${status.name} failed: ${TileShareLog.describe(error)}');
        failure = CommitmentFailure(
          status: status,
          answered: answered,
          total: todo.length,
          remaining: todo.sublist(i),
        );
        break;
      }
    }
    bool refreshFailed = false;
    if (status == InvitationStatus.accepted && answered > 0) {
      try {
        TileShareLog.d(_tag, 'refreshing schedule after $answered accepts');
        await _assignments.afterAccept();
        TileShareLog.d(_tag, 'schedule refreshed after accepting');
      } catch (error) {
        refreshFailed = true;
        TileShareLog.d(_tag,
            'schedule refresh after accepting failed: ${TileShareLog.describe(error)}');
      }
    }
    _emit(TileShareCommitmentState(
      statuses: state.statuses,
      sending: <String>{...state.sending}..removeAll(todo),
      failure: failure,
      scheduleRefreshFailed: refreshFailed,
    ));
    TileShareLog.d(
        _tag,
        'response finished status=${status.name} answered=$answered/${todo.length} '
        'remaining=${failure?.remaining ?? []} scheduleRefreshFailed=$refreshFailed');
    if (answered > 0) onAnswered?.call();
  }

  /// Sends the tasks a failed answer left pending.
  Future<void> retry() {
    final CommitmentFailure? failure = state.failure;
    if (failure == null) return Future<void>.value();
    return respond(failure.remaining, failure.status);
  }

  void _emit(TileShareCommitmentState next) {
    if (!isClosed) emit(next);
  }
}
