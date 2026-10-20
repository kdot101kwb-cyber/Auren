import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';

class AurenCreatePostScreen extends StatefulWidget {
  const AurenCreatePostScreen({super.key});

  @override
  State<AurenCreatePostScreen> createState() => _AurenCreatePostScreenState();
}

class _MixAttachmentDraft {
  _MixAttachmentDraft({this.type = 'image'}) : controller = TextEditingController();

  final TextEditingController controller;
  String type;

  void dispose() => controller.dispose();
}

class _AurenCreatePostScreenState extends State<AurenCreatePostScreen> {
  final textController = TextEditingController();
  final List<_MixAttachmentDraft> attachments = [_MixAttachmentDraft()];
  bool saving = false;
  String contentType = 'moment';
  bool livingMoment = true;

  final types = const {
    'moment': 'Moment',
    'mix': 'Mix Post',
    'idea': 'Idea',
    'question': 'Question',
    'project': 'Project',
    'opportunity': 'Opportunity',
  };

  Future<void> save() async {
    final text = textController.text.trim();
    final validAttachments = <Map<String, String>>[];
    for (final draft in attachments) {
      final raw = draft.controller.text.trim();
      if (raw.isEmpty) continue;
      final uri = Uri.tryParse(raw);
      if (uri == null || !{'http', 'https'}.contains(uri.scheme.toLowerCase()) || uri.host.isEmpty) {
        _showMessage('Use a valid http:// or https:// media URL.');
        return;
      }
      validAttachments.add({'type': draft.type, 'url': uri.toString()});
    }

    final uid = FirebaseAurenAuthService().currentUserId;
    if ((text.isEmpty && validAttachments.isEmpty) || uid == null || saving) {
      if (uid == null) _showMessage('Sign in to publish to AUREN Pulse.');
      return;
    }

    setState(() => saving = true);
    try {
      final primary = validAttachments.isEmpty ? null : validAttachments.first;
      await PostRepository().create(
        AurenPost(
          id: 'post_${DateTime.now().microsecondsSinceEpoch}',
          authorId: uid,
          text: text,
          mediaUrl: primary?['url'] ?? '',
          mediaType: primary?['type'] ?? 'none',
          mixItems: validAttachments,
          contentType: contentType,
          contextLabel: contentType == 'opportunity'
              ? 'Open for collaboration'
              : contentType == 'project'
                  ? 'Building now'
                  : livingMoment && contentType == 'moment'
                      ? 'Living Moment • updates welcome'
                      : contentType == 'mix'
                          ? 'AUREN Mix • text, media and ideas together'
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
      if (mounted) _showMessage('Could not publish: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.bolt, size: 26),
                    SizedBox(width: 8),
                    Expanded(child: Text('One moment. Many ways to tell it.',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                  ]),
                  SizedBox(height: 8),
                  Text('Share an update that can grow over time, or mix text with several kinds of media.'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Choose your format', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.entries.map((e) {
                final selected = contentType == e.key;
                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(_typeIcon(e.key), size: 17),
                  label: Text(e.value),
                  onSelected: (_) => setState(() {
                    contentType = e.key;
                    if (e.key == 'mix') livingMoment = false;
                    if (e.key == 'moment') livingMoment = true;
                  }),
                );
              }).toList(),
            ),
            if (contentType == 'moment') ...[
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: livingMoment,
                onChanged: (value) => setState(() => livingMoment = value),
                title: const Text('Living Moment'),
                subtitle: const Text('Invite updates and follow the story as it unfolds.'),
                secondary: const Icon(Icons.timeline),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              maxLength: 2200,
              decoration: const InputDecoration(
                hintText: 'What is happening? Share an idea, an update, or a question…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('Mix attachments', style: TextStyle(fontWeight: FontWeight.w800))),
              TextButton.icon(
                onPressed: attachments.length >= 5
                    ? null
                    : () => setState(() => attachments.add(_MixAttachmentDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Add media'),
              ),
            ]),
            const Text('Add up to 5 image, video, audio or link URLs. Empty rows are ignored.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            ...List.generate(attachments.length, (index) {
              final item = attachments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: item.type,
                          decoration: const InputDecoration(labelText: 'Media type', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'image', child: Text('Image')),
                            DropdownMenuItem(value: 'video', child: Text('Video')),
                            DropdownMenuItem(value: 'audio', child: Text('Audio')),
                            DropdownMenuItem(value: 'link', child: Text('Link')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => item.type = value);
                          },
                        ),
                      ),
                      if (attachments.length > 1)
                        IconButton(
                          tooltip: 'Remove attachment',
                          onPressed: () => setState(() {
                            attachments.removeAt(index).dispose();
                          }),
                          icon: const Icon(Icons.close),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: item.controller,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL (optional)',
                        hintText: 'https://…',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: Icon(saving ? Icons.hourglass_top : Icons.rocket_launch_outlined),
              label: Text(saving ? 'Publishing…' : 'Publish to AUREN Pulse'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'mix': return Icons.dashboard_customize_outlined;
      case 'idea': return Icons.lightbulb_outline;
      case 'question': return Icons.help_outline;
      case 'project': return Icons.rocket_launch_outlined;
      case 'opportunity': return Icons.work_outline;
      default: return Icons.bolt;
    }
  }

  @override
  void dispose() {
    textController.dispose();
    for (final attachment in attachments) {
      attachment.dispose();
    }
    super.dispose();
  }
}
