import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_runtime.dart';

/// Private AUREN project dashboard and NOVA management council.
/// The council is a structured multi-perspective review from one model call;
/// it is not a set of independent agents and never executes its own plan.
class AurenManagementDashboardScreen extends StatefulWidget {
  const AurenManagementDashboardScreen({super.key});

  @override
  State<AurenManagementDashboardScreen> createState() =>
      _AurenManagementDashboardScreenState();
}

class _AurenManagementDashboardScreenState
    extends State<AurenManagementDashboardScreen> {
  bool _busy = false;
  bool _historyBusy = false;
  bool _dailyAutoChecked = false;
  String? _error;
  String? _historyStatus;
  Map<String, dynamic>? _review;
  DateTime? _reviewedAt;
  List<Map<String, dynamic>> _history = const [];

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

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _loadHistory() async {
    if (!NovaFirebaseRuntime.initialized) {
      if (mounted) {
        setState(() => _historyStatus =
            'سجل الاجتماعات يظهر بعد إعداد Firebase وتسجيل الدخول.');
      }
      return;
    }
    if (_historyBusy) return;
    setState(() {
      _historyBusy = true;
      _historyStatus = null;
    });
    try {
      await _ensureSignedIn();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('تعذر الحصول على هوية المستخدم.');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('novaDebates')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      if (!mounted) return;
      setState(() {
        _history = snapshot.docs
            .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
        _historyStatus = _history.isEmpty
            ? 'لا توجد اجتماعات محفوظة لهذا الحساب حتى الآن.'
            : 'آخر ${_history.length} اجتماعات محفوظة في حسابك الخاص.';
      });
      await _maybeStartDailyMeeting(snapshot.docs);
    } catch (e) {
      if (mounted) {
        setState(() => _historyStatus =
            'تعذر تحميل سجل الاجتماعات. تحقق من الاتصال وصلاحيات Firestore.');
      }
    } finally {
      if (mounted) setState(() => _historyBusy = false);
    }
  }

  Future<void> _maybeStartDailyMeeting(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    if (_dailyAutoChecked || !NovaFirebaseRuntime.appCheckActivated) return;
    _dailyAutoChecked = true;
    final now = DateTime.now();
    final alreadyMetToday = documents.any((document) {
      final value = document.data()['createdAt'];
      if (value is! Timestamp) return false;
      final date = value.toDate().toLocal();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    });
    if (!alreadyMetToday && mounted) {
      await _startDailyMeeting();
    }
  }

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
      await _ensureSignedIn();
      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      const prompt = '''
عقد اجتماع مجلس الإدارة اليومي الخاص بمشروعي NOVA وAUREN.
راجع القرار من أربع زوايا: الهندسة، الجودة والاختبارات، الأمان والخصوصية، والتكلفة والأداء. لا توافق تلقائياً؛ اعترض على الافتراضات الضعيفة واقترح بدائل عملية.
المطلوب:
1) ملخص تنفيذي وأهم ثلاث أولويات.
2) اقتراحات عملية لمشروع AUREN وتكامل لوحة إدارته داخل NOVA.
3) اعتراضات ومخاطر واعتماديات وأدلة ناقصة.
4) خطة يوم واحد مرتبة حسب الأثر والوقت والتكلفة، ومعيار تحقق لكل خطوة.
5) فكرة أو تجربة نمو واحدة تناسب ميزانية صفر، مع طريقة قياس نتيجتها.
لا تخترع أرقام مستخدمين أو دخل أو نتائج CI. لا تعتبر بيانات المستودع أو الاختبارات متاحة ما لم تُقدّم في السياق.
القيود: لا دمج PR ولا نشر ولا تغيير صلاحيات ولا إرسال خارجي دون موافقة صريحة. قدّم توصيات فقط ولا تدّع تنفيذها.
''';
      final response = await FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('novaStrategicDebate').call(<String, dynamic>{
        'prompt': prompt,
        'context':
            'تاريخ الاجتماع: $date. مراجعة يومية من لوحة NOVA الخاصة. '
            'المستودع: https://github.com/kdot101kwb-cyber/Auren . '
            'فرع العمل المعروف: feat/nova-ai-android-app؛ PR #283. '
            'لا توجد نتائج CI حديثة موثقة في هذا الطلب؛ حالة البناء والاختبارات تحتاج تحققاً مباشراً. '
            'وازن النتيجة والوقت والتكلفة، وافصل الحقائق عن الافتراضات.',
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
      await _loadHistory();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() => _error = e.message ?? 'تعذر تشغيل اجتماع المجلس.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'تعذر إكمال الاجتماع: $e');
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

  DateTime? _dateOf(Map<String, dynamic> row) {
    final value = row['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'التاريخ غير متاح';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة AUREN ومجلس NOVA')),
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
                Text('مركز إدارة AUREN',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'لوحة خاصة داخل NOVA لمراجعة الأولويات ومخاطر التطوير والجودة والأمان والتكلفة، مع سجل اجتماعات واقتراحات يومية.',
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
                'أرقام CI ونسبة الإنجاز والأخطاء والدخل لن تظهر كحقائق حتى تُقرأ من مصادر فعلية.',
          ),
          const SizedBox(height: 8),
          const _StatusCard(
            icon: Icons.groups_outlined,
            title: 'مجلس الإدارة',
            value: '4 زوايا مراجعة',
            detail:
                'الهندسة، الجودة، الأمان والخصوصية، والتكلفة والأداء. هذه مراجعة منظمة من نموذج واحد وليست أربعة وكلاء مستقلين.',
          ),
          const SizedBox(height: 16),
          const Text('جدول اجتماع اليوم',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._agenda.map((item) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF30284E),
                    child: Icon(item.icon, color: const Color(0xFF9B87FF)),
                  ),
                  title: Text(item.title, textDirection: TextDirection.rtl),
                  subtitle: Text(item.detail, textDirection: TextDirection.rtl),
                ),
              )),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _startDailyMeeting,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_circle_outline),
            label: Text(_busy ? 'المجلس يناقش الأولويات...' : 'ابدأ اجتماع اليوم'),
          ),
          const SizedBox(height: 8),
          const Text(
            'عند إعداد Firebase وApp Check، تحاول اللوحة عقد اجتماع واحد تلقائياً في أول فتح لها كل يوم إذا لم يوجد اجتماع مسجل لذلك اليوم. يمكنك أيضاً تشغيله يدوياً. هذا لا يعمل أثناء إغلاق التطبيق؛ الجدولة الخلفية الدائمة تحتاج خدمة مجدولة منشورة.',
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
            Text('محضر الاجتماع — ${_dateLabel(_reviewedAt)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التوصية: ${_value(_review?['recommendation'])}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_value(_review?['summary']), textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Text(_value(_review?['decisionRationale']), textDirection: TextDirection.rtl),
                  ],
                ),
              ),
            ),
            _reviewSection('اعتراضات المجلس', 'objections', (item) => [
                  _value(item['title']),
                  'الزاوية: ${_value(item['role'])}',
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
            if (_review?['missingEvidence'] is List &&
                (_review!['missingEvidence'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الأدلة الناقصة',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                  'هذه توصيات مولّدة وليست تقرير CI أو دليلاً على تنفيذ التغييرات. تحقق من كل خطوة قبل اعتمادها.',
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('سجل اجتماعات المجلس',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'تحديث السجل',
                onPressed: _historyBusy ? null : _loadHistory,
                icon: _historyBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_historyStatus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_historyStatus!, textDirection: TextDirection.rtl),
            ),
          ..._history.map((row) {
            final debate = row['debate'] is Map
                ? Map<String, dynamic>.from(row['debate'] as Map)
                : <String, dynamic>{};
            return Card(
              child: ExpansionTile(
                leading: const Icon(Icons.history, color: Color(0xFF9B87FF)),
                title: Text(
                  _value(debate['summary'], _value(row['prompt'], 'اجتماع مجلس الإدارة')),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  '${_dateLabel(_dateOf(row))} • ${_value(row['status'])}',
                  textDirection: TextDirection.rtl,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_value(debate['decisionRationale']), textDirection: TextDirection.rtl),
                        const SizedBox(height: 8),
                        if (debate['plan'] is List)
                          ...(debate['plan'] as List).whereType<Map>().map(
                            (step) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.task_alt),
                              title: Text(_value(step['step']), textDirection: TextDirection.rtl),
                              subtitle: Text('التحقق: ${_value(step['verification'])}', textDirection: TextDirection.rtl),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'السجل خاص بحسابك في Firestore. عند عدم إعداد Firebase، ستبقى واجهة المجلس متاحة لكن الاجتماعات والسجل السحابي لن يعملا.',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white70),
          ),
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
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines(row)
                        .map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(line, textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                  ),
                )),
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
