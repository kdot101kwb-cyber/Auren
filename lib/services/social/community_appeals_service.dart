import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'community_casework_models.dart';

class AurenCommunityAppealsService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  AurenCommunityAppealsService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('Sign in required'));

  CollectionReference<Map<String, dynamic>> get _appeals =>
      db.collection('community_case_appeals');

  Stream<List<AurenCaseAppeal>> watchPending() => _appeals
      .where('status', isEqualTo: 'pending')
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map(AurenCaseAppeal.fromDoc).toList());

  Future<String> submit({
    required String reportId,
    required String reason,
  }) async {
    final id = reportId.trim();
    final appealReason = reason.trim();

    if (id.isEmpty ||
        appealReason.isEmpty ||
        appealReason.length > 1000) {
      throw ArgumentError('Appeal reason must be 1–1000 characters.');
    }

    final reportRef = db.collection('reports').doc(id);
    final appealRef = _appeals.doc('${id}__${uid}');

    // Eligibility and duplicate detection share a transaction. Rules must
    // independently enforce the same checks before this flow is enabled.
    await db.runTransaction((transaction) async {
      final reportSnapshot = await transaction.get(reportRef);
      if (!reportSnapshot.exists) {
        throw StateError('Report not found.');
      }

      final report = reportSnapshot.data() ?? const <String, dynamic>{};
      final reportStatus = report['status'] as String? ?? '';
      final isParticipant = report['reporterUid'] == uid ||
          report['reportedUid'] == uid;

      if (!isParticipant ||
          !const {'resolved', 'rejected'}.contains(reportStatus)) {
        throw StateError('This report is not eligible for an appeal.');
      }

      final existingAppeal = await transaction.get(appealRef);
      if (existingAppeal.exists) {
        throw StateError('An appeal has already been submitted for this report.');
      }

      transaction.set(appealRef, {
        'reportId': id,
        'appellantUid': uid,
        'reason': appealReason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return appealRef.id;
  }

  Future<void> decide({
    required String appealId,
    required String status,
    required String note,
  }) async {
    final id = appealId.trim();
    final reviewNote = note.trim();

    if (id.isEmpty ||
        !const {'accepted', 'rejected'}.contains(status) ||
        reviewNote.isEmpty ||
        reviewNote.length > 1000) {
      throw ArgumentError('Invalid appeal decision.');
    }

    final appealRef = _appeals.doc(id);
    final eventRef = db.collection('community_case_events').doc();

    // Only one decision can transition a pending appeal; the audit record is
    // written atomically with the decision.
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(appealRef);
      if (!snapshot.exists ||
          (snapshot.data()?['status'] as String? ?? '') != 'pending') {
        throw StateError('Appeal is not pending.');
      }

      transaction.update(appealRef, {
        'status': status,
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewNote': reviewNote,
      });
      transaction.set(eventRef, {
        'entityType': 'appeal',
        'entityId': id,
        'actorUid': uid,
        'fromStatus': 'pending',
        'toStatus': status,
        'note': reviewNote,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
