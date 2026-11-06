import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Append-only milestones, decisions, and outcomes for an existing community.
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
    return _entries(id).orderBy('createdAt', descending: true).limit(100)
        .snapshots().map((s) => s.docs.map(AurenCommunityMemoryEntry.fromDoc).toList());
  }

  Future<String> createEntry({required String communityId, required String kind,
    required String title, required String body}) async {
    final id = communityId.trim(), k = kind.trim(), t = title.trim(), b = body.trim();
    if (id.isEmpty || !const {'milestone','decision','outcome'}.contains(k) ||
        t.isEmpty || t.length > 120 || b.isEmpty || b.length > 2000) {
      throw ArgumentError('Community memory entry is invalid.');
    }
    final ref = _entries(id).doc();
    await ref.set({'kind': k, 'title': t, 'body': b, 'recordedBy': uid,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    return ref.id;
  }
}

class AurenCommunityMemoryEntry {
  final String id, kind, title, body, recordedBy;
  final DateTime? createdAt;
  const AurenCommunityMemoryEntry({required this.id, required this.kind,
    required this.title, required this.body, required this.recordedBy, required this.createdAt});
  factory AurenCommunityMemoryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AurenCommunityMemoryEntry(id: doc.id, kind: d['kind'] as String? ?? 'milestone',
      title: d['title'] as String? ?? '', body: d['body'] as String? ?? '',
      recordedBy: d['recordedBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate());
  }
}
