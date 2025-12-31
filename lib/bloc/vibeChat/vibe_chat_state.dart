part of 'vibe_chat_bloc.dart';

enum VibeChatStep {
  initial,
  loading,
  loaded,
  loadingMore,
  sending,
  recording,
  transcribing,
  error,
}

class VibeChatState extends Equatable {
  final VibeChatStep step;
  final String sessionId;
  final List<VibeMessage> messages;
  final bool hasMoreMessages;
  final int currentIndex;
  final String? error;
  final String? transcribedText;

  const VibeChatState({
    this.step = VibeChatStep.initial,
    this.sessionId = '',
    this.messages = const [],
    this.hasMoreMessages = true,
    this.currentIndex = 0,
    this.error,
    this.transcribedText
  });

  VibeChatState copyWith({
    VibeChatStep? step,
    String? sessionId,
    List<VibeMessage>? messages,
    bool? hasMoreMessages,
    int? currentIndex,
    String? error,
    String? transcribedText
  }) {
    return VibeChatState(
      step: step ?? this.step,
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error ?? this.error,
      transcribedText: transcribedText ?? this.transcribedText
    );
  }

  @override
  List<Object?> get props => [
    step,
    sessionId,
    messages,
    hasMoreMessages,
    currentIndex,
    error,
    transcribedText
  ];
}