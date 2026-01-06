part of 'vibe_chat_bloc.dart';


abstract class VibeChatEvent {}



class LoadMoreMessagesEvent extends VibeChatEvent {}

class SendAMessageEvent extends VibeChatEvent{
  String message;
  SendAMessageEvent(this.message);
  List<Object?> get props => [message];
}

class StartRecordingEvent extends VibeChatEvent {
   StartRecordingEvent();

  @override
  List<Object?> get props => [];
}

class StopRecordingAndTranscribeEvent extends VibeChatEvent {}

class CancelRecordingEvent extends VibeChatEvent {}

class ClearTranscribedTextEvent extends VibeChatEvent {}

class LoadSessionsEvent extends VibeChatEvent {}

class SelectSessionEvent extends VibeChatEvent {
  VibeSession session;
  SelectSessionEvent(this.session);
  List<Object?> get props => [session];
}


class CreateNewChatEvent extends VibeChatEvent {}
