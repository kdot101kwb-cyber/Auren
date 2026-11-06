import 'package:flutter/material.dart';

import '../../../services/emergency/emergency_preparedness_service.dart';

class AurenEmergencyPreparednessCard extends StatefulWidget {
  const AurenEmergencyPreparednessCard({super.key, required this.area});

  final String area;

  @override
  State<AurenEmergencyPreparednessCard> createState() =>
      _AurenEmergencyPreparednessCardState();
}

class _AurenEmergencyPreparednessCardState
    extends State<AurenEmergencyPreparednessCard> {
  final _service = AurenEmergencyPreparednessService();
  List<AurenPreparednessTask> _tasks = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AurenEmergencyPreparednessCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) _load();
  }

  Future<void> _load() async {
    if (widget.area.trim().isEmpty) {
      if (mounted) setState(() {
        _tasks = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final tasks = await _service.tasksFor(widget.area);
      if (mounted) setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(AurenPreparednessTask task, bool value) async {
    if (_saving) return;
    final previous = _tasks;
    setState(() {
      _saving = true;
      _tasks = _tasks
          .map((item) => item.id == task.id
              ? item.copyWith(completed: value)
              : item)
          .toList();
    });
    try {
      await _service.setCompleted(
        area: widget.area,
        taskId: task.id,
        completed: value,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _tasks = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ خطة الطوارئ محلياً.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.area.trim().isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.checklist_rtl),
          title: Text('خطة الاستعداد للطوارئ'),
          subtitle: Text('اختر المدينة والدولة لحفظ قائمة خاصة بهذه المنطقة.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.checklist_rtl),
              title: Text('خطة الاستعداد للطوارئ'),
              subtitle: Text('قائمة شخصية محفوظة على هذا الجهاز فقط.'),
            ),
            if (_loading)
              const LinearProgressIndicator()
            else if (_tasks.isEmpty)
              const Text('تعذر تحميل القائمة. أعد فتح هذه الصفحة للمحاولة.')
            else ...[
              ..._tasks.map((task) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: task.completed,
                    title: Text(task.title),
                    onChanged: _saving ? null : (value) => _toggle(task, value ?? false),
                  )),
              Text(
                '${_tasks.where((task) => task.completed).length} من ${_tasks.length} خطوات مكتملة',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
