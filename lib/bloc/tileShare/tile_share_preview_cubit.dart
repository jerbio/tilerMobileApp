import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_state.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileSharePendingAccept.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';

/// The accept preview for one assignment (redesign T21-T26): see how it would
/// land on the calendar, look at other arrangements, then accept - flexibly, or
/// locking one session - or decline.
///
/// * **Reading changes nothing.** The forecast, other arrangements and choosing
///   between them never accept or reserve anything.
/// * **Arrangements swap instantly.** Each alternative arrives with its whole
///   preview, so choosing one needs no request (a revise only for an option that
///   came without one). The session a lock would fix is re-bound on every swap.
/// * **Accepting is one `status` request** that runs the whole acceptance and
///   answers with the outcome - `completed`, or `rejected` / `needsreview` with a
///   reason - so there is no polling. Conflicts found before it queues are HTTP
///   409s, mapped to what to do next (stale preview, invalid session, already
///   answered, another response in progress).
/// * **An accept whose outcome was never seen is repeated, not re-made.** The
///   command (operation id, token, mode, session, interval) is saved before it is
///   sent; a timeout, a lost connection or a closed app leaves it pending, and
///   repeating the same command returns the stored outcome or resumes the
///   interrupted acceptance - never a second accept. Opening the preview again
///   resumes a pending command before anything else.
/// * One request of each kind at a time; a response that arrives after a newer
///   preview was generated, or after a newer choice, is dropped.
class TileSharePreviewCubit extends Cubit<TileSharePreviewState> {
  static const String _tag = 'TileSharePreview';

  final TileSharePreviewSource _source;
  final TileShareAssignmentsSource _assignments;
  final String assignmentId;
  final TileSharePendingAcceptStore? _pendingStore;
  final DateTime Function() _clock;

  /// Bumped by every (re)load, so an older response never lands on a newer
  /// preview.
  int _generation = 0;

  /// Bumped by every choice of arrangement, so a late revise is dropped.
  int _selectionSeq = 0;

  bool _optionsRunning = false;
  bool _submitting = false;
  bool _declining = false;
  bool _checking = false;
  PendingAccept? _pending;

  /// Where the task lands in the original and in every arrangement shown.
  final Set<String> _seen = <String>{};

  TileSharePreviewCubit({
    required TileSharePreviewSource source,
    required TileShareAssignmentsSource assignments,
    required this.assignmentId,
    TileSharePendingAcceptStore? pendingStore,
    DateTime Function()? clock,
  })  : _source = source,
        _assignments = assignments,
        _pendingStore = pendingStore,
        _clock = clock ?? DateTime.now,
        super(const TileSharePreviewState());

  bool _outdated(int generation) => isClosed || generation != _generation;

  // ---- loading ----------------------------------------------------------------

  /// Opens the preview: resumes an accept left unconfirmed if there is one,
  /// otherwise builds the forecast.
  Future<void> load() async {
    final int generation = ++_generation;
    _seen.clear();
    _emit(const TileSharePreviewState(phase: PreviewPhase.loading));
    PendingAccept? pending;
    try {
      pending = await _pendingStore?.read(assignmentId);
    } catch (error) {
      TileShareLog.d(_tag, 'reading the pending accept failed: $error');
    }
    if (_outdated(generation)) return;
    if (pending != null) {
      _pending = pending;
      TileShareLog.d(_tag,
          'resuming accept ${pending.operationId} for $assignmentId (${pending.mode.name})');
      await _send(pending, resumed: true);
      return;
    }
    await _loadPreview(generation);
  }

  /// "Generate new preview": a fresh forecast. The current preview stays on
  /// screen until the new one arrives, and is replaced whole; a failure keeps it.
  Future<void> regenerate() async {
    final TileSharePreviewState s = state;
    final bool allowed = s.phase == PreviewPhase.ready ||
        s.phase == PreviewPhase.unsupported ||
        s.phase == PreviewPhase.error;
    if (!allowed) return;
    final int generation = ++_generation;
    if (s.preview == null) {
      _emit(const TileSharePreviewState(phase: PreviewPhase.loading));
      await _loadPreview(generation);
      return;
    }
    _emit(s.copyWith(isRefreshing: true));
    await _loadPreview(generation, keepOnFailure: true);
  }

