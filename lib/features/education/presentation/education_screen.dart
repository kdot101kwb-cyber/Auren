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
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Icon(Icons.auto_awesome,size:36),const SizedBox(height:12),
        Text('AUREN adapts to you',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
        const SizedBox(height:6),const Text('ابدأ بما تريد، وخلّي AUREN يساعدك في الخطوة التالية.')
      ]))),
      const SizedBox(height:12),
      ...items.map((x)=>Card(child:ListTile(leading:const Icon(Icons.arrow_forward_ios),title:Text(x['t']!),subtitle:Text(x['s']!),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:x['p'])))))),
    ]));
}