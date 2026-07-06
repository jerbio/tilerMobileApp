part of 'vibe_chat_bloc.dart';


abstract class VibeChatEvent {}

class OpenChatEvent extends VibeChatEvent {}
class CloseChatEvent extends VibeChatEvent {}

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

class LoadMoreSessionsEvent extends VibeChatEvent {}

class SelectSessionEvent extends VibeChatEvent {
  VibeSession session;
  SelectSessionEvent(this.session);
  List<Object?> get props => [session];
}


class CreateNewChatEvent extends VibeChatEvent {}

class AcceptChangesEvent extends VibeChatEvent {
  @override
  List<Object?> get props => [];
}

class LogOutVibeChatEvent extends VibeChatEvent {
  Function getContextCallBack;
  LogOutVibeChatEvent(this.getContextCallBack);
}


class PreviewActionEvent extends VibeChatEvent {
  final String vibeRequestId;
  final String actionId;
  PreviewActionEvent(this.vibeRequestId, this.actionId);
  List<Object?> get props => [vibeRequestId, actionId];
}

/// Opens the TileCast preview carousel for a request. Polls the request-level
/// preview until it reaches a terminal state, then loads the shared schedule.
/// When [actionId] is supplied the carousel opens focused on that action.
class LoadTileCastEvent extends VibeChatEvent {
  final String vibeRequestId;
  final String? actionId;
  LoadTileCastEvent(this.vibeRequestId, {this.actionId});
  List<Object?> get props => [vibeRequestId, actionId];
}

/// Moves the TileCast carousel to [index]. Purely client-side — no refetch,
/// since every action shares the same downloaded schedule and differs only by
/// which tile is highlighted.
class NavigateTileCastEvent extends VibeChatEvent {
  final int index;
  NavigateTileCastEvent(this.index);
  List<Object?> get props => [index];
}

/// Re-attempts a TileCast preview that timed out or failed.
class RetryTileCastEvent extends VibeChatEvent {
  final String vibeRequestId;
  RetryTileCastEvent(this.vibeRequestId);
  List<Object?> get props => [vibeRequestId];
}