  Future<void> _loadPreview(int generation, {bool keepOnFailure = false}) async {
    try {
      final TileSharePreview preview = await _source.preview(assignmentId);
      if (_outdated(generation)) return;
      TileShareLog.d(
          _tag,
          'loaded preview for $assignmentId: viable=${preview.isViable} '
          'sessions=${preview.sessions.length} '
          'token=${preview.previewToken == null ? 'none' : 'yes'}'
          '${preview.isUnsupported ? ' unsupported=${preview.unsupportedReason!.name}' : ''}');
      _seen
        ..clear()
        ..add(_signature(preview.sessions));
      _emit(TileSharePreviewState(
        phase: preview.isUnsupported ? PreviewPhase.unsupported : PreviewPhase.ready,
        preview: preview,
        original: preview,
        highlightedSessionKey: _firstPlacedKey(preview),
      ));
    } catch (error) {
      if (_outdated(generation)) return;
      TileShareLog.d(_tag, 'preview for $assignmentId failed: $error');
      if (keepOnFailure && state.preview != null) {
        _emit(state.copyWith(isRefreshing: false, problem: PreviewProblem.loadFailed));
        return;
      }
      _emit(_failedLoad(error));
    }
  }

  TileSharePreviewState _failedLoad(Object error) {
    PreviewPhase phase = PreviewPhase.error;
    PreviewProblem problem = PreviewProblem.loadFailed;
    if (error is TileSharePreviewFailure) {
      switch (error.kind) {
        case PreviewFailureKind.notFound:
          phase = PreviewPhase.unavailable;
          problem = PreviewProblem.gone;
        case PreviewFailureKind.unavailable:
          phase = PreviewPhase.unavailable;
          problem = PreviewProblem.switchedOff;
        case PreviewFailureKind.unauthorized:
          problem = PreviewProblem.signInAgain;
        case PreviewFailureKind.invalid:
          problem = PreviewProblem.invalidRequest;
        case PreviewFailureKind.conflict:
        case PreviewFailureKind.server:
          break;
      }
    }
    return TileSharePreviewState(
        phase: phase,
        problem: problem,
        reason: error is TileSharePreviewFailure ? error.reason : null);
  }

  // ---- the session a lock would fix ----------------------------------------------

  /// Chooses which placed session "Accept and lock" would fix.
  void highlightSession(String sessionKey) {
    final TileSharePreview? preview = state.preview;
    if (preview == null || state.phase != PreviewPhase.ready) return;
    final bool placed = preview.sessions.any((s) =>
        s.sessionKey == sessionKey && s.viable && s.isProposed);
    if (placed) _emit(state.copyWith(highlightedSessionKey: sessionKey));
  }

  // ---- other arrangements --------------------------------------------------------

  /// Asks for the next page of other arrangements (the first, if none yet).
  /// Does nothing while a request is out, or when there is no more.
  Future<void> findOtherTimes() async {
    final TileSharePreviewState s = state;
    final TileSharePreview? original = s.original;
    if (!s.canFindOtherTimes || original == null) return;
    if (_optionsRunning) return;
    if (s.optionsStarted && s.nextOffset == null) return;
    final String? key = s.highlightedSessionKey ?? _firstPlacedKey(original);
    if (key == null) return;
    if (original.isExpiredAt(_clock())) {
      _emit(s.copyWith(
          problem: PreviewProblem.stale, reason: 'previewExpired'));
      return;
    }

    final int generation = _generation;
    _optionsRunning = true;
    _emit(s.copyWith(optionsLoad: OptionsLoad.loading));
    try {
      final PreviewOptionsPage page = await _source.options(
          assignmentId: assignmentId,
          previewToken: original.previewToken!,
          sessionKey: key,
          offset: s.optionsStarted ? (s.nextOffset ?? 0) : 0);
      if (_outdated(generation)) return;

      final List<PreviewOption> fresh = <PreviewOption>[];
      for (final PreviewOption option in page.options) {
        final bool known = state.options.any((o) => o.optionId == option.optionId) ||
            fresh.any((o) => o.optionId == option.optionId);
        if (known) continue;
        if (!_seen.add(_optionSignature(option, key))) continue;
        fresh.add(option);
      }
      TileShareLog.d(
          _tag,
          'other arrangements for $assignmentId: ${page.options.length} sent, '
          '${fresh.length} new, next=${page.nextOffset}');
      _emit(state.copyWith(
        options: <PreviewOption>[...state.options, ...fresh],
        optionsLoad: OptionsLoad.ready,
        optionsStarted: true,
        nextOffset: page.nextOffset,
        clearNextOffset: page.nextOffset == null,
        noDifferentFound: fresh.isEmpty,
      ));
    } catch (error) {
      if (_outdated(generation)) return;
      TileShareLog.d(_tag, 'other arrangements for $assignmentId failed: $error');
      if (error is TileSharePreviewFailure &&
          error.kind == PreviewFailureKind.conflict) {
        _emit(state.copyWith(
            optionsLoad: OptionsLoad.error,
            problem: PreviewProblem.stale,
            reason: error.reason));
      } else {
        _emit(state.copyWith(optionsLoad: OptionsLoad.error));
      }
    } finally {
      _optionsRunning = false;
    }
  }

