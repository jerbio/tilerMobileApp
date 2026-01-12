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
  });

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
    currentSessionIndex
  ];
}

