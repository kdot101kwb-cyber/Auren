import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/media/auren_media_service.dart';
import '../../../services/social/post_repository.dart';

class AurenCreatePostScreen extends StatefulWidget {
  const AurenCreatePostScreen({super.key});

  @override
  State<AurenCreatePostScreen> createState() => _AurenCreatePostScreenState();
}

class _AurenCreatePostScreenState extends State<AurenCreatePostScreen> {
  final textController = TextEditingController();
  final mediaController = TextEditingController();
  bool saving = false;
  String contentType = 'moment';
  String mediaType = 'image';
  XFile? selectedMedia;

  Future<void> pickMedia(String type) async {
    final picker = ImagePicker();
    final picked = type == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() {
      selectedMedia = picked;
      mediaType = type;
      mediaController.clear();
    });
  }

  final types = const {
    'moment': 'Moment',
    'idea': 'Idea',
    'question': 'Question',
    'project': 'Project',
    'opportunity': 'Opportunity',
  };

  Future<void> save() async {
    final text = textController.text.trim();
    var mediaUrl = mediaController.text.trim();
    final uid = FirebaseAurenAuthService().currentUserId;
    if ((text.isEmpty && mediaUrl.isEmpty) || uid == null || saving) return;

    setState(() => saving = true);
    try {
      if (selectedMedia != null) {
        final file = selectedMedia!;
        final result = await AurenMediaService().uploadBytes(
          uid: uid,
          bytes: await file.readAsBytes(),
          fileName: file.name,
          contentType: file.mimeType ??
              (mediaType == 'video' ? 'video/mp4' : 'image/jpeg'),
          folder: 'pulse',
        );
        mediaUrl = result.downloadUrl;
      }
      await PostRepository().create(
        AurenPost(
          id: 'post_${DateTime.now().microsecondsSinceEpoch}',
          authorId: uid,
          text: text,
          mediaUrl: mediaUrl,
          mediaType: mediaUrl.isEmpty ? 'none' : mediaType,
          contentType: contentType,
          contextLabel: contentType == 'opportunity'
              ? 'Open for collaboration'
              : contentType == 'project'
                  ? 'Building now'
                  : 'Shared with AUREN',
          actionLabel: contentType == 'opportunity'
              ? 'Connect'
              : contentType == 'project'
                  ? 'Join'
                  : contentType == 'question'
                      ? 'Answer'
                      : contentType == 'idea'
                          ? 'Build'
                          : '',
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish post: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Create in Pulse'),
          actions: [
            TextButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Publishing…' : 'Share'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('What do you want to move forward?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.entries.map((e) {
                final selected = contentType == e.key;
                return ChoiceChip(
                  selected: selected,
                  label: Text(e.value),
                  onSelected: (_) => setState(() => contentType = e.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 7,
              maxLength: 2200,
              decoration: const InputDecoration(
                hintText: 'Share the idea, ask the question, show the project…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: saving ? null : () => pickMedia('image'),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choose image'),
                ),
                OutlinedButton.icon(
                  onPressed: saving ? null : () => pickMedia('video'),
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Choose video'),
                ),
              ],
            ),
            if (selectedMedia != null) ...[
              const SizedBox(height: 8),
              Text('Selected: ${selectedMedia!.name}'),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: mediaController,
              onChanged: (value) {
                if (value.trim().isNotEmpty && selectedMedia != null) {
                  setState(() => selectedMedia = null);
                }
              },
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Media URL (optional; also supports audio links)',
                hintText: 'https://…',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: mediaType,
              decoration: const InputDecoration(
                labelText: 'Media type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'image', child: Text('Image')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'audio', child: Text('Audio')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => mediaType = value);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(saving ? 'Publishing…' : 'Put it in Pulse'),
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