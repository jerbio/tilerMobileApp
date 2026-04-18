import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageList extends StatefulWidget {
  final VibeChatState state;
  final ScrollController scrollController;


  const MessageList({
    Key? key,
    required this.state,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(() {
      final atBottom = widget.scrollController.position.pixels <= 50;
      if (atBottom != _isAtBottom) setState(() => _isAtBottom = atBottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (widget.state.step == VibeChatStep.loading) {
      return PendingWidget();
    }

    if (widget.state.step != VibeChatStep.loading) {
      if (widget.state.messages.isEmpty) {
        return _buildEmptyChat(context,localization);
      }
      return _buildMessageList(context,localization);
    }

    return SizedBox.shrink();
  }

  Widget _buildMessageList(BuildContext context,AppLocalizations localization) {
    return Stack(
      children: [
        Column(
          children: [
            if (widget.state.step == VibeChatStep.loadingMoreMessages)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                controller: widget.scrollController,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  itemCount: widget.state.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.state.messages[index];
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
                          _buildMessage(context, message.content ?? '', isUser,localization),
                          if (message.actions != null && message.actions!.isNotEmpty)
                            ...message.actions!
                                .where((action) =>
                            action.type != 'conversational_and_not_supported')
                                .map((action) => _buildActionTile(context,requestId: message.requestId, action: action)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        if (!_isAtBottom)
          Positioned(
            bottom: 12, right: 12,
            child:ElevatedButton(
              onPressed: () => widget.scrollController.animateTo(
                0, duration: Duration(milliseconds: 100), curve: Curves.easeOut,
              ),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(12),
              ),
              child: Icon(Icons.arrow_downward_rounded),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyChat(BuildContext context,AppLocalizations localization) {
    final tileThemeExtension = Theme.of(context).extension<TileThemeExtension>()!;

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

  String _linkifyText(String text) {
    final urlRegex = RegExp(r'(?<!\[)(?<!\()https?://[^\s\)\]]+', caseSensitive: false);
    return text.replaceAllMapped(urlRegex, (match) {
      final url = match.group(0)!;
      return '[$url]($url)';
    });
  }

  Widget _buildMessage(BuildContext context, String text, bool isUser,AppLocalizations localization) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Builder(
        builder: (innerContext) => GestureDetector(
          onLongPress: () {
            final RenderBox renderBox = innerContext.findRenderObject() as RenderBox;
            final offset = renderBox.localToGlobal(Offset.zero);
            showMenu(
              context: innerContext,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              position: RelativeRect.fromLTRB(offset.dx, offset.dy - 50, offset.dx + 100, offset.dy),
              items: [
                PopupMenuItem(
                  height: 36,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 16),
                      SizedBox(width: 6),
                      Text(localization.copy, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  onTap: () => Clipboard.setData(ClipboardData(text: text)),
                ),
              ],
            );
          },
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.65),
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


            child: GptMarkdown(
            _linkifyText(text),
            style: TextStyle(
              color: isUser ? colorScheme.onSurface : colorScheme.onPrimary,
            ),
            linkBuilder: (context, text, url, style) => GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                url,
                style: const TextStyle(
                  color: TileColors.vibeChatLinkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: TileColors.vibeChatLinkColor,
                ),
              ),
            ),
                      ),
          ),
        ),
       ),
      // )
    );
  }

  Widget _buildActionTile(BuildContext context, {required VibeAction action, String? requestId}) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileThemeExtension = Theme.of(context).extension<TileThemeExtension>()!;
    final statusColor = _getActionStatusColor(action.status, tileThemeExtension);

    return GestureDetector(
      onTap: () {
        if (widget.state.step != VibeChatStep.loaded) return;
        const nonClickableTypes = {
          'remove_existing_task',
          'whatif_removedtask',
          'conversational_and_not_supported',
          'none',
        };
        const nonClickableStatuses = {
          ActionStatus.executed,
          ActionStatus.failed,
          ActionStatus.exited,
          ActionStatus.disposed,
        };

        if (nonClickableTypes.contains(action.type)) return;
        if (nonClickableStatuses.contains(action.status)) return;

        if (requestId != null) {
          context.read<VibeChatBloc>().add(PreviewActionEvent(requestId, action.id ?? ''));
        }
      },
      child: Align(
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
      ),
    );
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

  Color _getActionStatusColor(ActionStatus? status, TileThemeExtension theme) {
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
        return theme.vibeChatExitedAction;
      case ActionStatus.disposed:
        return theme.vibeChatDisposedAction;
      default:
        return theme.vibeChatDefaultAction;
    }
  }
}
