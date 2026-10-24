import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/social/community_collaboration_service.dart';
import '../../../services/social/community_workbench_store.dart';

class AurenCollaborationSpacesScreen extends StatefulWidget {
  const AurenCollaborationSpacesScreen({super.key});

  @override
  State<AurenCollaborationSpacesScreen> createState() =>
      _AurenCollaborationSpacesScreenState();
}

class _AurenCollaborationSpacesScreenState
    extends State<AurenCollaborationSpacesScreen> {
  final _service = AurenCollaborationService();
  late AurenCommunityWorkbenchStore _workbench;
  StreamSubscription<User?>? _authSubscription;
  bool _busy = false;
  int _accountGeneration = 0;

  @override
  void initState() {
    super.initState();
    final auth = FirebaseAuth.instance;
    _workbench = AurenCommunityWorkbenchStore(
      scope: auth.currentUser?.uid ?? 'anonymous',
    );
    _authSubscription = auth.authStateChanges().listen((user) {
      if (!mounted) return;
      _accountGeneration++;
      setState(() {
        _workbench = AurenCommunityWorkbenchStore(scope: user?.uid ?? 'anonymous');
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _createSpace() async {
    final generation = _accountGeneration;
    final requestedWorkbench = _workbench;
    final title = TextEditingController();
    final description = TextEditingController();
    final topic = TextEditingController();
    final rules = TextEditingController();
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
            TextField(controller: topic, maxLength: 80,
              decoration: const InputDecoration(labelText: 'الموضوع')), 
            TextField(controller: rules, maxLength: 2000, maxLines: 3,
              decoration: const InputDecoration(labelText: 'قواعد المساحة (محلية على هذا الجهاز)')),
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
    if (create != true || !mounted || generation != _accountGeneration) {
      title.dispose();
      description.dispose();
      topic.dispose();
      rules.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      final spaceId = await _service.createSpace(
        title: title.text,
        description: description.text,
      );
      if (!mounted || generation != _accountGeneration ||
          !identical(requestedWorkbench, _workbench)) return;
      try {
        await requestedWorkbench.saveSpaceGuidelines(
          spaceId: spaceId,
          topic: topic.text,
          rules: rules.text,
        );
        if (mounted && generation == _accountGeneration &&
            identical(requestedWorkbench, _workbench)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء مساحة التعاون وحفظ قواعدها محلياً')),
          );
        }
      } catch (metadataError) {
        if (mounted && generation == _accountGeneration &&
            identical(requestedWorkbench, _workbench)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم إنشاء المساحة، لكن تعذر حفظ الموضوع والقواعد محلياً: $metadataError',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted && generation == _accountGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء المساحة: $error')),
        );
      }
    } finally {
      title.dispose();
      description.dispose();
      topic.dispose();
      rules.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editGuidelines(AurenCollaborationSpace space) async {
    final generation = _accountGeneration;
    final requestedWorkbench = _workbench;
    final current = await requestedWorkbench.readSpaceGuidelines(space.id);
    if (!mounted || generation != _accountGeneration ||
        !identical(requestedWorkbench, _workbench)) return;
    final topic = TextEditingController(text: current['topic'] as String? ?? '');
    final rules = TextEditingController(text: current['rules'] as String? ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('موضوع وقواعد المساحة'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: topic, maxLength: 80,
              decoration: const InputDecoration(labelText: 'الموضوع')),
            TextField(controller: rules, maxLength: 2000, maxLines: 4,
              decoration: const InputDecoration(labelText: 'القواعد (محلية على هذا الجهاز)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ محلياً')),
        ],
      ),
    );
    try {
      if (save == true && mounted && generation == _accountGeneration &&
          identical(requestedWorkbench, _workbench)) {
        await requestedWorkbench.saveSpaceGuidelines(
          spaceId: space.id, topic: topic.text, rules: rules.text);
        if (mounted && generation == _accountGeneration &&
            identical(requestedWorkbench, _workbench)) setState(() {});
      }
    } catch (error) {
      if (mounted && generation == _accountGeneration &&
          identical(requestedWorkbench, _workbench)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ القواعد محلياً: $error')));
      }
    } finally {
      topic.dispose();
      rules.dispose();
    }
  }

  Future<void> _invite(AurenCollaborationSpace space) async {
    final generation = _accountGeneration;
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
    if (invite != true || !mounted || generation != _accountGeneration) {
      memberUid.dispose();
      return;
    }
    try {
      await _service.inviteToSpace(
        spaceId: space.id, memberUid: memberUid.text.trim());
      if (mounted && generation == _accountGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة العضو')));
      }
    } catch (error) {
      if (mounted && generation == _accountGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذرت الدعوة: $error')));
      }
    } finally {
      memberUid.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collaboration Spaces')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('سجّل الدخول لعرض مساحات التعاون أو إنشاء مساحة.'),
          ),
        ),
      );
    }
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
              return Card(child: FutureBuilder<Map<String, dynamic>>(
                future: _workbench.readSpaceGuidelines(space.id),
                builder: (context, meta) {
                  final topic = meta.data?['topic'] as String? ?? '';
                  final rules = meta.data?['rules'] as String? ?? '';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
                    title: Text(space.title),
                    subtitle: Text([
                      space.description,
                      if (topic.isNotEmpty) 'الموضوع: $topic',
                      if (rules.isNotEmpty) 'القواعد المحلية: $rules',
                      '${space.memberIds.length} أعضاء',
                    ].where((line) => line.isNotEmpty).join('\n')),
                    isThreeLine: true,
                    trailing: isOwner
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(tooltip: 'تعديل الموضوع والقواعد',
                              onPressed: _busy ? null : () => _editGuidelines(space),
                              icon: const Icon(Icons.rule_outlined)),
                            IconButton(tooltip: 'دعوة عضو',
                              onPressed: _busy ? null : () => _invite(space),
                              icon: const Icon(Icons.person_add_alt_1)),
                          ])
                        : const Icon(Icons.lock_open_outlined),
                  );
                },
              ));
            },
          );
        },
      ),
    );
  }
}
