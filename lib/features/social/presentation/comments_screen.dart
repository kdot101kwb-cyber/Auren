import 'package:flutter/material.dart';
import '../../../core/models/comment.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/comment_repository.dart';

class AurenCommentsScreen extends StatefulWidget {
  final String postId;
  const AurenCommentsScreen({super.key, required this.postId});
  @override State<AurenCommentsScreen> createState() => _AurenCommentsScreenState();
}

class _AurenCommentsScreenState extends State<AurenCommentsScreen> {
  final c = TextEditingController();
  bool sending = false;

  Future<void> send() async {
    final text = c.text.trim();
    final uid = FirebaseAurenAuthService().currentUserId;
    if (text.isEmpty || uid == null || sending) return;
    setState(() => sending = true);
    try {
      await CommentRepository().create(AurenComment(
        id: 'comment_${DateTime.now().microsecondsSinceEpoch}',
        postId: widget.postId,
        authorId: uid,
        text: text,
        createdAt: DateTime.now(),
      ));
      c.clear();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> remove(AurenComment comment) async {
    try {
      await CommentRepository().delete(comment);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<AurenComment>>(
            stream: CommentRepository().watch(widget.postId),
            builder: (context, s) {
              if (s.hasError) return const Center(child: Text('Could not load comments.'));
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final list = s.data!;
              if (list.isEmpty) return const Center(child: Text('Be the first to comment.'));
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final comment = list[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(comment.authorId),
                    subtitle: Text(comment.text),
                    trailing: comment.authorId == uid
                        ? IconButton(
                            tooltip: 'Delete',
                            onPressed: () => remove(comment),
                            icon: const Icon(Icons.delete_outline),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Row(children: [
            Expanded(child: TextField(
              controller: c,
              maxLength: 2000,
              decoration: const InputDecoration(hintText: 'Write a comment…'),
            )),
            IconButton(onPressed: sending ? null : send, icon: const Icon(Icons.send)),
          ]),
        ),
      ]),
    );
  }

  @override void dispose() { c.dispose(); super.dispose(); }
}