enum AurenDocumentStatus { draft, readyForReview, finalized, archived }

class AurenDocumentRevision {
  final int number;
  final String title;
  final String body;
  final DateTime savedAt;

  AurenDocumentRevision({
    required this.number,
    required this.title,
    required this.body,
    required this.savedAt,
  }) {
    if (number < 1) throw ArgumentError.value(number, 'number');
    if (title.trim().isEmpty) throw ArgumentError.value(title, 'title');
  }
}

class AurenDocument {
  final String id;
  final String ownerId;
  final String title;
  final String body;
  final AurenDocumentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AurenDocumentRevision> revisions;

  AurenDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    List<AurenDocumentRevision> revisions = const [],
  }) : revisions = List.unmodifiable(revisions) {
    if (id.trim().isEmpty || ownerId.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Document id, owner, and title are required.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot be earlier than createdAt.');
    }
    final numbers = this.revisions.map((revision) => revision.number).toSet();
    if (numbers.length != this.revisions.length) {
      throw ArgumentError('Revision numbers must be unique.');
    }
  }

  AurenDocument copyWith({
    String? title,
    String? body,
    AurenDocumentStatus? status,
    DateTime? updatedAt,
    List<AurenDocumentRevision>? revisions,
  }) => AurenDocument(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        body: body ?? this.body,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        revisions: revisions ?? this.revisions,
      );
}
