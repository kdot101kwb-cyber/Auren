enum CreativeProjectStatus { planning, active, paused, completed, archived }

enum CreativeAssetKind { document, image, audio, video, other }

class CreativeAssetReference {
  final String id;
  final String name;
  final CreativeAssetKind kind;
  final String uri;
  final String? contentType;
  final int? sizeBytes;
  final String? checksum;
  final DateTime addedAt;

  CreativeAssetReference({
    required this.id,
    required this.name,
    required this.kind,
    required this.uri,
    required this.addedAt,
    this.contentType,
    this.sizeBytes,
    this.checksum,
  }) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id', 'Must not be empty.');
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name', 'Must not be empty.');
    if (uri.trim().isEmpty) throw ArgumentError.value(uri, 'uri', 'Must not be empty.');
    if (sizeBytes != null && sizeBytes! < 0) {
      throw ArgumentError.value(sizeBytes, 'sizeBytes', 'Must not be negative.');
    }
  }
}

class CreativeProjectVersion {
  final int number;
  final String summary;
  final DateTime createdAt;
  final String? snapshotUri;

  CreativeProjectVersion({
    required this.number,
    required this.summary,
    required this.createdAt,
    this.snapshotUri,
  }) {
    if (number < 1) throw ArgumentError.value(number, 'number', 'Must be at least 1.');
    if (summary.trim().isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'Must not be empty.');
    }
  }
}

/// A local/domain representation of a creator-owned production project.
/// Persistence, sharing, and media processing are intentionally handled by
/// repositories/adapters rather than implied by this model.
class AurenCreativeProject {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final CreativeProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CreativeAssetReference> assets;
  final List<CreativeProjectVersion> versions;

  AurenCreativeProject({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    List<CreativeAssetReference> assets = const [],
    List<CreativeProjectVersion> versions = const [],
  })  : assets = List.unmodifiable(assets),
        versions = List.unmodifiable(versions) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id', 'Must not be empty.');
    if (ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Must not be empty.');
    }
    if (title.trim().isEmpty) throw ArgumentError.value(title, 'title', 'Must not be empty.');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot be earlier than createdAt.');
    }
    final assetIds = this.assets.map((asset) => asset.id).toSet();
    if (assetIds.length != this.assets.length) {
      throw ArgumentError('Asset IDs must be unique within a project.');
    }
    final versionNumbers = this.versions.map((version) => version.number).toList()..sort();
    if (versionNumbers.toSet().length != versionNumbers.length) {
      throw ArgumentError('Version numbers must be unique within a project.');
    }
  }

  AurenCreativeProject copyWith({
    String? title,
    String? description,
    CreativeProjectStatus? status,
    DateTime? updatedAt,
    List<CreativeAssetReference>? assets,
    List<CreativeProjectVersion>? versions,
  }) => AurenCreativeProject(
        id: id,
        ownerId: ownerId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        assets: assets ?? this.assets,
        versions: versions ?? this.versions,
      );
}
