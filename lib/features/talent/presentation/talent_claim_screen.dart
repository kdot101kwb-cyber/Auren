import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_claim_repository.dart';

class AurenTalentClaimScreen extends StatefulWidget {
  final String talentId;
  final String talentName;
  const AurenTalentClaimScreen({super.key, required this.talentId, required this.talentName});
  @override
  State<AurenTalentClaimScreen> createState() => _AurenTalentClaimScreenState();
}

class _AurenTalentClaimScreenState extends State<AurenTalentClaimScreen> {
  final _evidence = TextEditingController();
  final _repo = TalentClaimRepository();
  bool _saving = false;

  @override
  void dispose() { _evidence.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final evidence = _evidence.text.trim();
    if (uid == null || evidence.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.submit(talentId: widget.talentId, claimantUid: uid, evidence: evidence);
      if (!mounted) return;
      _evidence.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب المطالبة للمراجعة.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: ' + e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved': return 'تم اعتماد الطلب وربط الملف بحسابك.';
      case 'rejected': return 'تم رفض الطلب بعد المراجعة.';
      default: return 'قيد المراجعة.';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.verified;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.hourglass_top;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.person_search), title: Text(widget.talentName), subtitle: const Text('طلب إدارة هذه الصفحة باسمك'))),
          const SizedBox(height: 12),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('المطالبة لا تعني التحقق تلقائياً. اذكر أدلة يمكن مراجعتها، مثل رابط حساب رسمي، صفحة نادي أو اتحاد، أو إثبات آخر مناسب. لا ترسل كلمات مرور أو بيانات حساسة.'))),
          const SizedBox(height: 12),
          TextField(controller: _evidence, onChanged: (_) => setState(() {}), maxLines: 7, maxLength: 1200, decoration: const InputDecoration(labelText: 'أدلة الملكية أو الهوية', hintText: 'ضع الروابط أو وصف الأدلة التي تثبت أنك صاحب الصفحة...', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving || _evidence.text.trim().isEmpty ? null : _submit,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
            label: const Text('إرسال طلب المطالبة'),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _repo.watchMine(uid),
            builder: (context, snapshot) {
              final claims = snapshot.data ?? const [];
              if (claims.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Column(
                  children: [
                    const ListTile(leading: Icon(Icons.history), title: Text('طلباتك')),
                    ...claims.map((claim) => ListTile(
                      title: Text('ملف: ' + (claim['talentId'] ?? '').toString()),
                      subtitle: Text(_statusLabel((claim['status'] ?? 'pending').toString())),
                      leading: Icon(_statusIcon((claim['status'] ?? 'pending').toString())),
                    )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
