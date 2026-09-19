class AurenGoal {
  final String id;
  final String title;
  final String? description;
  final int progress;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AurenGoal({
    required this.id,
    required this.title,
    this.description,
    required this.progress,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'progress': progress,
        'status': status,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory AurenGoal.fromMap(String id, Map<String, dynamic> map) => AurenGoal(
        id: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String?,
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        status: map['status'] as String? ?? 'active',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
