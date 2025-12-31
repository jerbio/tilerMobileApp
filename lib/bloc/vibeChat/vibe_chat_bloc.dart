import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/chat.dart';
import 'dart:developer' as developer;

import 'package:tiler_app/services/audiRecordingService.dart';
part 'vibe_chat_event.dart';
part 'vibe_chat_state.dart';


class VibeChatBloc extends Bloc<VibeChatEvent, VibeChatState> {
  final ChatApi chatApi;
  AudioRecordingService? _audioService;

  VibeChatBloc({required this.chatApi}) : super(VibeChatState()) {
    on<LoadVibeChatSessionEvent>(_onLoadVibeChatSession);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<SendAMessageEvent>(_onSendAMessage);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingAndTranscribeEvent>(_onStopRecordingAndTranscribe);
    on<CancelRecordingEvent>(_onCancelRecording);
    on<ClearTranscribedTextEvent>(_onClearTranscribedText);
  }

  Stream<double> get amplitudeStream => _audioService?.amplitudeStream ?? Stream.empty();

  Future<void> _onLoadVibeChatSession(LoadVibeChatSessionEvent event, Emitter<VibeChatState> emit,) async {
    try {
      emit(state.copyWith(step: VibeChatStep.loading));
      final sessionId = await _getLatestSession();

      if (sessionId.isEmpty) {
        emit(state.copyWith(
          step: VibeChatStep.loaded,
          sessionId: '',
          messages: [],
          hasMoreMessages: false,
          currentIndex: 0,
        ));
        return;
      }

      final messages = await _getMessagesWithActions(sessionId, emit);

      emit(state.copyWith(
        step: VibeChatStep.loaded,
        sessionId: sessionId,
        messages: messages,
        hasMoreMessages: messages.length == 5,
        currentIndex: 5,
      ));
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: (e as TilerError).Message,
      ));
    }
  }

  Future<String> _getLatestSession() async {
    final sessions = await chatApi.getVibeSessions();

    if (sessions.isEmpty) {
      return '';
    }

    sessions.sort((a, b) =>
        b.creationTimeInMs!.compareTo(a.creationTimeInMs!));

    return sessions.first.id!;
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
        state.sessionId,
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
        error: (e as TilerError).Message,
      ));
    }
  }

  Future<void> _onSendAMessage(SendAMessageEvent event, Emitter<VibeChatState> emit,) async {
    try {
      emit(state.copyWith(step: VibeChatStep.sending));

      final response = await chatApi.sendChatMessage(
        event.message,
        state.sessionId.isEmpty ? null : state.sessionId,
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

      final newSessionId = state.sessionId.isEmpty && newMessages.isNotEmpty
          ? newMessages.first.sessionId ?? state.sessionId
          : state.sessionId;
      emit(state.copyWith(
        sessionId: newSessionId,
        step: VibeChatStep.loaded,
        messages: combinedMessages,
        currentIndex: combinedMessages.length
      ));

    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: (e as TilerError).Message,
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
        error: (e as TilerError).Message,
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
        error: e is TilerError ? e.Message : 'Transcription failed',
      ));
    }
  }

  Future<void> _onCancelRecording(
      CancelRecordingEvent event,
      Emitter<VibeChatState> emit,
      ) async {
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

 }
