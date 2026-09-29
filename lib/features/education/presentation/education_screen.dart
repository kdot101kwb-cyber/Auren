import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/education/education_repository.dart';
import '../../../services/education/education_catalog.dart';
import '../../../core/models/education.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'certifications_screen.dart';
import 'learning_plan_screen.dart';
import 'education_resources_screen.dart';
import '../../../services/education/education_resource_matcher.dart';

class AurenAURENEducationScreen extends StatefulWidget {
  const AurenAURENEducationScreen({super.key});
  @override State<AurenAURENEducationScreen> createState() => _EducationState();
}

class _EducationState extends State<AurenAURENEducationScreen> {
  final repo = EducationRepository();
  String query = '';
  String? category;
  String track = 'All';
  String level = 'All';
  String? language;
  String? schoolStage;

  void _openTutor(String prompt) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول عشان تستخدم التعلم.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Education'),
        actions: [
          IconButton(
            tooltip: 'AI Tutor',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _openTutor('أنت مدرس AUREN الشخصي. اسألني عن هدفي ومستواي ووقتي المتاح، ثم ابنِ لي خطة تعلم يومية سهلة مع شرح وتمارين واختبارات قصيرة.'),
          ),
        ],
      ),
      body: StreamBuilder<List<AurenCourse>>(
        stream: repo.watchCourses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل التعليم: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final all = snapshot.data ?? const <AurenCourse>[];
          final q = query.trim().toLowerCase();
          final courses = all.where((c) {
            final searchable = '${c.title} ${c.description} ${c.category} ${c.skills.join(' ')}'.toLowerCase();
            return (q.isEmpty || searchable.contains(q)) && (category == null || c.category == category) && (level == 'All' || c.level == level);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.school, size: 34),
                title: Text('تعلم مع AUREN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                subtitle: Text('لغة، مدرسة، معاهد، مهارات، ومدرس AI شخصي.'),
              ),
              _aiShortcuts(),
              const SizedBox(height: 12),
              Card(child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('الشهادات العالمية'),
                subtitle: const Text('Microsoft، Cisco، AWS، Google وغيرها في تخصصات متعددة'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificationsScreen())),
              )),
              Card(child: ListTile(
                leading: const Icon(Icons.route),
                title: const Text('خطتي الدراسية'),
                subtitle: const Text('أنشئ خطة شخصية حسب هدفك ومستواك ووقتك'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningPlanScreen())),
              )),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن لغة، مادة، تخصص أو دورة'),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 12),
              _trackSelector(),
              const SizedBox(height: 8),
              _levelSelector(),
              if (track == 'Languages') ...[const SizedBox(height: 12), _languageSelector()],
              if (track == 'School') ...[const SizedBox(height: 12), _schoolStageSelector()],
              if (category != null) Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => category = null),
                  icon: const Icon(Icons.clear),
                  label: const Text('إلغاء تصفية الدورات'),
                ),
              ),
              const SizedBox(height: 8),
              _assessmentButton(),
              const SizedBox(height: 8),
              _recommendedResources(),
              const SizedBox(height: 8),
              _myLearning(uid),
              if (courses.isEmpty) _emptyState() else ...courses.map((c) => _card(context, c, uid)),
            ],
          );
        },
      ),
    );
  }

  Widget _aiShortcuts() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _shortcut('تعلم لغة', Icons.translate, 'أريد تعلم لغة جديدة. اختبر مستواي ثم علّمني يومياً بالمحادثة والاستماع والنطق والقراءة والكتابة.'),
          _shortcut('مدرسة', Icons.menu_book, 'أنا طالب مدرسة. اسألني عن الصف والمادة والدرس، واشرح لي خطوة بخطوة مع تمارين واختبار، ولا تعطِ الإجابة فقط.'),
          _shortcut('معهد', Icons.build, 'أريد تعلم مهارة أو تخصص في معهد. اسألني عن المجال والمستوى والوقت، ثم اصنع لي مساراً عملياً بمشاريع وتمارين وتقييمات.'),
          _shortcut('خطة شخصية', Icons.route, 'ابنِ لي خطة تعلم شخصية حسب هدفي ومستواي والوقت المتاح، وراجع تقدمي أسبوعياً وعدّل الخطة.'),
        ],
      ),
    ),
  );

  Widget _shortcut(String title, IconData icon, String prompt) =>
      OutlinedButton.icon(onPressed: () => _openTutor(prompt), icon: Icon(icon), label: Text(title));

  Widget _trackSelector() {
    final tracks = ['All', ...EducationCatalog.learningTracks];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: tracks.map((value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(value == 'All' ? 'الكل' : value),
          selected: track == value,
          onSelected: (_) => setState(() {
            track = value;
            if (value != 'Languages') language = null;
            if (value != 'School') schoolStage = null;
          }),
        ),
      )).toList()),
    );
  }

  Widget _levelSelector() {
    final levels = ['All', ...EducationCatalog.levels];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: levels.map((value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(value == 'All' ? 'كل المستويات' : value),
          selected: level == value,
          onSelected: (_) => setState(() => level = value),
        ),
      )).toList()),
    );
  }

  Widget _assessmentButton() {
    final subject = query.trim();
    if (subject.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('اختبر مستواي'),
        subtitle: Text('تحديد المستوى في: $subject'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationLevelAssessmentScreen(subject: subject))),
      ),
    );
  }

  Widget _languageSelector() {
    final visible = EducationCatalog.languages.where((l) =>
      query.isEmpty || l.toLowerCase().contains(query.toLowerCase())).toList();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.translate),
        title: Text(language == null ? 'اختر اللغة' : 'اللغة: $language'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: visible.map((l) => ChoiceChip(
                label: Text(l),
                selected: language == l,
                onSelected: (_) => setState(() => language = language == l ? null : l),
              )).toList(),
            ),
          ),
          if (language != null) Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: () => _openTutor('أريد تعلم $language. ابدأ باختبار تحديد المستوى، ثم علّمني بطريقة سهلة مع محادثة واستماع ونطق وقراءة وكتابة ومراجعة للأخطاء.'),
              icon: const Icon(Icons.play_arrow),
              label: Text('ابدأ تعلم $language'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _schoolStageSelector() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.school_outlined),
        title: Text(schoolStage == null ? 'اختر المرحلة الدراسية' : 'المرحلة: $schoolStage'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: EducationCatalog.schoolStages.map((stage) => ChoiceChip(
                label: Text(stage),
                selected: schoolStage == stage,
                onSelected: (_) => setState(() => schoolStage = schoolStage == stage ? null : stage),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: () => _openTutor('أنا طالب في مرحلة $schoolStage. اسألني عن الصف والمادة والدرس، واشرح بما يناسب مستواي، ثم أعطني تمارين متدرجة واختباراً وخطة مراجعة.'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('افتح المدرس الشخصي'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendedResources() {
    final subject = query.trim();
    final recommendations = EducationResourceMatcher.recommend(
      subject: subject,
      language: language ?? '',
      level: level == 'All' ? '' : level,
      limit: 4,
    );
    if (subject.isEmpty && language == null && level == 'All') {
      return const SizedBox.shrink();
    }
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مصادر مناسبة لك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subject.isEmpty ? 'مصادر حسب اللغة والمستوى' : 'فيديو، كتاب، محاكاة وتمارين لـ $subject', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ...recommendations.map((item) {
              final resource = item.resource;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
                title: Text(resource['name'] ?? ''),
                subtitle: Text('${resource['type'] ?? ''} • ${resource['languages'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openResource(resource),
              );
            }),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationResourcesScreen(initialSubject: subject, initialLanguage: language))),
                  icon: const Icon(Icons.library_books_outlined), label: const Text('كل المصادر'),
                )),
                const SizedBox(width: 8),
                Expanded(child: FilledButton.icon(
                  onPressed: subject.isEmpty ? null : () => _openTutor(EducationResourceMatcher.buildTutorPrompt(subject: subject, language: language ?? '', level: level == 'All' ? '' : level)),
                  icon: const Icon(Icons.auto_awesome), label: const Text('AI Tutor'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _openResource(Map<String, String> resource) async {
    final raw = resource['url'];
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح المصدر الآن')));
    }
  }

  Widget _myLearning(String uid) {
    return StreamBuilder<List<AurenLearningProgress>>(
      stream: repo.watchMyLearning(uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AurenLearningProgress>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('تعلمي الحالي'),
            subtitle: Text('${items.length} دورة مسجلة'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _emptyState() => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.search_off, size: 40),
        const SizedBox(height: 8),
        const Text('ما لقينا دورة مطابقة حالياً.'),
        OutlinedButton.icon(
          onPressed: () => _openTutor('لم أجد دورة مناسبة. علّمني الموضوع الذي أبحث عنه من خلال دروس قصيرة وتمارين واختبارات.'),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('خلّي AI يعلّمني'),
        ),
      ]),
    ),
  );

  Widget _card(BuildContext context, AurenCourse c, String uid) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(c.title),
      subtitle: Text('${c.category} • ${c.lessonCount} lessons${c.skills.isEmpty ? '' : ' • ${c.skills.take(3).join(', ')}'}'),
      leading: const CircleAvatar(child: Icon(Icons.school)),
      trailing: StreamBuilder<Set<String>>(
        stream: repo.watchSavedIds(uid),
        builder: (context, snapshot) {
          final saved = (snapshot.data ?? <String>{}).contains(c.id);
          return IconButton(
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => repo.toggleSaved(uid, c.id, !saved),
          );
        },
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(c.description),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openTutor('ساعدني أدرس دورة ${c.title}. اشرح كل درس بطريقة بسيطة، اختبر فهمي، وراجع نقاط ضعفي معي.'),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Tutor'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
