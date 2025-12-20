import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VibeChat extends StatefulWidget {
  @override
  State<VibeChat> createState() => _VibeChatState();
}

class _VibeChatState extends State<VibeChat> {
  late final ScrollController _scrollController;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late MediaQueryData mediaQuery;
  late double screenHeight ;
  late double  screenWidth ;
  late TileThemeExtension tileThemeExtension;
  late AppLocalizations localization;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 100 ){
        final state = context.read<VibeChatBloc>().state;
        if (state.step  == VibeChatStep.loaded && state.hasMoreMessages) {
          context.read<VibeChatBloc>().add(LoadMoreMessagesEvent());
        }
      }
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    mediaQuery=MediaQuery.of(context);
    screenWidth=mediaQuery.size.width;
    screenHeight=mediaQuery.size.height;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    localization= AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    NotificationOverlayMessage notificationOverlayMessage =
    NotificationOverlayMessage();
    return BlocConsumer<VibeChatBloc, VibeChatState>(
        listener: (context, state) {
          if (state.step == VibeChatStep.loaded) {
            _messageController.clear();
          }
          if (state.step == VibeChatStep.error && state.error != null) {
            notificationOverlayMessage.showToast(
                context,
                state.error!,
                NotificationOverlayMessageType.error
            );
          }
        },
        builder: (context, state) {
        return Container(
          height: screenHeight * 0.6,
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
              _buildHandle(),
              Flexible(
                child: _buildContent(state),
              ),
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final isSending = state.step == VibeChatStep.sending;
        final hasText = _messageController.text.trim().isNotEmpty;

        return SafeArea(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20,vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !isSending,
                    decoration: InputDecoration(
                      hintText: localization.describeATask,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        left: 20,
                        right: 12,
                        top: 14,
                        bottom: 14,
                      ),
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.4,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal:4,vertical: 2),
                  child: isSending
                      ? Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                      : IconButton(
                    onPressed: hasText
                        ? () {
                      context.read<VibeChatBloc>().add(
                        SendAMessageEvent(
                          _messageController.text.trim(),
                        ),
                      );
                    }
                        : (){},
                    icon: Icon(Icons.arrow_upward_rounded),
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      backgroundColor: hasText
                          ? colorScheme.primary
                          : tileThemeExtension.surfaceContainerGreater,
                      foregroundColor: hasText
                          ? colorScheme.onPrimary
                          : tileThemeExtension.onSurfaceVariantSecondary,
                      minimumSize: Size(36, 36),
                      maximumSize: Size(36, 36),
                      shape: CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle(){
    return  Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      width: screenWidth * 0.3,
      height: 5,
      decoration: BoxDecoration(
        color: tileThemeExtension.vibeChatModalBottomSheetHandle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }



  Widget _buildContent(VibeChatState state) {
    if (state.step == VibeChatStep.loading) {
      return PendingWidget();
    }

    if (state.step == VibeChatStep.loaded ||
        state.step == VibeChatStep.loadingMore ||
        state.step == VibeChatStep.sending ||
        state.step == VibeChatStep.error) {
      if (state.messages.isEmpty) {
        return _buildEmptyChat();
      }
      return Column(
        children: [
          if (state.step == VibeChatStep.loadingMore)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              controller: _scrollController,
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  final isUser = message.origin == MessageOrigin.user;

                  return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                    child: Column(
                      children: [
                        _buildMessage(message.content ?? '', isUser, screenWidth),
                        if (message.actions != null && message.actions!.isNotEmpty)
                          ...message.actions!
                              .where((action) => action.type !=  'conversational_and_not_supported')
                              .map((action) =>
                              _buildActionTile(action: action)
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }


    return SizedBox.shrink();
  }

  Widget _buildEmptyChat(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/tiler_logo_black.png',
            height: 64,
            width: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            localization.whatWouldYouLikeToDo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            localization.describeATask,
            style: TextStyle(
              fontSize: 14,
              color: tileThemeExtension.onSurfaceVariantSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required VibeAction action,
  }) {
    final statusColor = _getActionStatusColor(action.status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(5),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionIcon(action),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                action.descriptions ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
             SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  dynamic _getActionIconPath(VibeAction action) {
    switch (action.type) {
      case 'add_new_appointment':
        return 'assets/icons/vibeChat/add_block.svg';
      case 'add_new_task':
        return 'assets/icons/vibeChat/add_new_tile.svg';
      case 'update_existing_task':
        return 'assets/icons/vibeChat/update_tile.svg';
      case 'remove_existing_task':
        return 'assets/icons/vibeChat/delete_tile.svg';
      case 'procrastinate_all_tasks':
        return 'assets/icons/vibeChat/clear_all.svg';
      case 'exit_prompting':
        return 'assets/icons/vibeChat/exited_action.svg';
      case 'add_new_project':
        return '📋';
      case 'decide_if_task_or_project':
        return '🤔';
      case 'mark_task_as_done':
        return '✓';
      case 'whatif_addanewappointment':
        return '📅❓';
      case 'whatif_addednewtask':
        return '✅❓';
      case 'whatif_editupdatetask':
        return '✏️❓';
      case 'whatif_procrastinatetask':
        return '⏱️❓';
      case 'whatif_removedtask':
        return '🗑️❓';
      case 'whatif_markedtaskasdone':
        return '✓❓';
      case 'whatif_procrastinateall':
        return '⏱️❓';
      case 'conversational_and_not_supported':
        return '💬';
      case 'none':
        return '⚪';
      default:
        return '🔹';
    }
  }

  Widget _buildActionIcon(VibeAction action) {
    final icon = _getActionIconPath(action);
    if (icon is String && icon.endsWith('.svg')) {
      return SvgPicture.asset(
        icon,
        width: 14,
        height: 14,
      );
    } else {
      return Text(
        icon,
        style: TextStyle(fontSize: 14),
      );
    }
  }

  Widget _buildMessage(String text, bool isUser, double width) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: width * 0.65),
            decoration: BoxDecoration(
              color: isUser
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 16 : 4),
                topRight: Radius.circular(isUser ? 4 : 16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isUser
                    ? colorScheme.onSurface
                    : colorScheme.onPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getActionStatusColor(ActionStatus? status) {
    switch (status) {
      case ActionStatus.parsed:
        return TileColors.vibeChatParsedAction;
      case ActionStatus.clarification:
        return TileColors.vibeChatClarificationAction;
      case ActionStatus.pending:
        return TileColors.vibeChatPendingAction;
      case ActionStatus.executed:
        return TileColors.vibeChatExecutedAction;
      case ActionStatus.failed:
        return TileColors.vibeChatFailedAction;
      case ActionStatus.exited:
        return tileThemeExtension.vibeChatExitedAction;
      case ActionStatus.disposed:
        return tileThemeExtension.vibeChatDisposedAction;
      default:
        return tileThemeExtension.vibeChatDefaultAction;
    }
  }
}
