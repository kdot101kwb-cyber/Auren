import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Append-only milestones, decisions, and outcomes for an existing community.
/// Firestore rules restrict reads to members and reject edits/deletions.
class AurenCommunityMemoryService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  AurenCommunityMemoryService({FirebaseFirestore? db, FirebaseAuth? auth})
      : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String? get currentUid => auth.currentUser?.uid;
  String get uid => currentUid ?? (throw StateError('Sign in required'));

  CollectionReference<Map<String, dynamic>> _entries(String communityId) =>
      db.collection('communities').doc(communityId).collection('memory_entries');

  Stream<List<AurenCommunityMemoryEntry>> watchEntries(String communityId) {
    final id = communityId.trim();
    if (id.isEmpty) throw ArgumentError('Community ID is required.');
    return _entries(id)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(AurenCommunityMemoryEntry.fromDoc)
            .toList(growable: false));
  }

  Future<String> createEntry({
    required String communityId,
    required String kind,
    required String title,
    required String body,
  }) async {
    final id = communityId.trim();
    final normalizedKind = kind.trim();
    final normalizedTitle = title.trim();
    final normalizedBody = body.trim();

    if (id.isEmpty ||
        !const {'milestone', 'decision', 'outcome'}.contains(normalizedKind) ||
        normalizedTitle.isEmpty ||
        normalizedTitle.length > 120 ||
        normalizedBody.isEmpty ||
        normalizedBody.length > 2000) {
      throw ArgumentError('Community memory entry is invalid.');
    }

    final ref = _entries(id).doc();
    await ref.set({
      'kind': normalizedKind,
      'title': normalizedTitle,
      'body': normalizedBody,
      'recordedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}

class AurenCommunityMemoryEntry {
  final String id;
  final String kind;
  final String title;
  final String body;
  final String recordedBy;
  final DateTime? createdAt;

  const AurenCommunityMemoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.recordedBy,
    required this.createdAt,
  });

  factory AurenCommunityMemoryEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AurenCommunityMemoryEntry(
      id: doc.id,
      kind: data['kind'] as String? ?? 'milestone',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      recordedBy: data['recordedBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
