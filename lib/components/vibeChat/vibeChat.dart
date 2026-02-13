
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/MessageList.dart';
import 'package:tiler_app/components/vibeChat/messageInput.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class VibeChat extends StatefulWidget {
  @override
  State<VibeChat> createState() => _VibeChatState();
}

class _VibeChatState extends State<VibeChat> with TickerProviderStateMixin  {
  late final ScrollController _scrollController;
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
    _messageController.dispose();
    _lineAnimationController.dispose();
    super.dispose();
  }

  void _handleBlocStateChanges(BuildContext context, VibeChatState state) {



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
    final sessionsScrollController = ScrollController();
    sessionsScrollController.addListener(() {
      if (sessionsScrollController.position.extentAfter < 100) {
        if (state.step == VibeChatStep.loaded && state.hasMoreSessions) {
          context.read<VibeChatBloc>().add(LoadMoreSessionsEvent());
        }
      }
    });
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
                controller: sessionsScrollController,
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
  @override
  Widget build(BuildContext context) {

    return BlocConsumer<VibeChatBloc, VibeChatState>(
      listener: _handleBlocStateChanges,
      builder: (context, state) {
        return Scaffold(
          endDrawer: _buildDrawer(context,state),
          appBar: _buildAppBar(state),
          body: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.only(
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
                if (state.shouldShowAcceptButton && state.step == VibeChatStep.loaded)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<VibeChatBloc>().add(AcceptChangesEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        child: Text(localization.acceptChanges),
                      ),
                    ),
                  ),
                if (state.step == VibeChatStep.sending || state.step == VibeChatStep.transcribing)
                  _buildAnimatedLoadingWidget(state.step==VibeChatStep.transcribing),
                MessageInput(
                  controller: _messageController,
                ),
              ],
            ),
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
