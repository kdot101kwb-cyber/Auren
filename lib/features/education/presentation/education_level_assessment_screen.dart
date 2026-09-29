import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/education/education_level_assessment_service.dart';
import '../../../services/education/learning_plan_service.dart';
import 'learning_plan_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class EducationLevelAssessmentScreen extends StatefulWidget {
  final String subject;
  const EducationLevelAssessmentScreen({super.key, required this.subject});
  @override State<EducationLevelAssessmentScreen> createState()=>_EducationLevelAssessmentScreenState();
}

class _EducationLevelAssessmentScreenState extends State<EducationLevelAssessmentScreen> {
  final service=EducationLevelAssessmentService();
  final plans=LearningPlanService();
  int index=0;
  final answers=<int>[];
  EducationAssessmentResult? result;

  Future<void> _answer(int value) async {
    answers.add(value);
    if (index + 1 < EducationLevelAssessmentService.questions.length) {
      setState(()=>index++);
    } else {
      final evaluated=service.evaluate(answers);
      setState(()=>result=evaluated);
      final uid=FirebaseAuth.instance.currentUser?.uid;
      if(uid!=null){ await service.saveResult(uid:uid,subject:widget.subject,result:evaluated); }
    }
  }

  @override Widget build(BuildContext context) {
    final r=result;
    if (r != null) {
      return Scaffold(
        appBar: AppBar(title:const Text('نتيجة تحديد المستوى')),
        body: ListView(padding:const EdgeInsets.all(20),children:[
          Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
            const Icon(Icons.insights,size:48),
            const SizedBox(height:10),
            Text(r.level,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
            Text('النتيجة: ${r.score}/${r.total}'),
          ]))),
          const SizedBox(height:12),
          Text('نقاط القوة: ${r.strengths.isEmpty ? 'نحتاج مزيداً من التدريب' : r.strengths.join('، ')}'),
          const SizedBox(height:8),
          Text('نركز الآن على: ${r.focusAreas.isEmpty ? 'تثبيت المستوى' : r.focusAreas.join('، ')}'),
          const SizedBox(height:20),
          FilledButton.icon(
            onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:service.buildTutorPrompt(subject:widget.subject,result:r)))),
            icon:const Icon(Icons.auto_awesome),label:const Text('ابدأ مساري مع AI Tutor'),
          ),
          const SizedBox(height:10),
          OutlinedButton.icon(
            onPressed:() async {
              final uid=FirebaseAuth.instance.currentUser?.uid;
              if(uid==null) return;
              await plans.savePlan(uid:uid,title:'مسار ${widget.subject}',track:'Adaptive Learning',subject:widget.subject,level:r.level,minutesPerDay:30,weeklyGoals:['التركيز: ${r.focusAreas.join('، ')}','درس يومي','تمارين','اختبار ومراجعة']);
              if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const LearningPlanScreen()));
            },
            icon:const Icon(Icons.route),label:const Text('حوّل النتيجة إلى خطة تعلم'),
          ),
        ]),
      );
    }
    final q=EducationLevelAssessmentService.questions[index];
    return Scaffold(
      appBar:AppBar(title:Text('تحديد مستوى • ${index+1}/${EducationLevelAssessmentService.questions.length}')),
      body:ListView(padding:const EdgeInsets.all(20),children:[
        Text(widget.subject,style:Theme.of(context).textTheme.titleMedium),
        const SizedBox(height:16),
        Text(q.prompt,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:20),
        ...List.generate(q.options.length,(i)=>Padding(
          padding:const EdgeInsets.only(bottom:10),
          child:OutlinedButton(onPressed:()=>_answer(i),child:Padding(padding:const EdgeInsets.all(14),child:Align(alignment:AlignmentDirectional.centerStart,child:Text(q.options[i])))),
        )),
      ]),
    );
  }
}
