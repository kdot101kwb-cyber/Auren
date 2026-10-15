import 'package:flutter/material.dart';

import '../../content/presentation/content_platform_screen.dart';
import '../../entertainment/presentation/auren_production_studio_screen.dart';
import 'creator_screen.dart';
import 'creator_studio_screen.dart';

/// A single entry point for the existing creator tools.
/// The destination screens remain the source of truth for their own workflows.
class AurenCreatorUniverseScreen extends StatelessWidget {
  const AurenCreatorUniverseScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tools = <_CreatorTool>[
      _CreatorTool(
        title: 'Creator Studio',
        subtitle: 'انشر محتواك وتابع الأداء والنمو والأرباح المسجلة.',
        icon: Icons.dashboard_customize_outlined,
        onOpen: (context) => _open(context, const AurenCreatorStudioScreen()),
      ),
      _CreatorTool(
        title: 'المسودات ومساعد AI',
        subtitle: 'احفظ الأفكار، عدّل المسودات، وجهّز صيغاً مختلفة للنشر.',
        icon: Icons.auto_awesome_outlined,
        onOpen: (context) => _open(context, const AurenAURENCreatorStudioScreen()),
      ),
      _CreatorTool(
        title: 'قنوات وفيديوهات AUREN',
        subtitle: 'أنشئ قناة، انشر فيديوهات، واكتشف القنوات واشترك فيها.',
        icon: Icons.video_library_outlined,
        onOpen: (context) => _open(context, const AurenContentPlatformScreen()),
      ),
      _CreatorTool(
        title: 'استوديو الإنتاج بالذكاء الاصطناعي',
        subtitle: 'انتقل إلى أدوات إنتاج المحتوى المرئي الموجودة في AUREN.',
        icon: Icons.movie_creation_outlined,
        onOpen: (context) => _open(context, const AurenProductionStudioScreen()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Creator Universe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                Icon(Icons.movie_filter_outlined, size: 34, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  'كل أدوات المبدع في مكان واحد',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'للفلوقرز، وصنّاع الفيديو، والفنانين، والخبراء، وأصحاب الهوايات. اختر الأداة المناسبة، واحتفظ ببقية AUREN مترابطة مع تجربتك.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...tools.map(
            (tool) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(tool.icon, color: theme.colorScheme.onSecondaryContainer),
                ),
                title: Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(tool.subtitle),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => tool.onOpen(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ملاحظة: كل أداة تحتفظ بوظيفتها الحالية. توحيد البيانات وتجربة البث المباشر يحتاجان مراجعة منفصلة قبل إضافة وظائف جديدة.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CreatorTool {
  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context) onOpen;

  const _CreatorTool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onOpen,
  });
}
