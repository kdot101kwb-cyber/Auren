enum AudioSessionStatus { planned, recording, recorded, reviewed, exported, discarded }

class AudioMarker {
  final Duration offset;
  final String label;

  AudioMarker({required this.offset, required this.label}) {
    if (offset.isNegative) throw ArgumentError.value(offset, 'offset');
    if (label.trim().isEmpty) throw ArgumentError.value(label, 'label');
  }
}

/// Metadata for a recording/editing session; this model does not itself record,
/// transform, or export audio bytes.
class AurenAudioSession {
  final String id;
  final String ownerId;
  final String title;
  final AudioSessionStatus status;
  final String? sourcePath;
  final String? exportedPath;
  final Duration? duration;
  final List<AudioMarker> markers;
  final DateTime createdAt;
  final DateTime updatedAt;

  AurenAudioSession({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourcePath,
    this.exportedPath,
    this.duration,
    List<AudioMarker> markers = const [],
  }) : markers = List.unmodifiable(markers) {
    if (id.trim().isEmpty || ownerId.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Session id, owner, and title are required.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot be earlier than createdAt.');
    }
    if (duration != null && duration!.isNegative) {
      throw ArgumentError.value(duration, 'duration');
    }
    if (status.index >= AudioSessionStatus.recorded.index &&
        status != AudioSessionStatus.discarded &&
        (sourcePath == null || sourcePath!.trim().isEmpty)) {
      throw ArgumentError('Recorded sessions require a source path.');
    }
    if (status == AudioSessionStatus.exported &&
        (exportedPath == null || exportedPath!.trim().isEmpty)) {
      throw ArgumentError('Exported sessions require an exported path.');
    }
  }
}
