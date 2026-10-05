import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenStayScreen extends StatelessWidget {
  const AurenStayScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Stay'),actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ساعدني في Stay داخل AUREN واقترح أفضل الخيارات والخطوات.'))),icon:const Icon(Icons.auto_awesome))]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Stay',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        const Text('واجهة AUREN الأساسية تعمل الآن. يمكنك استخدام AUREN AI للتخطيط والمقارنة وتحويل احتياجك إلى خطوات عملية.'),
        const SizedBox(height:16),
        FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'حلّل احتياجي الآن وقدّم لي الخيارات المناسبة وخطة تنفيذ واضحة.'))),icon:const Icon(Icons.auto_awesome),label:const Text('اسأل AUREN')),
      ])),
    ]),
  );
}
}
