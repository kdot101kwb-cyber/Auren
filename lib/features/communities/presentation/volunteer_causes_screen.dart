import 'package:flutter/material.dart';

import '../../../services/social/community_collaboration_service.dart';

class AurenVolunteerCausesScreen extends StatefulWidget {
  const AurenVolunteerCausesScreen({super.key});

  @override
  State<AurenVolunteerCausesScreen> createState() =>
      _AurenVolunteerCausesScreenState();
}

class _AurenVolunteerCausesScreenState
    extends State<AurenVolunteerCausesScreen> {
  final _service = AurenCollaborationService();
  bool _creating = false;

  Future<void> _createCause() async {
    final title = TextEditingController();
    final category = TextEditingController();
    final description = TextEditingController();
    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنشاء مبادرة تطوعية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'اسم المبادرة'),
              ),
              TextField(
                controller: category,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'المجال'),
              ),
              TextField(
                controller: description,
                maxLength: 2000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'كيف يمكن للناس المساعدة؟',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('نشر المبادرة'),
          ),
        ],
      ),
    );
    if (create != true) {
      title.dispose();
      category.dispose();
      description.dispose();
      return;
    }

    setState(() => _creating = true);
    try {
      await _service.createCause(
        title: title.text,
        category: category.text,
        description: description.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر المبادرة')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر نشر المبادرة: $error')),
        );
      }
    } finally {
      title.dispose();
      category.dispose();
      description.dispose();
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _volunteer(AurenVolunteerCause cause) async {
    try {
      await _service.volunteerForCause(cause.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل اهتمامك بالتطوع')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التسجيل: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer & Causes'),
        actions: [
          IconButton(
            tooltip: 'إنشاء مبادرة',
            onPressed: _creating ? null : _createCause,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: StreamBuilder<List<AurenVolunteerCause>>(
        stream: _service.watchOpenCauses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('تعذر تحميل المبادرات. تحقق من الاتصال والصلاحيات.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final causes = snapshot.data!;
          if (causes.isEmpty) {
            return const Center(
              child: Text('لا توجد مبادرات مفتوحة حالياً. أنشئ أول مبادرة.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: causes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cause = causes[index];
              final joined = cause.volunteerIds.contains(_service.currentUid);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.volunteer_activism_outlined),
                  title: Text(cause.title),
                  subtitle: Text(
                    cause.category +
                        ' • ' +
                        cause.volunteerIds.length.toString() +
                        ' متطوع\n' +
                        cause.description,
                  ),
                  isThreeLine: true,
                  trailing: cause.ownerId == _service.currentUid
                      ? const Chip(label: Text('مبادرتك'))
                      : FilledButton.tonal(
                          onPressed: joined ? null : () => _volunteer(cause),
                          child: Text(joined ? 'أنت متطوع' : 'تطوع'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
