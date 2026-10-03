import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareClassFanout.dart';
import 'package:tiler_app/data/tileShareRoster.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/tileShareRecipientsApi.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

/// A change to one task's assignee (a Project) that is going out or failed.
enum TaskChangePhase { working, failed }

class TaskChange extends Equatable {
  final TaskChangePhase phase;
  final String? reason;

  const TaskChange(this.phase, {this.reason});

  @override
  List<Object?> get props => [phase, reason];
}

class TileShareRosterState extends Equatable {
  /// The people, in order of first appearance, then adds on no task yet.
  final List<RosterRow> rows;

  /// Task changes still outstanding, by task (tilette) id; a task with
  /// nothing outstanding is absent.
  final Map<String, TaskChange> tasks;

  /// Delivery has been read from the cluster's activity.
  final bool deliveryLoaded;

  /// The last contact refused as already on the roster, to say so.
  final String? duplicate;

  const TileShareRosterState({
    this.rows = const <RosterRow>[],
    this.tasks = const <String, TaskChange>{},
    this.deliveryLoaded = false,
    this.duplicate,
  });

  @override
  List<Object?> get props => [rows, tasks, deliveryLoaded, duplicate];
}

/// A task's assignee change, kept to retry.
class _TaskOp {
  final Contact contact;
  final Set<String> keys;
  final String? replacingAssignmentId;
  TaskChangePhase phase = TaskChangePhase.working;
  String? reason;

  _TaskOp(this.contact, this.keys, this.replacingAssignmentId);
}

/// An add in progress or failed, for one person.
class _PendingAdd {
  final String localKey;
  final Contact contact;
  final Set<String> keys;
  RosterRowPhase phase = RosterRowPhase.adding;
  String? reason;

  _PendingAdd(this.localKey, this.contact, this.keys);
}

/// A share's roster as its owner manages it (redesign Steps 9.13 / 9.14):
/// people matched across the share's tasks, one cell per task - a Broadcast
/// has one task, a Class several.
///
/// * **Adding a person adds them to every task** they are not on yet (the
///   Class fan-out, O9 - one call per task, in order, never a second call for a
///   task they are already on). It shows at once; a task that refuses leaves
///   the person marked with the reason and **Retry**, the tasks that worked
///   stay done, and it is never reported as success (contact-input doc
///   3.3 / 3.4).
/// * **Removing a person removes them from every task**: they disappear at
///   once; a task that refuses brings them back, marked (a 404 counts as
///   removed).
/// * **One change at a time** for the whole share, in order (3.5).
/// * Someone already on the roster, or being added, is not added twice.
/// * A person on some tasks but not all is **incomplete**; [repair] adds them
///   to the rest.
/// * **Reassigning a task** (a Project, [assignTask]) adds the new person to
///   that one task first and then removes the old one, so a failure never
///   leaves the task with no one; a failed change stays on the task with the
///   reason and [retryTask] (which skips what already happened).
/// * The roster refreshes from each answer (an add answers with the task and
///   its recipients) and from the share's reloads ([sync]).
class TileShareRosterCubit extends Cubit<TileShareRosterState> {
  static const String _tag = 'TileShareRoster';

  final TileShareRecipientsSource _source;
  final String clusterId;
  List<TileShareTemplate> _tilettes;

  Map<String, (RecipientDelivery, String?)> _delivery =
      const <String, (RecipientDelivery, String?)>{};
  final List<_PendingAdd> _pending = <_PendingAdd>[];

  /// People being removed (their identities), hidden meanwhile.
  final List<Set<String>> _removing = <Set<String>>[];

  /// People a removal failed for, with the reason.
  final List<(Set<String>, String?)> _removeFailed = <(Set<String>, String?)>[];

  final Map<String, _TaskOp> _taskOps = <String, _TaskOp>{};

  Future<void> _queue = Future<void>.value();
  int _localIds = 0;
  bool _deliveryLoaded = false;
  String? _duplicate;

  TileShareRosterCubit({
    required TileShareRecipientsSource source,
    required this.clusterId,
    required List<TileShareTemplate> tilettes,
  })  : _source = source,
        _tilettes = List<TileShareTemplate>.of(tilettes),
        super(const TileShareRosterState()) {
    _rebuild();
  }

  // ---- delivery ------------------------------------------------------------------

