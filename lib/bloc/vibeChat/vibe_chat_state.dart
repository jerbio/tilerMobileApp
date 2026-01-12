part of 'vibe_chat_bloc.dart';

enum VibeChatStep {
  initial,
  loading,
  loadingMore,
  loadingSessions,
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

  const VibeChatState({
    this.step = VibeChatStep.initial,
    this.currentSession ,
    this.messages = const [],
    this.hasMoreMessages = true,
    this.currentIndex = 0,
    this.error,
    this.transcribedText,
    this.sessions= const[],
    this.shouldShowAcceptButton=false
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
    bool? shouldShowAcceptButton
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
      shouldShowAcceptButton: shouldShowAcceptButton ?? this.shouldShowAcceptButton
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
    shouldShowAcceptButton
  ];
}

