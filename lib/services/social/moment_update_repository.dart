import 'package:cloud_firestore/cloud_firestore.dart';

class MomentUpdate {
  final String id;
  final String authorId;
  final String text;
  final DateTime? createdAt;

  const MomentUpdate({
    required this.id,
    required this.authorId,
    required this.text,
    this.createdAt,
  });

  factory MomentUpdate.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return MomentUpdate(
      id: id,
      authorId: data['authorId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: created is Timestamp
          ? created.toDate()
          : DateTime.tryParse(created?.toString() ?? ''),
    );
  }
}

class MomentUpdateRepository {
  final FirebaseFirestore _db;

  MomentUpdateRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _updates(String postId) =>
      _db.collection('posts').doc(postId).collection('moment_updates');

  Stream<List<MomentUpdate>> watch(String postId) => _updates(postId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MomentUpdate.fromMap(doc.id, doc.data()))
          .toList());

  Future<void> add({
    required String postId,
    required String authorId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length > 1200) {
      throw ArgumentError('An update must contain 1–1200 characters.');
    }
    await _updates(postId).add({
      'authorId': authorId,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete({
    required String postId,
    required String updateId,
  }) =>
      _updates(postId).doc(updateId).delete();
}
