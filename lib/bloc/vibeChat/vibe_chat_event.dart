part of 'vibe_chat_bloc.dart';


abstract class VibeChatEvent {}

class LoadVibeChatSessionEvent extends VibeChatEvent {}

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

class StopRecordingAndTranscribeEvent extends VibeChatEvent {
  final String audioPath;

   StopRecordingAndTranscribeEvent(this.audioPath);

  @override
  List<Object?> get props => [audioPath];
}

class CancelRecordingEvent extends VibeChatEvent {}

class ClearTranscribedTextEvent extends VibeChatEvent {}