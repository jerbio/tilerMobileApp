import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/MessageList.dart';
import 'package:tiler_app/components/vibeChat/messageInput.dart';

class VibeChat extends StatefulWidget {
  @override
  State<VibeChat> createState() => _VibeChatState();
}

class _VibeChatState extends State<VibeChat> {
  late final ScrollController _scrollController;
  late final TextEditingController _messageController;
  late ThemeData theme;
  late ColorScheme colorScheme;
  VibeChatStep? _previousStep;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _setupScrollListener();
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
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

  PreferredSizeWidget _buildAppBar(){
    return AppBar(
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
        color: colorScheme.onSurface,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.menu),
          color: colorScheme.onSurface,
          onPressed: () {
            // TODO: Implement chat history
          },
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
          appBar: _buildAppBar(),
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