  /// Reads how each recipient's invitation was delivered. A failure leaves the
  /// roster as it is.
  Future<void> loadDelivery() async {
    try {
      final events = await _source.clusterActivity(clusterId);
      _delivery = RosterDelivery.fromActivity(events);
      _deliveryLoaded = true;
      TileShareLog.d(_tag, 'delivery for $clusterId: ${_delivery.length} known');
      _rebuild();
    } catch (error) {
      TileShareLog.d(_tag, 'delivery for $clusterId failed: $error');
    }
  }

  // ---- reloading ----------------------------------------------------------------

  /// The share's tasks after a reload; adds not yet answered are kept and a
  /// removal in flight stays hidden.
  void sync(List<TileShareTemplate> tilettes) {
    _tilettes = List<TileShareTemplate>.of(tilettes);
    _rebuild();
  }

  // ---- adding -------------------------------------------------------------------

  /// Adds [contact] to every task; `false` when they are already on the roster
  /// or being added. Completes when every task has answered.
  Future<bool> add(Contact contact) {
    final Set<String> keys = ClassFanout.identityKeys(contact);
    if (keys.isEmpty) return Future<bool>.value(false);
    final bool known = state.rows.any((r) => r.identities.any(keys.contains)) ||
        _pending.any((p) => p.keys.any(keys.contains));
    if (known) {
      _duplicate = _labelOf(contact);
      TileShareLog.d(_tag, 'not adding $_duplicate: already on the roster');
      _rebuild();
      return Future<bool>.value(false);
    }
    _duplicate = null;
    final _PendingAdd add = _PendingAdd('local-${++_localIds}', contact, keys);
    _pending.add(add);
    _rebuild();
    return _enqueue(() => _runAdd(add)).then((_) => true);
  }

  /// Sends a failed add again, to the tasks still missing.
  Future<void> retryAdd(String key) {
    final _PendingAdd? add = _pendingFor(key);
    if (add == null || add.phase != RosterRowPhase.addFailed) {
      return Future<void>.value();
    }
    add.phase = RosterRowPhase.adding;
    add.reason = null;
    _rebuild();
    return _enqueue(() => _runAdd(add));
  }

  /// Adds an incomplete person to the tasks they are not on.
  Future<void> repair(String key) {
    final RosterRow? row = _row(key);
    if (row == null || row.contact == null || !row.isIncomplete) {
      return Future<void>.value();
    }
    if (_pendingFor(key) != null) return retryAdd(key);
    final _PendingAdd add = _PendingAdd(
        'local-${++_localIds}', row.contact!, ClassFanout.identityKeys(row.contact!));
    _pending.add(add);
    _rebuild();
    return _enqueue(() => _runAdd(add));
  }

  /// Drops a failed add; tasks it did reach keep the person.
  void dismiss(String key) {
    final _PendingAdd? add = _pendingFor(key);
    if (add == null || add.phase != RosterRowPhase.addFailed) return;
    _pending.remove(add);
    _rebuild();
  }

  Future<void> _runAdd(_PendingAdd add) async {
    int failed = 0;
    String? reason;
    for (final TileShareTemplate tilette in List<TileShareTemplate>.of(_tilettes)) {
      if (tilette.id == null || _holds(tilette, add.keys)) continue;
      try {
        final TileShareTemplate updated =
            await _source.addRecipient(tilette.id!, add.contact);
        _replaceTilette(updated);
        TileShareLog.d(_tag, 'added ${_labelOf(add.contact)} to ${tilette.id}');
        _rebuild();
      } catch (error) {
        failed++;
        reason ??= _reasonOf(error);
        TileShareLog.d(
            _tag, 'adding ${_labelOf(add.contact)} to ${tilette.id} failed: $error');
      }
    }
    if (failed == 0) {
      _pending.remove(add);
    } else {
      add.phase = RosterRowPhase.addFailed;
      add.reason = reason;
    }
    _rebuild();
  }

  // ---- removing -----------------------------------------------------------------

