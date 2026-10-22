import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'community_casework_models.dart';

class AurenCommunityCaseworkService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  AurenCommunityCaseworkService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('Sign in required'));

  Stream<List<AurenCaseReport>> watchQueue() => db
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map(AurenCaseReport.fromDoc).toList());

  Future<void> review({
    required String id,
    required String status,
    required String note,
  }) async {
    final reportId = id.trim();
    final reviewNote = note.trim();

    if (reportId.isEmpty ||
        !const {'under_review', 'resolved', 'rejected'}.contains(status) ||
        reviewNote.length > 1000 ||
        (status != 'under_review' && reviewNote.isEmpty)) {
      throw ArgumentError('Invalid review decision.');
    }

    final reportRef = db.collection('reports').doc(reportId);
    final eventRef = db.collection('community_case_events').doc();

    // Keep the status check and the decision/audit writes atomic so two
    // reviewers cannot both act on a stale status read.
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reportRef);
      if (!snapshot.exists) {
        throw StateError('Report not found.');
      }

      final data = snapshot.data() ?? const <String, dynamic>{};
      final fromStatus = data['status'] as String? ?? '';
      final allowed = (fromStatus == 'open' && status == 'under_review') ||
          (fromStatus == 'under_review' &&
              const {'resolved', 'rejected'}.contains(status));

      if (!allowed) {
        throw StateError('Report is not reviewable from its current status.');
      }

      transaction.update(reportRef, {
        'status': status,
        'moderatedBy': uid,
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderationNote': reviewNote,
      });
      transaction.set(eventRef, {
        'entityType': 'report',
        'entityId': reportId,
        'actorUid': uid,
        'fromStatus': fromStatus,
        'toStatus': status,
        'note': reviewNote,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
