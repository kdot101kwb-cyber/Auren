import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/opportunities/opportunity_repository.dart';
import '../../../core/models/opportunity.dart';
import '../../../core/models/user_profile.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../talent/presentation/talent_engine_screen.dart';

class AurenOpportunitiesScreen extends StatefulWidget {
  const AurenOpportunitiesScreen({super.key});
  @override
  State<AurenOpportunitiesScreen> createState() => _AurenOpportunitiesScreenState();
}

class _AurenOpportunitiesScreenState extends State<AurenOpportunitiesScreen> {
  final repo = OpportunityRepository();
  final search = TextEditingController();
  String type = 'All';
  static const types = [
    'All','Job','Freelance','Project','Partnership','Supplier',
    'Investment','Learning','Volunteer',
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لاكتشاف الفرص.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Opportunities'),
        actions: [
          IconButton(
            tooltip: 'Talent Scout',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AurenTalentEngineScreen(),
            )),
          ),
          IconButton(
            tooltip: 'Verified Skill Matches',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => _showVerifiedMatches(context, uid),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watchApplicationNotifications(uid),
            builder: (context, snapshot) {
              final unread = (snapshot.data ?? const <Map<String, dynamic>>[])
                  .where((n) => n['read'] != true)
                  .length;
              return IconButton(
                tooltip: unread == 0 ? 'إشعارات الفرص' : 'إشعارات الفرص ($unread)',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(Icons.notifications_none_outlined),
                ),
                onPressed: () => _applicationNotifications(context, uid),
              );
            },
          ),
          IconButton(
            tooltip: 'طلباتي',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => _myApplications(context, uid),
          ),
          IconButton(
            tooltip: 'طلبات فرصي',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () => _receivedApplications(context, uid),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const MessengerScreen(
                initialPrompt: 'حلّل أهدافي ومهاراتي واقترح لي فرصاً مناسبة مع سبب المطابقة والخطوة التالية.',
              ),
            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, uid),
        icon: const Icon(Icons.add),
        label: const Text('أضف فرصة'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث عن فرصة أو مهارة...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(types[i]),
                selected: type == types[i],
                onSelected: (_) => setState(() => type = types[i]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AurenOpportunity>>(
              stream: repo.watchOpen(query: search.text, type: type),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('تعذر تحميل الفرص: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد فرص مطابقة حالياً.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _card(context, list[i], uid),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applicationNotifications(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * .72,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: repo.watchApplicationNotifications(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('تعذر تحميل الإشعارات: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات فرص حالياً.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final n = notifications[index];
                final id = n['id']?.toString() ?? '';
                final read = n['read'] == true;
                final title = n['title']?.toString() ?? 'إشعار فرصة';
                final status = n['status']?.toString();
                final opportunityId = n['opportunityId']?.toString() ?? '';
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: read ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(.35),
                  leading: Icon(
                    status == 'accepted'
                        ? Icons.check_circle_outline
                        : status == 'rejected'
                            ? Icons.cancel_outlined
                            : Icons.work_outline,
                  ),
                  title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w700)),
                  subtitle: opportunityId.isEmpty ? null : Text('الفرصة: $opportunityId'),
                  trailing: read
                      ? null
                      : const Icon(Icons.fiber_manual_record, size: 10),
                  onTap: read
                      ? null
                      : () async {
                          try {
                            await repo.markApplicationNotificationRead(uid, id);
                          } catch (_) {}
                        },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showVerifiedMatches(BuildContext context, String uid) async {
    try {
      final matches = await repo.findVerifiedSkillMatches(uid);
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: MediaQuery.of(context).size.height * .75,
          child: matches.isEmpty
              ? const Center(child: Text('لا توجد فرص مطابقة لمهاراتك الموثقة بعد.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Match Everything • Verified Skills',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('AUREN استخدم فقط المهارات الموثقة لرفع دقة المطابقة.'),
                    const SizedBox(height: 12),
                    ...matches.map((item) {
                      final opportunity = item['opportunity'] as AurenOpportunity;
                      final matched = (item['matchedSkills'] as List).join(' • ');
                      final score = ((item['score'] as num) * 100).round();
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.work_outline)),
                          title: Text(opportunity.title),
                          subtitle: Text('$score% match • $matched'),
                          onTap: () {
                            Navigator.pop(context);
                            _details(context, opportunity, uid);
                          },
                        ),
                      );
                    }),
                  ],
                ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حساب المطابقات: $e')),
        );
      }
    }
  }

  Widget _card(BuildContext context, AurenOpportunity opportunity, String uid) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.work_outline)),
        title: Text(opportunity.title),
        subtitle: Text([
          opportunity.type,
          opportunity.category,
          opportunity.city,
          opportunity.country,
        ].where((x) => x.isNotEmpty).join(' • ')),
        onTap: () => _details(context, opportunity, uid),
      ),
    );
  }

  Future<void> _details(BuildContext context, AurenOpportunity opportunity, String uid) async {
    final applied = await repo.hasApplied(uid, opportunity.id);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(opportunity.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(opportunity.description),
            if (opportunity.skills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 6,
                  children: opportunity.skills.map((x) => Chip(label: Text(x))).toList(),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: uid == opportunity.ownerId
                  ? () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AurenTalentEngineScreen(
                        opportunityId: opportunity.id,
                        opportunityTitle: opportunity.title,
                        opportunityDescription: opportunity.description,
                        opportunitySkills: opportunity.skills,
                      ),
                    ))
                  : null,
              icon: const Icon(Icons.person_search),
              label: const Text('ابحث عن مواهب لهذه الفرصة'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: applied || uid == opportunity.ownerId
                        ? null
                        : () => _apply(context, opportunity, uid),
                    icon: Icon(applied ? Icons.check : Icons.send),
                    label: Text(applied ? 'تم التقديم' : 'تقديم'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const MessengerScreen(
                        initialPrompt: 'جهز لي رسالة تقديم احترافية لهذه الفرصة.',
                      ),
                    )),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context, AurenOpportunity opportunity, String uid) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('التقديم على الفرصة'),
        content: TextField(
          controller: note,
          maxLines: 5,
          maxLength: 2000,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظة لصاحب الفرصة (اختياري)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إرسال التقديم')),
        ],
      ),
    );
    if (ok != true) {
      note.dispose();
      return;
    }
    try {
      await repo.apply(uid: uid, opportunity: opportunity, note: note.text);
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التقديم بنجاح.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التقديم: $e')));
      }
    } finally {
      note.dispose();
    }
  }

  void _myApplications(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child: StreamBuilder<List<AurenOpportunityApplication>>(
          stream: repo.watchMyApplications(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Center(child: Text('لا توجد طلبات تقديم بعد.'));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('طلباتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ...snapshot.data!.map((a) => Card(
                  child: ListTile(
                    title: Text(a.title),
                    subtitle: Text([
                      a.note.isEmpty ? 'بدون ملاحظة' : a.note,
                      if (a.matchScore > 0) 'مطابقة موثقة: ${(a.matchScore * 100).round()}%',
                      if (a.matchedVerifiedSkills.isNotEmpty) 'مهارات: ${a.matchedVerifiedSkills.join(' • ')}',
                    ].join('\\n')),
                    trailing: _applicationStatusChip(a.status),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _applicationStatusChip(String status) {
    final normalized = status.trim().toLowerCase();
    final label = switch (normalized) {
      'accepted' => 'تم القبول',
      'rejected' => 'مرفوض',
      'pending' => 'قيد المراجعة',
      _ => status.isEmpty ? 'غير معروف' : status,
    };
    final icon = switch (normalized) {
      'accepted' => Icons.check_circle_outline,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.schedule_outlined,
    };
    return Chip(avatar: Icon(icon, size: 17), label: Text(label));
  }

  void _receivedApplications(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child: StreamBuilder<List<AurenOpportunityApplication>>(
          stream: repo.watchReceived(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Center(child: Text('لا توجد طلبات مستلمة.'));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('طلبات فرصي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ...snapshot.data!.map((a) => Card(
                  child: ListTile(
                    title: Text(a.title),
                    subtitle: Text([
                      a.note.isEmpty ? 'بدون ملاحظة' : a.note,
                      'مطابقة موثقة: ${(a.matchScore * 100).round()}%',
                      if (a.matchedVerifiedSkills.isNotEmpty)
                        'سبب المطابقة: ${a.matchedVerifiedSkills.join(' • ')}'
                      else
                        'سبب المطابقة: لا توجد مهارات موثقة مشتركة بعد',
                    ].join('\\n')),
                    onTap: () => _openApplicantProfile(context, a),
                    trailing: PopupMenuButton<String>(
                      onSelected: (status) async {
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(status == 'accepted' ? 'قبول المتقدم؟' : 'رفض الطلب؟'),
                            content: Text(
                              status == 'accepted'
                                  ? 'سيتم تسجيل هذا الطلب كمقبول.'
                                  : 'سيتم تسجيل هذا الطلب كمرفوض.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: Text(status == 'accepted' ? 'قبول' : 'رفض'),
                              ),
                            ],
                          ),
                        );
                        if (accepted != true || !context.mounted) return;
                        try {
                          await repo.updateApplicationStatus(
                            ownerId: uid,
                            applicantId: a.applicantId,
                            opportunityId: a.opportunityId,
                            status: status,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(status == 'accepted' ? 'تم قبول المتقدم.' : 'تم رفض الطلب.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر تحديث الطلب: $e')),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'accepted', child: Text('قبول')),
                        PopupMenuItem(value: 'rejected', child: Text('رفض')),
                      ],
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openApplicantProfile(BuildContext context, AurenOpportunityApplication application) async {
    if (application.applicantId.trim().isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(application.applicantId)
          .get();
      if (!context.mounted) return;
      final data = snap.data() ?? <String, dynamic>{};
      final profile = AurenUserProfile.fromMap(application.applicantId, data);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AurenPublicProfileScreen(profile: profile, viewerCanInspectProof: true),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح ملف المتقدم: $e')),
        );
      }
    }
  }

  Future<void> _create(BuildContext context, String uid) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final skills = TextEditingController();
    final city = TextEditingController();
    final country = TextEditingController();
    String typeValue = 'Job';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة فرصة'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
                TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'الوصف')),
                DropdownButtonFormField<String>(
                  initialValue: typeValue,
                  items: types.where((x) => x != 'All').map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => typeValue = value ?? typeValue),
                  decoration: const InputDecoration(labelText: 'النوع'),
                ),
                TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills (comma separated)')),
                TextField(controller: city, decoration: const InputDecoration(labelText: 'المدينة')),
                TextField(controller: country, decoration: const InputDecoration(labelText: 'الدولة')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء')),
          ],
        ),
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await repo.create(
        ownerId: uid,
        title: title.text,
        description: desc.text,
        type: typeValue,
        category: 'General',
        city: city.text,
        country: country.text,
        skills: skills.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(),
      );
    }
    for (final controller in [title, desc, skills, city, country]) {
      controller.dispose();
    }
  }
}
