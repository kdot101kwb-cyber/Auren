import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'auren_ai_series_studio_screen.dart';
import 'auren_anime_world_screen.dart';
import 'auren_entertainment_create_screen.dart';
import 'auren_gaming_screen.dart';
import 'auren_podcasts_screen.dart';
import 'auren_videos_screen.dart';
import 'entertainment_detail_screen.dart';
import 'entertainment_shorts_screen.dart';
import 'watch_together_screen.dart';

/// A unified entry point over existing entertainment destinations.
/// New concepts are labelled as planned until their underlying workflows exist.
class AurenEntertainmentUniverseScreen extends StatelessWidget {
  const AurenEntertainmentUniverseScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openMood(BuildContext context, String mood, String goal) {
    _open(
      context,
      MessengerScreen(
        initialPrompt:
            'أنت مساعد AUREN Entertainment. اختار لي تجربة ترفيه مناسبة لمزاج "$mood". الهدف: $goal. اقترح فقط تجارب وخدمات متاحة فعلاً داخل AUREN، وراعِ الوقت واستهلاك البيانات، ولا تدّعِ تشغيل محتوى غير موجود.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Entertainment Universe'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 34),
                const SizedBox(height: 10),
                Text(
                  'الترفيه على طريقتك',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'كرتون وقصص وشوتات وألعاب وصوت ومبدعون — في مدخل واحد. اختار تجربتك، وارجع وقت ما يناسبك.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _openMood(
                        context,
                        'ضحك',
                        'أريد شوتاً كوميدياً قصيراً أو محتوى خفيفاً.',
                      ),
                      icon: const Icon(Icons.sentiment_very_satisfied_rounded),
                      label: const Text('عايز أضحك'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openMood(
                        context,
                        'اكتشاف',
                        'أريد اكتشاف محتوى أو مبدع جديد.',
                      ),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('فاجئني باكتشاف'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'ادخل التجربة',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _DestinationTile(
            icon: Icons.animation_rounded,
            title: 'AUREN TOON والعوالم المتحركة',
            subtitle: 'استكشف عالم الأنمي الموجود حالياً؛ تجربة الكرتون الأصلي المتصل قيد التخطيط.',
            trailingLabel: 'جزء قادم',
            onTap: () => _open(context, const AurenAnimeWorldScreen()),
          ),
          _DestinationTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'الشوتات والفيديوهات',
            subtitle: 'شاهد المقاطع القصيرة والفيديوهات المتاحة.',
            onTap: () => _open(context, const AurenEntertainmentShortsScreen()),
          ),
          _DestinationTile(
            icon: Icons.groups_2_outlined,
            title: 'شاهدها مع أصحابك',
            subtitle: 'افتح غرفة مشاهدة وادعُ أصدقاءك.',
            onTap: () => _open(context, const AurenWatchTogetherScreen()),
          ),
          _DestinationTile(
            icon: Icons.sports_esports_outlined,
            title: 'الألعاب والتحديات',
            subtitle: 'انتقل إلى تجارب الألعاب الموجودة.',
            onTap: () => _open(context, const AurenGamingScreen()),
          ),
          _DestinationTile(
            icon: Icons.mic_none_rounded,
            title: 'البودكاست والصوت',
            subtitle: 'اكتشف البرامج والحلقات الصوتية.',
            onTap: () => _open(context, const AurenPodcastsScreen()),
          ),
          _DestinationTile(
            icon: Icons.movie_creation_outlined,
            title: 'اصنع تجربة جديدة',
            subtitle: 'جهّز فكرة أو مسودة محتوى داخل أدوات الإنشاء.',
            onTap: () => _open(context, const AurenEntertainmentCreateScreen()),
          ),
          _DestinationTile(
            icon: Icons.auto_awesome_outlined,
            title: 'استوديو المسلسلات بالذكاء الاصطناعي',
            subtitle: 'أنشئ موجز إنتاج لمسلسل أصلي.',
            onTap: () => _open(context, const AurenAiSeriesStudioScreen()),
          ),
          const SizedBox(height: 22),
          const Text(
            'اكتشاف اليوم',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'اختيار من الكتالوج المتاح حالياً؛ ليس وعداً بمحتوى جديد كل يوم.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<AurenEntertainmentItem>>(
            stream: EntertainmentRepository().watchItems(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('تعذر تحميل الاكتشافات الآن. حاول مرة أخرى لاحقاً.'),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(22),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = (snapshot.data ?? const <AurenEntertainmentItem>[])
                  .where((item) => item.title.trim().isNotEmpty)
                  .toList()
                ..sort((a, b) => a.id.compareTo(b.id));
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد اكتشافات منشورة حالياً. يمكنك تجربة الألعاب أو إنشاء فكرة جديدة.'),
                  ),
                );
              }
              return Column(
                children: items.take(5).map((item) {
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: item.imageUrl.isEmpty
                          ? const CircleAvatar(child: Icon(Icons.play_arrow_rounded))
                          : CircleAvatar(
                              backgroundImage: NetworkImage(item.imageUrl),
                              onBackgroundImageError: (_, __) {},
                            ),
                      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${item.type} • ${item.description}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open(
                        context,
                        AurenEntertainmentDetailScreen(itemId: item.id),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'قريباً ضمن الخطة: تصويت يغيّر نهاية القصة، ألغاز مخفية اختيارية، ألبوم اللحظات، وRemix يحوّل الفكرة إلى أشكال محتوى متعددة. هذه أفكار مخططة وليست وظائف مفعّلة بعد.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingLabel;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: trailingLabel == null
            ? const Icon(Icons.chevron_right_rounded)
            : Text(trailingLabel!, style: Theme.of(context).textTheme.labelSmall),
        onTap: onTap,
      ),
    );
  }
}
