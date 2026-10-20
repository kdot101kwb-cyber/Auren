import 'package:flutter/material.dart';
import '../../../services/social/moment_update_repository.dart';

class AurenLivingMomentUpdatesScreen extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String currentUid;

  const AurenLivingMomentUpdatesScreen({
    super.key,
    required this.postId,
    required this.ownerId,
    required this.currentUid,
  });

  @override
  State<AurenLivingMomentUpdatesScreen> createState() =>
      _AurenLivingMomentUpdatesScreenState();
}

class _AurenLivingMomentUpdatesScreenState
    extends State<AurenLivingMomentUpdatesScreen> {
  final MomentUpdateRepository _repository = MomentUpdateRepository();
  bool _saving = false;

  Future<void> _addUpdate() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a moment update'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1200,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'What changed? Share the next part of the story…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Add update'),
          ),
        ],
      ),
    );
    final cleanText = text?.trim() ?? '';
    controller.dispose();
    if (cleanText.isEmpty || !mounted) return;

    setState(() => _saving = true);
    try {
      await _repository.add(
        postId: widget.postId,
        authorId: widget.currentUid,
        text: cleanText,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add update: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpdate = widget.currentUid == widget.ownerId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Living Moment'),
        actions: [
          if (canUpdate)
            IconButton(
              tooltip: 'Add update',
              onPressed: _saving ? null : _addUpdate,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
            ),
        ],
      ),
      body: StreamBuilder<List<MomentUpdate>>(
        stream: _repository.watch(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load moment updates. Please try again.'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final updates = snapshot.data!;
          if (updates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timeline, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'The story starts here',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      canUpdate
                          ? 'Add an update whenever this moment moves forward.'
                          : 'New updates from this moment will appear here.',
                      textAlign: TextAlign.center,
                    ),
                    if (canUpdate) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _saving ? null : _addUpdate,
                        icon: const Icon(Icons.add),
                        label: const Text('Add the first update'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final update = updates[index];
              final time = update.createdAt;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 17,
                          child: Icon(Icons.bolt, size: 18),
                        ),
                        if (index < updates.length - 1)
                          Container(
                            width: 2,
                            height: 72,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                update.authorId == widget.ownerId
                                    ? 'Moment owner'
                                    : 'Update author',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (time != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '${time.toLocal()}'.split('.').first,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(update.text),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canUpdate
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _addUpdate,
              icon: const Icon(Icons.add),
              label: const Text('Add update'),
            )
          : null,
    );
  }
}
