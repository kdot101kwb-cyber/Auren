import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/kids/kids_parent_settings_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'kids_parent_center_screen.dart';

class AurenKidsScreen extends StatefulWidget {
  const AurenKidsScreen({super.key});

  @override
  State<AurenKidsScreen> createState() => _AurenKidsScreenState();
}

class _AurenKidsScreenState extends State<AurenKidsScreen> {
  final settingsRepo = KidsParentSettingsRepository();

  final activities = const <Map<String, Object>>[
    {
      'title': 'Learn & Explore',
      'subtitle': 'تعلم ممتع ومناسب للعمر',
      'icon': Icons.school_outlined,
    },
    {
      'title': 'Creative Studio',
      'subtitle': 'رسم، قصص ومشاريع إبداعية',
      'icon': Icons.palette_outlined,
    },
    {
      'title': 'Games & Challenges',
      'subtitle': 'ألعاب وتحديات تعليمية بدون رهانات',
      'icon': Icons.extension_outlined,
    },
    {
      'title': 'World Discovery',
      'subtitle': 'علوم، ثقافات ولغات حول العالم',
      'icon': Icons.public_outlined,
    },
  ];

  void _openTutor(BuildContext context, String prompt) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessengerScreen(initialPrompt: prompt),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول لاستخدام AUREN Kids.')),
      );
    }

    return StreamBuilder<KidsParentSettings>(
      stream: settingsRepo.watch(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('AUREN Kids')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل إعدادات Kids حالياً. حاول مرة أخرى.',
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = snapshot.data!;
        final ageBand = settings.ageBand;
        final tutorEnabled = settings.aiTutor;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AUREN Kids'),
            actions: [
              IconButton(
                tooltip: 'Parent Center',
                icon: const Icon(Icons.family_restroom_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AurenKidsParentCenterScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مساحة آمنة للتعلّم والنمو',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'محتوى تعليمي وإبداعي مصمم حسب العمر، مع تجربة منفصلة عن اجتماعات ومراسلات البالغين.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الفئة العمرية',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            ageBand == 13
                                ? '13–17'
                                : '$' '{ageBand}–$' '{ageBand + 2}',
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AurenKidsParentCenterScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('ولي الأمر'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('AI Learning Coach'),
                  subtitle: Text(
                    'خطة تعلم يومية للفئة $' '{ageBand}+ مع أنشطة مناسبة للعمر.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: tutorEnabled
                      ? () => _openTutor(
                            context,
                            'أنشئ خطة تعلم آمنة ومناسبة لعمر طفل في الفئة '
                            '$' '{ageBand}+، مع أهداف يومية وأنشطة قصيرة وتعليم '
                            'بالتجربة. الحد اليومي المسموح: '
                            '$' '{settings.dailyMinutes} دقيقة.',
                          )
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AurenKidsParentCenterScreen(),
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'استكشف',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...activities.map(
                (item) => Card(
                  child: ListTile(
                    leading: Icon(item['icon'] as IconData),
                    title: Text(item['title'] as String),
                    subtitle: Text(item['subtitle'] as String),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: tutorEnabled
                        ? () => _openTutor(
                              context,
                              'اقترح أنشطة آمنة ومناسبة للأطفال في '
                              '$' '{item['title']} للفئة العمرية $' '{ageBand}+. '
                              'اجعلها تعليمية، قصيرة، وإبداعية. الحد اليومي: '
                              '$' '{settings.dailyMinutes} دقيقة.',
                            )
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AurenKidsParentCenterScreen(),
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.family_restroom_outlined),
                      title: const Text('Parent Center'),
                      subtitle: const Text(
                        'إعدادات الأسرة، الخصوصية ومتابعة التعلم تكون بيد ولي الأمر.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AurenKidsParentCenterScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.lock_outline),
                      title: Text('Safety first'),
                      subtitle: Text(
                        'لا توجد مراسلة عامة للأطفال ضمن مساحة Kids.',
                      ),
                      trailing: Icon(Icons.verified_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
