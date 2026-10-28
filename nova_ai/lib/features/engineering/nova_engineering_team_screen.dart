import 'package:flutter/material.dart';

import 'nova_engineering_orchestrator.dart';

class NovaEngineeringTeamScreen extends StatefulWidget {
  const NovaEngineeringTeamScreen({super.key});

  @override
  State<NovaEngineeringTeamScreen> createState() =>
      _NovaEngineeringTeamScreenState();
}

class _NovaEngineeringTeamScreenState extends State<NovaEngineeringTeamScreen> {
  static const _orchestrator = NovaEngineeringOrchestrator();
  final _goalController = TextEditingController();
  NovaEngineeringAssignment? _assignment;
  String? _error;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _planTask() {
    try {
      final assignment = _orchestrator.plan(_goalController.text);
      setState(() {
        _assignment = assignment;
        _error = null;
      });
    } on ArgumentError {
      setState(() {
        _assignment = null;
        _error = 'اكتب المهمة التي تريد من فريق NOVA التخطيط لها.';
      });
    }
  }

  String _riskLabel(NovaEngineeringRisk risk) => switch (risk) {
        NovaEngineeringRisk.low => 'منخفض',
        NovaEngineeringRisk.medium => 'متوسط',
        NovaEngineeringRisk.high => 'مرتفع',
      };

  IconData _roleIcon(NovaEngineeringRole role) => switch (role) {
        NovaEngineeringRole.architect => Icons.account_tree_outlined,
        NovaEngineeringRole.flutterUi => Icons.phone_android,
        NovaEngineeringRole.backendApi => Icons.cloud_outlined,
        NovaEngineeringRole.security => Icons.shield_outlined,
        NovaEngineeringRole.testEngineer => Icons.fact_check_outlined,
        NovaEngineeringRole.buildRelease => Icons.build_circle_outlined,
        NovaEngineeringRole.codeReviewer => Icons.rate_review_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF382B70), Color(0xFF172D48)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.engineering, size: 34),
                SizedBox(height: 10),
                Text(
                  'NOVA Engineering Core',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'فريق تخطيط هندسي لتطوير AUREN وتطبيقاتك الأخرى. يوزع المهام ويحدد مراجعات الجودة والأمان قبل التنفيذ.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _goalController,
            minLines: 2,
            maxLines: 4,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'المهمة الهندسية',
              hintText: 'مثال: أصلح فشل Flutter وافحص بناء APK وصلاحيات Firebase',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onSubmitted: (_) => _planTask(),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _planTask,
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('وزّع المهمة على المهندسين'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (assignment != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('خطة الفريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('المخاطر: ${_riskLabel(assignment.risk)}'),
                    const SizedBox(height: 6),
                    Text(assignment.reason),
                    const SizedBox(height: 10),
                    const Text(
                      'هذه خطة توزيع وليست دليلاً على أن التغييرات نُفذت أو أن الاختبارات نجحت.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...assignment.roles.map((role) {
              final department = NovaEngineeringOrchestrator.departments
                  .firstWhere((item) => item.role == role);
              return Card(
                child: ListTile(
                  leading: Icon(_roleIcon(role)),
                  title: Text(department.name),
                  subtitle: Text(department.mandate),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('بوابة موافقة المالك'),
                subtitle: Text(
                  'التعديل الفعلي للمستودع، تشغيل أوامر خارجية، النشر، الدفع أو الدمج يحتاج عامل تنفيذ موصولاً وصلاحيات مناسبة وموافقتك.',
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('الأقسام الهندسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...NovaEngineeringOrchestrator.departments.map(
            (department) => Card(
              child: ListTile(
                leading: Icon(_roleIcon(department.role)),
                title: Text(department.name),
                subtitle: Text(department.mandate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
