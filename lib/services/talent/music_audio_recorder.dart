import 'dart:io';
import 'dart:math' as math;

import 'package:fftea/fftea.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AurenMusicAudioAnalysis {
  final double sampleRate;
  final double rms;
  final double? frequencyHz;
  final String? note;
  final double? cents;
  final double pitchConfidence;

  const AurenMusicAudioAnalysis({
    required this.sampleRate,
    required this.rms,
    required this.frequencyHz,
    required this.note,
    required this.cents,
    required this.pitchConfidence,
  });

  bool get hasPitch => frequencyHz != null;

  Map<String, dynamic> toMap() => {
        'sampleRate': sampleRate,
        'rms': rms,
        'frequencyHz': frequencyHz,
        'note': note,
        'cents': cents,
        'pitchConfidence': pitchConfidence,
      };
}

/// Captures WAV audio and performs a lightweight, offline pitch/energy analysis.
class AurenMusicAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> requestPermission() => _recorder.hasPermission();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<String?> startWavRecording() async {
    if (!await _recorder.hasPermission()) return null;

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

  /// Reads a PCM16 WAV file, estimates RMS and the dominant frequency.
  Future<AurenMusicAudioAnalysis?> analyzeWav(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.length < 44) return null;

    final header = bytes.sublist(0, 44);
    if (String.fromCharCodes(header.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(header.sublist(8, 12)) != 'WAVE') {
      return null;
    }

    final channels = _u16(header, 22);
    final sampleRate = _u32(header, 24).toDouble();
    final bitsPerSample = _u16(header, 34);
    if (channels < 1 || bitsPerSample != 16 || sampleRate <= 0) return null;

    final dataOffset = _findDataChunk(bytes);
    if (dataOffset == null) return null;

    final samples = <double>[];
    for (var i = dataOffset; i + 1 < bytes.length; i += 2 * channels) {
      final value = _i16(bytes, i) / 32768.0;
      samples.add(value);
    }
    if (samples.length < 1024) return null;

    var sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    final rms = math.sqrt(sumSquares / samples.length);

    final frameLength = math.min(8192, _largestPowerOfTwo(samples.length));
    final frame = samples.sublist(0, frameLength);
    final fft = FFT(frameLength);
    final spectrum = fft.realFft(frame).discardConjugates().magnitudes();

    var bestBin = 0;
    var bestMagnitude = 0.0;
    final maxBin = math.min(spectrum.length - 1, (1200 * frameLength / sampleRate).floor());
    final minBin = math.max(1, (60 * frameLength / sampleRate).floor());

    for (var bin = minBin; bin <= maxBin; bin++) {
      final magnitude = spectrum[bin].abs();
      if (magnitude > bestMagnitude) {
        bestMagnitude = magnitude;
        bestBin = bin;
      }
    }

    if (bestBin == 0 || bestMagnitude == 0) {
      return AurenMusicAudioAnalysis(
        sampleRate: sampleRate,
        rms: rms,
        frequencyHz: null,
        note: null,
        cents: null,
        pitchConfidence: 0,
      );
    }

    final frequency = bestBin * sampleRate / frameLength;
    final midi = 69 + 12 * (math.log(frequency / 440) / math.ln2);
    final roundedMidi = midi.round();
    final cents = (midi - roundedMidi) * 100;
    final noteNames = const ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final note = '${noteNames[roundedMidi % 12]}${(roundedMidi ~/ 12) - 1}';

    final confidence = (bestMagnitude / math.max(0.000001, frameLength * rms))
        .clamp(0.0, 1.0);

    return AurenMusicAudioAnalysis(
      sampleRate: sampleRate,
      rms: rms,
      frequencyHz: frequency,
      note: note,
      cents: cents,
      pitchConfidence: confidence,
    );
  }

  int _u16(List<int> b, int o) => b[o] | (b[o + 1] << 8);

  int _u32(List<int> b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  int _i16(List<int> b, int o) {
    final v = _u16(b, o);
    return v >= 0x8000 ? v - 0x10000 : v;
  }

  int? _findDataChunk(List<int> b) {
    var offset = 12;
    while (offset + 8 <= b.length) {
      final id = String.fromCharCodes(b.sublist(offset, offset + 4));
      final size = _u32(b, offset + 4);
      if (id == 'data') return offset + 8;
      offset += 8 + size;
      if (offset.isOdd) offset++;
    }
    return null;
  }

  int _largestPowerOfTwo(int value) {
    var result = 1;
    while (result * 2 <= value) {
      result *= 2;
    }
    return result;
  }
}
