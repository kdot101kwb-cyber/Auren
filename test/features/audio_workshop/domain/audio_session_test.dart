import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/audio_workshop/domain/audio_session.dart';

void main() {
  final date = DateTime.utc(2026, 1, 1);

  test('validates recorded and exported session paths', () {
    expect(() => AurenAudioSession(
      id: 'audio-1', ownerId: 'user-1', title: 'Voice note',
      status: AudioSessionStatus.recorded, createdAt: date, updatedAt: date,
    ), throwsArgumentError);
    expect(() => AurenAudioSession(
      id: 'audio-1', ownerId: 'user-1', title: 'Voice note',
      status: AudioSessionStatus.exported, sourcePath: '/tmp/source.wav',
      createdAt: date, updatedAt: date,
    ), throwsArgumentError);
  });

  test('keeps markers immutable and validates marker positions', () {
    final markers = <AudioMarker>[AudioMarker(offset: const Duration(seconds: 3), label: 'Intro')];
    final session = AurenAudioSession(
      id: 'audio-1', ownerId: 'user-1', title: 'Voice note',
      status: AudioSessionStatus.recorded, sourcePath: '/tmp/source.wav',
      duration: const Duration(seconds: 10), createdAt: date, updatedAt: date,
      markers: markers,
    );
    markers.clear();
    expect(session.markers, hasLength(1));
    expect(() => session.markers.clear(), throwsUnsupportedError);
    expect(() => AudioMarker(offset: const Duration(seconds: -1), label: 'Bad'), throwsArgumentError);
    expect(() => AudioMarker(offset: Duration.zero, label: ' '), throwsArgumentError);
  });

  test('rejects negative duration and invalid timestamps', () {
    expect(() => AurenAudioSession(
      id: 'audio-1', ownerId: 'user-1', title: 'Voice note',
      status: AudioSessionStatus.planned, duration: const Duration(seconds: -1),
      createdAt: date, updatedAt: date,
    ), throwsArgumentError);
    expect(() => AurenAudioSession(
      id: 'audio-1', ownerId: 'user-1', title: 'Voice note',
      status: AudioSessionStatus.planned, createdAt: date,
      updatedAt: date.subtract(const Duration(seconds: 1)),
    ), throwsArgumentError);
  });
}
