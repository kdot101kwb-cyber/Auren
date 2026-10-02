import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/education_repository.dart';
import '../../../core/models/education.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEducationScreen extends StatefulWidget {
  const AurenAURENEducationScreen({super.key});

  @override
  State<AurenAURENEducationScreen> createState() => _EducationState();
}

class _EducationState extends State<AurenAURENEducationScreen> {
  final repo = EducationRepository();
  String query = '';
  String? category;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول عشان تستخدم التعلم.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Education'),
        actions: [
          IconButton(
            tooltip: 'AI Tutor',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessengerScreen(
                  initialPrompt: 'ابني لي خطة تعلم شخصية بناءً على أهدافي ومهاراتي.',
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AurenCourse>>(
        stream: repo.watchCourses(),
        builder: (context, coursesSnapshot) {
          if (coursesSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 10),
                    const Text('تعذر تحميل الدورات التعليمية.'),
                    const SizedBox(height: 8),
                    Text('${coursesSnapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (coursesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = coursesSnapshot.data ?? const <AurenCourse>[];
          final cats = all
              .map((e) => e.category)
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final q = query.trim().toLowerCase();
          final courses = all.where((c) {
            final searchable =
                '${c.title} ${c.description} ${c.category} ${c.skills.join(' ')}'
                    .toLowerCase();
            return (q.isEmpty || searchable.contains(q)) &&
                (category == null || c.category == category);
          }).toList();

          return StreamBuilder<List<AurenLearningProgress>>(
            stream: repo.watchMyLearning(uid),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42),
                        const SizedBox(height: 10),
                        const Text('تعذر تحميل تقدمك الدراسي.'),
                        const SizedBox(height: 8),
                        Text('${progressSnapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final progress = <String, AurenLearningProgress>{
                for (final item
                    in (progressSnapshot.data ?? const <AurenLearningProgress>[]))
                  item.courseId: item,
              };

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            child: Icon(Icons.school_outlined),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Learn with AUREN',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'دورات، تقدم، مهارات، ومدرس شخصي بالذكاء الاصطناعي.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'ابحث عن دورة أو مهارة',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        null,
                        ...cats,
                      ].map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c ?? 'All'),
                            selected: category == c,
                            onSelected: (_) => setState(() => category = c),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _studyPlanCard(context, uid, progress, all),
                  if (progress.isNotEmpty)
                    _learningSummary(context, progress, all),
                  _completedCoursesCard(context, uid, progress, all),
                  _learningProgressCard(context, progress, all),
                  _learnedSkillsCard(context, progress, all),
                  StreamBuilder<List<AurenCourse>>(
                    stream: repo.watchSavedCourses(uid),
                    builder: (context, savedSnapshot) {
                      if (savedSnapshot.hasError) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.bookmark_border),
                            title: const Text('تعذر تحميل دوراتي المحفوظة'),
                            subtitle: Text('${savedSnapshot.error}'),
                            trailing: IconButton(
                              tooltip: 'إعادة المحاولة',
                              icon: const Icon(Icons.refresh),
                              onPressed: () => setState(() {}),
                            ),
                          ),
                        );
                      }
                      final saved = savedSnapshot.data ?? const <AurenCourse>[];
                      if (saved.isEmpty) return const SizedBox.shrink();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'دوراتي المحفوظة',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              ...saved.take(5).map(
                                (course) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.bookmark_outline),
                                  ),
                                  title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('${course.category} • ${course.lessonCount} lessons'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _showCourseSheet(
                                    context,
                                    course,
                                    uid,
                                    progress[course.id],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  if (courses.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('ما لقينا دورات مطابقة للبحث الحالي.'),
                      ),
                    )
                  else
                    ...courses.map(
                      (course) => _courseCard(
                        context,
                        course,
                        uid,
                        progress[course.id],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _studyPlanCard(BuildContext context, String uid, Map<String, AurenLearningProgress> progress, List<AurenCourse> courses) {
    final active = progress.entries.where((entry) {
      final course = _findCourse(courses, entry.key);
      return course != null && course.lessonCount > 0 && entry.value.completedLessons < course.lessonCount;
    }).toList();
    final suggested = courses.where((course) => progress[course.id] == null).where((course) => category == null || course.category == category).take(3).toList();
    return Card(child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const CircleAvatar(child: Icon(Icons.auto_awesome)), const SizedBox(width: 12), const Expanded(child: Text('خطة تعلمك مع AUREN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), IconButton(
        tooltip: 'AI Study Plan',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'ابنِ لي خطة تعلم شخصية في AUREN باستخدام دوراتي وتقدمي ومهاراتي إن كانت متاحة، مع ترتيب يومي ومراجعة واختبارات قصيرة. لا تفترض معلومات غير معروفة.'))),
        icon: const Icon(Icons.calendar_month_outlined),
      )]),
      const SizedBox(height: 8),
      Text(active.isNotEmpty ? 'لديك ${active.length} دورة نشطة — أكمل التالية أولاً.' : suggested.isNotEmpty ? 'ابدأ بدورة مناسبة من القائمة المقترحة أدناه.' : 'استخدم AI Tutor لبناء خطة جديدة حسب هدفك.'),
      if (active.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...active.take(2).map((entry) {
          final course = _findCourse(courses, entry.key)!;
          final value = course.lessonCount > 0 ? (entry.value.completedLessons / course.lessonCount).clamp(0.0, 1.0) : 0.0;
          return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.play_circle_outline), title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${entry.value.completedLessons}/${course.lessonCount} • ${(value * 100).round()}%'), onTap: () => _showCourseSheet(context, course, uid, entry.value));
        }),
      ] else if (suggested.isNotEmpty) ...[
        const SizedBox(height: 10),
        ...suggested.map((course) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.recommend_outlined), title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${course.category} • ${course.lessonCount} lessons'), onTap: () => _showCourseSheet(context, course, uid, null))),
      ],
    ])));
  }

  Widget _completedCoursesCard(BuildContext context, String uid, Map<String, AurenLearningProgress> progress, List<AurenCourse> courses) {
    final completed = progress.entries.where((entry) {
      final course = _findCourse(courses, entry.key);
      return course != null && course.lessonCount > 0 && entry.value.completedLessons >= course.lessonCount;
    }).toList();
    if (completed.isEmpty) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.verified_outlined), SizedBox(width: 8), Text('دورات مكتملة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 6),
      ...completed.take(5).map((entry) {
        final course = _findCourse(courses, entry.key)!;
        return ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.check)), title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('\${course.lessonCount}/\${course.lessonCount} lessons • 100%'), trailing: const Icon(Icons.chevron_right), onTap: () => _showCourseSheet(context, course, uid, entry.value));
      }),
    ])));
  }
  Widget _learningProgressCard(
    BuildContext context,
    Map<String, AurenLearningProgress> progress,
    List<AurenCourse> courses,
  ) {
    var total = 0;
    var done = 0;
    for (final entry in progress.entries) {
      final course = _findCourse(courses, entry.key);
      if (course == null || course.lessonCount < 1) continue;
      total += course.lessonCount;
      done += entry.value.completedLessons.clamp(0, course.lessonCount);
    }
    if (total == 0) return const SizedBox.shrink();
    final value = (done / total).clamp(0.0, 1.0);
    AurenCourse? next;
    for (final entry in progress.entries) {
      final course = _findCourse(courses, entry.key);
      if (course != null && entry.value.completedLessons < course.lessonCount) {
        next = course;
        break;
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.insights_outlined),
              const SizedBox(width: 8),
              const Expanded(child: Text('ملخص تقدمك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              Text('${(value * 100).round()}%'),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: value),
            const SizedBox(height: 8),
            Text('$done من $total درس مكتمل.'),
            if (next != null) ...[
              const SizedBox(height: 6),
              Text('التالي: ' + next.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
  Widget _learnedSkillsCard(
    BuildContext context,
    Map<String, AurenLearningProgress> progress,
    List<AurenCourse> courses,
  ) {
    final skills = <String>{};
    for (final entry in progress.entries) {
      final course = _findCourse(courses, entry.key);
      if (course == null || course.lessonCount < 1) continue;
      if (entry.value.completedLessons >= course.lessonCount) {
        skills.addAll(
          course.skills.map((skill) => skill.trim()).where((skill) => skill.isNotEmpty),
        );
      }
    }
    final visible = skills.take(12).toList()..sort();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'المهارات المكتسبة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'AI Skill Coach',
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessengerScreen(
                        initialPrompt:
                            'راجع مهاراتي المكتسبة من دورات AUREN الحالية: '
                            '${visible.join(', ')}. اقترح لي المهارة التالية التي أتعلمها، '
                            'ولماذا، وخطة عملية قصيرة لتطبيقها. لا تفترض مهارات غير موجودة.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visible.map((skill) => Chip(
                avatar: const Icon(Icons.check, size: 16),
                label: Text(skill),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _learningSummary(
    BuildContext context,
    Map<String, AurenLearningProgress> progress,
    List<AurenCourse> courses,
  ) {
    final enrolled = progress.length;
    final completed = progress.entries.where((entry) {
      final course = _findCourse(courses, entry.key);
      return course != null &&
          course.lessonCount > 0 &&
          entry.value.completedLessons >= course.lessonCount;
    }).length;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: Text('$enrolled دورة في تعلمك'),
        subtitle: Text('$completed مكتملة • أكمل من حيث توقفت'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLearningSheet(context, progress, courses),
      ),
    );
  }

  Widget _courseCard(
    BuildContext context,
    AurenCourse course,
    String uid,
    AurenLearningProgress? learning,
  ) {
    final enrolled = learning != null;
    final completed = learning?.completedLessons ?? 0;
    final total = course.lessonCount;
    final value = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCourseSheet(context, course, uid, learning),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.menu_book_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.category} • ${course.lessonCount} lessons',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: enrolled ? 'Continue' : 'Open course',
                    icon: Icon(
                      enrolled
                          ? Icons.play_circle_outline
                          : Icons.chevron_right,
                    ),
                    onPressed: () =>
                        _showCourseSheet(context, course, uid, learning),
                  ),
                ],
              ),
              if (enrolled) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: value),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text('$completed/$total lessons'),
                    const Spacer(),
                    Text('${(value * 100).round()}%'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseSheet(
    BuildContext context,
    AurenCourse course,
    String uid,
    AurenLearningProgress? learning,
  ) {
    final completed = learning?.completedLessons ?? 0;
    final total = course.lessonCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(course.description),
              if (course.skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Skills: ${course.skills.take(5).join(' • ')}'),
              ],
              const SizedBox(height: 14),
              if (learning != null && total > 0) ...[
                LinearProgressIndicator(
                  value: (completed / total).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 6),
                Text('التقدم: $completed من $total درس'),
                const SizedBox(height: 12),
              ],
              StreamBuilder<Set<String>>(
                stream: repo.watchSavedIds(uid),
                builder: (context, savedSnapshot) {
                  final saved = savedSnapshot.data?.contains(course.id) == true;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await repo.toggleSaved(uid, course.id, !saved);
                          } catch (e) {
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text('تعذر تحديث الحفظ: $e')),
                              );
                            }
                          }
                        },
                        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                        label: Text(saved ? 'إزالة الحفظ' : 'حفظ الدورة'),
                      ),
                      if (learning == null)
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await repo.enroll(uid, course.id);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            } catch (e) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('تعذر التسجيل: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add_task),
                          label: const Text('سجّل في الدورة'),
                        ),
                      if (learning != null && completed < total)
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await repo.completeLesson(uid, course, completed + 1);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            } catch (e) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('تعذر تحديث التقدم: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(completed == 0 ? 'إكمال الدرس الأول' : 'إكمال الدرس التالي'),
                        ),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessengerScreen(
                              initialPrompt:
                                  'أنت المدرس الشخصي لدورة "${course.title}". '
                                  'اشرح لي الدرس الحالي خطوة بخطوة، ثم اختبر فهمي. '
                                  'لا تعتبر الدرس مكتملاً إلا بعد موافقتي.',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('AI Tutor'),
                      ),
                      if (learning != null && total > 0 && completed >= total)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MessengerScreen(
                                initialPrompt:
                                    'أنشئ لي اختبار مراجعة قصير لدورة "${course.title}". '
                                    'استخدم مهارات الدورة: ${course.skills.take(8).join(', ')}. '
                                    'اسأل سؤالاً واحداً في كل مرة، صحح إجابتي، وفي النهاية أعطني '
                                    'نقاط المراجعة والمهارات التي تحتاج تقوية.',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.quiz_outlined),
                          label: const Text('اختبار مراجعة AI'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  AurenCourse? _findCourse(List<AurenCourse> courses, String id) {
    for (final course in courses) {
      if (course.id == id) return course;
    }
    return null;
  }

  void _showLearningSheet(
    BuildContext context,
    Map<String, AurenLearningProgress> progress,
    List<AurenCourse> courses,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: progress.values.map((item) {
          final course = _findCourse(courses, item.courseId);
          return ListTile(
            title: Text(course?.title ?? item.courseId),
            subtitle: Text('أكملت ${item.completedLessons} درس'),
            trailing: const Icon(Icons.chevron_right),
            onTap: course == null
                ? null
                : () => _showCourseSheet(
                      context,
                      course,
                      FirebaseAuth.instance.currentUser!.uid,
                      item,
                    ),
          );
        }).toList(),
      ),
    );
  }
}