  /// Removes a person (by row key or one of their assignments) from every
  /// task: gone at once, back if a task refuses.
  Future<void> remove(String keyOrAssignment) {
    final RosterRow? row = state.rows
        .where((r) =>
            r.key == keyOrAssignment ||
            r.cells.any((c) => c.assignmentId == keyOrAssignment))
        .firstOrNull;
    if (row == null || row.assignmentId == null) return Future<void>.value();
    final Set<String> keys = row.identities;
    _removing.add(keys);
    _removeFailed.removeWhere((f) => f.$1.any(keys.contains));
    _rebuild();
    return _enqueue(() async {
      int failed = 0;
      String? reason;
      for (final RosterCell cell in row.cells.where((c) => c.isPresent)) {
        try {
          await _source.removeRecipient(cell.tiletteId, cell.assignmentId!);
          _dropAssignment(cell.tiletteId, cell.assignmentId!);
          TileShareLog.d(_tag, 'removed ${row.label} from ${cell.tiletteId}');
        } catch (error) {
          if (error is TileShareRecipientFailure &&
              error.kind == TileShareFailureKind.notFound) {
            _dropAssignment(cell.tiletteId, cell.assignmentId!);
            TileShareLog.d(
                _tag, '${row.label} was already gone from ${cell.tiletteId}');
          } else {
            failed++;
            reason ??= _reasonOf(error);
            TileShareLog.d(_tag,
                'removing ${row.label} from ${cell.tiletteId} failed: $error');
          }
        }
      }
      _removing.remove(keys);
      if (failed > 0) _removeFailed.add((keys, reason));
      _rebuild();
    });
  }

  // ---- one task's assignee (a Project) -------------------------------------------

  /// Gives task [tiletteId] to [contact], replacing [replacingAssignmentId]
  /// if given: the new person is added first, the old one removed after.
  /// Nothing is sent when [contact] already has the task.
  Future<void> assignTask(String tiletteId, Contact contact,
      {String? replacingAssignmentId}) {
    final Set<String> keys = ClassFanout.identityKeys(contact);
    final TileShareTemplate? tilette = _tilette(tiletteId);
    if (keys.isEmpty || tilette == null) return Future<void>.value();
    final bool holds = _holds(tilette, keys);
    final bool replacingThem = replacingAssignmentId == null ||
        _assignmentKeys(tilette, replacingAssignmentId).any(keys.contains);
    if (holds && replacingThem) {
      TileShareLog.d(
          _tag, '${_labelOf(contact)} already has $tiletteId; nothing to send');
      return Future<void>.value();
    }
    _taskOps[tiletteId] = _TaskOp(contact, keys, replacingAssignmentId);
    _rebuild();
    return _enqueue(() => _runTask(tiletteId));
  }

  /// Sends a failed task change again; what already happened is skipped.
  Future<void> retryTask(String tiletteId) {
    final _TaskOp? op = _taskOps[tiletteId];
    if (op == null || op.phase != TaskChangePhase.failed) {
      return Future<void>.value();
    }
    op.phase = TaskChangePhase.working;
    op.reason = null;
    _rebuild();
    return _enqueue(() => _runTask(tiletteId));
  }

  Future<void> _runTask(String tiletteId) async {
    final _TaskOp? op = _taskOps[tiletteId];
    if (op == null) return;
    try {
      TileShareTemplate? tilette = _tilette(tiletteId);
      if (tilette != null && !_holds(tilette, op.keys)) {
        final TileShareTemplate updated =
            await _source.addRecipient(tiletteId, op.contact);
        _replaceTilette(updated);
        TileShareLog.d(_tag, 'assigned ${_labelOf(op.contact)} to $tiletteId');
        _rebuild();
      }
      final String? old = op.replacingAssignmentId;
      tilette = _tilette(tiletteId);
      if (old != null &&
          tilette != null &&
          _assignmentKeys(tilette, old).isNotEmpty &&
          !_assignmentKeys(tilette, old).any(op.keys.contains)) {
        try {
          await _source.removeRecipient(tiletteId, old);
        } on TileShareRecipientFailure catch (failure) {
          if (failure.kind != TileShareFailureKind.notFound) rethrow;
        }
        _dropAssignment(tiletteId, old);
        TileShareLog.d(_tag, 'unassigned $old from $tiletteId');
      }
      _taskOps.remove(tiletteId);
    } catch (error) {
      op.phase = TaskChangePhase.failed;
      op.reason = _reasonOf(error);
      TileShareLog.d(_tag, 'changing $tiletteId failed: $error');
    }
    _rebuild();
  }

  // ---- building the rows -----------------------------------------------------------

