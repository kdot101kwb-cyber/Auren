import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/explain_my_data_service.dart';

class AurenExplainMyDataScreen extends StatefulWidget {
  const AurenExplainMyDataScreen({super.key});
  @override State<AurenExplainMyDataScreen> createState() => _AurenExplainMyDataScreenState();
}
class _AurenExplainMyDataScreenState extends State<AurenExplainMyDataScreen> {
  final _auth = FirebaseAurenAuthService();
  final _service = ExplainMyDataService();
  AurenDataExplanation? _data;
  bool _loading = false;

  Future<void> _explain() async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final result = await _service.build(uid);
      if (mounted) setState(() => _data = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحليل بياناتك: ${e}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Explain My Data')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('افهم بياناتك بدل ما تكون مجرد أرقام.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('AUREN يشرح ما هو موجود في أهدافك وذاكرتك الشخصية، بدون تعديل أو حذف للبيانات.'),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _loading ? null : _explain,
        icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.insights_outlined),
        label: Text(_loading ? 'جاري التحليل…' : 'اشرح لي بياناتي'),
      ),
      if (_data != null) ...[
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_data!.goalCount} أهداف • ${_data!.activeGoalCount} نشطة • ${_data!.enabledMemoryCount} ذكريات مفعّلة'),
          const SizedBox(height: 8),
          Text('متوسط تقدم الأهداف النشطة: ${_data!.averageProgress}%'),
          const SizedBox(height: 12),
          ..._data!.insights.map((i) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.analytics_outlined), title: Text(i.title), subtitle: Text('${i.value}\n${i.explanation}'))),
          const SizedBox(height: 8),
          Text('آخر تحديث للتحليل: ${_data!.generatedAt.toLocal()}'),
        ]))),
      ],
    ]),
  );
}