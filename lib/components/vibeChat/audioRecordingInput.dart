
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/components/vibeChat/recordingAudioWavePainter.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'dart:async';

class AudioRecordingInput extends StatefulWidget {
  const AudioRecordingInput({Key? key}) : super(key: key);

  @override
  State<AudioRecordingInput> createState() => _AudioRecordingInputState();
}

class _AudioRecordingInputState extends State<AudioRecordingInput>  with TickerProviderStateMixin {

  late AnimationController _animationController;
  StreamSubscription<double>? _amplitudeSubscription;
  double _currentAmplitude = 0.2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat();

    _subscribeToAmplitude();
  }
  void _subscribeToAmplitude() {
    _amplitudeSubscription = context
        .read<VibeChatBloc>()
        .amplitudeStream
        .listen((amplitude) {
      if (mounted) {
        setState(() {
          _currentAmplitude = amplitude.clamp(0.1, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileThemeExtension = Theme.of(context).extension<TileThemeExtension>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 4),
        IconButton(
          onPressed: () => context.read<VibeChatBloc>().add(CancelRecordingEvent()),
          icon: Icon(Icons.close),
          iconSize: 20,
          style: IconButton.styleFrom(
            backgroundColor: tileThemeExtension.surfaceContainerGreater,
            foregroundColor: colorScheme.onError,
            minimumSize: Size(36, 36),
            maximumSize: Size(36, 36),
            shape: CircleBorder(),
          ),
        ),
        SizedBox(width: 4),

        Expanded(
          child: Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: recordingAudioWavePainter(
                    animation: _animationController,
                    amplitude: _currentAmplitude,
                    color: colorScheme.primary,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),
        SizedBox(width: 4),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: IconButton(
            onPressed: () => context.read<VibeChatBloc>().add(StopRecordingAndTranscribeEvent()),
            icon: Icon(Icons.stop),
            iconSize: 20,
            style: IconButton.styleFrom(
              backgroundColor: tileThemeExtension.surfaceContainerGreater,
              foregroundColor: colorScheme.onError,
              minimumSize: Size(36, 36),
              maximumSize: Size(36, 36),
              shape: CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
