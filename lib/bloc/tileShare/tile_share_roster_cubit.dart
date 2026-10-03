import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

class TileShareRosterState extends Equatable {
  /// The recipients in the server's order, then adds not yet confirmed.
  final List<RosterRow> rows;

  /// Delivery has been read from the cluster's activity.
  final bool deliveryLoaded;

  /// The last contact refused as already on the roster (normalised), to say
  /// so; `null` otherwise.
  final String? duplicate;

  const TileShareRosterState({
    this.rows = const <RosterRow>[],
    this.deliveryLoaded = false,
    this.duplicate,
  });

  TileShareRosterState copyWith({
    List<RosterRow>? rows,
    bool? deliveryLoaded,
    String? duplicate,
    bool clearDuplicate = false,
  }) =>
      TileShareRosterState(
        rows: rows ?? this.rows,
        deliveryLoaded: deliveryLoaded ?? this.deliveryLoaded,
        duplicate: clearDuplicate ? null : (duplicate ?? this.duplicate),
      );

  @override
  List<Object?> get props => [rows, deliveryLoaded, duplicate];
}

/// One tilette's roster as its owner manages it (redesign Step 9.13).
///
/// * Rows are the tilette's recipients - answer, progress, and how their
///   invitation was delivered (each one's newest `invitation_*` event).
/// * **Adding shows at once** as "being added" and is never silently lost: a
///   refused or unanswered add stays on the roster as failed with the reason,
///   to retry or dismiss (contact-input doc 3.3 / 3.4). The roster refreshes
///   from the server's answer, so nothing reloads behind the user's typing.
/// * **One change at a time**: adds and removals go out in order, never in
///   parallel (3.5).
/// * Someone already on the roster, or already being added, is not added
///   twice.
/// * **A removal disappears at once**; if the server refuses it, the row comes
///   back where it was, marked. One the server no longer has counts as
///   removed.
class TileShareRosterCubit extends Cubit<TileShareRosterState> {
  static const String _tag = 'TileShareRoster';

  final TileShareRecipientsSource _source;
  final String clusterId;
  final String tiletteId;

  /// Delivery per assignment, kept to apply to rows that arrive later.
  Map<String, (RecipientDelivery, String?)> _delivery =
      const <String, (RecipientDelivery, String?)>{};

  /// Every change goes out after the previous one.
  Future<void> _queue = Future<void>.value();
  int _localIds = 0;

  TileShareRosterCubit({
    required TileShareRecipientsSource source,
    required this.clusterId,
    required this.tiletteId,
    required List<DesignatedUser> recipients,
  })  : _source = source,
        super(TileShareRosterState(
            rows: recipients.map(RosterRow.fromRecipient).toList()));

  // ---- delivery ------------------------------------------------------------------

  /// Reads how each recipient's invitation was delivered. A failure leaves the
  /// roster as it is.
  Future<void> loadDelivery() async {
    try {
      final events = await _source.clusterActivity(clusterId);
      _delivery = RosterDelivery.fromActivity(events);
      TileShareLog.d(_tag,
          'delivery for $clusterId: ${_delivery.length} of ${state.rows.length} known');
      _emit(state.copyWith(
          rows: state.rows.map(_withDelivery).toList(), deliveryLoaded: true));
    } catch (error) {
      TileShareLog.d(_tag, 'delivery for $clusterId failed: $error');
    }
  }

  RosterRow _withDelivery(RosterRow row) {
    final (RecipientDelivery, String?)? known =
        row.assignmentId == null ? null : _delivery[row.assignmentId];
    if (known == null) return row;
    return row.copyWith(delivery: known.$1, deliveryChannel: known.$2);
  }

  // ---- reloading ----------------------------------------------------------------

  /// The server's roster after a reload; adds not yet confirmed stay at the
  /// end, and a removal still in flight stays hidden.
  void sync(List<DesignatedUser> recipients) {
    final List<RosterRow> pending =
        state.rows.where((r) => r.assignmentId == null).toList();
    _emit(state.copyWith(rows: [
      ...recipients
          .map(RosterRow.fromRecipient)
          .where((r) => !_removing.contains(r.assignmentId))
          .map(_withDelivery),
      ...pending,
    ]));
  }

  // ---- adding -------------------------------------------------------------------

