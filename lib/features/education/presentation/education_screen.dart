import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/education_repository.dart';
import '../../../core/models/education.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEducationScreen extends StatelessWidget {
  const AurenAURENEducationScreen({super.key});
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _authRequired();
    final repo = EducationRepository();
    return Scaffold(appBar: AppBar(title: const Text('AUREN Education')), body: StreamBuilder<List<AurenCourse>>(
      stream: repo.watchCourses(), builder: (context, snapshot) {
        if (snapshot.hasError) return _error(snapshot.error);
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final courses = snapshot.data ?? const <AurenCourse>[];
        return ListView(padding: const EdgeInsets.all(16), children: [
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.school, size: 34), title: Text('Learn with AUREN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), subtitle: Text('دورات، تقدم، ومدرس شخصي بالذكاء الاصطناعي.')),
          const Text('My Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          StreamBuilder<List<AurenLearningProgress>>(stream: repo.watchMyLearning(uid), builder: (context, ps) {
            final progress = {for (final p in ps.data ?? const <AurenLearningProgress>[]) p.courseId: p};
            final mine = courses.where((c) => progress.containsKey(c.id)).toList();
            if (mine.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('لسه ما سجلت في أي دورة.'));
            return Column(children: mine.map((c) => _courseCard(context, c, repo, uid, progress[c.id])).toList());
          }),
          const SizedBox(height: 8), const Text('Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (courses.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد دورات منشورة حالياً.'))),
          ...courses.map((c) => _courseCard(context, c, repo, uid)),
        ]);
      },
    ));
  }
  Widget _courseCard(BuildContext context, AurenCourse c, EducationRepository repo, String uid, [AurenLearningProgress? progress]) {
    final enrolled = progress != null; final done = progress?.completedLessons ?? 0; final total = c.lessonCount <= 0 ? 1 : c.lessonCount; final ratio = (done / total).clamp(0.0, 1.0);
    return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
      leading: CircleAvatar(child: Icon(enrolled ? Icons.play_arrow : Icons.school)), title: Text(c.title),
      subtitle: Text('${c.category} • ${c.lessonCount} lessons${enrolled ? ' • ${(ratio * 100).round()}%' : ''}'),
      trailing: enrolled ? SizedBox(width: 72, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [LinearProgressIndicator(value: ratio), const SizedBox(height: 4), Text('${done}/${c.lessonCount}')])) : FilledButton(onPressed: () async { await repo.enroll(uid, c.id); }, child: const Text('Enroll')),
      onTap: enrolled ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'ساعدني أكمل دورة ${c.title}، أنا وصلت ${done} من ${c.lessonCount} درس.'))) : null,
    ));
  }
}
Widget _authRequired() => const Scaffold(appBar: AppBar(title: Text('AUREN Education')), body: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('سجّل الدخول عشان تستخدم التعلم.'))));
Widget _error(Object? e) => Center(child: Padding(padding: EdgeInsets.all(24), child: Text('تعذر تحميل بيانات التعليم. $e')));
