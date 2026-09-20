import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEducationScreen extends StatelessWidget {
  const AurenAURENEducationScreen({super.key});
  static const items = <Map<String,String>>[
    {'t':'Discover','s':'اكتشف خيارات مناسبة لك','p':'ساعدني أكتشف أفضل الخيارات المناسبة لي في Education.'},
    {'t':'My Plan','s':'حوّل هدفك إلى خطوات','p':'ابنِ لي خطة عملية في Education خطوة بخطوة.'},
    {'t':'AI Guide','s':'اسأل AUREN','p':'تصرف كمرشد ذكي في Education واسألني ما تحتاجه ثم اقترح الخطوة التالية.'},
  ];
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('AUREN Education')),
    body:ListView(padding:const EdgeInsets.all(16),children:[const ListTile(leading:Icon(Icons.school),title:Text('Courses'),subtitle:Text('تعلم من دورات ومسارات منظمة')),const ListTile(leading:Icon(Icons.play_lesson),title:Text('Lessons'),subtitle:Text('دروس قصيرة مع تطبيق عملي')),const ListTile(leading:Icon(Icons.quiz),title:Text('AI Quiz'),subtitle:Text('اختبارات ذكية حسب الدرس')),const ListTile(leading:Icon(Icons.person),title:Text('AI Tutor'),subtitle:Text('مدرس شخصي داخل AUREN')),const ListTile(leading:Icon(Icons.workspace_premium),title:Text('Certificates'),subtitle:Text('تقدم ومشاريع وشهادات')),const SizedBox(height:12),Text('My Learning'),Card(child:ListTile(title:const Text('Flutter & Dart'),subtitle:const Text('12 lessons • 25% progress'),trailing:Icon(Icons.play_arrow),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'ساعدني أكمل دورة Flutter & Dart.')))),Card(child:ListTile(title:const Text('English'),subtitle:const Text('24 lessons'),trailing:Icon(Icons.play_arrow),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'ابدأ معي درس English الآن.'))))]));
}