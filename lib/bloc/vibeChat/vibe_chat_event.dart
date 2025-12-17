part of 'vibe_chat_bloc.dart';


abstract class VibeChatEvent {}

class LoadVibeChatSessionEvent extends VibeChatEvent {}

class LoadMoreMessagesEvent extends VibeChatEvent {}
