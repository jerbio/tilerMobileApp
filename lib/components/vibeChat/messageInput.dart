import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/textMessageInput.dart';
import 'package:tiler_app/components/vibeChat/audioRecordingInput.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;

  const MessageInput({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<VibeChatBloc, VibeChatState>(
      builder: (context, state) {
        final isRecording = state.step == VibeChatStep.recording;

        return SafeArea(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isRecording ? colorScheme.error : colorScheme.outlineVariant,
                width: isRecording ? 2 : 1,
              ),
            ),
            child: isRecording
                ? AudioRecordingInput(
            )
                : TextMessageInput(
              controller: widget.controller,
            ),
          ),
        );
      },
    );
  }
}