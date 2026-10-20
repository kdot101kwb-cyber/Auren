import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/post.dart';
import '../../../services/social/post_repository.dart';
import '../../../services/media/auren_media_service.dart';
import '../../../services/auth/auth_service.dart';

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
  late String mediaType;
  XFile? selectedMedia;

  Future<void> pickMedia(String type) async {
    try {
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select media: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.post.text);
    mediaController = TextEditingController(text: widget.post.mediaUrl);
    mediaType = const {'image', 'video', 'audio'}.contains(widget.post.mediaType)
        ? widget.post.mediaType
        : 'image';
  }

  Future<void> save() async {
    if (saving) return;
    final text = textController.text.trim();
    var mediaUrl = mediaController.text.trim();
    if (text.isEmpty && mediaUrl.isEmpty && selectedMedia == null) return;
    setState(() => saving = true);
    try {
      if (selectedMedia != null) {
        final uid = FirebaseAurenAuthService().currentUserId;
        if (uid == null) throw StateError('Sign in before uploading media.');
        final file = selectedMedia!;
        final sizeBytes = await file.length();
        if (sizeBytes > 25 * 1024 * 1024) {
          throw ArgumentError('Media exceeds 25 MB MVP limit');
        }
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
      await PostRepository().updateContent(
        widget.post.id,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update post: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Pulse post'),
          actions: [
            TextButton(onPressed: saving ? null : save, child: Text(saving ? 'Saving…' : 'Save')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: textController, maxLines: 8, maxLength: 2200, decoration: const InputDecoration(labelText: 'Post', border: OutlineInputBorder())),
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
              keyboardType: TextInputType.url,
              onChanged: (value) {
                if (value.trim().isNotEmpty && selectedMedia != null) {
                  setState(() => selectedMedia = null);
                }
              },
              decoration: const InputDecoration(labelText: 'Media URL (audio links supported)', border: OutlineInputBorder()),
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
              onChanged: selectedMedia != null
                  ? null
                  : (value) {
                      if (value != null) setState(() => mediaType = value);
                    },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save_outlined), label: const Text('Save changes')),
          ],
        ),
      );

  @override
  void dispose() { textController.dispose(); mediaController.dispose(); super.dispose(); }
}