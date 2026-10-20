import 'package:flutter/material.dart';

import '../../../services/social/community_collaboration_service.dart';

class AurenCollaborationSpacesScreen extends StatefulWidget {
  const AurenCollaborationSpacesScreen({super.key});

  @override
  State<AurenCollaborationSpacesScreen> createState() =>
      _AurenCollaborationSpacesScreenState();
}

class _AurenCollaborationSpacesScreenState
    extends State<AurenCollaborationSpacesScreen> {
  final _service = AurenCollaborationService();
  bool _busy = false;

  Future<void> _createSpace() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنشاء مساحة تعاون'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, maxLength: 120,
              decoration: const InputDecoration(labelText: 'اسم المساحة')),
            TextField(controller: description, maxLength: 2000, maxLines: 3,
              decoration: const InputDecoration(labelText: 'وصف المساحة')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إنشاء')),
        ],
      ),
    );
    if (create != true) {
      title.dispose();
      description.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.createSpace(title: title.text, description: description.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء مساحة التعاون')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء المساحة: $error')));
      }
    } finally {
      title.dispose();
      description.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(AurenCollaborationSpace space) async {
    final memberUid = TextEditingController();
    final invite = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('دعوة عضو'),
        content: TextField(controller: memberUid,
          decoration: const InputDecoration(labelText: 'معرّف المستخدم UID')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('دعوة')),
        ],
      ),
    );
    if (invite != true) {
      memberUid.dispose();
      return;
    }
    try {
      await _service.inviteToSpace(
        spaceId: space.id, memberUid: memberUid.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة العضو')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذرت الدعوة: $error')));
      }
    } finally {
      memberUid.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collaboration Spaces'),
        actions: [
          IconButton(tooltip: 'إنشاء مساحة',
            onPressed: _busy ? null : _createSpace,
            icon: const Icon(Icons.add_circle_outline)),
        ]),
      body: StreamBuilder<List<AurenCollaborationSpace>>(
        stream: _service.watchMySpaces(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل مساحات التعاون.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final spaces = snapshot.data!;
          if (spaces.isEmpty) {
            return const Center(child: Text(
              'لا توجد مساحات بعد. أنشئ مساحة للعمل مع فريقك.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: spaces.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final space = spaces[index];
              final isOwner = space.ownerId == _service.uid;
              return Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
                title: Text(space.title),
                subtitle: Text(space.description + '\n' +
                  space.memberIds.length.toString() + ' أعضاء'),
                isThreeLine: true,
                trailing: isOwner
                    ? IconButton(tooltip: 'دعوة عضو',
                        onPressed: () => _invite(space),
                        icon: const Icon(Icons.person_add_alt_1))
                    : const Icon(Icons.lock_open_outlined),
              ));
            },
          );
        },
      ),
    );
  }
}