  void _rebuild() {
    final List<RosterRow> people = RosterPeople.of(_tilettes, _delivery);
    // An add whose person is now on every task is done.
    _pending.removeWhere((p) {
      final RosterRow? person =
          people.where((r) => r.identities.any(p.keys.contains)).firstOrNull;
      return person != null &&
          !person.isIncomplete &&
          p.phase == RosterRowPhase.addFailed;
    });
    final List<RosterRow> rows = <RosterRow>[];
    for (final RosterRow person in people) {
      final Set<String> keys = person.identities;
      if (_removing.any((r) => r.any(keys.contains))) continue;
      final _PendingAdd? add =
          _pending.where((p) => p.keys.any(keys.contains)).firstOrNull;
      final (Set<String>, String?)? removeFailed =
          _removeFailed.where((f) => f.$1.any(keys.contains)).firstOrNull;
      rows.add(RosterRow(
        key: person.key,
        label: person.label,
        contact: person.contact,
        cells: person.cells,
        phase: add?.phase ??
            (removeFailed != null ? RosterRowPhase.removeFailed : RosterRowPhase.saved),
        failureReason: add?.reason ?? removeFailed?.$2,
      ));
    }
    for (final _PendingAdd add in _pending) {
      if (people.any((r) => r.identities.any(add.keys.contains))) continue;
      rows.add(RosterRow(
        key: add.localKey,
        label: _labelOf(add.contact),
        contact: add.contact,
        cells: <RosterCell>[
          for (final TileShareTemplate t in _tilettes)
            RosterCell(tiletteId: t.id ?? ''),
        ],
        phase: add.phase,
        failureReason: add.reason,
      ));
    }
    _emit(TileShareRosterState(
      rows: rows,
      tasks: <String, TaskChange>{
        for (final MapEntry<String, _TaskOp> e in _taskOps.entries)
          e.key: TaskChange(e.value.phase, reason: e.value.reason),
      },
      deliveryLoaded: _deliveryLoaded,
      duplicate: _duplicate,
    ));
  }

  // ---- helpers ------------------------------------------------------------------

  static bool _holds(TileShareTemplate tilette, Set<String> keys) {
    for (final DesignatedUser user
        in tilette.designatedUsers ?? const <DesignatedUser>[]) {
      final Contact? contact = ClassFanout.contactOfUser(user);
      if (contact != null &&
          ClassFanout.identityKeys(contact).any(keys.contains)) {
        return true;
      }
    }
    return false;
  }

  TileShareTemplate? _tilette(String id) =>
      _tilettes.where((t) => t.id == id).firstOrNull;

  /// The identity of whoever holds [assignmentId] on [tilette]; empty when no
  /// one does.
  static Set<String> _assignmentKeys(
      TileShareTemplate tilette, String assignmentId) {
    for (final DesignatedUser user
        in tilette.designatedUsers ?? const <DesignatedUser>[]) {
      if (RosterPeople.assignmentOf(user) == assignmentId) {
        final Contact? contact = ClassFanout.contactOfUser(user);
        return contact == null
            ? <String>{'assignment:$assignmentId'}
            : ClassFanout.identityKeys(contact);
      }
    }
    return const <String>{};
  }

  void _replaceTilette(TileShareTemplate updated) {
    _tilettes = <TileShareTemplate>[
      for (final TileShareTemplate t in _tilettes)
        t.id == updated.id ? updated : t,
    ];
  }

  void _dropAssignment(String tiletteId, String assignmentId) {
    for (final TileShareTemplate t in _tilettes) {
      if (t.id == tiletteId) {
        t.designatedUsers = <DesignatedUser>[
          for (final DesignatedUser u
              in t.designatedUsers ?? const <DesignatedUser>[])
            if (RosterPeople.assignmentOf(u) != assignmentId) u,
        ];
      }
    }
  }

  _PendingAdd? _pendingFor(String key) {
    final RosterRow? row = _row(key);
    for (final _PendingAdd p in _pending) {
      if (p.localKey == key) return p;
      if (row != null && row.identities.any(p.keys.contains)) return p;
    }
    return null;
  }

  RosterRow? _row(String key) =>
      state.rows.where((r) => r.key == key).firstOrNull;

  Future<void> _enqueue(Future<void> Function() change) {
    final Future<void> next = _queue.then((_) => change());
    _queue = next.catchError((Object _) {});
    return next;
  }

  static String _labelOf(Contact contact) {
    for (final String? v in [contact.email, contact.phoneNumber, contact.username]) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static String? _reasonOf(Object error) =>
      error is TileShareRecipientFailure ? error.reason : null;

  void _emit(TileShareRosterState next) {
    if (!isClosed) emit(next);
  }
}
