import 'package:flutter/material.dart';
import '../../../services/social/community_member_tools_service.dart';

/// Member tools are private to this device; they do not publish or sync data.
class AurenCommunityMemberToolsScreen extends StatefulWidget {
  final String communityId;
  const AurenCommunityMemberToolsScreen({super.key, required this.communityId});
  @override
  State<AurenCommunityMemberToolsScreen> createState() =>
      _AurenCommunityMemberToolsScreenState();
}

class _AurenCommunityMemberToolsScreenState extends State<AurenCommunityMemberToolsScreen> {
  final _service = AurenCommunityMemberToolsService();
  final _title = TextEditingController(), _link = TextEditingController(),
      _description = TextEditingController();
  List<AurenOnboardingTask> _tasks = [];
  List<AurenCommunityResource> _resources = [];
  AurenCommunityDigestPreferences _digest = const AurenCommunityDigestPreferences();
  AurenCommunityActivitySummary _activity = const AurenCommunityActivitySummary();
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _title.dispose(); _link.dispose(); _description.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait<Object>([
        _service.onboardingTasks(widget.communityId),
        _service.resources(widget.communityId),
        _service.digestPreferences(),
        _service.activitySummary(widget.communityId),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = values[0] as List<AurenOnboardingTask>;
        _resources = values[1] as List<AurenCommunityResource>;
        _digest = values[2] as AurenCommunityDigestPreferences;
        _activity = values[3] as AurenCommunityActivitySummary;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل الأدوات المحلية.'; _loading = false; });
    }
  }

  Future<void> _toggleTask(AurenOnboardingTask task, bool value) async {
    try {
      await _service.setOnboardingTask(communityId: widget.communityId,
        taskId: task.id, completed: value);
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ تقدمك. حاول مرة أخرى.')));
    }
  }

  Future<void> _addResource() async {
    try {
      await _service.addResource(communityId: widget.communityId,
        title: _title.text, link: _link.text, description: _description.text);
      _title.clear(); _link.clear(); _description.clear();
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم تتم إضافة المورد: ' + error.toString())));
    }
  }

  Future<void> _saveDigest(AurenCommunityDigestPreferences next) async {
    try {
      await _service.saveDigestPreferences(next);
      if (mounted) setState(() => _digest = next);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ إعدادات الملخص.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('أدوات عضو المجتمع')),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!), TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))])
        : RefreshIndicator(onRefresh: _load, child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('هذه البيانات محفوظة على جهازك فقط، وليست إحصاءات رسمية للمجتمع.'),
              const SizedBox(height: 12),
              _section('١. الانضمام للمجتمع', Icons.flag_outlined, [
                ..._tasks.map((task) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero, value: task.completed,
                  title: Text(task.title),
                  onChanged: (value) => _toggleTask(task, value ?? false))),
                Text(_tasks.where((task) => task.completed).length.toString() +
                  ' من ' + _tasks.length.toString() + ' خطوات مكتملة'),
              ]),
              _section('٢. مكتبة الموارد', Icons.bookmarks_outlined, [
                TextField(controller: _title, maxLength: 120,
                  decoration: const InputDecoration(labelText: 'اسم المورد')),
                TextField(controller: _link, keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'رابط HTTPS أو HTTP')),
                TextField(controller: _description, maxLength: 500,
                  decoration: const InputDecoration(labelText: 'وصف اختياري')),
                Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
                  onPressed: _addResource, icon: const Icon(Icons.add_link),
                  label: const Text('حفظ المورد محلياً'))),
                if (_resources.isEmpty) const Text('لا توجد موارد محفوظة على هذا الجهاز.'),
                ..._resources.map((resource) => ListTile(
                  contentPadding: EdgeInsets.zero, title: Text(resource.title),
                  subtitle: Text(resource.description.isEmpty ? resource.link :
                    resource.description + '\n' + resource.link),
                  isThreeLine: resource.description.isNotEmpty,
                  trailing: IconButton(tooltip: 'حذف المورد المحلي',
                    icon: const Icon(Icons.delete_outline), onPressed: () async {
                      await _service.removeResource(communityId: widget.communityId,
                        resourceId: resource.id);
                      await _load();
                    }),
                )),
              ]),
              _section('٣. تفضيلات ملخص المجتمع', Icons.mark_email_unread_outlined, [
                SwitchListTile(contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل تفضيلات الملخص'),
                  subtitle: const Text('حفظ التفضيل فقط؛ لا تُرسل إشعارات تلقائياً.'),
                  value: _digest.enabled,
                  onChanged: (value) => _saveDigest(_digest.copyWith(enabled: value))),
                DropdownButtonFormField<String>(
                  value: _digest.frequency,
                  decoration: const InputDecoration(labelText: 'التكرار المفضل'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('يومي')),
                    DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                  ],
                  onChanged: (value) {
                    if (value != null) _saveDigest(_digest.copyWith(frequency: value));
                  },
                ),
                SwitchListTile(contentPadding: EdgeInsets.zero,
                  title: const Text('تضمين الذاكرة المجتمعية'),
                  value: _digest.includeMemory,
                  onChanged: (value) => _saveDigest(_digest.copyWith(includeMemory: value))),
                SwitchListTile(contentPadding: EdgeInsets.zero,
                  title: const Text('تضمين الموارد المحفوظة'),
                  value: _digest.includeResources,
                  onChanged: (value) => _saveDigest(_digest.copyWith(includeResources: value))),
              ]),
              _section('٤. مؤشرات مشاركتي المحلية', Icons.insights_outlined, [
                _metric('خطوات الانضمام المكتملة', _activity.onboardingTasksCompleted),
                _metric('موارد أُضيفت', _activity.resourcesSaved),
                _metric('موارد حُذفت', _activity.resourcesRemoved),
                _metric('إجراءات مسجلة على الجهاز', _activity.recordedActions),
                const Text('الأرقام تخص هذا الجهاز فقط ولا تمثل نشاط بقية الأعضاء.'),
              ]),
            ],
          )),
  );

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon), const SizedBox(width: 8),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium))]),
        const SizedBox(height: 10), ...children,
      ],
    )),
  );

  Widget _metric(String label, int value) => ListTile(
    contentPadding: EdgeInsets.zero, title: Text(label),
    trailing: Text(value.toString(), style: Theme.of(context).textTheme.titleMedium),
  );
}
