import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/media/auren_media_service.dart';

class AurenMediaStudioScreen extends StatelessWidget {
  const AurenMediaStudioScreen({super.key});
  @override Widget build(BuildContext context){
    final uid=FirebaseAurenAuthService().currentUserId;
    return Scaffold(
      appBar:AppBar(title:const Text('Media Infrastructure')),
      body:Padding(padding:const EdgeInsets.all(16),child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          const Text('Media Storage',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          const Text('طبقة Firebase Storage الأساسية جاهزة للصور والفيديو والصوت والملفات الصغيرة. الحد الحالي 25MB للملف.'),
          const SizedBox(height:10),
          Text(uid==null?'سجّل الدخول لاستخدام الوسائط.':'Media تحفظ داخل مساحة حسابك.'),
          const SizedBox(height:16),
          const Text('واجهة اختيار Gallery / Camera / File Picker وربط المعاينة والـthumbnail ستأتي فوق هذه الخدمة.'),
        ],
      )))),
    );
  }
}
