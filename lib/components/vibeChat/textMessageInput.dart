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
  Timer? _dotTimer;
  int _dotCount = 0;
  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }
  void _startDotAnimation() {
    _dotTimer?.cancel();
    _dotCount = 0;
    _dotTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  void _stopDotAnimation() {
    _dotTimer?.cancel();
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileThemeExtension = Theme.of(context).extension<TileThemeExtension>()!;
    final localization = AppLocalizations.of(context)!;

    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final isSending = state.step == VibeChatStep.sending;
        final isTranscribing = state.step == VibeChatStep.transcribing;
        final hasText = widget.controller.text.trim().isNotEmpty;

        if (isTranscribing && _dotTimer == null) {
          _startDotAnimation();
        } else if (!isTranscribing && _dotTimer != null) {
          _stopDotAnimation();
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                scrollPadding: EdgeInsets.only(bottom: 100),
                controller: widget.controller,
                enabled: state.step == VibeChatStep.loaded,
                decoration: InputDecoration(
                  hintText: isTranscribing ? 'Transcribing${'.' * _dotCount}' : localization.describeATask,
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
              colorScheme,
              tileThemeExtension,
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
      ColorScheme colorScheme,
      TileThemeExtension tileThemeExtension,
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
        onPressed: (isSending || isTranscribing || state.step == VibeChatStep.loading)
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