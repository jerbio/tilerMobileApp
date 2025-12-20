part of 'vibe_chat_bloc.dart';


abstract class VibeChatEvent {}

class LoadVibeChatSessionEvent extends VibeChatEvent {}

class LoadMoreMessagesEvent extends VibeChatEvent {}

class SendAMessageEvent extends VibeChatEvent{
  String message;
  SendAMessageEvent(this.message);
  List<Object?> get props => [message];
}