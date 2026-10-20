import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/social/post_repository.dart';
import '../utils/post_media_type.dart';

class AurenEditPostScreen extends StatefulWidget {
  final AurenPost post;
  const AurenEditPostScreen({super.key, required this.post});

  @override
  State<AurenEditPostScreen> createState() => _AurenEditPostScreenState();
}

class _AurenEditPostScreenState extends State<AurenEditPostScreen> {
  late final TextEditingController textController;
  late final TextEditingController mediaController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.post.text);
    mediaController = TextEditingController(text: widget.post.mediaUrl);
  }

  Future<void> save() async {
    if (saving) return;
    final text = textController.text.trim();
    final mediaUrl = mediaController.text.trim();
    if (text.isEmpty && mediaUrl.isEmpty) return;
    setState(() => saving = true);
    try {
      await PostRepository().updateContent(
        widget.post.id,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: _mediaTypeFor(mediaUrl),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save changes. Check your connection and try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _mediaTypeFor(String url) {
    if (url == widget.post.mediaUrl) return widget.post.mediaType;
    return postMediaTypeFromUrl(url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Pulse post'),
          actions: [
            TextButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: textController,
              maxLines: 8,
              maxLength: 2200,
              decoration: const InputDecoration(
                labelText: 'Post',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mediaController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Media URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save changes'),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    textController.dispose();
    mediaController.dispose();
    super.dispose();
  }
}
