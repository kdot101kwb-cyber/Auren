import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/education_repository.dart';
import '../../../core/models/education.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEducationScreen extends StatefulWidget {
  const AurenAURENEducationScreen({super.key});
  @override State<AurenAURENEducationScreen> createState()=>_EducationState();
}
class _EducationState extends State<AurenAURENEducationScreen> {
  final repo=EducationRepository();
  String query='';
  String? category;
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول عشان تستخدم التعلم.')));
    return Scaffold(
      appBar:AppBar(title:const Text('AUREN Education'),actions:[
        IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ابني لي خطة تعلم شخصية بناءً على أهدافي ومهاراتي.')))),
      ]),
      body:StreamBuilder<List<AurenCourse>>(
        stream:repo.watchCourses(),
        builder:(context,snapshot){
          if(snapshot.hasError)return Center(child:Text('تعذر تحميل الدورات: ${snapshot.error}'));
          final courses=snapshot.data??const <AurenCourse>[];
          final cats=courses.map((e)=>e.category).where((e)=>e.isNotEmpty).toSet().toList()..sort();
          final filtered=courses.where((c){
            final q=query.trim().toLowerCase();
            return (q.isEmpty||('${c.title} ${c.description} ${c.category}').toLowerCase().contains(q))&&(category==null||c.category==category);
          }).toList();
          return ListView(padding:const EdgeInsets.all(16),children:[
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Learn by Doing',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
              const SizedBox(height:6),
              const Text('دورات منشورة، تقدم محفوظ، ومساعدة AI عند الحاجة.'),
              const SizedBox(height:12),
              TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),border:OutlineInputBorder(),hintText:'ابحث عن دورة أو مهارة'),onChanged:(v)=>setState(()=>query=v)),
            ]))),
            const SizedBox(height:10),
            if(cats.isNotEmpty)SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
              ChoiceChip(label:const Text('الكل'),selected:category==null,onSelected:(_)=>setState(()=>category=null)),
              const SizedBox(width:8),
              ...cats.map((c)=>Padding(padding:const EdgeInsetsDirectional.only(end:8),child:ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c)))),
            ])),
            const SizedBox(height:12),
            if(filtered.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد دورات مطابقة حالياً.')))
            else ...filtered.map((course)=>_courseCard(context,uid,course)),
          ]);
        },
      ),
    );
  }
  Widget _courseCard(BuildContext context,String uid,AurenCourse course)=>StreamBuilder<List<AurenLearningProgress>>(
    stream:repo.watchMyLearning(uid),
    builder:(context,snapshot){
      final progress=(snapshot.data??const <AurenLearningProgress>[]).where((p)=>p.courseId==course.id).firstOrNull;
      final completed=progress?.completedLessons??0;
      final value=course.lessonCount>0?(completed/course.lessonCount).clamp(0.0,1.0):0.0;
      return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Icon(Icons.school_outlined),const SizedBox(width:10),Expanded(child:Text(course.title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),Chip(label:Text(course.category))]),
        const SizedBox(height:8),
        Text(course.description,maxLines:3,overflow:TextOverflow.ellipsis),
        const SizedBox(height:8),
        LinearProgressIndicator(value:value),
        const SizedBox(height:6),
        Text('$completed/${course.lessonCount} lessons • ${(value*100).round()}%'),
        const SizedBox(height:10),
        Row(children:[
          Expanded(child:FilledButton(onPressed:()=>_openCourse(context,uid,course,progress),child:Text(progress==null?'التسجيل / فتح':'متابعة'))),
          const SizedBox(width:8),
          IconButton(onPressed:()=>repo.toggleSaved(uid,course.id,true),icon:const Icon(Icons.bookmark_border)),
        ]),
      ])));
    },
  );
  Future<void> _openCourse(BuildContext context,String uid,AurenCourse course,AurenLearningProgress? progress)async{
    if(progress==null){
      try{await repo.enroll(uid,course.id);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التسجيل: $e')));return;}
    }
    if(!mounted)return;
    Navigator.push(context,MaterialPageRoute(builder:(_)=>_EducationCourseDetail(course:course,repo:repo,uid:uid)));
  }
}
class _EducationCourseDetail extends StatefulWidget {
  final AurenCourse course;
  final EducationRepository repo;
  final String uid;

  const _EducationCourseDetail({
    required this.course,
    required this.repo,
    required this.uid,
  });

  @override
  State<_EducationCourseDetail> createState() => _EducationCourseDetailState();
}

class _EducationCourseDetailState extends State<_EducationCourseDetail> {
  bool _savingProgress = false;

  Future<void> _completeLesson(int completedLessons, int lessonCount) async {
    if (_savingProgress || completedLessons >= lessonCount) return;
    setState(() => _savingProgress = true);
    try {
      await widget.repo.setProgress(widget.uid, widget.course.id, completedLessons + 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ تقدمك في الدورة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التقدم: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: StreamBuilder<List<AurenLesson>>(
        stream: widget.repo.watchLessons(widget.course.id),
        builder: (context, lessonSnapshot) {
          if (lessonSnapshot.hasError) {
            return const Center(child: Text('تعذر تحميل دروس الدورة حالياً.'));
          }
          if (!lessonSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lessons = lessonSnapshot.data!;
          return StreamBuilder<List<AurenLearningProgress>>(
            stream: widget.repo.watchMyLearning(widget.uid),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.hasError) {
                return const Center(child: Text('تعذر تحميل تقدمك في الدورة.'));
              }
              final enrollment = (progressSnapshot.data ?? const <AurenLearningProgress>[])
                  .where((item) => item.courseId == widget.course.id)
                  .firstOrNull;
              final completed = enrollment?.completedLessons ?? 0;
              final total = widget.course.lessonCount;
              final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.course.description),
                          const SizedBox(height: 8),
                          Text('عدد الدروس: $total'),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 6),
                          Text('أكملت $completed من $total درسًا (${(progress * 100).round()}%)'),
                          if (widget.course.skills.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('المهارات: ${widget.course.skills.join(' • ')}'),
                          ],
                          if (completed >= total && total > 0) ...[
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(child: Text('أكملت الدورة؛ تمت إضافة المهارات المرتبطة إلى ملفك المهني عند توفرها.')),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (lessons.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('لا توجد دروس منشورة في هذه الدورة حتى الآن.'),
                      ),
                    )
                  else
                    ...lessons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lesson = entry.value;
                      final isCompleted = index < completed;
                      final isNext = index == completed;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Icon(isCompleted ? Icons.check : Icons.menu_book_outlined),
                                ),
                                title: Text(lesson.title),
                                subtitle: Text('${lesson.durationMinutes} دقيقة'),
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(lesson.title),
                                    content: SingleChildScrollView(child: Text(lesson.content)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('إغلاق'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isCompleted)
                                const Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Chip(
                                    avatar: Icon(Icons.check_circle, size: 18),
                                    label: Text('مكتمل'),
                                  ),
                                )
                              else if (isNext && completed < total)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: FilledButton.icon(
                                    onPressed: _savingProgress
                                        ? null
                                        : () => _completeLesson(completed, total),
                                    icon: _savingProgress
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check),
                                    label: Text(_savingProgress ? 'جارٍ الحفظ…' : 'إكمال الدرس'),
                                  ),
                                )
                              else
                                const Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text('أكمل الدرس السابق أولاً'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
