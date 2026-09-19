import 'package:flutter/material.dart';
import '../../../core/models/conversation.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/conversation_repository.dart';

class AurenGroupDetailsScreen extends StatefulWidget {
  final AurenConversation conversation;
  const AurenGroupDetailsScreen({super.key, required this.conversation});

  @override
  State<AurenGroupDetailsScreen> createState() => _AurenGroupDetailsScreenState();
}

class _AurenGroupDetailsScreenState extends State<AurenGroupDetailsScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = ConversationRepository();
  bool _busy = false;

  Future<void> _addMembers() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add members'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'UIDs separated by commas',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || _auth.currentUserId != widget.conversation.ownerId) return;
    final additions = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final members = {...widget.conversation.memberIds, ...additions}.toList();
    await _run(() => _repo.updateGroupMembers(
      conversationId: widget.conversation.id,
      ownerUid: widget.conversation.ownerId!,
      memberIds: members,
    ));
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You will stop receiving messages from this group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _repo.leaveGroup(conversationId: widget.conversation.id, uid: _auth.currentUserId!);
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUserId;
    final isOwner = uid != null && uid == widget.conversation.ownerId;
    return Scaffold(
      appBar: AppBar(title: const Text('Group details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.groups)),
            title: Text(widget.conversation.title),
            subtitle: Text('${widget.conversation.memberIds.length} members'),
          ),
          const Divider(),
          ...widget.conversation.memberIds.map((id) => ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(id),
            trailing: id == widget.conversation.ownerId ? const Chip(label: Text('Owner')) : null,
          )),
          const SizedBox(height: 12),
          if (isOwner)
            FilledButton.icon(
              onPressed: _busy ? null : _addMembers,
              icon: const Icon(Icons.person_add),
              label: const Text('Add members'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy || isOwner ? null : _leave,
            icon: const Icon(Icons.logout),
            label: Text(isOwner ? 'Transfer ownership first' : 'Leave group'),
          ),
        ],
      ),
    );
  }
}
