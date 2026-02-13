import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class TextMessageInput extends StatefulWidget {
  final TextEditingController controller;

  const TextMessageInput({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<TextMessageInput> createState() => _TextMessageInputState();
}

class _TextMessageInputState extends State<TextMessageInput> {
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;


  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final localization= AppLocalizations.of(context)!;
    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final isSending = state.step == VibeChatStep.sending;
        final isTranscribing = state.step == VibeChatStep.transcribing;
        final hasText = widget.controller.text.trim().isNotEmpty;


        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                scrollPadding: EdgeInsets.only(bottom: 100),
                controller: widget.controller,
                enabled: state.step == VibeChatStep.loaded,
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
            _buildActionButton(
              state,
              isSending,
              isTranscribing,
              hasText,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
      VibeChatState state,
      bool isSending,
      bool isTranscribing,
      bool hasText,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: (isSending || isTranscribing)
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
        onPressed: state.step != VibeChatStep.loaded
          ? null
          : (hasText ? _handleSendMessage : () => context.read<VibeChatBloc>().add(StartRecordingEvent())),
        icon: Icon(
          hasText ? Icons.arrow_upward_rounded : Icons.mic_none_rounded,
        ),
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
    );
  }

  void _handleSendMessage() {
    context.read<VibeChatBloc>().add(
      SendAMessageEvent(widget.controller.text.trim()),
    );
  }


}