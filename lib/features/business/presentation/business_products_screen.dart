import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/product.dart';
import '../../../services/marketplace/marketplace_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/core/auren_core_five_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../marketplace/presentation/product_detail_screen.dart';

class AurenBusinessProductsScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  const AurenBusinessProductsScreen({super.key,required this.businessId,required this.businessName});
  @override State<AurenBusinessProductsScreen> createState()=>_AurenBusinessProductsScreenState();
}
class _AurenBusinessProductsScreenState extends State<AurenBusinessProductsScreen>{
  final repo=MarketplaceRepository();
  bool get _owner => FirebaseAuth.instance.currentUser?.uid != null;
  Future<void> add() async {
    final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;
    final business=await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
    if(!business.exists || business.data()?['ownerId'] != uid){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('فقط مالك النشاط يمكنه إضافة منتجات.')));
      return;
    }
    final n=TextEditingController(),d=TextEditingController(),price=TextEditingController(),img=TextEditingController();
    String cat='General',currency='USD';bool service=false;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:Text('إضافة إلى '+widget.businessName),
      content:SingleChildScrollView(child:Column(children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),
        TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'رابط الصورة')),
        DropdownButtonFormField<String>(value:cat,items:['General','Fashion','Food','Electronics','Services','Home','Agriculture','Other'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>cat=v!)),
        DropdownButtonFormField<String>(value:currency,items:['USD','EUR','SDG','AED','SAR','EGP'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>currency=v!)),
        SwitchListTile(value:service,onChanged:(v)=>setD(()=>service=v),title:const Text('خدمة بدل منتج')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('إضافة'))],
    )));
    if(ok!=true)return;
    final minor=(double.tryParse(price.text.trim())??0)*100;
    await repo.create(ownerId:uid,businessId:widget.businessId,name:n.text,description:d.text,category:cat,currency:currency,priceMinor:minor.round(),imageUrl:img.text,service:service);
    for(final c in [n,d,price,img])c.dispose();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Products & Services'),actions:[IconButton(tooltip:'Core 5 AI',icon:const Icon(Icons.auto_awesome),onPressed:()async{final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;final snapshot=await AurenCoreFiveRepository().load(uid);if(!context.mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:snapshot.toPrompt()+'\nركّز على كيف أطور منتجات وخدمات هذا النشاط وأربطها بأهدافي وفرصي.')));})]),
    floatingActionButton:FirebaseAuth.instance.currentUser?.uid==null?null:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('إضافة')),
    body:StreamBuilder<List<AurenProduct>>(stream:repo.watchBusiness(widget.businessId),builder:(context,s){
      if(s.hasError)return Center(child:Text('حدث خطأ: '+s.error.toString()));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      if(s.data!.isEmpty)return const Center(child:Text('لا توجد منتجات أو خدمات بعد.'));
      return ListView.separated(padding:const EdgeInsets.all(16),itemCount:s.data!.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
        itemBuilder:(context,i){final p=s.data![i];return Card(child:ListTile(
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenProductDetailScreen(product:p))),
          leading:p.imageUrl.isEmpty?const Icon(Icons.inventory_2_outlined):Image.network(p.imageUrl,width:48,height:48,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined)),
          title:Text(p.name),subtitle:Text((p.priceMinor/100).toStringAsFixed(2)+' '+p.currency+(p.service?' • خدمة':'')),
          trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:FirebaseAuth.instance.currentUser?.uid==p.ownerId?()async{await repo.delete(p.id);setState((){});} : null),
        ));});
    }),
  );
}
