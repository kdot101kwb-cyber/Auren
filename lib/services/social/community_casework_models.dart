import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCaseReport {
  final String id, reporterUid, reportedUid, reason, status, note;
  final String? contentId, contentType, reviewedBy;
  final DateTime? createdAt, reviewedAt;
  const AurenCaseReport({required this.id,required this.reporterUid,required this.reportedUid,required this.reason,required this.status,required this.note,required this.contentId,required this.contentType,required this.reviewedBy,required this.createdAt,required this.reviewedAt});
  factory AurenCaseReport.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) {
    final d=doc.data()??const <String,dynamic>{};
    return AurenCaseReport(id:doc.id,reporterUid:d['reporterUid'] as String? ?? '',reportedUid:d['reportedUid'] as String? ?? '',reason:d['reason'] as String? ?? '',status:d['status'] as String? ?? 'open',note:d['moderationNote'] as String? ?? '',contentId:d['contentId'] as String?,contentType:d['contentType'] as String?,reviewedBy:d['moderatedBy'] as String?,createdAt:(d['createdAt'] as Timestamp?)?.toDate(),reviewedAt:(d['moderatedAt'] as Timestamp?)?.toDate());
  }
}

class AurenCaseAppeal {
  final String id, reportId, appellantUid, reason, status, note;
  final String? reviewedBy;
  final DateTime? createdAt, reviewedAt;
  const AurenCaseAppeal({required this.id,required this.reportId,required this.appellantUid,required this.reason,required this.status,required this.note,required this.reviewedBy,required this.createdAt,required this.reviewedAt});
  factory AurenCaseAppeal.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) {
    final d=doc.data()??const <String,dynamic>{};
    return AurenCaseAppeal(id:doc.id,reportId:d['reportId'] as String? ?? '',appellantUid:d['appellantUid'] as String? ?? '',reason:d['reason'] as String? ?? '',status:d['status'] as String? ?? 'pending',note:d['reviewNote'] as String? ?? '',reviewedBy:d['reviewedBy'] as String?,createdAt:(d['createdAt'] as Timestamp?)?.toDate(),reviewedAt:(d['reviewedAt'] as Timestamp?)?.toDate());
  }
}
