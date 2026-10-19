import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
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
  String momentContext = 'Now';

  final types = const {
    'moment': 'Moment',
    'idea': 'Idea',
    'question': 'Question',
    'project': 'Project',
    'opportunity': 'Opportunity',
  };

  final momentContexts = const [
    ('Now', 'ماذا يحدث الآن؟', Icons.bolt_rounded),
    ('Making progress', 'أشارك تقدّمي', Icons.trending_up_rounded),
    ('On the move', 'من مكاني أو طريقي', Icons.place_outlined),
    ('Open conversation', 'أفتح نقاشاً', Icons.forum_outlined),
  ];

  Future<void> save() async {
    final text = textController.text.trim();
    final mediaUrl = mediaController.text.trim();
    final uid = FirebaseAurenAuthService().currentUserId;
    if ((text.isEmpty && mediaUrl.isEmpty) || uid == null || saving) return;

    if (mediaUrl.isNotEmpty) {
      final uri = Uri.tryParse(mediaUrl);
      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid http or https media URL.')),
        );
        return;
      }
    }

    setState(() => saving = true);
    try {
      await PostRepository().create(
        AurenPost(
          id: 'post_${DateTime.now().microsecondsSinceEpoch}',
          authorId: uid,
          text: text,
          mediaUrl: mediaUrl,
          mediaType: mediaUrl.isEmpty ? 'none' : 'image',
          contentType: contentType,
          contextLabel: contentType == 'moment'
              ? momentContexts.firstWhere((item) => item.$1 == momentContext).$2
              : contentType == 'opportunity'
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not publish this post. Please try again.')),
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
            const Text(
              'One post, more of your life',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'اجمع كلامك وصورتك في منشور واحد، أو شارك لحظة سريعة من يومك.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            const Text('What are you sharing?',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
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
            if (contentType == 'moment') ...[
              const SizedBox(height: 18),
              const Text('Living moment',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'أضف سياقاً بسيطاً للحظة؛ لا تتم مشاركة موقعك تلقائياً.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: momentContexts.map((item) {
                  return ChoiceChip(
                    avatar: Icon(item.$3, size: 17),
                    label: Text(item.$1),
                    selected: momentContext == item.$1,
                    onSelected: (_) => setState(() => momentContext = item.$1),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              onChanged: (_) => setState(() {}),
              maxLines: 6,
              maxLength: 2200,
              decoration: const InputDecoration(
                hintText: 'Share the idea, ask the question, show the project…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mediaController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                hintText: 'https://…',
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(),
                helperText: 'Add an image to mix media and text in one post.',
              ),
            ),
            const SizedBox(height: 16),
            _PostPreview(
              text: textController.text.trim(),
              mediaUrl: mediaController.text.trim(),
              typeLabel: types[contentType]!,
              contextLabel: contentType == 'moment'
                  ? momentContexts.firstWhere((item) => item.$1 == momentContext).$2
                  : '',
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

class _PostPreview extends StatelessWidget {
  const _PostPreview({
    required this.text,
    required this.mediaUrl,
    required this.typeLabel,
    required this.contextLabel,
  });

  final String text;
  final String mediaUrl;
  final String typeLabel;
  final String contextLabel;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_outlined),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Preview',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Chip(label: Text(typeLabel)),
                ],
              ),
              if (contextLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(contextLabel,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(text),
              ],
              if (mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0x11000000),
                        child: Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 36),
                        ),
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                    ),
                  ),
                ),
              ],
              if (text.isEmpty && mediaUrl.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Your text and image will appear together here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      );
}
