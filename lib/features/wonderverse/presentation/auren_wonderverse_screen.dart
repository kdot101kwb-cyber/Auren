import 'package:flutter/material.dart';

/// Initial, self-contained UI foundation. Backend and multiplayer are not enabled yet.
class AurenWonderverseScreen extends StatelessWidget {
  const AurenWonderverseScreen({super.key});

  static const experiences = <_WonderExperience>[
    _WonderExperience('one-minute-civilization', 'حضارة في دقيقة', 'ابنوا حضارة جماعية بقرارات صغيرة.', 'ابدأوا من جزيرة فارغة. كل مشارك يضيف قراراً، والقرارات تغيّر شكل الحضارة وقوانينها.', Icons.location_city_rounded, Color(0xFF8B5CF6), 'تجربة جماعية'),
    _WonderExperience('mystery-no-owner', 'اللغز الذي لا يملكه أحد', 'المجتمع كله يجمع خيوط اللغز.', 'اكتشفوا الأدلة على مراحل، شاركوا النظريات، وصوّتوا على التفسير قبل كشف النتيجة.', Icons.manage_search_rounded, Color(0xFF06B6D4), 'لغز المجتمع'),
    _WonderExperience('butterfly-engine', 'تأثير الفراشة', 'اختيار صغير يغيّر مسار العالم.', 'جرّب قراراً داخل قصة متفرعة وشاهد كيف تتغيّر الأحداث. أعد التجربة لاكتشاف مسارات أخرى.', Icons.bubble_chart_rounded, Color(0xFFF59E0B), 'قصة تفاعلية'),
    _WonderExperience('creature-lab', 'مختبر المخلوقات', 'صمّموا كائناً بلمسات متعددة.', 'كل مشارك يضيف صفة أو قدرة أو موطناً، ثم يظهر سجل بمساهمات المشاركين.', Icons.pets_rounded, Color(0xFFEC4899), 'إبداع مشترك'),
    _WonderExperience('wonder-lab', 'مصنع الخيال', 'حوّل فكرة غريبة إلى تجربة.', 'ابدأ بفكرة، أضف قيداً إبداعياً، ثم حوّلها إلى تحدٍّ أو مشهد أو عالم صغير.', Icons.auto_awesome_rounded, Color(0xFF10B981), 'اصنع تجربة'),
    _WonderExperience('parallel-worlds', 'العوالم المتوازية', 'اكتشف نسخاً مختلفة من الأحداث.', 'غيّر تفصيلاً واحداً في موقف خيالي واستكشف عالماً بديلاً بنتائج وقواعد مختلفة.', Icons.public_rounded, Color(0xFF60A5FA), 'عوالم بديلة'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('WONDERVERSE')),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: _WonderHero(onTap: () => _open(context, experiences.first)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('بوابات العوالم', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .82),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ExperienceCard(experience: experiences[index], onTap: () => _open(context, experiences[index])),
              childCount: experiences.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: const Card(child: ListTile(
              leading: Icon(Icons.lightbulb_outline_rounded),
              title: Text('العالم يتطوّر بمساهمتك'),
              subtitle: Text('هذه بداية الواجهة. حفظ التقدم والمشاركة المباشرة سيُربطان بخدمات موثوقة في مراحل لاحقة.'),
            )),
          ),
        ),
      ]),
    );
  }

  void _open(BuildContext context, _WonderExperience experience) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _WonderExperienceDetail(experience: experience)));
  }
}

class _WonderHero extends StatelessWidget {
  const _WonderHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF211044), Color(0xFF402078), Color(0xFF123C54)]),
    ),
    child: Stack(children: [
      const Positioned(right: -16, top: -20, child: Icon(Icons.blur_circular, size: 150, color: Color(0x227DD3FC))),
      const Positioned(right: 26, top: 30, child: Icon(Icons.auto_awesome, size: 36, color: Color(0xFFFFD166))),
      Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
            child: const Text('تجربة اليوم • بداية جديدة', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(height: 18),
          const Text('عوالم أُورِن', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('كل يوم عالم جديد.\nكل اختيار يغيّر الحكاية.', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.explore_rounded),
            label: const Text('ادخل التجربة'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF28134A)),
          ),
        ]),
      ),
    ]),
  );
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience, required this.onTap});
  final _WonderExperience experience;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: experience.color.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)),
              child: Icon(experience.icon, color: experience.color, size: 27),
            ),
            const Spacer(),
            Text(experience.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(experience.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text(experience.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: experience.color, fontWeight: FontWeight.bold))),
              Icon(Icons.arrow_forward_rounded, size: 17, color: theme.colorScheme.onSurfaceVariant),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _WonderExperienceDetail extends StatelessWidget {
  const _WonderExperienceDetail({required this.experience});
  final _WonderExperience experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(experience.title)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [experience.color.withValues(alpha: .85), const Color(0xFF17152F)])),
          child: Icon(experience.icon, size: 88, color: Colors.white),
        ),
        const SizedBox(height: 22),
        Text(experience.label, style: theme.textTheme.labelLarge?.copyWith(color: experience.color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(experience.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(experience.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
        const SizedBox(height: 24),
        const Card(child: ListTile(
          leading: Icon(Icons.construction_outlined),
          title: Text('المرحلة التأسيسية'),
          subtitle: Text('واجهة التجربة جاهزة للتطوير؛ التقدم والمشاركة المباشرة لم يُفعّلا بعد.'),
        )),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded), label: const Text('العودة إلى العوالم')),
      ]),
    );
  }
}

class _WonderExperience {
  const _WonderExperience(this.id, this.title, this.subtitle, this.description, this.icon, this.color, this.label);
  final String id, title, subtitle, description, label;
  final IconData icon;
  final Color color;
}
