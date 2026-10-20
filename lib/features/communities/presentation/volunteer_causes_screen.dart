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
      appBar: AppBar(title: const Text('Volunteer & Causes')),
      body: StreamBuilder<List<AurenVolunteerCause>>(
        stream: _service.watchOpenCauses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل المبادرات.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final causes = snapshot.data!;
          if (causes.isEmpty) {
            return const Center(child: Text('لا توجد مبادرات مفتوحة حالياً.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: causes.length,
            itemBuilder: (context, index) {
              final item = causes[index];
              final joined = item.volunteerIds.contains(_service.uid);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.volunteer_activism_outlined),
                  title: Text(item.title),
                  subtitle: Text(
                    item.category + ' • ' + item.volunteerIds.length.toString() +
                    ' متطوع\n' + item.description,
                  ),
                  isThreeLine: true,
                  trailing: item.ownerId == _service.uid
                      ? const Chip(label: Text('منشورك'))
                      : FilledButton.tonal(
                          onPressed: joined ? null : () => _volunteer(item),
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
