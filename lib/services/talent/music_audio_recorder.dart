import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records microphone audio for AUREN Music Talent.
///
/// This is the capture layer only. DSP/FFT analysis should consume the
/// resulting WAV/PCM data separately so recording and analysis stay testable.
class AurenMusicAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> requestPermission() => _recorder.hasPermission();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<String?> startWavRecording() async {
    if (!await _recorder.hasPermission()) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/auren_music_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: file.path,
    );

    return file.path;
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<void> cancelRecording() => _recorder.cancel();

  Future<void> dispose() => _recorder.dispose();
}
