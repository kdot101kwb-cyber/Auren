import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_repository.dart';

class AurenTalentSkillGraph extends StatelessWidget {
  const AurenTalentSkillGraph({super.key});

  Future<void> _requestVerification(BuildContext context, Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final skill = (data['skill'] ?? '').toString();
    try {
      await TalentRepository().requestSkillVerification(
        ownerId: uid,
        skill: skill,
        proof: {
          'evidenceCount': data['evidenceCount'] ?? 0,
          'result': data['lastResult'] ?? '',
          'evidence': data['evidence'] ?? '',
          'source': data['source'] ?? 'discovery_mission',
        },
      );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب توثيق المهارة.')));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إرسال طلب التوثيق.')));
    }
  }

  void _showProofChain(BuildContext context, Map<String, dynamic> data) {
    final skill = (data['skill'] ?? 'مهارة').toString();
    final result = (data['lastResult'] ?? '').toString();
    final evidence = (data['evidence'] ?? '').toString();
    final count = (data['evidenceCount'] as num?)?.toInt() ?? 0;
    final confidence = ((data['confidence'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(skill, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Proof Chain • ' + (confidence * 100).round().toString() + '% ثقة'),
              const SizedBox(height: 14),
              const Text('كيف وصلت AUREN لهذا الترشيح؟', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: const Text('مصدر الاكتشاف'),
                subtitle: Text('Discovery Mission • ' + count.toString() + ' دليل'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('النتيجة المسجلة'),
                subtitle: Text(result.isEmpty ? 'لا توجد نتيجة.' : result),
              ),
              if (evidence.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('الدليل المرفق'),
                  subtitle: Text(evidence),
                ),
              Text(
                'هذا استنتاج مبني على الأدلة المتاحة، وليس إثباتاً نهائياً للمهارة.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _requestVerification(context, data),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('اطلب توثيق هذه المهارة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('talent_skill_graph')
              .where('ownerId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('تعذر تحميل Skill Graph حالياً.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = [...snapshot.data!.docs]
              ..sort((a, b) {
                final ac = (a.data()['confidence'] as num?)?.toDouble() ?? 0;
                final bc = (b.data()['confidence'] as num?)?.toDouble() ?? 0;
                return bc.compareTo(ac);
              });

            if (docs.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Skill Graph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('أكمل Discovery Missions لتبدأ AUREN في بناء خريطة مهارات مبنية على الأدلة.'),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree_outlined),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Skill Graph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    Text('${docs.length} مهارات'),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('مهارات مرشحة مبنية على الأدلة، وليست حكماً نهائياً على قدراتك.'),
                const SizedBox(height: 12),
                ...docs.take(8).map((doc) {
                  final data = doc.data();
                  final confidence = ((data['confidence'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
                  final evidenceCount = (data['evidenceCount'] as num?)?.toInt() ?? 0;
                  final skill = (data['skill'] ?? 'مهارة غير معروفة').toString();
                  final evidence = (data['lastResult'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _showProofChain(context, data),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                skill,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text('${(confidence * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: confidence),
                        const SizedBox(height: 4),
                        Text(
                          '${evidenceCount} دليل • ${evidence.isEmpty ? 'لا توجد نتيجة مسجلة' : evidence}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
