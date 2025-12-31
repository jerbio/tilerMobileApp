import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  AudioRecorder? _audioRecorder;
  String? _currentRecordingPath;
  // Amplitude is an object from the record package containing audio volume measurements
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  StreamController<double>? _amplitudeController;
  Stream<double> get amplitudeStream => _amplitudeController?.stream ?? Stream.empty();

  Future<void> startRecording() async {
    try {
      _audioRecorder = AudioRecorder();
      bool hasPermission = await _audioRecorder!.hasPermission();

      if (!hasPermission) {
        await openAppSettings();
        await cancelRecording();
        throw TilerError(
            Message: LocalizationService.instance.translations.microphonePermissionDenied
        );
      }
      _amplitudeController = StreamController<double>.broadcast();
      final directory = await getApplicationDocumentsDirectory();
      final pcmPath = '${directory.path}/audio_${DateTime
          .now()
          .millisecondsSinceEpoch}.pcm';
      _currentRecordingPath = pcmPath;

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 48000,
          numChannels: 1,
        ),
        path: pcmPath,
      );

      _amplitudeSubscription = _audioRecorder!
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        double normalized;
        if (amp.current < -40) {
          normalized = 0.2;
        } else {
          normalized = ((amp.current + 50) / 50).clamp(0.2, 1.0);
        }
        _amplitudeController!.add(normalized);
      }
      );
    }catch (e) {
      await cancelRecording();

      if (e is TilerError) {
        rethrow;
      }
      throw TilerError(Message: LocalizationService.instance.translations.failedToStartRecording(e.toString()));
    }
  }

  Future<String> _convertPcmToWebm(String pcmPath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final webmPath = '${dir.path}/audio_$timestamp.webm';

      await FFmpegKit.execute(
          '-f s16le -ar 48000 -ac 1 -i "$pcmPath" -c:a libopus -b:a 128k "$webmPath"'
      );

      if (!await File(webmPath).exists()) {
        throw TilerError(Message: LocalizationService.instance.translations.audioConversionFailed);
      }

      await File(pcmPath).delete();

      return webmPath;

    } catch (e) {
      if (e is TilerError) {
        rethrow;
      }
      throw TilerError(Message: LocalizationService.instance.translations.audioConversionError(e.toString()));
    }
  }

  Future<String> stopRecording() async {
    if (_audioRecorder == null) {
      throw TilerError(Message: LocalizationService.instance.translations.noActiveRecording);
    }

    try {
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      await _audioRecorder!.stop();
      await _audioRecorder!.dispose();

      _amplitudeController?.close();
      _amplitudeController = null;

      final path = _currentRecordingPath;
      _audioRecorder = null;
      _currentRecordingPath = null;

      if (path == null || path.isEmpty) {
        throw TilerError(Message: LocalizationService.instance.translations.recordingPathIsEmpty);
      }

      return await _convertPcmToWebm(path);

    } catch (e) {
      if (e is TilerError) {
        rethrow;
      }
      throw TilerError(Message: LocalizationService.instance.translations.failedToStopRecording(e.toString()));
    }
  }

  Future<void> cancelRecording() async {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (_audioRecorder != null) {
      await _audioRecorder!.stop();
      await _audioRecorder!.dispose();
      _audioRecorder = null;
    }

    if (_currentRecordingPath != null) {
      try {
        await File(_currentRecordingPath!).delete();
      } catch (_) {}
      _currentRecordingPath = null;
    }
    _amplitudeController?.close();
    _amplitudeController = null;
  }

  void dispose() {
    _amplitudeSubscription?.cancel();
    _amplitudeController?.close();
    _audioRecorder?.dispose();
  }

}