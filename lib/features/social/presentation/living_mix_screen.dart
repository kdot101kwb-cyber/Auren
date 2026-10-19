import 'package:flutter/material.dart';

import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';

/// Unified composer for evolving Living Moments and multi-format Mix Posts.
class AurenLivingMixComposerScreen extends StatefulWidget {
  final String initialFormat;

  const AurenLivingMixComposerScreen({super.key, this.initialFormat = 'mix'});

  @override
  State<AurenLivingMixComposerScreen> createState() =>
      _AurenLivingMixComposerScreenState();
}

class _AurenLivingMixComposerScreenState
    extends State<AurenLivingMixComposerScreen> {
  final _textController = TextEditingController();
  final _summaryController = TextEditingController();
  final List<_MixBlockDraft> _blocks = [];
  bool _saving = false;
  late String _format;
  String _livingStatus = 'active';

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat == 'living' ? 'living' : 'mix';
  }

  Future<void> _publish() async {
    final uid = FirebaseAurenAuthService().currentUserId;
    final text = _textController.text.trim();
    final blocks = _blocks
        .map((block) => <String, dynamic>{
              'type': block.type,
              'value': block.controller.text.trim(),
            })
        .where((block) => (block['value'] as String).isNotEmpty)
        .toList(growable: false);
    if (uid == null) {
      _notice('Sign in to publish.');
      return;
    }
    if (_saving) return;
    if (text.isEmpty && blocks.isEmpty) {
      _notice('Add a message or at least one content block.');
      return;
    }
    if (_format == 'living' && _summaryController.text.trim().isEmpty) {
      _notice('Add a short summary so people understand what this moment is about.');
      return;
    }

    setState(() => _saving = true);
    try {
      await PostRepository().create(
        AurenPost(
          id: 'post_${DateTime.now().microsecondsSinceEpoch}',
          authorId: uid,
          text: text,
          createdAt: DateTime.now(),
          contentType: _format,
          postFormat: _format,
          mixBlocks: blocks,
          livingStatus: _livingStatus,
          livingSummary: _summaryController.text.trim(),
          mediaType: blocks.any((block) => block['type'] == 'image')
              ? 'mixed'
              : 'none',
          contextLabel: _format == 'living'
              ? 'A story that evolves over time'
              : 'A multi-format post',
          actionLabel: _format == 'living' ? 'Follow the story' : '',
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _notice('Could not publish: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addBlock(String type) {
    if (_blocks.length >= 6) {
      _notice('A Mix Post can contain up to 6 extra blocks.');
      return;
    }
    setState(() => _blocks.add(_MixBlockDraft(type)));
  }

  @override
  Widget build(BuildContext context) {
    final isLiving = _format == 'living';
    return Scaffold(
      appBar: AppBar(
        title: Text(isLiving ? 'Create Living Moment' : 'Create Mix Post'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _publish,
            child: Text(_saving ? 'Publishing…' : 'Publish'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'living',
                  icon: Icon(Icons.bolt),
                  label: Text('Living Moment'),
                ),
                ButtonSegment(
                  value: 'mix',
                  icon: Icon(Icons.dashboard_customize_outlined),
                  label: Text('Mix Post'),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) =>
                  setState(() => _format = selection.first),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isLiving ? 'A moment that keeps unfolding' : 'One post, many formats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isLiving
                ? 'Share what is happening now. Add updates as the story changes.'
                : 'Combine a note, image, audio clip, or useful link in one post.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _textController,
            maxLines: 5,
            maxLength: 2200,
            decoration: InputDecoration(
              labelText: isLiving ? 'What is happening?' : 'Your message (optional)',
              hintText: isLiving
                  ? 'Set the scene for everyone following this moment…'
                  : 'Give your mixed content some context…',
              border: const OutlineInputBorder(),
            ),
          ),
          if (isLiving) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _summaryController,
              maxLines: 2,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Moment summary',
                hintText: 'What should people follow?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timeline),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  selected: _livingStatus == 'active',
                  avatar: const Icon(Icons.sensors, size: 17),
                  label: const Text('Ongoing'),
                  onSelected: (_) => setState(() => _livingStatus = 'active'),
                ),
                ChoiceChip(
                  selected: _livingStatus == 'completed',
                  avatar: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('Completed'),
                  onSelected: (_) =>
                      setState(() => _livingStatus = 'completed'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('Content blocks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
              ),
              Text('${_blocks.length}/6',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _addBlockChip('Text', 'text', Icons.notes),
              _addBlockChip('Image URL', 'image', Icons.image_outlined),
              _addBlockChip('Audio URL', 'audio', Icons.graphic_eq),
              _addBlockChip('Link', 'link', Icons.link),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _blocks.length; i++)
            _buildBlockEditor(i, _blocks[i]),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _publish,
            icon: Icon(isLiving ? Icons.sensors : Icons.auto_awesome_mosaic),
            label: Text(_saving
                ? 'Publishing…'
                : isLiving
                    ? 'Start Living Moment'
                    : 'Publish Mix Post'),
          ),
          const SizedBox(height: 8),
          Text(
            'Links and media are shared as URLs. Upload and in-app audio playback can be added as a later media-pipeline step.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _addBlockChip(String label, String type, IconData icon) => ActionChip(
        avatar: Icon(icon, size: 17),
        label: Text(label),
        onPressed: () => _addBlock(type),
      );

  Widget _buildBlockEditor(int index, _MixBlockDraft block) {
    final label = switch (block.type) {
      'image' => 'Image URL',
      'audio' => 'Audio URL',
      'link' => 'Web link',
      _ => 'Text block',
    };
    return Card(
      key: ValueKey(block),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(switch (block.type) {
                  'image' => Icons.image_outlined,
                  'audio' => Icons.graphic_eq,
                  'link' => Icons.link,
                  _ => Icons.notes,
                }),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Remove block',
                  onPressed: () => setState(() {
                    _blocks.removeAt(index);
                    block.dispose();
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              controller: block.controller,
              maxLines: block.type == 'text' ? 3 : 1,
              keyboardType: block.type == 'text'
                  ? TextInputType.multiline
                  : TextInputType.url,
              decoration: InputDecoration(
                hintText: switch (block.type) {
                  'image' => 'https://…/image.jpg',
                  'audio' => 'https://…/audio.mp3',
                  'link' => 'https://…',
                  _ => 'Add a note…',
                },
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _summaryController.dispose();
    for (final block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }
}

class _MixBlockDraft {
  final String type;
  final TextEditingController controller = TextEditingController();

  _MixBlockDraft(this.type);

  void dispose() => controller.dispose();
}
