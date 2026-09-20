import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEntertainmentScreen extends StatelessWidget {
  const AurenAURENEntertainmentScreen({super.key});
  static const items = <Map<String,String>>[
    {'t':'Discover','s':'اكتشف خيارات مناسبة لك','p':'ساعدني أكتشف أفضل الخيارات المناسبة لي في Entertainment.'},
    {'t':'My Plan','s':'حوّل هدفك إلى خطوات','p':'ابنِ لي خطة عملية في Entertainment خطوة بخطوة.'},
    {'t':'AI Guide','s':'اسأل AUREN','p':'تصرف كمرشد ذكي في Entertainment واسألني ما تحتاجه ثم اقترح الخطوة التالية.'},
  ];
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('AUREN Entertainment')),
    body:ListView(padding:const EdgeInsets.all(16),children:[const ListTile(leading:Icon(Icons.tv),title:Text('Global Series'),subtitle:Text('مسلسلات عالمية — Turkish داخل Global Series')),const ListTile(leading:Icon(Icons.animation),title:Text('Anime World'),subtitle:Text('أنمي وعوالم وشخصيات')),const ListTile(leading:Icon(Icons.people),title:Text('Watch Together'),subtitle:Text('شاهد مع أصدقائك')),const ListTile(leading:Icon(Icons.public),title:Text('Live Planet'),subtitle:Text('ثقافة وأحداث وتجارب')),const ListTile(leading:Icon(Icons.podcasts),title:Text('Music & Podcasts'),subtitle:Text('استمع واكتشف')),const ListTile(leading:Icon(Icons.menu_book),title:Text('Books & Manga'),subtitle:Text('كتب ومانجا ومكتبة')),const ListTile(leading:Icon(Icons.videogame_asset),title:Text('AUREN World'),subtitle:Text('عالم تفاعلي')),]));
}