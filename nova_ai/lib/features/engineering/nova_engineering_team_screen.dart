import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import 'nova_engineering_orchestrator.dart';
import 'nova_engineering_task_queue.dart';

class NovaEngineeringTeamScreen extends StatefulWidget {
  const NovaEngineeringTeamScreen({super.key});

  @override
  State<NovaEngineeringTeamScreen> createState() =>
      _NovaEngineeringTeamScreenState();
}

class _NovaEngineeringTeamScreenState extends State<NovaEngineeringTeamScreen> {
  static const _orchestrator = NovaEngineeringOrchestrator();
  final _taskQueue = NovaEngineeringTaskQueue();
  List<NovaEngineeringQueuedTask> _queuedTasks = const [];
  bool _queueLoading = true;
  final _goalController = TextEditingController();
  NovaEngineeringAssignment? _assignment;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _setTaskStatus(
    NovaEngineeringQueuedTask task,
    NovaEngineeringTaskStatus status,
  ) async {
    final updated = await _taskQueue.updateStatus(task.id, status);
    if (!mounted) return;
    if (!updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث حالة المهمة.')),
      );
      return;
    }
    await _loadQueue();
  }

  Future<void> _loadQueue() async {
    final tasks = await _taskQueue.load();
    if (!mounted) return;
    setState(() {
      _queuedTasks = tasks;
      _queueLoading = false;
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _planTask() async {
    try {
      final assignment = _orchestrator.plan(_goalController.text);
      setState(() {
        _assignment = assignment;
        _error = null;
      });
      final saved = await _taskQueue.enqueue(assignment);
      if (!mounted) return;
      setState(() {
        _queuedTasks = [saved, ..._queuedTasks].take(100).toList();
      });
    } on ArgumentError {
      setState(() {
        _assignment = null;
        _error = 'اكتب المهمة التي تريد من فريق NOVA التخطيط لها.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر حفظ المهمة محلياً؛ لم يتم تشغيل أي تنفيذ.';
      });
    }
  }

  Future<void> _copyPlan(NovaEngineeringAssignment assignment) async {
    final roleNames = assignment.roles.map((role) {
      return NovaEngineeringOrchestrator.departments
          .firstWhere((department) => department.role == role)
          .name;
    });
    final brief = [
      'NOVA — موجز المهمة الهندسية',
      '',
      'المهمة: ${assignment.goal}',
      'مستوى المخاطر: ${_riskLabel(assignment.risk)}',
      'الأدوار: ${roleNames.join('، ')}',
      '',
      'بوابة الموافقة: مطلوبة قبل أي تعديل فعلي أو تشغيل أوامر أو نشر أو دمج.',
      'معايير القبول: فحص الملفات الفعلية، تنفيذ تغييرات محدودة، تشغيل الاختبارات المناسبة، إرفاق النتائج، ومراجعة الفرق.',
      'الحالة: خطة فقط؛ لم يتم تنفيذ الكود ولم يتم التحقق من نجاح الاختبارات.',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: brief));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نُسخ موجز المهمة إلى الحافظة. لم يبدأ التنفيذ الفعلي.')),
    );
  }

  String _taskStatusLabel(String status) => switch (status) {
        'planned' => 'خطة محفوظة',
        'awaitingApproval' => 'بانتظار الموافقة',
        'approved' => 'موافق عليها للتنفيذ',
        'completed' => 'مكتملة',
        'blocked' => 'متوقفة',
        _ => 'غير معروفة',
      };

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
            OutlinedButton.icon(
              onPressed: () => _copyPlan(assignment),
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('نسخ موجز المهمة ومعايير القبول'),
            ),
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
          const Text('طابور المهام المحفوظة على الجهاز',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_queueLoading)
            const Center(child: CircularProgressIndicator())
          else if (_queuedTasks.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.inbox_outlined),
                title: Text('لا توجد مهام محفوظة بعد'),
                subtitle: Text('خطط لمهمة لحفظها محلياً ومراجعتها لاحقاً.'),
              ),
            )
          else
            ..._queuedTasks.map((task) => Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(task.goal),
                    subtitle: Text(
                      'الحالة: ${_taskStatusLabel(task.status)} • المخاطر: ${task.risk == 'high' ? 'مرتفعة' : task.risk == 'medium' ? 'متوسطة' : 'منخفضة'}'
                      '\nموافقة المالك مطلوبة: ${task.requiresHumanApproval ? 'نعم' : 'لا'}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('معايير القبول', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...task.acceptanceCriteria.map((criterion) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.checklist_outlined),
                            title: Text(criterion),
                          )),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: task.status == NovaEngineeringTaskStatus.awaitingApproval.name
                                ? null
                                : () => _setTaskStatus(task, NovaEngineeringTaskStatus.awaitingApproval),
                            child: const Text('إرسال للمراجعة'),
                          ),
                          OutlinedButton(
                            onPressed: task.status == NovaEngineeringTaskStatus.blocked.name
                                ? null
                                : () => _setTaskStatus(task, NovaEngineeringTaskStatus.blocked),
                            child: const Text('إيقاف المهمة'),
                          ),
                        ],
                      ),
                      const Text(
                        'تغيير الحالة لا يشغّل الكود ولا يمنح إذناً بالتنفيذ أو الدمج.',
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                )),
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
