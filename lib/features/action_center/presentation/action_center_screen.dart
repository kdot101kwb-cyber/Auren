import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AurenActionCenterScreen extends StatelessWidget {
  const AurenActionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام Action Center.')));
    final stream = FirebaseFirestore.instance.collection('users').doc(uid).collection('match_action_flows').orderBy('updatedAt', descending: true).limit(50).snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('Action Center')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المسارات الآن.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(28), child: Text('لا توجد إجراءات نشطة بعد.\nابدأ من Match Everything وسيظهر مسارك هنا.', textAlign: TextAlign.center)));
          final active = docs.where((d) => d.data()['status'] != 'completed').toList();
          final completed = docs.where((d) => d.data()['status'] == 'completed').toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (active.isNotEmpty) ...[const Text('قيد المتابعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...active.map((doc) => _FlowCard(data: doc.data()))],
            if (completed.isNotEmpty) ...[const SizedBox(height: 20), const Text('مكتمل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...completed.take(10).map((doc) => _FlowCard(data: doc.data()))],
          ]);
        },
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FlowCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final kind = (data['targetKind'] ?? '').toString();
    final action = (data['action'] ?? '').toString();
    final status = (data['status'] ?? 'active').toString();
    final step = (data['step'] as num?)?.toInt() ?? 0;
    final total = (data['totalSteps'] as num?)?.toInt() ?? 1;
    final intent = (data['intent'] ?? '').toString();
    final progress = ((step + 1) / total).clamp(0.0, 1.0);
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(child: Icon(_icon(kind))), const SizedBox(width: 12), Expanded(child: Text(_title(kind, action), style: const TextStyle(fontWeight: FontWeight.w800))), Chip(label: Text(status == 'completed' ? 'مكتمل' : 'نشط'))]),
      const SizedBox(height: 10), LinearProgressIndicator(value: progress), const SizedBox(height: 7),
      Text('الخطوة ${step + 1} من $total'),
      if (intent.isNotEmpty) ...[const SizedBox(height: 6), Text(intent, maxLines: 2, overflow: TextOverflow.ellipsis)],
    ])));
  }

  static IconData _icon(String kind) {
    switch (kind) {
      case 'business': return Icons.storefront_outlined;
      case 'product': return Icons.shopping_bag_outlined;
      case 'opportunity': return Icons.work_outline;
      case 'content': return Icons.play_circle_outline;
      default: return Icons.person_outline;
    }
  }

  static String _title(String kind, String action) {
    const actions = {'requestQuote': 'طلب عرض سعر', 'apply': 'التقديم على فرصة', 'addToCart': 'الشراء', 'contact': 'التواصل', 'follow': 'المتابعة', 'save': 'الحفظ', 'watch': 'المشاهدة', 'open': 'فتح النتيجة'};
    const kinds = {'business': 'نشاط تجاري', 'product': 'منتج', 'opportunity': 'فرصة', 'content': 'محتوى', 'person': 'شخص'};
    return '${actions[action] ?? 'إجراء AUREN'} • ${kinds[kind] ?? 'نتيجة'}';
  }
}
