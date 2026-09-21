import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/education_repository.dart';
import '../../../core/models/education.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEducationScreen extends StatefulWidget {
  const AurenAURENEducationScreen({super.key});
  @override State<AurenAURENEducationScreen> createState()=>_EducationState();
}
class _EducationState extends State<AurenAURENEducationScreen>{
  final repo=EducationRepository(); String query=''; String? category; bool savedOnly=false;
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول عشان تستخدم التعلم.')));
    return Scaffold(appBar:AppBar(title:const Text('AUREN Education'),actions:[IconButton(icon:Icon(savedOnly?Icons.bookmark:Icons.bookmark_border),onPressed:()=>setState(()=>savedOnly=!savedOnly)),IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ابني لي خطة تعلم شخصية بناءً على أهدافي ومهاراتي.'))))]),body:StreamBuilder<List<AurenCourse>>(stream:repo.watchCourses(),builder:(context,s){
      if(s.hasError)return Center(child:Text('تعذر تحميل التعليم: '+s.error.toString())); if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      final all=s.data??const <AurenCourse>[]; final cats=all.map((e)=>e.category).where((e)=>e.isNotEmpty).toSet().toList()..sort();
      final q=query.toLowerCase(); final courses=all.where((c)=>(q.isEmpty||(c.title+' '+c.description+' '+c.category).toLowerCase().contains(q))&&(category==null||c.category==category)).toList();
      return ListView(padding:const EdgeInsets.all(16),children:[
        const ListTile(contentPadding:EdgeInsets.zero,leading:Icon(Icons.school,size:34),title:Text('Learn with AUREN',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),subtitle:Text('دورات، تقدم، ومدرس شخصي بالذكاء الاصطناعي.')),
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن دورة أو مهارة'),onChanged:(v)=>setState(()=>query=v)),
        const SizedBox(height:8),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[null,...cats].map((c)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(c??'All'),selected:category==c,onSelected:(_)=>setState(()=>category=c))).toList()))),
        const SizedBox(height:12),...courses.map((c)=>_card(context,c,uid)),
      ]);
    }));
  }
  Widget _card(BuildContext context,AurenCourse c,String uid)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
    title:Text(c.title),subtitle:Text(c.category+' • '+c.lessonCount.toString()+' lessons'),leading:const CircleAvatar(child:Icon(Icons.school)),
    trailing:FilledButton(onPressed:()=>repo.enroll(uid,c.id),child:const Text('Enroll')),
    onTap:()=>showModalBottomSheet(context:context,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(c.title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(c.description),const SizedBox(height:12),
      FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'ساعدني أدرس دورة '+c.title+' واصنع لي اختباراً بعد كل درس.'))),icon:const Icon(Icons.auto_awesome),label:const Text('AI Tutor'))
    ]))));
}