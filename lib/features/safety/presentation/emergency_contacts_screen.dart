import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/safety/emergency_contacts_repository.dart';

class AurenEmergencyContactsScreen extends StatelessWidget {
  const AurenEmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لإدارة جهات الاتصال للطوارئ.')));
    final repo = AurenEmergencyContactsRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts'), actions: [
        IconButton(tooltip: 'إضافة جهة اتصال', onPressed: () => _add(context, uid, repo), icon: const Icon(Icons.add)),
      ]),
      body: StreamBuilder<List<AurenEmergencyContact>>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل جهات الاتصال.'));
          final contacts = snapshot.data ?? const <AurenEmergencyContact>[];
          if (contacts.isEmpty) return _empty(context, uid, repo);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(child: ListTile(
                leading: CircleAvatar(child: Icon(contact.primary ? Icons.star : Icons.person_outline)),
                title: Text(contact.name),
                subtitle: Text([contact.phone, contact.relation].where((x) => x.isNotEmpty).join(' • ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'اتصال',
                      onPressed: () => _call(context, contact.phone),
                      icon: const Icon(Icons.call_outlined),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        try {
                          if (value == 'primary') await repo.setPrimary(uid, contact.id);
                          if (value == 'delete') await repo.delete(uid, contact.id);
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
                        }
                      },
                      itemBuilder: (_) => [
                        if (!contact.primary) const PopupMenuItem(value: 'primary', child: Text('تعيين كجهة أساسية')),
                        const PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
              ));
            },
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, String uid, AurenEmergencyContactsRepository repo) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.contact_emergency_outlined, size: 52),
        const SizedBox(height: 12),
        const Text('أضف شخصًا تثق به ليظهر لك بسرعة عند الحاجة.'),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () => _add(context, uid, repo), icon: const Icon(Icons.add), label: const Text('إضافة جهة اتصال')),
      ]),
    ),
  );

  static Future<void> _call(BuildContext context, String phone) async {
    final normalized = phone.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر.')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    try {
      if (!await launchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الاتصال.')));
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الاتصال.')));
      }
    }
  }

  static Future<void> _add(BuildContext context, String uid, AurenEmergencyContactsRepository repo) async {
    final name = TextEditingController(), phone = TextEditingController(), relation = TextEditingController();
    var primary = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة جهة اتصال'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            TextField(controller: relation, decoration: const InputDecoration(labelText: 'صلة القرابة / الوصف')),
            SwitchListTile(contentPadding: EdgeInsets.zero, value: primary, onChanged: (v) => setState(() => primary = v), title: const Text('جهة أساسية')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () async {
              try {
                await repo.add(uid: uid, name: name.text, phone: phone.text, relation: relation.text, primary: primary);
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
              }
            }, child: const Text('حفظ')),
          ],
        ),
      ),
    );
    name.dispose(); phone.dispose(); relation.dispose();
    if (saved == true && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ جهة الاتصال.')));
  }
}
