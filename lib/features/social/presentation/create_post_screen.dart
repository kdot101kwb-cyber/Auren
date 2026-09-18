import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';

class AurenCreatePostScreen extends StatefulWidget {
  const AurenCreatePostScreen({super.key});
  @override State<AurenCreatePostScreen> createState() => _AurenCreatePostScreenState();
}
class _AurenCreatePostScreenState extends State<AurenCreatePostScreen> {
  final controller = TextEditingController();
  bool saving = false;

  Future<void> save() async {
    final text = controller.text.trim();
    final uid = FirebaseAurenAuthService().currentUserId;
    if (text.isEmpty || uid == null) return;
    setState(() => saving = true);
    try {
      await PostRepository().create(AurenPost(
        id: 'post_${DateTime.now().microsecondsSinceEpoch}',
        authorId: uid,
        text: text,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Pulse')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: controller, maxLines: 6, decoration: const InputDecoration(hintText: 'What do you want to share?')),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Publishing…' : 'Publish'))),
      ]),
    ),
  );

  @override void dispose() { controller.dispose(); super.dispose(); }
}