  /// Adds [contact]; `false` when they are already on the roster or being
  /// added. Completes when this add has been answered.
  Future<bool> add(Contact contact) {
    final String? label = _labelOf(contact);
    if (label == null) return Future<bool>.value(false);
    final String id = RosterRow.normalise(label);
    final bool known = state.rows.any((r) => r.identities.contains(id));
    if (known) {
      TileShareLog.d(_tag, 'not adding $label: already on the roster');
      _emit(state.copyWith(duplicate: id));
      return Future<bool>.value(false);
    }
    final RosterRow row = RosterRow(
      key: 'local-${++_localIds}',
      label: label,
      contact: contact,
      phase: RosterRowPhase.adding,
    );
    _emit(state.copyWith(rows: [...state.rows, row], clearDuplicate: true));
    return _enqueue(() => _sendAdd(row.key)).then((_) => true);
  }

  /// Sends a failed add again.
  Future<void> retryAdd(String key) {
    final RosterRow? row = _row(key);
    if (row == null || row.phase != RosterRowPhase.addFailed) {
      return Future<void>.value();
    }
    _replace(key, row.copyWith(phase: RosterRowPhase.adding, clearFailure: true));
    return _enqueue(() => _sendAdd(key));
  }

  /// Drops a failed add from the roster.
  void dismiss(String key) {
    final RosterRow? row = _row(key);
    if (row == null || row.phase != RosterRowPhase.addFailed) return;
    _emit(state.copyWith(
        rows: state.rows.where((r) => r.key != key).toList()));
  }

  Future<void> _sendAdd(String key) async {
    final RosterRow? row = _row(key);
    if (row == null || row.contact == null) return;
    try {
      final TileShareTemplate tilette =
          await _source.addRecipient(tiletteId, row.contact!);
      TileShareLog.d(_tag, 'added ${row.label} to $tiletteId');
      final List<RosterRow> others = state.rows
          .where((r) => r.assignmentId == null && r.key != key)
          .toList();
      _emit(state.copyWith(rows: [
        ...(tilette.designatedUsers ?? const <DesignatedUser>[])
            .map(RosterRow.fromRecipient)
            .where((r) => !_removing.contains(r.assignmentId))
            .map(_withDelivery),
        ...others,
      ]));
    } catch (error) {
      TileShareLog.d(_tag, 'adding ${row.label} failed: $error');
      _replace(
          key,
          row.copyWith(
              phase: RosterRowPhase.addFailed, failureReason: _reasonOf(error)));
    }
  }

  // ---- removing -----------------------------------------------------------------

  final Set<String?> _removing = <String?>{};

  /// Removes the recipient with [assignmentId]: gone at once, back in place
  /// if the server refuses.
  Future<void> remove(String assignmentId) {
    final int index =
        state.rows.indexWhere((r) => r.assignmentId == assignmentId);
    if (index < 0) return Future<void>.value();
    final RosterRow row = state.rows[index];
    _removing.add(assignmentId);
    _emit(state.copyWith(
        rows: state.rows.where((r) => r.assignmentId != assignmentId).toList()));
    return _enqueue(() async {
      try {
        await _source.removeRecipient(tiletteId, assignmentId);
        TileShareLog.d(_tag, 'removed ${row.label} from $tiletteId');
      } catch (error) {
        if (error is TileShareRecipientFailure &&
            error.kind == TileShareFailureKind.notFound) {
          TileShareLog.d(_tag, '${row.label} was already gone from $tiletteId');
        } else {
          TileShareLog.d(_tag, 'removing ${row.label} failed: $error');
          final List<RosterRow> rows = [...state.rows];
          rows.insert(
              index.clamp(0, rows.length),
              row.copyWith(
                  phase: RosterRowPhase.removeFailed,
                  failureReason: _reasonOf(error)));
          _emit(state.copyWith(rows: rows));
        }
      } finally {
        _removing.remove(assignmentId);
      }
    });
  }

  // ---- helpers ------------------------------------------------------------------

  Future<void> _enqueue(Future<void> Function() change) {
    final Future<void> next = _queue.then((_) => change());
    _queue = next.catchError((Object _) {});
    return next;
  }

  RosterRow? _row(String key) {
    for (final RosterRow r in state.rows) {
      if (r.key == key) return r;
    }
    return null;
  }

  void _replace(String key, RosterRow row) {
    _emit(state.copyWith(
        rows: state.rows.map((r) => r.key == key ? row : r).toList()));
  }

  static String? _labelOf(Contact contact) {
    for (final String? v in [contact.email, contact.phoneNumber]) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String? _reasonOf(Object error) =>
      error is TileShareRecipientFailure ? error.reason : null;

  void _emit(TileShareRosterState next) {
    if (!isClosed) emit(next);
  }
}
