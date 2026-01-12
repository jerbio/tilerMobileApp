import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/data/VibeChat/VibeSession.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/chatApi.dart';
import 'package:tiler_app/services/audiRecordingService.dart';
import 'package:tiler_app/services/localizationService.dart';

part 'vibe_chat_event.dart';
part 'vibe_chat_state.dart';


class VibeChatBloc extends Bloc<VibeChatEvent, VibeChatState> {
  final ChatApi chatApi;
  AudioRecordingService? _audioService;

  VibeChatBloc({required this.chatApi}) : super(VibeChatState()) {
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<SendAMessageEvent>(_onSendAMessage);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingAndTranscribeEvent>(_onStopRecordingAndTranscribe);
    on<CancelRecordingEvent>(_onCancelRecording);
    on<ClearTranscribedTextEvent>(_onClearTranscribedText);
    on<LoadSessionsEvent>(_onLoadSessions);
    on<SelectSessionEvent>(_onSelectSession);
    on<CreateNewChatEvent>(_onCreateNewChat);
    on<AcceptChangesEvent>(_onAcceptChanges);
  }

  Stream<double> get amplitudeStream => _audioService?.amplitudeStream ?? Stream.empty();

  Future<void> _onLoadSessions (LoadSessionsEvent event, Emitter<VibeChatState> emit) async{
    try{
      emit(state.copyWith(step: VibeChatStep.loadingSessions));
      final sessions = await chatApi.getVibeSessions();

      sessions.sort((a, b) => b.creationTimeInMs!.compareTo(a.creationTimeInMs!));

      emit(state.copyWith(step: VibeChatStep.loaded, sessions: sessions));
    }
    catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError ? e.Message : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onSelectSession(SelectSessionEvent event, Emitter<VibeChatState> emit)async{
    try{
      if (state.currentSession != null && event.session.id == state.currentSession?.id) {
        return;
      }
      emit(state.copyWith(step: VibeChatStep.loading,currentSession: event.session));
      final messages = await _getMessagesWithActions(event.session.id!, emit);
      bool shouldShowAccept = false;
      final lastRequestId = messages.isNotEmpty ? messages.last.requestId : null;
      if (lastRequestId != null) {
        shouldShowAccept = await _shouldShowAcceptButton(lastRequestId);
      }
      emit(state.copyWith(
          step: VibeChatStep.loaded,
          messages: messages,
          hasMoreMessages: messages.length == 5,
          currentIndex: 5,
          shouldShowAcceptButton: shouldShowAccept
      ));
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError ? e.Message : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  void _onCreateNewChat (CreateNewChatEvent event, Emitter<VibeChatState> emit) {
    emit(VibeChatState(
      step: VibeChatStep.loaded,
      messages: [],
      currentIndex: 0,
      sessions: state.sessions,
    ));
  }

  Future<List<VibeMessage>> _getMessagesWithActions(String sessionId, Emitter<VibeChatState> emit, {int? batchSize, int? index})  async {
    final messages = await chatApi.getMessages(sessionId: sessionId,  batchSize: batchSize ?? 5,
      index: index ?? 0,);

    if (messages.isEmpty) {
      return [];
    }
    messages.sort((a, b) {
      final timestampA = _extractTimestamp(a.id!);
      final timestampB = _extractTimestamp(b.id!);
      return timestampB.compareTo(timestampA);
    });

    final uniqueActionIds = <String>{};
    for (var msg in messages) {
      if (msg.actionIds != null) {
        uniqueActionIds.addAll(msg.actionIds!);
      }
    }

    if (uniqueActionIds.isEmpty) {
      return messages;
    }

    final actions = await _fetchActionsWithBatching(
        uniqueActionIds.toList(),
        emit,
        sessionId,
        messages
    );

    final actionsMap = {
      for (var action in actions) action.id: action
    };

    final messagesWithActions = messages.map((msg) {
      if (msg.actionIds == null || msg.actionIds!.isEmpty) {
        return msg;
      }

      final resolvedActions = msg.actionIds!
          .map((id) => actionsMap[id])
          .where((action) => action != null)
          .cast<VibeAction>()
          .toList();

      return VibeMessage(
        id: msg.id,
        origin: msg.origin,
        content: msg.content,
        requestId: msg.requestId,
        sessionId: msg.sessionId,
        actionIds: msg.actionIds,
        actions: resolvedActions,
      );
    }).toList();

    messagesWithActions.sort((a, b) {
      final timestampA = _extractTimestamp(a.id!);
      final timestampB = _extractTimestamp(b.id!);
      return timestampA.compareTo(timestampB);
    });

    return messagesWithActions;
  }

  Future<List<VibeAction>> _fetchActionsWithBatching(List<String> actionIds, Emitter<VibeChatState> emit, String sessionId, List<VibeMessage> messages) async {
    const batchSize = 10;
    final allActions = <VibeAction>[];
    final actionsMap = <String, VibeAction>{};

    if (actionIds.length > batchSize) {
      for (int i = 0; i < actionIds.length; i += batchSize) {
        final end = (i + batchSize < actionIds.length)
            ? i + batchSize
            : actionIds.length;
        final batch = actionIds.sublist(i, end);
        final isLastBatch = (end >= actionIds.length);

        final batchActions = await chatApi.getActions(batch);
        allActions.addAll(batchActions);

        for (var action in batchActions) {
          actionsMap[action!.id!] = action;
        }

        final updatedMessages = messages.map((msg) {
          if (msg.actionIds == null || msg.actionIds!.isEmpty) return msg;

          final resolvedActions = msg.actionIds!
              .map((id) => actionsMap[id])
              .where((action) => action != null)
              .cast<VibeAction>()
              .toList();

          return VibeMessage(
            id: msg.id,
            origin: msg.origin,
            content: msg.content,
            requestId: msg.requestId,
            sessionId: msg.sessionId,
            actionIds: msg.actionIds,
            actions: resolvedActions,
          );
        }).toList();

        if (!isLastBatch) {
          emit(state.copyWith(
            step: VibeChatStep.loaded,
            messages: updatedMessages,
          ));
        }
      }
    } else {
      final actions = await chatApi.getActions(actionIds);
      allActions.addAll(actions);
    }

    return allActions;
  }

  int _extractTimestamp(String id) {
    final match = RegExp(r'(\d{18})').firstMatch(id);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<void> _onLoadMoreMessages(LoadMoreMessagesEvent event, Emitter<VibeChatState> emit,) async {
    if (state.step == VibeChatStep.loadingMore || !state.hasMoreMessages) return;

    try {
      emit(state.copyWith(
        step: VibeChatStep.loadingMore,
      ));

      final newMessages = await _getMessagesWithActions(
        state.currentSession?.id ?? '',
        emit,
        batchSize: 5,
        index: state.currentIndex,
      );

      if (newMessages.isEmpty) {
        emit(state.copyWith(
          step: VibeChatStep.loaded,
          hasMoreMessages: false,
        ));
        return;
      }

      final combinedMessages = [...state.messages, ...newMessages];

      combinedMessages.sort((a, b) {
        final timestampA = _extractTimestamp(a.id!);
        final timestampB = _extractTimestamp(b.id!);
        return timestampA.compareTo(timestampB);
      });

      emit(state.copyWith(
        step: VibeChatStep.loaded,
        messages: combinedMessages,
        hasMoreMessages: newMessages.length == 5,
        currentIndex: state.currentIndex + 5,
      ));

    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error:  e is TilerError ? e.Message : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onSendAMessage(SendAMessageEvent event, Emitter<VibeChatState> emit,) async {
    try {
      emit(state.copyWith(step: VibeChatStep.sending));

      final sessionId = state.currentSession?.id ?? '';
      final response = await chatApi.sendChatMessage(
        event.message,
        sessionId.isEmpty ? null : sessionId,
      );

      if (response == null ||  response.prompts ==null || response.prompts!.isEmpty) {
        emit(state.copyWith(step: VibeChatStep.loaded));
        return;
      }
      final existingIds = state.messages.map((m) => m.id).toSet();
      final newMessages = response.prompts!.where((m) => !existingIds.contains(m.id)).toList();
      final combinedMessages = [...state.messages, ...newMessages];

      combinedMessages.sort((a, b) {
        final timestampA = _extractTimestamp(a.id ?? '');
        final timestampB = _extractTimestamp(b.id ?? '');
        return timestampA.compareTo(timestampB);
      });
      final newRequestId = newMessages.isNotEmpty ? newMessages.last.requestId : null;

      final newSessionId = sessionId.isEmpty && newMessages.isNotEmpty
          ? newMessages.first.sessionId ?? sessionId
          :sessionId;
      List<VibeSession>? updatedSessions;
      VibeSession? updatedCurrentSession = state.currentSession;
      bool shouldShowAccept = false;
      if(sessionId!=newSessionId)
      {
        final sessions = await chatApi.getVibeSessions(sessionId: newSessionId);
        if(sessions.length==1) {
          final newSession = sessions.first;
          updatedSessions = [newSession, ...state.sessions];
          updatedCurrentSession = newSession;
        }
      }
      if (newRequestId != null) {
        shouldShowAccept = await _shouldShowAcceptButton(newRequestId);
      }
      emit(state.copyWith(
        currentSession: updatedCurrentSession,
        step: VibeChatStep.loaded,
        messages: combinedMessages,
        currentIndex: combinedMessages.length,
        sessions: updatedSessions,
        shouldShowAcceptButton: shouldShowAccept,
      ));

    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error:  e is TilerError ? e.Message : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onStartRecording(StartRecordingEvent event, Emitter<VibeChatState> emit,) async {
    try {
      if (_audioService != null) {
        await _audioService!.cancelRecording();
        _audioService!.dispose();
      }
      _audioService = AudioRecordingService();
      await _audioService!.startRecording();
      emit(state.copyWith(step: VibeChatStep.recording));
    } catch (e) {
      _audioService?.dispose();
      _audioService = null;
      emit(state.copyWith(
        step: VibeChatStep.error,
        error:  e is TilerError ? e.Message : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onStopRecordingAndTranscribe(StopRecordingAndTranscribeEvent event, Emitter<VibeChatState> emit,) async {
    try {

      emit(state.copyWith(step: VibeChatStep.transcribing));

      final webMPath = await _audioService!.stopRecording();
      _audioService = null;
      final transcriptionText = await chatApi.transcribeAudio(webMPath);
      await File(webMPath).delete();
      if (transcriptionText.isNotEmpty) {
        emit(state.copyWith(
          step: VibeChatStep.loaded,
          transcribedText: transcriptionText,
        ));
      } else {
        emit(state.copyWith(step: VibeChatStep.loaded));
      }
    } catch (e) {
      _audioService?.dispose();
      _audioService = null;
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError ? e.Message : LocalizationService.instance.translations.transcriptionFailed,
      ));
    }
  }

  Future<void> _onCancelRecording(CancelRecordingEvent event, Emitter<VibeChatState> emit,) async {
    if (_audioService != null) {
      await _audioService!.cancelRecording();
      _audioService = null;
    }

    emit(state.copyWith(
      step: VibeChatStep.loaded,
      transcribedText: '',
    ));
  }

  void _onClearTranscribedText(ClearTranscribedTextEvent event, Emitter<VibeChatState> emit) {
    emit(state.copyWith(transcribedText: ''));
  }

  Future<bool> _shouldShowAcceptButton(String requestId) async {
    try {
      final request = await chatApi.getVibeRequest(requestId);
      return request?.isClosed != true;
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError ? e.Message : LocalizationService.instance.translations.errorOccurred,
      ));
      return false;
    }
  }

  Future<void> _onAcceptChanges(AcceptChangesEvent event, Emitter<VibeChatState> emit) async {
    try {
      //In Web version on pressing accept button we were re loading all message
      // but on our mobile app we followed different way
      // started with fetching only recent 5 msgs instead of fetching all msgs
      // and add only new msgs( not already existed)
      // and then we went through our conversation and update actions
      emit(state.copyWith(step: VibeChatStep.sending));

      final lastRequestId = state.messages.isNotEmpty ? state.messages.last.requestId : null;

      if (lastRequestId == null) {
        throw TilerError(Message: LocalizationService.instance.translations.noRequestToExecute);
      }

      //Updating Messages
      await chatApi.executeVibeRequest(requestId: lastRequestId);
      List<VibeMessage> updatedMsgs = state.messages;

      List<VibeMessage> newMessages = [];
      final sessionId = state.currentSession?.id ?? '';
      if (sessionId.isNotEmpty) {
        final recentMessages = await _getMessagesWithActions(
          sessionId,
          emit,
          batchSize: 5,
          index: 0,
        );

        final existingIds = updatedMsgs.map((m) => m.id).toSet();
         newMessages = recentMessages.where((m) => !existingIds.contains(m.id)).toList();

        updatedMsgs = [...updatedMsgs, ...newMessages];

      }

      //Updating actions
      final uniqueActionIds = <String>{};
      for (var msg in newMessages) {
        if (msg.actionIds != null) {
          uniqueActionIds.addAll(msg.actionIds!);
        }
      }

      if (uniqueActionIds.isNotEmpty) {
       final updatedActions = await chatApi.getActions(uniqueActionIds.toList());

        // Rebuilding actions
        final updatedActionsMap = {for (var a in updatedActions) a.id: a};

        updatedMsgs = updatedMsgs.map((msg) {
          // Case 1: No actions in message,  returning  msg as it's
          if (msg.actions == null || msg.actions!.isEmpty) {
            return msg;
          }

          final newActions = msg.actions!.map((action) {
            // Case 2: Action ID matches updated(new) actions, replacing with new action
            if (updatedActionsMap.containsKey(action.id)) {
              return updatedActionsMap[action.id]!;
            }
            // Case 3: Action ID doesn't match AND status is executed, keep action as it's
            if (action.status == ActionStatus.executed) {
              return action;
            }
            // Case 4: Action ID doesn't match AND status is not executed, changing status to  dispose
            return action.copyWith(status: ActionStatus.disposed);
          }).toList();

          return msg.copyWith(actions: newActions);
        }).toList();


        emit(state.copyWith(
          step: VibeChatStep.loaded,
          messages: updatedMsgs,
          shouldShowAcceptButton: false,
        ));
      } else {
        emit(state.copyWith(
          step: VibeChatStep.loaded,
          shouldShowAcceptButton: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError ? e.Message : LocalizationService.instance.translations.transcriptionFailed,
      ));
    }
  }



}
