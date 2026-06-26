import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/VibeChat/VibeRequest.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/data/VibeChat/VibeSession.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/chatApi.dart';
import 'package:tiler_app/services/audiRecordingService.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/services/signalRSocketService.dart';
import 'package:tiler_app/util.dart';

part 'vibe_chat_event.dart';
part 'vibe_chat_state.dart';

class VibeChatBloc extends Bloc<VibeChatEvent, VibeChatState> {
  late ChatApi chatApi;
  final ScheduleBloc scheduleBloc;
  final ScheduleSummaryBloc scheduleSummaryBloc;
  final UiDateManagerBloc uiDateManagerBloc;
  AudioRecordingService? _audioService;
  SignalRSocketService? _signalRService;
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _previewReadySubscription;
  Timer? _pollTimer;
  String? _pollRequestId;
  int _pollElapsedMs = 0;

  VibeChatBloc(
      {required this.scheduleBloc,
      required this.scheduleSummaryBloc,
      required this.uiDateManagerBloc,
      required Function getContextCallBack})
      : super(VibeChatState()) {
    on<OpenChatEvent>(_onOpenChat);
    on<CloseChatEvent>(_onCloseChat);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<SendAMessageEvent>(_onSendAMessage);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingAndTranscribeEvent>(_onStopRecordingAndTranscribe);
    on<CancelRecordingEvent>(_onCancelRecording);
    on<ClearTranscribedTextEvent>(_onClearTranscribedText);
    on<LoadSessionsEvent>(_onLoadSessions);
    on<LoadMoreSessionsEvent>(_onLoadMoreSessions);
    on<SelectSessionEvent>(_onSelectSession, transformer: restartable());
    on<CreateNewChatEvent>(_onCreateNewChat);
    on<AcceptChangesEvent>(_onAcceptChanges);
    on<LogOutVibeChatEvent>(_onLogOut);
    on<PreviewActionEvent>(_onPreviewAction);
    on<FetchSimulationEvent>(_onFetchSimulation);
    chatApi = ChatApi(getContextCallBack: getContextCallBack);
  }

  Stream<double> get amplitudeStream =>
      _audioService?.amplitudeStream ?? Stream.empty();
  Stream<String> get signalRStatusStream =>
      _signalRService?.statusStream ?? Stream.empty();

  void _startPolling(String requestId) {
    _stopPolling();
    _pollRequestId = requestId;
    add(FetchSimulationEvent(requestId));
  }

