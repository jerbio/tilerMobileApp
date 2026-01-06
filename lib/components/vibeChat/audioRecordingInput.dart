
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'dart:async';

class AudioRecordingInput extends StatefulWidget {
  const AudioRecordingInput({Key? key}) : super(key: key);

  @override
  State<AudioRecordingInput> createState() => _AudioRecordingInputState();
}

class _AudioRecordingInputState extends State<AudioRecordingInput> {
  List<double> _waveformHeights = List.generate(30, (_) => 0.2);
  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _scrollTimer;
  double _latestAmplitude = 0.2;

  @override
  void initState() {
    super.initState();
    _subscribeToAmplitude();
  }

  void _subscribeToAmplitude() {
    _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final displayHeight = _latestAmplitude == 0.2
            ? 0.15 + (DateTime.now().millisecond % 10) * 0.01
            : _latestAmplitude;
        _waveformHeights = [..._waveformHeights.sublist(1), displayHeight];
      });
    });

    _amplitudeSubscription = context.read<VibeChatBloc>()
        .amplitudeStream
        .listen((amplitude) {
      _latestAmplitude = amplitude;
    });
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _scrollTimer?.cancel();
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
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _waveformHeights.map((height) {
                return Container(
                  width: 3,
                  height: height * 50,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
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