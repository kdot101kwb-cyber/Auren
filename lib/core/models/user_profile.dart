class AurenUserProfile {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  const AurenUserProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory AurenUserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return AurenUserProfile(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'AUREN User',
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
