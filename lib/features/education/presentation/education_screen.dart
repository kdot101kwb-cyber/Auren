import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/education_repository.dart';
import '../../../core/models/education.dart';
import '../../../services/education/education_gamification_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'education_activity_screen.dart';

class AurenAURENEducationScreen extends StatefulWidget {
  const AurenAURENEducationScreen({super.key});
  @override State<AurenAURENEducationScreen> createState()=>_EducationState();
}
class _EducationState extends State<AurenAURENEducationScreen>{
  final repo=EducationRepository();
  final gamification=EducationGamificationService();
  String query=''; String? category;
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول عشان تستخدم التعلم.')));
    return Scaffold(appBar:AppBar(title:const Text('AUREN Education'),actions:[IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ابني لي خطة تعلم شخصية بناءً على أهدافي ومهاراتي.'))))]),body:StreamBuilder<List<AurenCourse>>(stream:repo.watchCourses(),builder:(context,s){
      if(s.hasError)return Center(child:Text('تعذر تحميل التعليم: '+s.error.toString())); if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      final all=s.data??const <AurenCourse>[]; final cats=all.map((e)=>e.category).where((e)=>e.isNotEmpty).toSet().toList()..sort();
      final q=query.toLowerCase(); final courses=all.where((c)=>(q.isEmpty||(c.title+' '+c.description+' '+c.category).toLowerCase().contains(q))&&(category==null||c.category==category)).toList();
      return ListView(padding:const EdgeInsets.all(16),children:[
        const ListTile(contentPadding:EdgeInsets.zero,leading:Icon(Icons.school,size:34),title:Text('Learn with AUREN',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),subtitle:Text('دورات، تقدم، ومدرس شخصي بالذكاء الاصطناعي.')),
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن دورة أو مهارة'),onChanged:(v)=>setState(()=>query=v)),
        const SizedBox(height:12),
        FutureBuilder<Map<String, dynamic>>(
          future: gamification.getProfile(),
          builder: (context, snap) {
            final profile = snap.data?['profile'] as Map?;
            final xp = (profile?['totalXp'] ?? 0).toString();
            final weekly = (profile?['weeklyXp'] ?? 0).toString();
            final activities = (profile?['totalActivities'] ?? 0).toString();
            final challengeDone = profile?['weeklyChallengeCompleted'] == true;
            final badges = (profile?['badges'] as List? ?? const []).length;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
                title: Text('XP $xp'),
                subtitle: Text(
                  'هذا الأسبوع: $weekly XP • الأنشطة: $activities • '
                  'التحدي: ${challengeDone ? "مكتمل" : "5 أنشطة"} • الشارات: $badges',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.leaderboard_outlined),
                  tooltip: 'Leaderboard',
                  onPressed: () async {
                    final entries = await gamification.getLeaderboard();
                    if (!context.mounted) return;
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${e['rank'] ?? i + 1}')),
                            title: Text((e['displayName'] ?? 'AUREN Learner').toString()),
                            subtitle: Text('${e['weeklyXp'] ?? 0} XP'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height:8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.bolt_outlined),
                const SizedBox(width: 10),
                const Expanded(child: Text('أنشطة التعليم: Quiz • Language • Voice Tutor')),
                PopupMenuButton<String>(
                  onSelected: (mode) => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EducationActivityScreen(mode: mode)),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'quiz', child: Text('Quiz')),
                    PopupMenuItem(value: 'language', child: Text('Language')),
                    PopupMenuItem(value: 'voiceTutor', child: Text('Voice Tutor')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height:8),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[null,...cats].map((c)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(c??'All'),selected:category==c,onSelected:(_)=>setState(()=>category=c))).toList()))),
        const SizedBox(height:12),
          StreamBuilder<List<AurenLearningProgress>>(stream:repo.watchMyLearning(uid),builder:(context,p){
            final items=p.data??const <AurenLearningProgress>[];
            if(items.isEmpty)return const SizedBox.shrink();
            return Card(child:ListTile(leading:const Icon(Icons.insights_outlined),title:const Text('تعلمي الحالي'),subtitle:Text('${items.length} دورة مسجلة'),trailing:const Icon(Icons.chevron_right),onTap:()=>showModalBottomSheet(context:context,builder:(_)=>ListView(padding:const EdgeInsets.all(16),children:items.map((x)=>ListTile(title:Text(x.courseId),subtitle:Text('أكملت ${x.completedLessons} درس'))).toList()))));
          }),
        ...courses.map((c)=>_card(context,c,uid)),
      ]);
    }));
  }
  Widget _card(BuildContext context,AurenCourse c,String uid)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
    title:Text(c.title),subtitle:Text(c.category+' • '+c.lessonCount.toString()+' lessons'+(c.skills.isEmpty?'':' • '+c.skills.take(3).join(', '))),leading:const CircleAvatar(child:Icon(Icons.school)),
    trailing:StreamBuilder<Set<String>>(stream:repo.watchSavedIds(uid),builder:(context,s)=>IconButton(icon:Icon((s.data??{}).contains(c.id)?Icons.bookmark:Icons.bookmark_border),onPressed:()=>repo.toggleSaved(uid,c.id,!((s.data??{}).contains(c.id))))),
    onTap:()=>showModalBottomSheet(context:context,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(c.title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(c.description),const SizedBox(height:12),
      FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'ساعدني أدرس دورة '+c.title+' واصنع لي اختباراً بعد كل درس.'))),icon:const Icon(Icons.auto_awesome),label:const Text('AI Tutor'))
    ]))));
}