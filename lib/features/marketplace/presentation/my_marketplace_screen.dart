import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/product.dart';
import '../../../services/marketplace/marketplace_repository.dart';

class AurenMyMarketplaceScreen extends StatelessWidget{
  const AurenMyMarketplaceScreen({super.key});
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final repo=MarketplaceRepository();
    return Scaffold(appBar:AppBar(title:const Text('My Listings')),body:StreamBuilder<List<AurenProduct>>(
      stream:repo.watchOwner(uid),builder:(context,s){
        if(s.hasError)return Center(child:Text('حدث خطأ: '+s.error.toString()));
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        if(s.data!.isEmpty)return const Center(child:Text('لا توجد منتجات أو خدمات منشورة.'));
        return ListView.separated(padding:const EdgeInsets.all(16),itemCount:s.data!.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
          itemBuilder:(context,i){final p=s.data![i];return Card(child:ListTile(
            leading:const Icon(Icons.inventory_2_outlined),title:Text(p.name),subtitle:Text((p.priceMinor/100).toStringAsFixed(2)+' '+p.currency+' • '+p.businessId),
            trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='delete'){await repo.delete(p.id);}},itemBuilder:(_)=>const [PopupMenuItem(value:'delete',child:Text('حذف'))]),
          ));});
      }));
  }
}
