import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/social/community_appeals_service.dart';
import '../../../services/social/community_casework_models.dart';
import '../../../services/social/community_casework_service.dart';

/// Reviewer console. Firestore rules remain the authority; non-reviewers see
/// a permission error rather than gaining access through this UI.
class AurenCommunityGovernanceScreen extends StatefulWidget {
  const AurenCommunityGovernanceScreen({super.key});

  @override
  State<AurenCommunityGovernanceScreen> createState() =>
      _AurenCommunityGovernanceScreenState();
}

class _AurenCommunityGovernanceScreenState
    extends State<AurenCommunityGovernanceScreen> {
  final _casework = AurenCommunityCaseworkService();
  final _appeals = AurenCommunityAppealsService();

  Future<String?> _askNote({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLength: 1000,
            maxLines: 4,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controller.text.trim(),
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _reviewReport(AurenCaseReport report, String status) async {
    final note = await _askNote(
      title: 'مراجعة البلاغ',
      hint: status == 'under_review'
          ? 'ملاحظة بدء المراجعة'
          : 'سبب القرار النهائي',
    );
    if (note == null) return;
    try {
      await _casework.review(id: report.id, status: status, note: note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ قرار المراجعة')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث البلاغ: $error')),
        );
      }
    }
  }

  Future<void> _decideAppeal(AurenCaseAppeal appeal, String status) async {
    final note = await _askNote(
      title: status == 'accepted' ? 'قبول الاستئناف' : 'رفض الاستئناف',
      hint: 'اكتب سبب القرار',
    );
    if (note == null || note.isEmpty) return;
    try {
      await _appeals.decide(
        appealId: appeal.id,
        status: status,
        note: note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ قرار الاستئناف')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حسم الاستئناف: $error')),
        );
      }
    }
  }

  Widget _error(Object? error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'تعذر الوصول إلى بيانات الحوكمة. تتطلب هذه الشاشة صلاحية مراجع موثوق.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _reports() => StreamBuilder<List<AurenCaseReport>>(
        stream: _casework.watchQueue(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const Center(child: Text('لا توجد بلاغات للمراجعة.'));
          }
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final canStart = report.status == 'open';
              final canFinish = report.status == 'under_review';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بلاغ • ${report.status}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(report.reason),
                      if (report.contentId != null)
                        Text('المحتوى: ${report.contentId}'),
                      if (report.note.isNotEmpty) Text('آخر ملاحظة: ${report.note}'),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (canStart)
                            OutlinedButton(
                              onPressed: () => _reviewReport(report, 'under_review'),
                              child: const Text('بدء المراجعة'),
                            ),
                          if (canFinish)
                            FilledButton.tonal(
                              onPressed: () => _reviewReport(report, 'resolved'),
                              child: const Text('حل البلاغ'),
                            ),
                          if (canFinish)
                            OutlinedButton(
                              onPressed: () => _reviewReport(report, 'rejected'),
                              child: const Text('رفض البلاغ'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

  Widget _pendingAppeals() => StreamBuilder<List<AurenCaseAppeal>>(
        stream: _appeals.watchPending(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final appeals = snapshot.data!;
          if (appeals.isEmpty) {
            return const Center(child: Text('لا توجد استئنافات معلقة.'));
          }
          return ListView.builder(
            itemCount: appeals.length,
            itemBuilder: (context, index) {
              final appeal = appeals[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('استئناف البلاغ: ${appeal.reportId}'),
                      const SizedBox(height: 6),
                      Text(appeal.reason),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _decideAppeal(appeal, 'accepted'),
                            child: const Text('قبول'),
                          ),
                          OutlinedButton(
                            onPressed: () => _decideAppeal(appeal, 'rejected'),
                            child: const Text('رفض'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

  Widget _auditEvents() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('community_case_events')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!.docs;
          if (events.isEmpty) {
            return const Center(child: Text('لا توجد أحداث تدقيق بعد.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data();
              final createdAt = data['createdAt'];
              final date = createdAt is Timestamp
                  ? createdAt.toDate().toLocal().toString()
                  : 'وقت غير متاح';
              return ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(
                  '${data['entityType'] ?? 'case'}: '
                  '${data['fromStatus'] ?? '—'} → ${data['toStatus'] ?? '—'}',
                ),
                subtitle: Text(
                  '${data['entityId'] ?? ''}\n'
                  '${data['note'] ?? ''}\n$date',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      );

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('حوكمة المجتمع'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'البلاغات'),
                Tab(text: 'الاستئنافات'),
                Tab(text: 'سجل التدقيق'),
              ],
            ),
          ),
          body: TabBarView(
            children: [_reports(), _pendingAppeals(), _auditEvents()],
          ),
        ),
      );
}
