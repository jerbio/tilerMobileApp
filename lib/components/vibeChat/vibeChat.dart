import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/MessageList.dart';
import 'package:tiler_app/components/vibeChat/messageInput.dart';
import 'package:tiler_app/components/vibeChat/simulationReviewSheet.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class VibeChat extends StatefulWidget {
  @override
  State<VibeChat> createState() => _VibeChatState();
}

class _VibeChatState extends State<VibeChat> with TickerProviderStateMixin  {
  late final ScrollController _scrollController;
  late final ScrollController _sessionsScrollController;
  late final TextEditingController _messageController;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late AppLocalizations localization ;
  VibeChatStep? _previousStep;
  String? _previousSession;
  late AnimationController _lineAnimationController;
  late AnimationController _dotAnimationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _sessionsScrollController = ScrollController();
    _sessionsScrollController.addListener(() {
      if (_sessionsScrollController.position.extentAfter < 100) {
        final state = context.read<VibeChatBloc>().state;
        if (state.step == VibeChatStep.loaded && state.hasMoreSessions) {
          context.read<VibeChatBloc>().add(LoadMoreSessionsEvent());
        }
      }
    });
    _messageController = TextEditingController();
    context.read<VibeChatBloc>().add(OpenChatEvent());
    context.read<VibeChatBloc>().add(LoadSessionsEvent());
    _lineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _setupScrollListener();
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    localization = AppLocalizations.of(context)!;
    super.didChangeDependencies();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 100) {
        final state = context.read<VibeChatBloc>().state;
        if (state.step == VibeChatStep.loaded && state.hasMoreMessages) {
          context.read<VibeChatBloc>().add(LoadMoreMessagesEvent());
        }
      }
    });
  }

  @override
  void dispose() {
    _dotAnimationController.dispose();
    _scrollController.dispose();
    _sessionsScrollController.dispose();
    _messageController.dispose();
    _lineAnimationController.dispose();
    super.dispose();
  }

  void _handleBlocStateChanges(BuildContext context, VibeChatState state) {
    if (state.step == VibeChatStep.loadingPreview) {
      Navigator.pop(context);
    }
    if (
        (_previousStep == VibeChatStep.sending && state.step == VibeChatStep.loaded)
        ||
        _previousSession != state.currentSession?.id
    ) {
      _messageController.clear();
    }
    _previousSession = state.currentSession?.id;
    _previousStep = state.step;

    if (state.step == VibeChatStep.loaded &&
        state.transcribedText != null &&
        state.transcribedText!.isNotEmpty) {
      _messageController.text = state.transcribedText!;
      context.read<VibeChatBloc>().add(ClearTranscribedTextEvent());
      return;
    }

    if (state.step == VibeChatStep.error && state.error != null) {
      NotificationOverlayMessage().showToast(
        context,
        state.error!,
        NotificationOverlayMessageType.error,
      );
    }

  }

  Widget _buildDrawer(BuildContext context, VibeChatState state) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.add),
              title: Text(localization.newChat),
              onTap: () {
                context.read<VibeChatBloc>().add(CreateNewChatEvent());
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: const Divider(),
            ),

            Expanded(
              child: state.step == VibeChatStep.loadingSessions
                  ? const Center(child: CircularProgressIndicator())
                  : state.sessions.isEmpty
                  ? Center(child: Text(localization.noChatHistory))
                  : ListView.builder(
                controller: _sessionsScrollController,
                itemCount: state.sessions.length + (state.hasMoreSessions ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.sessions.length) {
                    return  Center(child: CircularProgressIndicator());
                  }
                  final session = state.sessions[index];
                  final isSelected = session.id == state.currentSession?.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: colorScheme.surfaceContainerHighest,
                    title: Text(
                      session.title ?? '${localization.unknownChat}  ${index + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: session.creationTimeInMs != null
                        ? Text(
                      DateFormat('yyyy-MM-dd').format(
                        DateTime.fromMillisecondsSinceEpoch(session.creationTimeInMs!),
                      ),
                      style: TextStyle(fontSize: 12),
                    )
                        : null,
                    onTap: () {
                      if(state.currentSession?.id != session.id)
                        context.read<VibeChatBloc>().add(SelectSessionEvent(session),);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  PreferredSizeWidget _buildAppBar(VibeChatState state){
    return  AppBar(
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          context.read<VibeChatBloc>().add(CloseChatEvent());
          Navigator.pop(context);
        },
        color: colorScheme.onSurface,
      ),
      title: Text(
        state.currentSession?.title ?? localization.newChat,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            color: colorScheme.onSurface,
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }
  Widget _buildAnimatedLoadingWidget(bool isTranscribing) {
    if (isTranscribing) {
      final status = _formatStatus('transcribing');
      return Column(
        children: [
          _buildAnimatedLoadingText(status),
          _buildAnimatedLine(),
        ],
      );
    }
    return StreamBuilder<String>(
      stream: context.read<VibeChatBloc>().signalRStatusStream,
      builder: (context, snapshot) {
        final rawStatus = snapshot.data ?? localization.sendingRequest;
        final status = _formatStatus(rawStatus);

        return Column(
          children: [
            _buildAnimatedLoadingText(status),
            _buildAnimatedLine(),
          ],
        );
      },
    );
  }
  Widget _buildAnimatedLine() {
    return ClipRect(
      child: SizedBox(
        height: 2,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _lineAnimationController,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final progress = _lineAnimationController.value;
                final width = constraints.maxWidth * 0.4;
                final position = (constraints.maxWidth - width) * progress;
                final centerDistance = (progress - 0.5).abs() * 2;
                final colorStopSpread = 0.02 + (0.48 * (1 - centerDistance));

                return Stack(
                  children: [
                    Positioned(
                      left: position,
                      child: Container(
                        width: width,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              colorScheme.primary,
                              colorScheme.primary,
                              Colors.transparent,
                            ],
                            stops: [
                              0.0,
                              0.5 - colorStopSpread,
                              0.5 + colorStopSpread,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
  Widget _buildAnimatedLoadingText(String status) {
    return AnimatedBuilder(
      animation: _dotAnimationController,
      builder: (context, child) {
        final dotCount = (_dotAnimationController.value * 4).floor();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            '$status${'.' * dotCount}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulationStrip(VibeChatState state) {
    final simState = state.simulationState;

    if (simState == SimulationState.invalidated) {
      return const SizedBox.shrink();
    }

    if (simState == null && state.activeRequestId == null) {
      return const SizedBox.shrink();
    }

    if (simState == null ||
        simState == SimulationState.queued ||
        simState == SimulationState.processing) {
      final String loadingText = simState == SimulationState.queued
          ? localization.tilecastQueued
          : simState == SimulationState.processing
              ? localization.generatingTilecast
              : localization.tilecastStarting;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              loadingText,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (simState == SimulationState.failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          localization.previewGenerationFailed,
          style: TextStyle(fontSize: 13, color: colorScheme.error),
        ),
      );
    }

    if (simState == SimulationState.ready) {
      final simulation = state.simulation;
      final actionCount = simulation?.previewActions?.length ?? 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => _openReviewSheet(context, state),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: TileColors.vibeChatReviewPreview,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 15, color: colorScheme.onPrimary),
                  const SizedBox(width: 7),
                  Text(
                    localization.reviewPreviewWithCount(actionCount),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: colorScheme.onPrimary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _openReviewSheet(BuildContext context, VibeChatState state) {
    final simulation = state.simulation;
    if (simulation == null) return;
    final bloc = context.read<VibeChatBloc>();
    final requestId = state.activeRequestId ?? simulation.vibeRequestId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SimulationReviewSheet(
        simulation: simulation,
        onActionTap: requestId == null
            ? null
            : (actionId) {
                Navigator.of(sheetContext).pop();
                bloc.add(PreviewActionEvent(requestId, actionId));
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VibeChatBloc, VibeChatState>(
      listener: _handleBlocStateChanges,
      builder: (context, state) {
        return Scaffold(
          endDrawer: _buildDrawer(context, state),
          appBar: _buildAppBar(state),
          body: Stack(
            children: [
            Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: MessageList(
                    state: state,
                    scrollController: _scrollController,
                  ),
                ),
                _buildSimulationStrip(state),
                if (state.shouldShowAcceptButton &&
                    (state.step == VibeChatStep.loaded ||
                        state.step == VibeChatStep.loadingPreview ||
                        state.step == VibeChatStep.previewLoaded))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<VibeChatBloc>()
                              .add(AcceptChangesEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        child: Text(localization.acceptChanges),
                      ),
                    ),
                  ),
                if (state.step == VibeChatStep.sending ||
                    state.step == VibeChatStep.transcribing)
                  _buildAnimatedLoadingWidget(
                      state.step == VibeChatStep.transcribing),
                MessageInput(
                  controller: _messageController,
                ),
              ],
            ),
          ),
          if (state.step == VibeChatStep.executedActionPreviewLoading)
            PendingWidget(blurBackGround: true),
          ],
          ),
        );
      },
    );
  }


  String _formatStatus(String status) {
    final map = {
      'action_initialization_start': [
        localization.initializingAction,
        localization.settingThingsUp,
        localization.preparingRequest,
        localization.gettingReady,
      ],
      'process_action_start': [
        localization.processingAction,
        localization.workingOnIt,
        localization.analyzingRequest,
        localization.thinking,
      ],
      'process_action_end': [
        localization.actionComplete,
        localization.processingDone,
        localization.allSet,
        localization.finishedProcessing,
      ],
      'summary_action_start': [
        localization.generatingSummary,
        localization.summarizingResults,
        localization.creatingOverview,
        localization.preparingSummary,
      ],
      'summary_action_end': [
        localization.summaryComplete,
        localization.summaryReady,
        localization.overviewComplete,
        localization.doneSummarizing,
      ],
      'schedule_load': [
        localization.loadingSchedule,
        localization.fetchingSchedule,
        localization.retrievingCalendar,
        localization.loadingTimeline,
      ],
      'schedule_process_start': [
        localization.optimizingSchedule,
        localization.reorganizingDay,
        localization.findingBestFit,
        localization.adjustingTimeline,
      ],
      'schedule_process_end': [
        localization.scheduleComplete,
        localization.scheduleUpdated,
        localization.timelineOptimized,
        localization.allDone,
      ],
      'transcribing': [
        localization.transcribing,
      ],
    };

    final messages = map[status];
    if (messages != null && messages.isNotEmpty) {
      return messages[Random().nextInt(messages.length)];
    }

    return status.replaceAll('_', ' ');
  }
}
