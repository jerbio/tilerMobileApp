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

class _VibeChatState extends State<VibeChat> {
  late final ScrollController _scrollController;
  late final TextEditingController _messageController;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late AppLocalizations localization ;
  VibeChatStep? _previousStep;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    context.read<VibeChatBloc>().add(LoadSessionsEvent());
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
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleBlocStateChanges(BuildContext context, VibeChatState state) {



    if (_previousStep == VibeChatStep.sending && state.step == VibeChatStep.loaded) {
      _messageController.clear();
    }
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
        onPressed: () => Navigator.pop(context),
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
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: Text(localization.acceptChanges),
                      ),
                    ),
                  ),
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

}
