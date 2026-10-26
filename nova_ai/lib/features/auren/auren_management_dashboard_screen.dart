import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_runtime.dart';

/// Private AUREN project dashboard and daily NOVA management-council review.
/// The council uses the existing server-side strategic-debate callable; it
/// does not claim independent agents or background execution.
class AurenManagementDashboardScreen extends StatefulWidget {
  const AurenManagementDashboardScreen({super.key});

  @override
  State<AurenManagementDashboardScreen> createState() =>
      _AurenManagementDashboardScreenState();
}

class _AurenManagementDashboardScreenState
    extends State<AurenManagementDashboardScreen> {
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _review;
  DateTime? _reviewedAt;

  static const _agenda = <({IconData icon, String title, String detail})>[
    (
      icon: Icons.verified_outlined,
      title: 'الجودة ونجاح الاختبارات',
      detail: 'مراجعة نتائج Flutter وFunctions وAndroid build قبل إعلان الجاهزية.',
    ),
    (
      icon: Icons.security_outlined,
      title: 'الأمان والخصوصية',
      detail: 'منع تسريب المفاتيح، والتحقق من Firebase وApp Check والصلاحيات.',
    ),
    (
      icon: Icons.account_tree_outlined,
      title: 'تقدم AUREN',
      detail: 'ترتيب الأنظمة والـ PRs المفتوحة حسب القيمة والتبعيات وتجنب التكرار.',
    ),
    (
      icon: Icons.savings_outlined,
      title: 'التكلفة والأثر',
      detail: 'تفضيل الحلول القابلة للاختبار ضمن ميزانية صفر قبل أي خدمة مدفوعة.',
    ),
    (
      icon: Icons.lightbulb_outline,
      title: 'فرص واقتراحات اليوم',
      detail: 'اقتراح تجربة صغيرة قابلة للقياس مع دليل تحقق واضح.',
    ),
  ];

  Future<void> _startDailyMeeting() async {
    if (_busy) return;
    if (!NovaFirebaseRuntime.initialized ||
        !NovaFirebaseRuntime.appCheckActivated) {
      setState(() {
        _error = NovaFirebaseRuntime.initializationError ??
            'يلزم إعداد Firebase وApp Check قبل تشغيل اجتماع المجلس.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _review = null;
    });

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      const prompt = '''
عقد اجتماع مجلس الإدارة اليومي الخاص بمشروعي NOVA وAUREN.
أنت مجلس مراجعة متعدد التخصصات بأربع زوايا: الهندسة، الجودة والاختبارات، الأمان والخصوصية، والتكلفة والأداء. لا توافق تلقائياً؛ اعترض على الافتراضات الضعيفة، واقترح بدائل عملية.
المطلوب:
1) ملخص تنفيذي قصير وأهم ثلاث أولويات.
2) اقتراحات عملية لمشروع AUREN وتكامل لوحة إدارته داخل NOVA.
3) مراجعة المخاطر والاعتماديات وما يجب ألا نعلنه من دون دليل.
4) خطة يوم واحد مرتبة حسب الأثر والوقت والتكلفة، مع معيار تحقق لكل خطوة.
5) وضّح الأدلة الناقصة ولا تخترع أرقام مستخدمين أو دخل أو نتائج CI.
القيود: ميزانية البدء صفر، لا دمج PR ولا نشر ولا تغيير صلاحيات أو إرسال خارجي دون موافقة صريحة. اعتبر كل نتائج المستودع والاختبارات غير متاحة ما لم يقدّمها السياق.
''';
      final response = await FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('novaStrategicDebate').call(<String, dynamic>{
        'prompt': prompt,
        'context':
            'تاريخ الاجتماع: $date. هذا طلب مراجعة يومية من لوحة NOVA الخاصة. '
            'المستودع: https://github.com/kdot101kwb-cyber/Auren . '
            'فرع العمل المعروف: feat/nova-ai-android-app؛ PR #283. '
            'لا توجد في هذا الطلب نتائج CI حديثة موثقة، لذلك يجب التصريح بأن حالة البناء والاختبارات تحتاج تحققاً مباشراً. '
            'اقترح ما يمكن فعله اليوم بأدلة قابلة للتحقق، ولا تدّع تنفيذ أي خطوة.',
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final debate = data['debate'];
      if (debate is! Map) {
        throw const FormatException('استجابة المجلس لا تحتوي على نتيجة صالحة.');
      }
      if (!mounted) return;
      setState(() {
        _review = Map<String, dynamic>.from(debate);
        _reviewedAt = now;
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? 'تعذر تشغيل اجتماع المجلس.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر إكمال الاجتماع: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _value(Object? value, [String fallback = 'غير متوفر']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<Map<String, dynamic>> _items(String key) {
    final raw = _review?[key];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة AUREN ومجلس NOVA'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF392A73), Color(0xFF155E59)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance, size: 32, color: Color(0xFF9FE9DD)),
                SizedBox(height: 10),
                Text(
                  'مركز إدارة AUREN',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'لوحة خاصة داخل NOVA لمراجعة الأولويات، ومخاطر التطوير، والجودة، والأمان، والتكلفة، واقتراح خطة يومية.',
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _StatusCard(
            icon: Icons.analytics_outlined,
            title: 'حالة المشروع',
            value: 'تحتاج تحققاً مباشراً',
            detail:
                'أرقام CI، نسبة الإنجاز، عدد الأخطاء، والمستخدمون لن تُعرض كحقائق حتى تُقرأ من مصادر فعلية.',
          ),
          const SizedBox(height: 8),
          const _StatusCard(
            icon: Icons.groups_outlined,
            title: 'مجلس الإدارة',
            value: '4 زوايا مراجعة',
            detail:
                'الهندسة، الجودة، الأمان والخصوصية، والتكلفة والأداء. هي مراجعة منظمة من نموذج واحد وليست أربعة وكلاء مستقلين.',
          ),
          const SizedBox(height: 16),
          const Text(
            'جدول اجتماع اليوم',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._agenda.map(
            (item) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF30284E),
                  child: Icon(item.icon, color: const Color(0xFF9B87FF)),
                ),
                title: Text(item.title, textDirection: TextDirection.rtl),
                subtitle: Text(item.detail, textDirection: TextDirection.rtl),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _startDailyMeeting,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline),
            label: Text(_busy ? 'المجلس يناقش الأولويات...' : 'ابدأ اجتماع اليوم'),
          ),
          const SizedBox(height: 8),
          const Text(
            'يُشغّل هذا الزر مراجعة عند الطلب ويسجلها نظام النقاش الحالي. لا يعمل اجتماع تلقائي أثناء إغلاق التطبيق بعد؛ ذلك يحتاج جدولة خلفية موثوقة.',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white70),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, textDirection: TextDirection.rtl),
              ),
            ),
          ],
          if (_review != null) ...[
            const SizedBox(height: 18),
            Text(
              'محضر الاجتماع'
              '${_reviewedAt == null ? '' : ' — ${_reviewedAt!.day}/${_reviewedAt!.month}/${_reviewedAt!.year}'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التوصية: ${_value(_review?['recommendation'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_value(_review?['summary']), textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Text(
                      _value(_review?['decisionRationale']),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            _reviewSection('اعتراضات المجلس', 'objections', (item) => [
              _value(item['title']),
              _value(item['role']),
              _value(item['reason']),
              'التخفيف: ${_value(item['mitigation'])}',
            ]),
            _reviewSection('اقتراحات وبدائل', 'alternatives', (item) => [
              _value(item['name']),
              'الفائدة: ${_value(item['benefit'])}',
              'التكلفة: ${_value(item['cost'])}',
              'المخاطر: ${_value(item['risk'])}',
            ]),
            _reviewSection('خطة اليوم ومعايير التحقق', 'plan', (item) => [
              _value(item['step']),
              'السبب: ${_value(item['reason'])}',
              'التحقق: ${_value(item['verification'])}',
              'الجهد التقديري: ${_value(item['estimatedEffort'])}',
            ]),
            _reviewSection('المخاطر', 'risks', (item) => [
              _value(item['risk']),
              'الأثر: ${_value(item['impact'])}',
              'التخفيف: ${_value(item['mitigation'])}',
            ]),
            if ((_review?['missingEvidence'] is List) &&
                (_review!['missingEvidence'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الأدلة الناقصة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...(_review!['missingEvidence'] as List).map(
                        (item) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.help_outline),
                          title: Text(item.toString(), textDirection: TextDirection.rtl),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'هذا محضر توصيات مولّد، وليس تقرير CI أو دليلاً على تنفيذ التغييرات. يلزم التحقق من كل خطوة قبل اعتمادها.',
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewSection(
    String title,
    String key,
    List<String> Function(Map<String, dynamic>) lines,
  ) {
    final rows = _items(key);
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines(row)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(line, textDirection: TextDirection.rtl),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF9B87FF)),
          title: Text(title),
          subtitle: Text(detail, textDirection: TextDirection.rtl),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}
