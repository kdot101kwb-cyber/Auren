import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENCreatorStudioScreen extends StatelessWidget {
  const AurenAURENCreatorStudioScreen({super.key});
  static const items = <Map<String,String>>[
    {'t':'Discover','s':'اكتشف خيارات مناسبة لك','p':'ساعدني أكتشف أفضل الخيارات المناسبة لي في Creator Studio.'},
    {'t':'My Plan','s':'حوّل هدفك إلى خطوات','p':'ابنِ لي خطة عملية في Creator Studio خطوة بخطوة.'},
    {'t':'AI Guide','s':'اسأل AUREN','p':'تصرف كمرشد ذكي في Creator Studio واسألني ما تحتاجه ثم اقترح الخطوة التالية.'},
  ];
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('AUREN Creator Studio')),
    body:ListView(padding:const EdgeInsets.all(16),children:[const ListTile(leading:Icon(Icons.add_circle),title:Text('Create'),subtitle:Text('Posts • Reels • Stories • Live')),const ListTile(leading:Icon(Icons.auto_awesome),title:Text('AI Studio'),subtitle:Text('Hooks • Scripts • Captions • Ideas')),const ListTile(leading:Icon(Icons.people),title:Text('Audience'),subtitle:Text('جمهور ومتابعة وتفاعل')),const ListTile(leading:Icon(Icons.analytics),title:Text('Analytics'),subtitle:Text('نمو وأداء المحتوى')),const ListTile(leading:Icon(Icons.monetization_on),title:Text('Monetization'),subtitle:Text('طرق تحقيق الدخل')),const SizedBox(height:12),Text('Quick start'),Card(child:ListTile(title:const Text('Create your first idea'),trailing:const Icon(Icons.arrow_forward_ios),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'أعطني فكرة محتوى قوية وابدأ معي في تنفيذها.')))))]));
}