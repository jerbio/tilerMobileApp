import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/MessageList.dart';
import 'package:tiler_app/components/vibeChat/messageInput.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class VibeChat extends StatefulWidget {
  @override
  State<VibeChat> createState() => _VibeChatState();
}

class _VibeChatState extends State<VibeChat> {
  late final ScrollController _scrollController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _setupScrollListener();
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
    if (state.step == VibeChatStep.sending && state.messages.isNotEmpty) {
      _messageController.clear();
    }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;

    return BlocConsumer<VibeChatBloc, VibeChatState>(
      listener: _handleBlocStateChanges,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: mediaQuery.viewInsets.bottom,
          ),
          child: Container(
            height: screenHeight ,
            width: screenWidth,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                _buildHandle(screenWidth, tileThemeExtension),
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

  Widget _buildHandle(double screenWidth, TileThemeExtension tileThemeExtension) {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      width: screenWidth * 0.3,
      height: 5,
      decoration: BoxDecoration(
        color: tileThemeExtension.vibeChatModalBottomSheetHandle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