  /// Shows [optionId]'s arrangement: the calendar strip, the time, and what
  /// Accept would send all follow it at once. Needs no request when the option
  /// carries its preview.
  Future<void> selectOption(String optionId) async {
    final TileSharePreviewState s = state;
    if (s.phase != PreviewPhase.ready) return;
    PreviewOption? option;
    for (final PreviewOption candidate in s.options) {
      if (candidate.optionId == optionId) option = candidate;
    }
    if (option == null) return;
    final int seq = ++_selectionSeq;
    final TileSharePreview? embedded = option.preview;
    if (embedded != null) {
      _swapTo(embedded, optionId);
      return;
    }
    final String? token = s.original?.previewToken;
    if (token == null) return;
    final int generation = _generation;
    _emit(s.copyWith(isSelecting: true, selectionFailed: false));
    try {
      final TileSharePreview revised = await _source.revise(
          assignmentId: assignmentId, previewToken: token, optionId: optionId);
      if (isClosed || generation != _generation || seq != _selectionSeq) return;
      _swapTo(revised, optionId);
    } catch (error) {
      if (isClosed || generation != _generation || seq != _selectionSeq) return;
      TileShareLog.d(_tag, 'choosing $optionId for $assignmentId failed: $error');
      if (error is TileSharePreviewFailure &&
          error.kind == PreviewFailureKind.conflict) {
        _emit(state.copyWith(
            isSelecting: false, problem: PreviewProblem.stale, reason: error.reason));
      } else {
        _emit(state.copyWith(isSelecting: false, selectionFailed: true));
      }
    }
  }

  /// Back to the preview as first forecast.
  void selectOriginal() {
    final TileSharePreview? original = state.original;
    if (original == null || state.phase != PreviewPhase.ready) return;
    _selectionSeq++;
    _swapTo(original, null);
  }

  void _swapTo(TileSharePreview preview, String? optionId) {
    final String? wanted = state.highlightedSessionKey;
    final bool keeps = wanted != null &&
        preview.sessions.any(
            (s) => s.sessionKey == wanted && s.viable && s.isProposed);
    final String? key = keeps ? wanted : _firstPlacedKey(preview);
    _emit(state.copyWith(
      preview: preview,
      selectedOptionId: optionId,
      clearSelectedOptionId: optionId == null,
      highlightedSessionKey: key,
      clearHighlightedSessionKey: key == null,
      isSelecting: false,
      selectionFailed: false,
      clearProblem: state.problem == PreviewProblem.sessionInvalid,
    ));
  }

  // ---- accepting -------------------------------------------------------------------

  /// Accept: every session at the reviewed times, flexible from then on.
  Future<void> accept() => _begin(TileShareAcceptanceMode.flexible);

  /// Accept and lock: every session, and the highlighted one fixed at the
  /// interval that was shown.
  Future<void> acceptAndLock() => _begin(TileShareAcceptanceMode.lockSession);

  Future<void> _begin(TileShareAcceptanceMode mode) async {
    final TileSharePreviewState s = state;
    if (_submitting) return;
    final bool locking = mode == TileShareAcceptanceMode.lockSession;
    if (locking ? !s.canAcceptAndLock : !s.canAccept) return;
    final TileSharePreview preview = s.preview!;
    if (preview.isExpiredAt(_clock())) {
      _emit(s.copyWith(problem: PreviewProblem.stale, reason: 'previewExpired'));
      return;
    }
    final PreviewBlock? target = locking ? s.lockTarget : null;
    final PendingAccept pending = PendingAccept(
      operationId: _source.newOperationId(),
      assignmentId: assignmentId,
      previewToken: preview.previewToken!,
      mode: mode,
      sessionKey: target?.sessionKey,
      lockedTimeLine:
          target == null ? null : TileShareLockedTimeLine.fromBlock(target),
      savedAtMs: _clock().millisecondsSinceEpoch,
    );
    // Saved before it is sent: if the answer is lost, this exact command is what
    // gets repeated.
    try {
      await _pendingStore?.save(pending);
    } catch (error) {
      TileShareLog.d(_tag, 'saving the pending accept failed: $error');
    }
    _pending = pending;
    await _send(pending);
  }

