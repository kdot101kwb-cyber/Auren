import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENTravelScreen extends StatelessWidget {
  const AurenAURENTravelScreen({super.key});
  static const items = <Map<String,String>>[
    {'t':'Discover','s':'اكتشف خيارات مناسبة لك','p':'ساعدني أكتشف أفضل الخيارات المناسبة لي في Travel.'},
    {'t':'My Plan','s':'حوّل هدفك إلى خطوات','p':'ابنِ لي خطة عملية في Travel خطوة بخطوة.'},
    {'t':'AI Guide','s':'اسأل AUREN','p':'تصرف كمرشد ذكي في Travel واسألني ما تحتاجه ثم اقترح الخطوة التالية.'},
  ];
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('AUREN Travel')),
    body:ListView(padding:const EdgeInsets.all(16),children:[const ListTile(leading:Icon(Icons.explore),title:Text('Destinations'),subtitle:Text('وجهات وثقافة وطعام وتجارب')),const ListTile(leading:Icon(Icons.map),title:Text('Journey Map'),subtitle:Text('خط سير وتنقل')),const ListTile(leading:Icon(Icons.hotel),title:Text('Stay & Culture'),subtitle:Text('إقامة وتجارب محلية')),const ListTile(leading:Icon(Icons.confirmation_number),title:Text('Travel Wallet'),subtitle:Text('تذاكر ومستندات ومصاريف')),const ListTile(leading:Icon(Icons.shield),title:Text('Travel Safety'),subtitle:Text('سلامة وتنبيهات')),const SizedBox(height:12),Text('Popular'),...['Khartoum','Cairo','Dubai','Istanbul','Nairobi'].map((x)=>Card(child:ListTile(title:Text(x),subtitle:const Text('Discover with AUREN'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'اكتشف لي $x وخطط رحلة مناسبة.')))))]));
}