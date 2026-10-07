enum LiveSessionType { normal, hybrid }

enum LiveMode { normal, skill }

enum LiveSessionStatus { live, ended, cancelled }

class LiveSkillSegment {
  final String id;
  final LiveMode mode;
  final String skillId;
  final DateTime startedAt;
  final DateTime? endedAt;

  const LiveSkillSegment({
    required this.id,
    required this.mode,
    this.skillId = '',
    required this.startedAt,
    this.endedAt,
  });

  bool get isOpen => endedAt == null;

  LiveSkillSegment copyWith({
    DateTime? endedAt,
    bool clearEndedAt = false,
  }) => LiveSkillSegment(
        id: id,
        mode: mode,
        skillId: skillId,
        startedAt: startedAt,
        endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'mode': mode.name,
        'skillId': skillId,
        'startedAt': startedAt.toUtc().toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
      };

  factory LiveSkillSegment.fromMap(Map<String, dynamic> map) {
    final modeName = map['mode']?.toString() ?? LiveMode.normal.name;
    return LiveSkillSegment(
      id: map['id']?.toString() ?? '',
      mode: LiveMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => LiveMode.normal,
      ),
      skillId: map['skillId']?.toString() ?? '',
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endedAt: DateTime.tryParse(map['endedAt']?.toString() ?? '')?.toUtc(),
    );
  }
}

class LiveSession {
  final String id;
  final String ownerId;
  final String title;
  final LiveSessionType type;
  final LiveMode currentMode;
  final LiveSessionStatus status;
  final String currentSkillId;
  final DateTime createdAt;
  final DateTime? endedAt;
  final List<LiveSkillSegment> segments;

  const LiveSession({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.currentMode,
    required this.status,
    this.currentSkillId = '',
    required this.createdAt,
    this.endedAt,
    this.segments = const [],
  });

  bool get isLive => status == LiveSessionStatus.live;
  bool get isSkillSession => currentMode == LiveMode.skill;

  LiveSession copyWith({
    LiveMode? currentMode,
    LiveSessionStatus? status,
    String? currentSkillId,
    DateTime? endedAt,
    bool clearEndedAt = false,
    List<LiveSkillSegment>? segments,
  }) => LiveSession(
        id: id,
        ownerId: ownerId,
        title: title,
        type: type,
        currentMode: currentMode ?? this.currentMode,
        status: status ?? this.status,
        currentSkillId: currentSkillId ?? this.currentSkillId,
        createdAt: createdAt,
        endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
        segments: segments ?? this.segments,
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        'type': type.name,
        'currentMode': currentMode.name,
        'status': status.name,
        'currentSkillId': currentSkillId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
        'segments': segments.map((segment) => segment.toMap()).toList(),
      };

  factory LiveSession.fromMap(String id, Map<String, dynamic> map) {
    final typeName = map['type']?.toString() ?? LiveSessionType.normal.name;
    final modeName = map['currentMode']?.toString() ?? LiveMode.normal.name;
    final statusName = map['status']?.toString() ?? LiveSessionStatus.ended.name;
    final rawSegments = map['segments'];
    return LiveSession(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      type: LiveSessionType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => LiveSessionType.normal,
      ),
      currentMode: LiveMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => LiveMode.normal,
      ),
      status: LiveSessionStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => LiveSessionStatus.ended,
      ),
      currentSkillId: map['currentSkillId']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endedAt: DateTime.tryParse(map['endedAt']?.toString() ?? '')?.toUtc(),
      segments: rawSegments is List
          ? rawSegments
              .whereType<Map>()
              .map((value) => LiveSkillSegment.fromMap(Map<String, dynamic>.from(value)))
              .toList()
          : const [],
    );
  }
}
