import 'package:flutter/material.dart';

import '../../core/offline/nova_local_workspace_store.dart';
import '../../core/planning/nova_offline_daily_planner.dart';

/// Plans local tasks against a user-selected time budget; never executes them.
class NovaDailyPlannerScreen extends StatefulWidget {
  const NovaDailyPlannerScreen({super.key, this.store, this.planner = const NovaOfflineDailyPlanner()});

  final NovaLocalWorkspaceStore? store;
  final NovaOfflineDailyPlanner planner;

  @override
  State<NovaDailyPlannerScreen> createState() => _NovaDailyPlannerScreenState();
}

class _NovaDailyPlannerScreenState extends State<NovaDailyPlannerScreen> {
  late final NovaLocalWorkspaceStore _store = widget.store ?? NovaLocalWorkspaceStore();
  List<NovaWorkspaceTask> _tasks = const [];
  final Map<String, int> _minutes = {};
  NovaDailyPlan? _plan;
  double _budget = 120;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final tasks = await _store.loadTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks.where((task) => !task.isCompleted).toList();
        for (final task in _tasks) {
          _minutes.putIfAbsent(task.id, () => 30);
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذر تحميل المهام المحلية.'; });
    }
  }

  void _buildPlan() {
    try {
      final plan = widget.planner.build(
        availableMinutes: _budget.round(),
        items: _tasks.map((task) => NovaPlanItem(
          id: task.id,
          title: task.title,
          estimatedMinutes: _minutes[task.id] ?? 30,
        )).toList(),
      );
      setState(() { _plan = plan; _error = null; });
    } catch (_) {
      setState(() => _error = 'تعذر إنشاء الخطة. تحقق من البيانات.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخطط اليومي'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'تحديث المهام')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('وقت العمل المتاح اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_budget.round()} دقيقة'),
                        Slider(
                          min: 15,
                          max: 480,
                          divisions: 31,
                          value: _budget,
                          label: '${_budget.round()} دقيقة',
                          onChanged: (value) => setState(() { _budget = value; _plan = null; }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('تقدير مدة كل مهمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_tasks.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد مهام مفتوحة. أضف مهاماً في مساحة عمل NOVA أولاً.'),
                  )),
                ..._tasks.map((task) => Card(
                  child: ListTile(
                    title: Text(task.title, textDirection: TextDirection.rtl),
                    subtitle: const Text('المدة التقديرية'),
                    trailing: DropdownButton<int>(
                      value: _minutes[task.id] ?? 30,
                      items: const [15, 30, 45, 60, 90, 120].map((value) =>
                        DropdownMenuItem(value: value, child: Text('$value د')),
                      ).toList(),
                      onChanged: (value) => setState(() {
                        if (value != null) _minutes[task.id] = value;
                        _plan = null;
                      }),
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _buildPlan,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('أنشئ خطة اليوم'),
                ),
                if (_error != null) Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
                if (_plan != null) ...[
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _Summary(label: 'مجدول', value: '${_plan!.scheduledCount}'),
                          _Summary(label: 'مؤجل', value: '${_plan!.deferredCount}'),
                          _Summary(label: 'مستخدم', value: '${_plan!.usedMinutes} د'),
                          _Summary(label: 'متبقٍ', value: '${_plan!.remainingMinutes} د'),
                        ],
                      ),
                    ),
                  ),
                  _PlanList(title: 'ابدأ بهذه المهام', items: _plan!.scheduled),
                  _PlanList(title: 'أُجّلت لوقت لاحق', items: _plan!.deferred),
                ],
                const SizedBox(height: 12),
                const Text(
                  'الخطة اقتراح زمني محلي فقط. لا تبدأ المهام ولا تشغّل وكلاء NOVA تلقائياً.',
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, textDirection: TextDirection.rtl),
    ],
  );
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.title, required this.items});
  final String title;
  final List<NovaPlanItem> items;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (items.isEmpty) const Text('لا توجد عناصر'),
          ...items.map((item) => ListTile(
            dense: true,
            title: Text(item.title, textDirection: TextDirection.rtl),
            trailing: Text('${item.estimatedMinutes} د'),
          )),
        ],
      ),
    ),
  );
}
