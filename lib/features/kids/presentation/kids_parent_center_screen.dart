import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/kids/kids_parent_settings_repository.dart';

class AurenKidsParentCenterScreen extends StatefulWidget {
  const AurenKidsParentCenterScreen({super.key});
  @override State<AurenKidsParentCenterScreen> createState() => _AurenKidsParentCenterScreenState();
}

class _AurenKidsParentCenterScreenState extends State<AurenKidsParentCenterScreen> {
  final repo = KidsParentSettingsRepository();
  int? ageBand;
  bool? aiTutor;
  bool? externalLinks;
  int? dailyMinutes;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام إعدادات الأسرة.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Center')),
      body: StreamBuilder<KidsParentSettings>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: const Text('تعذر تحميل إعدادات الأسرة حالياً. حاول مرة أخرى.'),
            ));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final settings = snapshot.data!;
          final selectedAge = ageBand ?? settings.ageBand;
          final selectedAi = aiTutor ?? settings.aiTutor;
          final selectedLinks = externalLinks ?? settings.externalLinks;
          final selectedMinutes = dailyMinutes ?? settings.dailyMinutes;

          Future<void> save({int? age, bool? tutor, bool? links, int? minutes}) async {
            try {
              await repo.save(uid,
                ageBand: age ?? selectedAge,
                aiTutor: tutor ?? selectedAi,
                externalLinks: links ?? selectedLinks,
                dailyMinutes: minutes ?? selectedMinutes,
              );
              if (!mounted) return;
              setState(() {
                if (age != null) ageBand = age;
                if (tutor != null) aiTutor = tutor;
                if (links != null) externalLinks = links;
                if (minutes != null) dailyMinutes = minutes;
              });
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الإعداد حالياً. حاول مرة أخرى.')));
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('إعدادات الطفل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('هذه الإعدادات محفوظة لحساب ولي الأمر وتُستخدم لتخصيص تجربة AUREN Kids.'),
                  const SizedBox(height: 14),
                  const Text('الفئة العمرية'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [6, 9, 13].map((age) => ChoiceChip(
                    label: Text(age == 13 ? '13–17' : '$age–${age + 2}'),
                    selected: selectedAge == age,
                    onSelected: (_) => save(age: age),
                  )).toList()),
                ]),
              )),
              const SizedBox(height: 12),
              Card(child: Column(children: [
                SwitchListTile(
                  value: selectedAi,
                  title: const Text('AI Learning Coach'),
                  subtitle: const Text('السماح بمدرب تعلم بالذكاء الاصطناعي داخل Kids.'),
                  onChanged: (value) => save(tutor: value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: selectedLinks,
                  title: const Text('External links'),
                  subtitle: const Text('السماح بفتح روابط خارجية من تجربة Kids.'),
                  onChanged: (value) => save(links: value),
                ),
              ])),
              const SizedBox(height: 12),
              Card(child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('الحد اليومي'),
                subtitle: Text('$selectedMinutes دقيقة'),
                trailing: DropdownButton<int>(
                  value: selectedMinutes,
                  items: const [15, 30, 60, 90, 120, 180, 240]
                      .map((value) => DropdownMenuItem(value: value, child: Text('$value د')))
                      .toList(),
                  onChanged: (value) { if (value != null) save(minutes: value); },
                ),
              )),
              const SizedBox(height: 12),
              const Card(child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('الخصوصية والسلامة'),
                subtitle: Text('Kids لا يضيف مراسلة عامة للأطفال. إعدادات ولي الأمر تبقى ضمن حسابه.'),
              )),
            ],
          );
        },
      ),
    );
  }
}
