import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/tileSharePreview.dart';

/// Where the accept preview is in its life.
enum PreviewPhase {
  /// Nothing asked yet.
  idle,

  /// The first forecast is being built (or an interrupted accept resumed).
  loading,

  /// A preview is showing. It may be one that cannot be accepted (does not fit,
  /// or stale): see [TileSharePreviewState.canAccept] and
  /// [TileSharePreviewState.problem].
  ready,

  /// The server did not try: already accepted, no future deadline, or
  /// constraints a preview cannot honour.
  unsupported,

  /// Gone (no access any more) or switched off on the server.
  unavailable,

  /// A request that could not be completed; [TileSharePreviewState.problem]
  /// says which.
  error,

  /// An accept or a decline is going out.
  submitting,

  /// Accepted, and scheduling confirmed.
  completed,

  /// Accepted, but scheduling could not be confirmed.
  needsReview,

  /// Not accepted (the server answered with a reason).
  rejected,

  /// Declined.
  declined,

  /// Another response holds the operation; one manual check settles it.
  adding,

  /// An accept was sent and its outcome was never seen (timeout, lost
  /// connection, closed app). Repeating the same command, or one check, settles
  /// it.
  unconfirmed,
}

/// What is wrong with the page as a whole.
enum PreviewProblem {
  /// The preview has moved on (expired, schedule or assignment changed): the
  /// selection is kept to look at, a fresh preview is needed to accept.
  stale,

  /// The session chosen for a lock is no longer valid; accepting flexibly is
  /// still possible.
  sessionInvalid,

  /// Another response is in progress for this assignment.
  responseInProgress,

  /// Signed out; sign in again.
  signInAgain,

  /// The server did not accept the request as made.
  invalidRequest,

  /// A forecast could not be built.
  loadFailed,

  /// Previews are switched off on the server.
  switchedOff,

  /// No access any more, or no longer there.
  gone,
}

enum OptionsLoad { idle, loading, ready, error }

class TileSharePreviewState extends Equatable {
  final PreviewPhase phase;

  /// The arrangement being shown: the original, or the chosen alternative.
  final TileSharePreview? preview;

  /// The preview as first forecast (kept to go back to).
  final TileSharePreview? original;

  /// The chosen alternative's id; `null` while the original is shown.
  final String? selectedOptionId;

  final List<PreviewOption> options;
  final OptionsLoad optionsLoad;

  /// At least one page of alternatives has been asked for.
  final bool optionsStarted;

  /// Where the next page starts; `null` once there is no more.
  final int? nextOffset;

  /// The last page added nothing new.
  final bool noDifferentFound;

  /// The session a lock would fix.
  final String? highlightedSessionKey;

  /// A new preview is being generated while this one stays on screen.
  final bool isRefreshing;

  /// A chosen alternative is being revised to (only when it came without its
  /// preview).
  final bool isSelecting;
  final bool selectionFailed;
  final bool declineFailed;
  final PreviewProblem? problem;

  /// The server's reason behind [problem] or an outcome.
  final String? reason;

  /// The accept's operation record, once there is one.
  final TileShareOperation? operation;

  const TileSharePreviewState({
    this.phase = PreviewPhase.idle,
    this.preview,
    this.original,
    this.selectedOptionId,
    this.options = const <PreviewOption>[],
    this.optionsLoad = OptionsLoad.idle,
    this.optionsStarted = false,
    this.nextOffset,
    this.noDifferentFound = false,
    this.highlightedSessionKey,
    this.isRefreshing = false,
    this.isSelecting = false,
    this.selectionFailed = false,
    this.declineFailed = false,
    this.problem,
    this.reason,
    this.operation,
  });

  /// The placed session a lock would fix.
  PreviewBlock? get lockTarget {
    final String? key = highlightedSessionKey;
    if (key == null) return null;
    for (final PreviewBlock session in preview?.sessions ?? const <PreviewBlock>[]) {
      if (session.sessionKey == key && session.viable && session.isProposed) {
        return session;
      }
    }
    return null;
  }

  bool get _acceptable =>
      phase == PreviewPhase.ready &&
      preview != null &&
      preview!.canAccept &&
      problem != PreviewProblem.stale &&
      !isRefreshing &&
      !isSelecting;

  /// Accept flexibly: there is a valid, stored, current preview.
  bool get canAccept => _acceptable;

  /// Accept and lock: as [canAccept], with a placed session to fix.
  bool get canAcceptAndLock =>
      _acceptable &&
      problem != PreviewProblem.sessionInvalid &&
      lockTarget != null;

  /// Other arrangements can be asked for.
  bool get canFindOtherTimes =>
      phase == PreviewPhase.ready &&
      original != null &&
      original!.canFindOtherTimes &&
      problem != PreviewProblem.stale;

  /// More alternatives may exist (before the first page, assume so).
  bool get hasMoreOptions => !optionsStarted || nextOffset != null;

  TileSharePreviewState copyWith({
    PreviewPhase? phase,
    TileSharePreview? preview,
    TileSharePreview? original,
    String? selectedOptionId,
    bool clearSelectedOptionId = false,
    List<PreviewOption>? options,
    OptionsLoad? optionsLoad,
    bool? optionsStarted,
    int? nextOffset,
    bool clearNextOffset = false,
    bool? noDifferentFound,
    String? highlightedSessionKey,
    bool clearHighlightedSessionKey = false,
    bool? isRefreshing,
    bool? isSelecting,
    bool? selectionFailed,
    bool? declineFailed,
    PreviewProblem? problem,
    bool clearProblem = false,
    String? reason,
    bool clearReason = false,
    TileShareOperation? operation,
    bool clearOperation = false,
  }) =>
      TileSharePreviewState(
        phase: phase ?? this.phase,
        preview: preview ?? this.preview,
        original: original ?? this.original,
        selectedOptionId: clearSelectedOptionId
            ? null
            : (selectedOptionId ?? this.selectedOptionId),
        options: options ?? this.options,
        optionsLoad: optionsLoad ?? this.optionsLoad,
        optionsStarted: optionsStarted ?? this.optionsStarted,
        nextOffset: clearNextOffset ? null : (nextOffset ?? this.nextOffset),
        noDifferentFound: noDifferentFound ?? this.noDifferentFound,
        highlightedSessionKey: clearHighlightedSessionKey
            ? null
            : (highlightedSessionKey ?? this.highlightedSessionKey),
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSelecting: isSelecting ?? this.isSelecting,
        selectionFailed: selectionFailed ?? this.selectionFailed,
        declineFailed: declineFailed ?? this.declineFailed,
        problem: clearProblem ? null : (problem ?? this.problem),
        reason: clearReason ? null : (reason ?? this.reason),
        operation: clearOperation ? null : (operation ?? this.operation),
      );

  @override
  List<Object?> get props => [
        phase,
        preview,
        original,
        selectedOptionId,
        options,
        optionsLoad,
        optionsStarted,
        nextOffset,
        noDifferentFound,
        highlightedSessionKey,
        isRefreshing,
        isSelecting,
        selectionFailed,
        declineFailed,
        problem,
        reason,
        operation,
      ];
}