  /// Repeats the accept whose outcome was never seen - the same operation id,
  /// token, mode, session and interval - which returns the stored outcome or
  /// resumes the interrupted acceptance. Never a second accept.
  Future<void> retryAccept() async {
    if (state.phase != PreviewPhase.unconfirmed &&
        state.phase != PreviewPhase.adding) {
      return;
    }
    final PendingAccept? pending = _pending;
    if (pending == null) return;
    await _send(pending);
  }

  Future<void> _send(PendingAccept pending, {bool resumed = false}) async {
    if (_submitting) return;
    _submitting = true;
    _emit(state.copyWith(
        phase: PreviewPhase.submitting, clearProblem: true, clearReason: true));
    try {
      final TileShareOperation operation = await _source.accept(
        assignmentId: pending.assignmentId,
        previewToken: pending.previewToken,
        operationId: pending.operationId,
        mode: pending.mode,
        sessionKey: pending.sessionKey,
        lockedTimeLine: pending.lockedTimeLine,
      );
      TileShareLog.d(
          _tag,
          'accept ${pending.operationId} (${pending.mode.name}) -> '
          '${operation.state.name}'
          '${operation.reason == null ? '' : ' (${operation.reason})'}');
      await _settle(operation);
    } on TileSharePreviewFailure catch (failure) {
      TileShareLog.d(_tag, 'accept ${pending.operationId} failed: $failure');
      await _acceptRefused(failure, resumed: resumed);
    } catch (error) {
      TileShareLog.d(_tag, 'accept ${pending.operationId} not confirmed: $error');
      _emit(state.copyWith(phase: PreviewPhase.unconfirmed));
    } finally {
      _submitting = false;
    }
  }

  /// The server answered with an operation record: a final one ends the accept.
  Future<void> _settle(TileShareOperation operation) async {
    switch (operation.state) {
      case OperationState.completed:
        await _forgetPending();
        _emit(state.copyWith(
            phase: PreviewPhase.completed, operation: operation, clearProblem: true));
      case OperationState.needsReview:
        await _forgetPending();
        _emit(state.copyWith(
            phase: PreviewPhase.needsReview,
            operation: operation,
            reason: operation.reason,
            clearProblem: true));
      case OperationState.rejected:
        await _forgetPending();
        _emit(state.copyWith(
            phase: PreviewPhase.rejected,
            operation: operation,
            reason: operation.reason,
            clearProblem: true));
      case OperationState.preview:
      case OperationState.queued:
      case OperationState.applied:
      case OperationState.unknown:
        // Another request holds it: not final, and never treated as done.
        _emit(state.copyWith(phase: PreviewPhase.adding, operation: operation));
    }
  }

  /// The server refused before queueing anything, so there is nothing to repeat;
  /// or it did not answer, which is [PreviewPhase.unconfirmed].
  Future<void> _acceptRefused(TileSharePreviewFailure failure,
      {required bool resumed}) async {
    if (failure.kind == PreviewFailureKind.server) {
      _emit(state.copyWith(phase: PreviewPhase.unconfirmed));
      return;
    }
    await _forgetPending();
    switch (failure.kind) {
      case PreviewFailureKind.conflict:
        final String reason = failure.reason ?? 'conflict';
        switch (reason) {
          case 'assignmentChanged':
            _emit(state.copyWith(phase: PreviewPhase.rejected, reason: reason));
          case 'responseInProgress':
            _emit(state.copyWith(
                phase: PreviewPhase.adding,
                problem: PreviewProblem.responseInProgress,
                reason: reason));
          case 'operationMismatch':
            _emit(state.copyWith(
                phase: PreviewPhase.error,
                problem: PreviewProblem.invalidRequest,
                reason: reason));
          case 'invalidSession':
            if (resumed && state.preview == null) {
              await _loadPreview(++_generation);
            } else {
              _emit(state.copyWith(
                  phase: PreviewPhase.ready,
                  problem: PreviewProblem.sessionInvalid,
                  reason: reason));
            }
          default:
            // previewExpired, invalidProposal, scheduleChanged, ...: the preview
            // moved on. Keep the choice on screen; a fresh preview is needed.
            if (resumed && state.preview == null) {
              await _loadPreview(++_generation);
            } else {
              _emit(state.copyWith(
                  phase: PreviewPhase.ready,
                  problem: PreviewProblem.stale,
                  reason: reason));
            }
        }
      case PreviewFailureKind.notFound:
        _emit(state.copyWith(
            phase: PreviewPhase.unavailable, problem: PreviewProblem.gone));
      case PreviewFailureKind.unavailable:
        _emit(state.copyWith(
            phase: PreviewPhase.unavailable, problem: PreviewProblem.switchedOff));
      case PreviewFailureKind.unauthorized:
        _emit(state.copyWith(
            phase: PreviewPhase.error, problem: PreviewProblem.signInAgain));
      case PreviewFailureKind.invalid:
        _emit(state.copyWith(
            phase: PreviewPhase.error, problem: PreviewProblem.invalidRequest));
      case PreviewFailureKind.server:
        break;
    }
  }

