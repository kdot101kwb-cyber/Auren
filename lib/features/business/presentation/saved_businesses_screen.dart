import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import 'business_detail_screen.dart';

class AurenSavedBusinessesScreen extends StatelessWidget {
  const AurenSavedBusinessesScreen({super.key});
  @override Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final repo=BusinessRepository();
    return Scaffold(appBar:AppBar(title:const Text('Saved Businesses')),body:StreamBuilder<List<String>>(
      stream:repo.watchSavedIds(uid),builder:(context,s){
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        if(s.data!.isEmpty)return const Center(child:Text('لا توجد Businesses محفوظة.'));
        return ListView.separated(padding:const EdgeInsets.all(16),itemCount:s.data!.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
          itemBuilder:(context,i)=>FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
            future:repo.getById(s.data![i]),builder:(context,b){
              if(!b.hasData||!b.data!.exists)return const SizedBox.shrink();
              final x=AurenBusiness.fromMap(b.data!.id,b.data!.data()!);
              return Card(child:ListTile(title:Text(x.name),subtitle:Text([x.category,x.city,x.country].where((e)=>e.isNotEmpty).join(' • ')),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenBusinessDetailScreen(business:x)))));
            }));
      }));
  }
}