import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/ActionsList.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  late AppLocalizations localization;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(() {
      final atBottom = widget.scrollController.position.pixels <= 50;
      if (atBottom != _isAtBottom) setState(() => _isAtBottom = atBottom);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=Theme.of(context).extension<TileThemeExtension>()!;
    localization = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.step == VibeChatStep.loading) {
      return PendingWidget();
    }

    if (widget.state.step != VibeChatStep.loading) {
      if (widget.state.messages.isEmpty) {
        return _buildEmptyChat(context);
      }
      return _buildMessageList(context);
    }

    return SizedBox.shrink();
  }

  Widget _buildMessageList(BuildContext context) {
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
              child: ListView.builder(
                findChildIndexCallback: (Key key) {
                  final id = (key as ValueKey<String>).value.replaceFirst('msg_', '');
                  final index = widget.state.messages.indexWhere((m) => m.id == id);
                  if (index == -1) return null;
                  return widget.state.messages.length - 1 - index;
                },
                reverse: true,
                padding: EdgeInsets.all(16),
                itemCount: widget.state.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.state.messages[widget.state.messages.length - 1 - index];
                  final isUser = message.origin == MessageOrigin.user;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('msg_${message.id}'),
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
                        _buildMessage(context, message.content ?? '', isUser),
                        if (message.actions != null && message.actions!.isNotEmpty)
                          ActionsList(
                            actions:message.actions!,
                            requestId:message.requestId,
                            state:widget.state,
                          ),
                ]
                    ),
                  );
                },
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

  Widget _buildEmptyChat(BuildContext context) {
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

  Widget _buildMessage(BuildContext context, String text, bool isUser) {
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
}
