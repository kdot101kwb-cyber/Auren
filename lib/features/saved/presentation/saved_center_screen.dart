import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/education/education_repository.dart';
import '../../../services/travel/travel_repository.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import '../../../core/models/product.dart';
import '../../../core/models/education.dart';
import '../../../core/models/travel.dart';
import '../../../core/models/entertainment.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../business/presentation/saved_businesses_screen.dart';
import '../../social/presentation/saved_pulse_screen.dart';

class AurenSavedCenterScreen extends StatelessWidget {
  const AurenSavedCenterScreen({super.key});
  @override Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لعرض المحفوظات.')));
    final e=EducationRepository(), t=TravelRepository(), x=EntertainmentRepository();
    return Scaffold(appBar:AppBar(title:const Text('AUREN Saved')),body:ListView(padding:const EdgeInsets.all(16),children:[
      _section('Education',Icons.school,StreamBuilder<List<AurenCourse>>(stream:e.watchSavedCourses(uid),builder:(c,s)=>_items(s.data??const <AurenCourse>[],(v)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.school)),title:Text(v.title),subtitle:Text(v.category),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'ساعدني أتعلم دورة '+v.title+' وأعمل خطة دراسة لها.'))))))),
      _section('Travel',Icons.place,StreamBuilder<List<AurenPlace>>(stream:t.watchSavedPlaces(uid),builder:(c,s)=>_items(s.data??const <AurenPlace>[],(v)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.place)),title:Text(v.name),subtitle:Text(v.city+', '+v.country),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'خطط لي زيارة إلى '+v.name+' في '+v.city+', '+v.country+'.'))))))),
      _section('Entertainment',Icons.movie,StreamBuilder<List<AurenEntertainmentItem>>(stream:x.watchSavedItems(uid),builder:(c,s)=>_items(s.data??const <AurenEntertainmentItem>[],(v)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.play_arrow)),title:Text(v.title),subtitle:Text(v.type),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'اقترح لي محتوى مشابه لـ'+v.title+'.'))))))),
      _section('Marketplace',Icons.shopping_bag_outlined,StreamBuilder<Set<String>>(stream:MarketplaceRepository().watchSavedIds(uid),builder:(c,s){final ids=s.data??<String>{};return StreamBuilder<List<AurenProduct>>(stream:FirebaseFirestore.instance.collection('products').where(FieldPath.documentId,whereIn:ids.isEmpty?['__none__']:ids.take(10).toList()).snapshots().map((q)=>q.docs.map((d)=>AurenProduct.fromMap(d.id,d.data())).toList()),builder:(c,p)=>_items(p.data??const <AurenProduct>[],(v)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.shopping_bag_outlined)),title:Text(v.name),subtitle:Text((v.priceMinor/100).toStringAsFixed(2)+' '+v.currency),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'أريد معلومات عن '+v.name+' في Marketplace.')))));}))),
      _shortcut(context, 'Business', Icons.storefront_outlined, 'المشاريع والشركات التي حفظتها.', const AurenSavedBusinessesScreen()),
      _shortcut(context, 'Pulse', Icons.dynamic_feed_outlined, 'منشورات Pulse المحفوظة.', const AurenSavedPulseScreen()),
    ]));
  }
  Widget _section(String title,IconData icon,Widget child)=>Card(margin:const EdgeInsets.only(bottom:14),child:Column(children:[ListTile(leading:Icon(icon),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))),child]));
  Widget _shortcut(BuildContext context,String title,IconData icon,String subtitle,Widget page)=>Card(child:ListTile(leading:Icon(icon),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>page))));
  Widget _items<T>(List<T> items,Widget Function(T) builder)=>items.isEmpty?const Padding(padding:EdgeInsets.all(12),child:Text('لا توجد عناصر محفوظة حالياً.')):Column(children:items.map(builder).toList());
}