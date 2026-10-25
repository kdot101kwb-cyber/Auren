import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// NOVA's dedicated workspace for progressing the AUREN app.
/// This screen is transparent about what is automated versus planned.
class AurenBuildWorkspaceScreen extends StatelessWidget {
  const AurenBuildWorkspaceScreen({super.key});

  static const _repo = 'https://github.com/kdot101kwb-cyber/Auren';
  static const _pullRequests = 'https://github.com/kdot101kwb-cyber/Auren/pulls';
  static const _actions = 'https://github.com/kdot101kwb-cyber/Auren/actions';
  static const _roadmap = 'https://github.com/kdot101kwb-cyber/Auren/issues/282';

  Future<void> _open(BuildContext context, String value) async {
    final uri = Uri.parse(value);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط. حاول مرة أخرى.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF382B70), Color(0xFF202039)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.precision_manufacturing, size: 32, color: Color(0xFF9B87FF)),
                  SizedBox(height: 10),
                  Text('NOVA Builder · مساحة AUREN',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'المركز المخصص لمتابعة بناء AUREN: الكود، الاختبارات، البناء، الأفكار، والأنظمة الناقصة.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _BuildStatusCard(
              icon: Icons.code,
              title: 'تطوير AUREN',
              detail: 'المصدر محفوظ في GitHub. يجب أن ينفذ التغيير على فرع عمل ثم يراجع قبل الدمج.',
              status: 'مرتبط بالمستودع',
            ),
            const _BuildStatusCard(
              icon: Icons.fact_check_outlined,
              title: 'اختبارات الجودة',
              detail: 'متابعة Flutter analyze والاختبارات وبناء Android من نتائج CI الفعلية.',
              status: 'تحقق من النتائج',
            ),
            const _BuildStatusCard(
              icon: Icons.schedule,
              title: 'المراقبة في الخلفية',
              detail: 'المراقبة المستمرة تحتاج GitHub Actions مجدولاً وخدمة خلفية وسجلاً للنتائج؛ فتح هذه الصفحة وحده لا يشغّل وكيلاً.',
              status: 'تحتاج تفعيلاً',
            ),
            const _BuildStatusCard(
              icon: Icons.lightbulb_outline,
              title: 'أفكار وأنظمة جديدة',
              detail: 'تسجيل فكرة، تقييم حاجة السوق، مقارنة تكلفة التنفيذ، ثم إنشاء مهمة تطوير قابلة للاختبار.',
              status: 'مسار عمل',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _open(context, _repo),
              icon: const Icon(Icons.source_outlined),
              label: const Text('فتح كود AUREN'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _open(context, _actions),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('فحص التشغيل والاختبارات في GitHub Actions'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _open(context, _pullRequests),
              icon: const Icon(Icons.merge_type),
              label: const Text('مراجعة التغييرات وطلبات الدمج'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _open(context, _roadmap),
              icon: const Icon(Icons.map_outlined),
              label: const Text('فتح خارطة طريق AUREN'),
            ),
            const SizedBox(height: 14),
            const _BuildNotice(
              text: 'ضمانات التشغيل: لا يدمج NOVA تغييرات تلقائياً إلى main، ولا ينشر تطبيقاً ولا يغيّر صلاحيات أو بيانات إنتاج دون قواعد أمان وموافقة. كل تشغيل يجب أن يسجل الفرع والالتزام ونتيجة الاختبار ورابط البناء.',
            ),
          ],
        ),
      );
}

class _BuildStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String status;

  const _BuildStatusCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF30284E),
            child: Icon(icon, color: const Color(0xFF9B87FF)),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('$detail\n$status'),
          ),
          isThreeLine: true,
        ),
      );
}

class _BuildNotice extends StatelessWidget {
  final String text;
  const _BuildNotice({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF282438),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text),
      );
}
