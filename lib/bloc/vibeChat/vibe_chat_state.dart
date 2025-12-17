part of 'vibe_chat_bloc.dart';

enum VibeChatStep {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class VibeChatState extends Equatable {
  final VibeChatStep step;
  final String sessionId;
  final List<VibeMessage> messages;
  final bool hasMoreMessages;
  final int currentIndex;
  final String? error;

  const VibeChatState({
    this.step = VibeChatStep.initial,
    this.sessionId = '',
    this.messages = const [],
    this.hasMoreMessages = true,
    this.currentIndex = 0,
    this.error,
  });

  VibeChatState copyWith({
    VibeChatStep? step,
    String? sessionId,
    List<VibeMessage>? messages,
    bool? hasMoreMessages,
    int? currentIndex,
    String? error,
  }) {
    return VibeChatState(
      step: step ?? this.step,
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error ?? this.error,
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
  ];
}