  /// One read of where the accept stands: its operation, or - when another
  /// response holds the assignment and ours never queued - the assignment
  /// itself. A single read, never a loop.
  Future<void> checkStatus() async {
    final PreviewPhase phase = state.phase;
    if (_checking || _submitting) return;
    if (phase != PreviewPhase.adding && phase != PreviewPhase.unconfirmed) return;
    _checking = true;
    try {
      final PendingAccept? pending = _pending;
      if (pending != null) {
        try {
          final TileShareOperation operation =
              await _source.operation(pending.operationId);
          TileShareLog.d(_tag,
              'status of ${pending.operationId}: ${operation.state.name}');
          await _settle(operation);
        } on TileSharePreviewFailure catch (failure) {
          if (failure.kind == PreviewFailureKind.notFound) {
            // The server never saw it, so nothing was accepted: free to try again.
            await _forgetPending();
            if (state.preview != null) {
              _emit(state.copyWith(phase: PreviewPhase.ready, clearProblem: true));
            } else {
              await _loadPreview(++_generation);
            }
          }
        }
      } else {
        final TileShareAssignmentResponse response =
            await _source.response(assignmentId);
        if (response.isAccepted) {
          _emit(state.copyWith(
              phase: PreviewPhase.completed,
              operation: TileShareOperation(
                  operationId: '',
                  assignmentId: assignmentId,
                  state: OperationState.completed,
                  calendarId: response.calendarId),
              clearProblem: true));
        }
      }
    } catch (error) {
      TileShareLog.d(_tag, 'checking $assignmentId failed: $error');
    } finally {
      _checking = false;
    }
  }

  Future<void> _forgetPending() async {
    _pending = null;
    try {
      await _pendingStore?.clear(assignmentId);
    } catch (error) {
      TileShareLog.d(_tag, 'clearing the pending accept failed: $error');
    }
  }

  // ---- declining -------------------------------------------------------------------

  /// Declines through the ordinary response; no preview is involved.
  Future<void> decline() async {
    final TileSharePreviewState s = state;
    if (_declining || _submitting) return;
    if (s.phase != PreviewPhase.ready && s.phase != PreviewPhase.unsupported) {
      return;
    }
    _declining = true;
    _emit(s.copyWith(phase: PreviewPhase.submitting, declineFailed: false));
    try {
      await _assignments.respond(assignmentId, InvitationStatus.declined);
      _emit(state.copyWith(phase: PreviewPhase.declined));
    } catch (error) {
      TileShareLog.d(_tag, 'declining $assignmentId failed: $error');
      _emit(state.copyWith(phase: s.phase, declineFailed: true));
    } finally {
      _declining = false;
    }
  }

  // ---- helpers ---------------------------------------------------------------------

  static String? _firstPlacedKey(TileSharePreview preview) {
    for (final PreviewBlock s in preview.sessions) {
      if (s.viable && s.isProposed && s.sessionKey != null) return s.sessionKey;
    }
    return null;
  }

  /// Where the task's sessions land, to tell arrangements apart.
  static String _signature(List<PreviewBlock> sessions) {
    final List<String> parts = sessions
        .map((s) => '${s.sessionKey}:${s.startMs}:${s.endMs}')
        .toList()
      ..sort();
    return parts.join('|');
  }

  static String _optionSignature(PreviewOption option, String sessionKey) =>
      option.preview != null
          ? _signature(option.preview!.sessions)
          : '$sessionKey:${option.startMs}:${option.endMs}';

  void _emit(TileSharePreviewState next) {
    if (!isClosed) emit(next);
  }
}
