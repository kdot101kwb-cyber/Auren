import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AurenWorkAuditScreen extends StatelessWidget {
  const AurenWorkAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('action_audit')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Audit Log')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل سجل التدقيق: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا توجد أحداث تدقيق بعد. كل إجراء AUREN سيظهر هنا بعد الاقتراح أو الموافقة أو التنفيذ.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final status = (data['status'] ?? 'unknown').toString();
              final actionType = (data['actionType'] ?? 'unknown').toString();
              final agentId = (data['agentId'] ?? 'primary').toString();
              final source = (data['source'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_iconForStatus(status)),
                  ),
                  title: Text(actionType),
                  subtitle: Text(
                    'الوكيل: $agentId\nالحالة: $status'
                    '${source.isEmpty ? '' : '\nالمصدر: $source'}',
                  ),
                  isThreeLine: true,
                  onTap: () => _showDetails(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error_outline;
      case 'approved':
        return Icons.verified_outlined;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      case 'proposed':
      case 'pending':
        return Icons.pending_actions_outlined;
      default:
        return Icons.history;
    }
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل التدقيق',
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...data.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(
                    '${entry.key}: ${entry.value}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'سجل التدقيق للقراءة فقط من التطبيق. لا يمكن للمستخدم تعديل أو حذف أحداث التدقيق.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
