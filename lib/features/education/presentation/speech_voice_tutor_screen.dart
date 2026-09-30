import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/accessibility_speech_service.dart';

class SpeechVoiceTutorScreen extends StatefulWidget {
  const SpeechVoiceTutorScreen({super.key});
  @override State<SpeechVoiceTutorScreen> createState()=>_SpeechVoiceTutorScreenState();
}

class _SpeechVoiceTutorScreenState extends State<SpeechVoiceTutorScreen> {
  final service=SpeechPracticeService();
  final controller=TextEditingController();
  String prompt='انطق الجملة التالية بوضوح: مرحباً بك في AUREN.';
  bool listening=false;
  double score=0;
  List<String> feedback=[];

  Future<void> _save() async {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null || controller.text.trim().isEmpty)return;
    await service.saveResult(uid,SpeechPracticeResult(
      prompt:prompt,transcript:controller.text.trim(),
      pronunciationScore:score,feedback:feedback,createdAt:DateTime.now(),
    ));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ نتيجة التدريب')));
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Voice Tutor')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Card(child:Padding(padding:EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(Icons.record_voice_over,size:40),SizedBox(height:10),
        Text('تدريب النطق بالصوت',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        SizedBox(height:6),Text('تحدث مع المدرس AI وتدرّب خطوة بخطوة.'),
      ]))),
      const SizedBox(height:18),
      const Text('الجملة الحالية',style:TextStyle(fontWeight:FontWeight.bold)),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Text(prompt,style:const TextStyle(fontSize:19)))),
      const SizedBox(height:12),
      TextField(controller:controller,maxLines:3,decoration:const InputDecoration(labelText:'النص المنطوق / المحوّل إلى نص',border:OutlineInputBorder())),
      const SizedBox(height:12),
      FilledButton.icon(
        onPressed:()=>setState(()=>listening=!listening),
        icon:Icon(listening?Icons.stop:Icons.mic),
        label:Text(listening?'إيقاف التدريب':'ابدأ التدريب الصوتي'),
      ),
      const SizedBox(height:12),
      Text('التقييم: ${score.toStringAsFixed(0)}%'),
      Slider(value:score,min:0,max:100,divisions:20,onChanged:(v)=>setState(()=>score=v)),
      if(feedback.isEmpty) const Text('بعد إضافة Speech-to-Text يمكن للـAI تحليل النطق وإظهار ملاحظات مخصصة هنا.'),
      ...feedback.map((x)=>ListTile(leading:const Icon(Icons.check_circle_outline),title:Text(x))),
      OutlinedButton.icon(onPressed:_save,icon:const Icon(Icons.save_outlined),label:const Text('حفظ النتيجة')),
    ]),
  );

  @override void dispose(){controller.dispose();super.dispose();}
}
