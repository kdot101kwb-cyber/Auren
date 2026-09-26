import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/message.dart';
import '../../../services/messaging/message_repository.dart';

class AurenActionCenterScreen extends StatelessWidget {
  const AurenActionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول لاستخدام Action Center.')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('match_action_flows')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Action Center')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل المسارات الآن.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'لا توجد إجراءات نشطة بعد.\nابدأ من Match Everything وسيظهر مسارك هنا.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final active =
              docs.where((d) => d.data()['status'] != 'completed').toList();
          final completed =
              docs.where((d) => d.data()['status'] == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const Text(
                  'قيد المتابعة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...active.map(
                  (doc) => _FlowCard(
                    flowId: doc.id,
                    uid: uid,
                    data: doc.data(),
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'مكتمل',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...completed.take(10).map(
                  (doc) => _FlowCard(
                    flowId: doc.id,
                    uid: uid,
                    data: doc.data(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FlowCard extends StatefulWidget {
  final String flowId;
  final String uid;
  final Map<String, dynamic> data;

  const _FlowCard({
    required this.flowId,
    required this.uid,
    required this.data,
  });

  @override
  State<_FlowCard> createState() => _FlowCardState();
}

class _FlowCardState extends State<_FlowCard> {
  StreamSubscription<List<AurenMessage>>? _messageSubscription;
  bool _replyUpdateSent = false;

  @override
  void initState() {
    super.initState();
    _watchForReply();
  }

  @override
  void didUpdateWidget(covariant _FlowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldConversation = oldWidget.data['conversationId']?.toString();
    final newConversation = widget.data['conversationId']?.toString();
    final oldStatus = oldWidget.data['status']?.toString();
    final newStatus = widget.data['status']?.toString();

    if (oldConversation != newConversation || oldStatus != newStatus) {
      _messageSubscription?.cancel();
      _replyUpdateSent = false;
      _watchForReply();
    }
  }

  void _watchForReply() {
    final status = (widget.data['status'] ?? 'active').toString();
    final conversationId =
        (widget.data['conversationId'] ?? '').toString().trim();
    if (conversationId.isEmpty ||
        status != 'waiting_response' ||
        widget.data['targetKind'] == null) {
      return;
    }

    final rawUpdatedAt = widget.data['updatedAt'];
    final flowUpdatedAt =
        rawUpdatedAt is Timestamp ? rawUpdatedAt.toDate() : null;
    if (flowUpdatedAt == null) return;

    final messages = FirestoreMessageRepository();
    _messageSubscription = messages.watchConversation(conversationId).listen(
      (items) {
        if (_replyUpdateSent || !mounted) return;

        final hasReply = items.any(
          (message) =>
              message.senderId.isNotEmpty &&
              message.senderId != widget.uid &&
              message.createdAt.isAfter(flowUpdatedAt),
        );
        if (!hasReply) return;

        _replyUpdateSent = true;
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('match_action_flows')
            .doc(widget.flowId)
            .update({
          'status': 'replied',
          'updatedAt': FieldValue.serverTimestamp(),
        })
            .catchError((_) {
          _replyUpdateSent = false;
        });
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = (widget.data['targetKind'] ?? '').toString();
    final action = (widget.data['action'] ?? '').toString();
    final status = (widget.data['status'] ?? 'active').toString();
    final step = (widget.data['step'] as num?)?.toInt() ?? 0;
    final total = (widget.data['totalSteps'] as num?)?.toInt() ?? 1;
    final intent = (widget.data['intent'] ?? '').toString();
    final progress = ((step + 1) / total).clamp(0.0, 1.0);

    final statusLabel = switch (status) {
      'waiting_response' => 'في انتظار الرد',
      'replied' => 'تم الرد',
      'completed' => 'مكتمل',
      _ => 'نشط',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(_icon(kind))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _title(kind, action),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 7),
            Text('الخطوة ${step + 1} من $total'),
            if (intent.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                intent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (status == 'waiting_response') ...[
              const SizedBox(height: 8),
              const Text(
                'AUREN تراقب المحادثة لهذا المسار. عند وصول رد من الطرف الآخر ستتحدث الحالة تلقائياً.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            if (status == 'replied') ...[
              const SizedBox(height: 8),
              const Text(
                'وصل رد جديد. راجع المحادثة وحدد الخطوة التالية بنفسك.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _icon(String kind) {
    switch (kind) {
      case 'business':
        return Icons.storefront_outlined;
      case 'product':
        return Icons.shopping_bag_outlined;
      case 'opportunity':
        return Icons.work_outline;
      case 'content':
        return Icons.play_circle_outline;
      default:
        return Icons.person_outline;
    }
  }

  static String _title(String kind, String action) {
    const actions = {
      'requestQuote': 'طلب عرض سعر',
      'apply': 'التقديم على فرصة',
      'addToCart': 'الشراء',
      'contact': 'التواصل',
      'follow': 'المتابعة',
      'save': 'الحفظ',
      'watch': 'المشاهدة',
      'open': 'فتح النتيجة',
    };
    const kinds = {
      'business': 'نشاط تجاري',
      'product': 'منتج',
      'opportunity': 'فرصة',
      'content': 'محتوى',
      'person': 'شخص',
    };
    return '${actions[action] ?? 'إجراء AUREN'} • ${kinds[kind] ?? 'نتيجة'}';
  }
}
