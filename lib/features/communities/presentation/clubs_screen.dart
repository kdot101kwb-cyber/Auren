import 'package:flutter/material.dart';

import '../../../services/social/community_collaboration_service.dart';

class AurenClubsScreen extends StatefulWidget {
  const AurenClubsScreen({super.key});

  @override
  State<AurenClubsScreen> createState() => _AurenClubsScreenState();
}

class _AurenClubsScreenState extends State<AurenClubsScreen> {
  final _service = AurenCollaborationService();
  final _search = TextEditingController();
  String _query = '';
  bool _creating = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createClub() async {
    final name = TextEditingController();
    final category = TextEditingController();
    final description = TextEditingController();
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنشاء نادٍ أو دائرة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'اسم النادي'),
              ),
              TextField(
                controller: category,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'الاهتمام أو النشاط'),
              ),
              TextField(
                controller: description,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    if (shouldCreate != true) {
      name.dispose();
      category.dispose();
      description.dispose();
      return;
    }
    setState(() => _creating = true);
    try {
      await _service.createClub(
        name: name.text,
        category: category.text,
        description: description.text,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء النادي: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
      name.dispose();
      category.dispose();
      description.dispose();
    }
  }

  Future<void> _toggleMembership(AurenClub club) async {
    try {
      final member = club.memberIds.contains(_service.uid);
      if (member) {
        await _service.leaveClub(club.id);
      } else {
        await _service.joinClub(club.id);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث العضوية: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Circles'),
        actions: [
          IconButton(
            tooltip: 'إنشاء نادٍ',
            onPressed: _creating ? null : _createClub,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث حسب النادي أو الاهتمام',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AurenClub>>(
              stream: _service.watchClubs(query: _query),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل النوادي. تحقق من الاتصال والصلاحيات.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final clubs = snapshot.data!;
                if (clubs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد نوادٍ مطابقة بعد. أنشئ أول دائرة.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: clubs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    final joined = club.memberIds.contains(_service.uid);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.groups_2_outlined),
                        ),
                        title: Text(club.name),
                        subtitle: Text(
                          '${club.category} • ${club.memberCount} عضو\n${club.description}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: club.ownerId == _service.uid
                            ? const Chip(label: Text('المالك'))
                            : FilledButton.tonal(
                                onPressed: () => _toggleMembership(club),
                                child: Text(joined ? 'مغادرة' : 'انضمام'),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
