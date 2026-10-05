import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/personal_ai/reminder_service.dart';

class AurenReminderScreen extends StatefulWidget {
  const AurenReminderScreen({super.key});
  @override
  State<AurenReminderScreen> createState() => _AurenReminderScreenState();
}

class _AurenReminderScreenState extends State<AurenReminderScreen> {
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final service = ReminderService();

  @override
  void dispose() {
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: StreamBuilder(
        stream: service.watch(uid),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? const <AurenReminder>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'التذكير',
                  prefixIcon: Icon(Icons.notifications_none),
                ),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'ملاحظة'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  await service.create(
                    uid,
                    title,
                    noteController.text,
                    DateTime.now().toUtc().toIso8601String(),
                  );
                  titleController.clear();
                  noteController.clear();
                },
                icon: const Icon(Icons.add_alert),
                label: const Text('إضافة'),
              ),
              const SizedBox(height: 12),
              ...reminders.map(
                (reminder) => Card(
                  child: CheckboxListTile(
                    value: reminder.done,
                    onChanged: (_) => service.done(uid, reminder),
                    title: Text(reminder.title),
                    subtitle: Text(
                      reminder.note.isEmpty ? 'بدون ملاحظة' : reminder.note,
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => service.delete(uid, reminder.id),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