  void _scheduleNextPoll() {
    if (_pollRequestId == null) return;
    final delayMs = _pollElapsedMs < 30000 ? 2000 : 10000;
    _pollTimer = Timer(Duration(milliseconds: delayMs), () {
      _pollElapsedMs += delayMs;
      if (_pollRequestId != null) {
        add(FetchSimulationEvent(_pollRequestId!));
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollRequestId = null;
    _pollElapsedMs = 0;
  }

  bool _isSimStateDone(SimulationState? s) =>
      s == SimulationState.ready ||
      s == SimulationState.failed ||
      s == SimulationState.invalidated;

  bool _isRequestTerminal(VibeRequest? request) {
    if (request == null) return false;
    if (request.isClosed == true) return true;
    if (request.supersededByRequestId != null) return true;
    final s = request.state;
    return s == VibeRequestState.executed ||
        s == VibeRequestState.superseded ||
        s == VibeRequestState.failed;
  }

Future<void> _onOpenChat(
      OpenChatEvent event, Emitter<VibeChatState> emit) async {
    final hasActiveSimulation = state.simulationState == SimulationState.ready;
    emit(state.copyWith(
      step: VibeChatStep.loaded,
      previewTiles: [],
      selectedActionEntityId: null,
      clearSimulation: !hasActiveSimulation,
    ));
    try {
      _signalRService ??=
          SignalRSocketService(getContextCallBack: chatApi.getContextCallBack);
      await _signalRService!.createVibeConnection();
      _statusSubscription = _signalRService!.statusStream.listen(
        null,
        onError: (e) {
          emit(state.copyWith(
            step: VibeChatStep.error,
            error: e is TilerError
                ? e.Message
                : LocalizationService.instance.translations.errorOccurred,
          ));
        },
      );

      _previewReadySubscription?.cancel();
      _previewReadySubscription =
          _signalRService!.previewReadyStream.listen((payload) {
        Utility.debugPrint(
            '[previewReady] bloc received=$payload active=${state.activeRequestId}');
        final requestId = payload['vibeRequestId'] as String?;
        if (requestId == null) return;
        final active = state.activeRequestId;
        if (active != null && requestId != active) return;
        _startPolling(requestId);
      });

    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onCloseChat(
      CloseChatEvent event, Emitter<VibeChatState> emit) async {
    _stopPolling();
    await _previewReadySubscription?.cancel();
    _previewReadySubscription = null;
    try {
      await _signalRService?.dispose();
    } catch (e) {
      Utility.debugPrint('Error disposing SignalR: $e');
    } finally {
      _signalRService = null;
      emit(state.copyWith(
        step: VibeChatStep.loaded,
        previewTiles: [],
        clearSimulation: true,
      ));
    }
  }

  Future<void> _onLoadSessions(
      LoadSessionsEvent event, Emitter<VibeChatState> emit) async {
    try {
      if (state.sessions.isNotEmpty) return;
      emit(state.copyWith(step: VibeChatStep.loadingSessions));
      final sessions = await chatApi.getVibeSessions();

      sessions
          .sort((a, b) => b.creationTimeInMs!.compareTo(a.creationTimeInMs!));

      emit(state.copyWith(
        step: VibeChatStep.loaded,
        sessions: sessions,
        hasMoreSessions: sessions.length == 15,
        currentSessionIndex: 15,
      ));
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onLoadMoreSessions(
      LoadMoreSessionsEvent event, Emitter<VibeChatState> emit) async {
    if (state.step == VibeChatStep.loadingSessions || !state.hasMoreSessions)
      return;

    try {
      emit(state.copyWith(step: VibeChatStep.loadingMoreSessions));

      final newSessions = await chatApi.getVibeSessions(
        batchSize: 15,
        index: state.currentSessionIndex,
      );

      if (newSessions.isEmpty) {
        emit(state.copyWith(
          step: VibeChatStep.loaded,
          hasMoreSessions: false,
        ));
        return;
      }

      final combinedSessions = [...state.sessions, ...newSessions];
      combinedSessions
          .sort((a, b) => b.creationTimeInMs!.compareTo(a.creationTimeInMs!));

      emit(state.copyWith(
        step: VibeChatStep.loaded,
        sessions: combinedSessions,
        hasMoreSessions: newSessions.length == 15,
        currentSessionIndex: state.currentSessionIndex + 15,
      ));
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onSelectSession(
      SelectSessionEvent event, Emitter<VibeChatState> emit) async {
    try {
      if (state.currentSession != null &&
          event.session.id == state.currentSession?.id) {
        return;
      }
      _stopPolling();
      emit(state.copyWith(
        step: VibeChatStep.loading,
        currentSession: event.session,
        clearSimulation: true,
      ));
      final messages = await _getMessagesWithActions(event.session.id!);
      bool shouldShowAccept = false;

      String? lastRequestId = messages.isNotEmpty ? messages.last.requestId : null;

      if (lastRequestId != null) {
        shouldShowAccept = await _shouldShowAcceptButton(lastRequestId);
      }
      emit(state.copyWith(
        step: VibeChatStep.loaded,
        messages: messages,
        hasMoreMessages: messages.length == 10,
        currentIndex: 10,
        shouldShowAcceptButton: shouldShowAccept,
      ));

      if (lastRequestId != null) {
        _startPolling(lastRequestId);
      }
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  void _onCreateNewChat(CreateNewChatEvent event, Emitter<VibeChatState> emit) {
    _stopPolling();
    emit(VibeChatState(
      step: VibeChatStep.loaded,
      messages: [],
      currentIndex: 0,
      sessions: state.sessions,
      hasMoreMessages: false,
    ));
  }

  Future<List<VibeMessage>> _getMessagesWithActions(
      String sessionId,
      {int? batchSize, int? index}) async {
    final messages = await chatApi.getMessages(
      sessionId: sessionId,
      batchSize: batchSize ?? 10,
      index: index ?? 0,
    );

    if (messages.isEmpty) {
      return [];
    }

    messages.sort((a, b) {
      Utility.debugPrint(a.content?.split('\n').first ?? '');
      final timestampA = _extractTimestamp(a.id!);
      Utility.debugPrint(b.content?.split('\n').first ?? '');
      final timestampB = _extractTimestamp(b.id!);
      return timestampA.compareTo(timestampB);
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

    final actions = await _fetchActionsWithBatching(uniqueActionIds.toList());

    final actionsMap = {for (var action in actions) action.id: action};

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

  Future<List<VibeAction>> _fetchActionsWithBatching(
      List<String> actionIds,
      ) async {
    const batchSize = 10;
    final allActions = <VibeAction>[];

    if (actionIds.length > batchSize) {
      for (int i = 0; i < actionIds.length; i += batchSize) {
        final end = (i + batchSize < actionIds.length)
            ? i + batchSize
            : actionIds.length;
        final batch = actionIds.sublist(i, end);
        final batchActions = await chatApi.getActions(batch);
        allActions.addAll(batchActions);

      }
    } else {
      final actions = await chatApi.getActions(actionIds);
      allActions.addAll(actions);
    }

    return allActions;
  }

  int _extractTimestamp(String id) {
    final match = RegExp(r'(\d{18})').firstMatch(id);
    Utility.debugPrint(
        'ID: $id, timestamp: ${match != null ? int.parse(match.group(1)!) : 0}');
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<VibeChatState> emit,
  ) async {
    if (state.step == VibeChatStep.loadingMoreMessages ||
        !state.hasMoreMessages) return;

    try {
      emit(state.copyWith(
        step: VibeChatStep.loadingMoreMessages,
      ));

      final newMessages = await _getMessagesWithActions(
        state.currentSession?.id ?? '',
        batchSize: 10,
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
        hasMoreMessages: newMessages.length == 10,
        currentIndex: state.currentIndex + 10,
      ));
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onSendAMessage(
    SendAMessageEvent event,
    Emitter<VibeChatState> emit,
  ) async {
    try {
      emit(state.copyWith(step: VibeChatStep.sending));

      final sessionId = state.currentSession?.id ?? '';
      final response = await chatApi.sendChatMessage(
        event.message,
        sessionId.isEmpty ? null : sessionId,
      );

      if (response == null ||
          response.prompts == null ||
          response.prompts!.isEmpty) {
        emit(state.copyWith(step: VibeChatStep.loaded));
        return;
      }
      final existingIds = state.messages.map((m) => m.id).toSet();
      final newMessages =
          response.prompts!.where((m) => !existingIds.contains(m.id)).toList();
      final combinedMessages = [...state.messages, ...newMessages];

      combinedMessages.sort((a, b) {
        final timestampA = _extractTimestamp(a.id ?? '');
        final timestampB = _extractTimestamp(b.id ?? '');
        return timestampA.compareTo(timestampB);
      });
      final newRequestId = newMessages.isNotEmpty ? newMessages.last.requestId : null;

      final newSessionId = sessionId.isEmpty && newMessages.isNotEmpty
          ? newMessages.first.sessionId ?? sessionId
          : sessionId;
      List<VibeSession>? updatedSessions;
      VibeSession? updatedCurrentSession = state.currentSession;
      bool shouldShowAccept = false;
      if (sessionId != newSessionId) {
        final sessions = await chatApi.getVibeSessions(sessionId: newSessionId);
        if (sessions.length == 1) {
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
        clearSimulation: true,
        activeRequestId: newRequestId,
      ));

      if (newRequestId != null) {
        _startPolling(newRequestId);
      }
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onStartRecording(
    StartRecordingEvent event,
    Emitter<VibeChatState> emit,
  ) async {
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
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onStopRecordingAndTranscribe(
    StopRecordingAndTranscribeEvent event,
    Emitter<VibeChatState> emit,
  ) async {
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
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.transcriptionFailed,
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

  void _onClearTranscribedText(
      ClearTranscribedTextEvent event, Emitter<VibeChatState> emit) {
    emit(state.copyWith(transcribedText: ''));
  }

  Future<bool> _shouldShowAcceptButton(String requestId) async {
    try {
      final request = await chatApi.getVibeRequest(requestId);
      return request?.isClosed != true;
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
      return false;
    }
  }

  void _refreshSchedule() {
    final scheduleState = scheduleBloc.state;
    Timeline? timeline;

    if (scheduleState is ScheduleEvaluationState) {
      timeline = scheduleState.lookupTimeline;
      scheduleBloc.add(GetScheduleEvent(
        isAlreadyLoaded: true,
        previousSubEvents: scheduleState.subEvents,
        scheduleTimeline: timeline,
        previousTimeline: timeline,
      ));
    }
    if (scheduleState is ScheduleLoadedState) {
      timeline = scheduleState.lookupTimeline;
      scheduleBloc.add(GetScheduleEvent(
        isAlreadyLoaded: true,
        previousSubEvents: scheduleState.subEvents,
        scheduleTimeline: timeline,
        previousTimeline: timeline,
      ));
    }
    if (scheduleState is ScheduleLoadingState) {
      timeline = scheduleState.previousLookupTimeline;
      scheduleBloc.add(GetScheduleEvent(
        isAlreadyLoaded: true,
        previousSubEvents: scheduleState.subEvents,
        scheduleTimeline: timeline,
        previousTimeline: timeline,
      ));
    }

    if (timeline != null) {
      final summaryState = scheduleSummaryBloc.state;
      if (summaryState is ScheduleSummaryInitial ||
          summaryState is ScheduleDaySummaryLoaded ||
          summaryState is ScheduleDaySummaryLoading) {
        scheduleSummaryBloc.add(GetScheduleDaySummaryEvent(timeline: timeline));
      }
    }
  }

  Future<void> _onAcceptChanges(
      AcceptChangesEvent event, Emitter<VibeChatState> emit) async {
    try {
      //In Web version on pressing accept button we were re loading all message
      // but on our mobile app we followed different way
      // started with fetching only recent 5 msgs instead of fetching all msgs
      // and add only new msgs( not already existed)
      // and then we went through our conversation and update actions
      emit(state.copyWith(step: VibeChatStep.sending));

      final lastRequestId =
          state.messages.isNotEmpty ? state.messages.last.requestId : null;

      if (lastRequestId == null) {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.noRequestToExecute);
      }

      //Updating Messages
      await chatApi.executeVibeRequest(requestId: lastRequestId);
      List<VibeMessage> updatedMsgs = state.messages;

      List<VibeMessage> newMessages = [];
      final sessionId = state.currentSession?.id ?? '';
      if (sessionId.isNotEmpty) {
        final recentMessages = await _getMessagesWithActions(
          sessionId,
          batchSize: 5,
          index: 0,
        );

        final existingIds = updatedMsgs.map((m) => m.id).toSet();
        newMessages =
            recentMessages.where((m) => !existingIds.contains(m.id)).toList();

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
        final updatedActions =
            await chatApi.getActions(uniqueActionIds.toList());

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
          clearSimulation: true,
        ));
      } else {
        emit(state.copyWith(
          step: VibeChatStep.loaded,
          shouldShowAcceptButton: false,
          clearSimulation: true,
        ));
      }
      _stopPolling();
      _refreshSchedule();
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.transcriptionFailed,
      ));
    }
  }

  Future<void> _onPreviewAction(
      PreviewActionEvent event, Emitter<VibeChatState> emit) async {
    try {
      emit(state.copyWith(
        step: VibeChatStep.loadingPreview,
        previewTiles: [],
        selectedActionEntityId: null,
      ));

      final previews =
          await chatApi.getVibeRequestPreviews(event.vibeRequestId);
      if (previews.isEmpty) {
        emit(state.copyWith(
          step: VibeChatStep.error,
          error: LocalizationService.instance.translations.noPreviewsAvailable,
        ));
        return;
      }

      VibePreviewAction? matchingPreviewAction;
      for (final preview in previews) {
        final actions = preview.previewActions;
        if (actions == null) continue;
        for (final previewAction in actions) {
          if (previewAction.action?.id == event.actionId) {
            matchingPreviewAction = previewAction;
            break;
          }
        }
        if (matchingPreviewAction != null) break;
      }

      final previewId = matchingPreviewAction?.vibePreviewId;
      if (previewId == null) {
        emit(state.copyWith(
          step: VibeChatStep.error,
          error: LocalizationService.instance.translations.previewUnavailable,
        ));
        return;
      }

      final summary = await chatApi.getVibePreviewSummary(previewId);
      if (summary == null) {
        emit(state.copyWith(
          step: VibeChatStep.error,
          error: LocalizationService
              .instance.translations.previewSummaryUnavailable,
        ));
        return;
      }

      emit(state.copyWith(
        step: VibeChatStep.previewLoaded,
        previewTiles: summary.subCalendarEvents,
        selectedActionEntityId: matchingPreviewAction?.entityId,
      ));
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
    }
  }

  Future<void> _onFetchSimulation(
      FetchSimulationEvent event, Emitter<VibeChatState> emit) async {
    try {
      VibeRequestPreview? simulation;
      SimulationState? simState;

      final request = await chatApi.getVibeRequest(event.vibeRequestId);
      final bool requestTerminal = _isRequestTerminal(request);

      if (_pollRequestId != event.vibeRequestId) return;

      if (requestTerminal) {
        _stopPolling();
        return;
      }

      final primed = request?.primedPreview;
      if (state.simulation == null && primed != null) {
        emit(state.copyWith(
          simulationState: primed.state,
          simulation: primed,
          activeRequestId: event.vibeRequestId,
        ));
      }

      try {
        final previews =
            await chatApi.getVibeRequestPreviews(event.vibeRequestId);
        if (previews.isNotEmpty) {
          simulation = previews.first;
          simState = simulation.state;
        }
      } catch (e) {
        Utility.debugPrint('[preview] fetch failed: $e');
      }

      if (_pollRequestId != event.vibeRequestId) return;

      Utility.debugPrint(
          '[previewReady] poll req=${event.vibeRequestId} state=$simState count=${simulation?.previewActions?.length} reqTerminal=$requestTerminal');

      if (simulation == null && primed != null) {
        simulation = primed;
        simState = primed.state;
      }

      if (simulation == null) {
        if (requestTerminal) {
          _stopPolling();
        } else {
          _scheduleNextPoll();
        }
        return;
      }

      emit(state.copyWith(
        simulationState: simState,
        simulation: simulation,
        activeRequestId: event.vibeRequestId,
      ));

      if (requestTerminal || _isSimStateDone(simState)) {
        _stopPolling();

      } else {
        _scheduleNextPoll();
      }
    } catch (e) {
      _scheduleNextPoll();
    }
  }

  @override
  Future<void> close() {
    _stopPolling();
    _statusSubscription?.cancel();
    _previewReadySubscription?.cancel();
    _signalRService?.dispose();
    _audioService?.dispose();
    return super.close();
  }

  Future<bool> executeActionPreview(String entityId) async {
    try {
      emit(state.copyWith(step: VibeChatStep.executedActionPreviewLoading));
      final baseId = entityId.contains('_')
          ? entityId.substring(0, entityId.lastIndexOf('_') + 1)
          : entityId;

      final loadedSubEvents = scheduleBloc.state is ScheduleLoadedState
          ? (scheduleBloc.state as ScheduleLoadedState).subEvents
          : scheduleBloc.state is ScheduleEvaluationState
              ? (scheduleBloc.state as ScheduleEvaluationState).subEvents
              : <SubCalendarEvent>[];

      DateTime? tileDate;
      final match = loadedSubEvents
          .where((e) => e.id != null && e.id!.startsWith(baseId) && e.start != null)
          .firstOrNull;
      if (match != null) {
        tileDate = DateTime.fromMillisecondsSinceEpoch(match.start!).dayDate;
      }

      if (tileDate == null) {
        final api = CalendarEventApi(getContextCallBack: chatApi.getContextCallBack!);
        final subEvents = await api.getSubEvents(entityId);
        if (subEvents.isNotEmpty) {
          final earliest = subEvents.reduce((a, b) => (a.start ?? 0) <= (b.start ?? 0) ? a : b);
          if (earliest.start != null) {
            tileDate = DateTime.fromMillisecondsSinceEpoch(earliest.start!).dayDate;
          }
        }
      }

      if (tileDate != null) {
        uiDateManagerBloc.add(DateChangeEvent(
          selectedDate: tileDate,
          dateChangeTrigger: DateChangeTrigger.buttonPress,
        ));
        emit(state.copyWith(selectedActionEntityId: entityId));
        return true;
      }
      return false;
    } catch (e) {
      emit(state.copyWith(
        step: VibeChatStep.error,
        error: e is TilerError
            ? e.Message
            : LocalizationService.instance.translations.errorOccurred,
      ));
      return false;
    }
  }

  void _onLogOut(LogOutVibeChatEvent event, Emitter<VibeChatState> emit) async {
    await _signalRService?.dispose();
    _signalRService = null;
    _audioService?.dispose();
    _audioService = null;
    chatApi = ChatApi(getContextCallBack: () {
      return event.getContextCallBack();
    });
    emit(VibeChatState());
  }
}
