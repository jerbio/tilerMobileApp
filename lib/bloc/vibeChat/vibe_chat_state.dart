part of 'vibe_chat_bloc.dart';

enum VibeChatStep {
  initial,
  loading,
  loadingMoreMessages,
  loadingSessions,
  loadingMoreSessions,
  loaded,
  sending,
  recording,
  transcribing,
  loadingPreview,
  previewLoaded,
  error,
}

class VibeChatState extends Equatable {
  final VibeChatStep step;
  final VibeSession? currentSession;
  final List<VibeMessage> messages;
  final bool hasMoreMessages;
  final int currentIndex;
  final String? error;
  final String? transcribedText;
  final List<VibeSession> sessions;
  final bool shouldShowAcceptButton;
  final bool hasMoreSessions;
  final int currentSessionIndex;
  final List<SubCalendarEvent>? previewTiles;
  final String? selectedActionEntityId;

  /// Ordered TileCast actions for the active request, used to drive the
  /// preview carousel and the navigable action list.
  final List<VibePreviewAction> previewActions;

  /// Index of the currently displayed TileCast carousel page.
  final int currentPreviewIndex;

  /// Request-level TileCast preview carrying readiness/staleness metadata.
  final VibeRequestPreview? previewBatch;

  /// Latest known TileCast readiness per request id, populated by background
  /// polling so the action list can reflect whether a preview is tappable.
  final Map<String, VibeRequestPreview> tileCastStatusByRequest;

  const VibeChatState({
    this.step = VibeChatStep.initial,
    this.currentSession ,
    this.messages = const [],
    this.hasMoreMessages = false,
    this.currentIndex = 0,
    this.error,
    this.transcribedText,
    this.sessions= const[],
    this.shouldShowAcceptButton=false,
    this.hasMoreSessions = false,
    this.currentSessionIndex = 0,
    this.previewTiles,
    this.selectedActionEntityId,
    this.previewActions = const [],
    this.currentPreviewIndex = 0,
    this.previewBatch,
    this.tileCastStatusByRequest = const {},
  });

  /// The TileCast action currently focused in the carousel, or null when the
  /// index is out of range / there are no actions.
  VibePreviewAction? get currentPreviewAction =>
      (currentPreviewIndex >= 0 && currentPreviewIndex < previewActions.length)
          ? previewActions[currentPreviewIndex]
          : null;

  /// Readiness state of the active TileCast preview batch.
  PreviewState get previewState => previewBatch?.state ?? PreviewState.unknown;

  /// Whether the active TileCast preview no longer reflects the live schedule.
  bool get isPreviewStale => previewBatch?.isStale ?? false;

  /// Latest known TileCast readiness for [requestId], or null when the request
  /// has not been polled yet.
  VibeRequestPreview? tileCastStatusFor(String? requestId) =>
      requestId == null ? null : tileCastStatusByRequest[requestId];

  /// Server-reported readiness state for [requestId]'s TileCast preview.
  PreviewState tileCastStateFor(String? requestId) =>
      tileCastStatusFor(requestId)?.state ?? PreviewState.unknown;

  /// Whether [requestId]'s TileCast preview has finished generating and can be
  /// opened without waiting.
  bool isTileCastReadyFor(String? requestId) =>
      tileCastStateFor(requestId) == PreviewState.ready;

  /// Whether [requestId]'s TileCast preview is still openable but no longer
  /// reflects the live schedule (a schedule change happened after it was
  /// generated). This is informational only — it must not block loading.
  bool isTileCastStaleFor(String? requestId) =>
      tileCastStatusFor(requestId)?.isStale ?? false;

  VibeChatState copyWith({
    VibeChatStep? step,
    VibeSession? currentSession,
    List<VibeMessage>? messages,
    bool? hasMoreMessages,
    int? currentIndex,
    String? error,
    String? transcribedText,
    List<VibeSession>? sessions,
    bool? shouldShowAcceptButton,
    bool? hasMoreSessions,
    int? currentSessionIndex,
    List<SubCalendarEvent>? previewTiles,
    String? selectedActionEntityId,
    List<VibePreviewAction>? previewActions,
    int? currentPreviewIndex,
    VibeRequestPreview? previewBatch,
    Map<String, VibeRequestPreview>? tileCastStatusByRequest,
  }) {
    return VibeChatState(
      step: step ?? this.step,
      currentSession: currentSession ?? this.currentSession,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error ?? this.error,
      transcribedText: transcribedText ?? this.transcribedText,
      sessions: sessions ?? this.sessions,
      shouldShowAcceptButton: shouldShowAcceptButton ?? this.shouldShowAcceptButton,
      hasMoreSessions: hasMoreSessions ?? this.hasMoreSessions,
      currentSessionIndex: currentSessionIndex ?? this.currentSessionIndex,
      previewTiles: previewTiles ?? this.previewTiles,
      selectedActionEntityId: selectedActionEntityId ?? this.selectedActionEntityId,
      previewActions: previewActions ?? this.previewActions,
      currentPreviewIndex: currentPreviewIndex ?? this.currentPreviewIndex,
      previewBatch: previewBatch ?? this.previewBatch,
      tileCastStatusByRequest:
          tileCastStatusByRequest ?? this.tileCastStatusByRequest,
    );
  }

  @override
  List<Object?> get props => [
    step,
    currentSession,
    messages,
    hasMoreMessages,
    currentIndex,
    error,
    transcribedText,
    sessions,
    shouldShowAcceptButton,
    hasMoreMessages,
    currentSessionIndex,
    previewTiles,
    selectedActionEntityId,
    previewActions,
    currentPreviewIndex,
    previewBatch,
    tileCastStatusByRequest,
  ];
}

