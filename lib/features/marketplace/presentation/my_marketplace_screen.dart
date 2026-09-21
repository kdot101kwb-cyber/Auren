import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/product.dart';
import '../../../services/marketplace/marketplace_repository.dart';

class AurenMyMarketplaceScreen extends StatefulWidget{
  const AurenMyMarketplaceScreen({super.key});
  @override State<AurenMyMarketplaceScreen> createState()=>_AurenMyMarketplaceScreenState();
}

class _AurenMyMarketplaceScreenState extends State<AurenMyMarketplaceScreen>{
  final repo=MarketplaceRepository();
  Future<void> _edit(BuildContext context,AurenProduct p) async {
    final n=TextEditingController(text:p.name), d=TextEditingController(text:p.description), price=TextEditingController(text:(p.priceMinor/100).toStringAsFixed(2)), img=TextEditingController(text:p.imageUrl);
    String cat=p.category, currency=p.currency; bool service=p.service;
    const cats=['General','Fashion','Food','Electronics','Services','Home','Agriculture','Other'];
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setM)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Text('تعديل المنتج / الخدمة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'السعر')),TextField(controller:img,decoration:const InputDecoration(labelText:'رابط الصورة')),DropdownButtonFormField<String>(value:cats.contains(cat)?cat:cats.first,items:cats.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setM(()=>cat=v!),decoration:const InputDecoration(labelText:'التصنيف')),TextField(controller:TextEditingController(text:currency),onChanged:(v)=>currency=v.trim().toUpperCase(),decoration:const InputDecoration(labelText:'العملة')),SwitchListTile(value:service,onChanged:(v)=>setM(()=>service=v),title:const Text('خدمة بدل منتج')),const SizedBox(height:12),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]))));
    if(ok==true){final minor=((double.tryParse(price.text.replaceAll(',','.'))??0)*100).round();await repo.update(p.id,{'name':n.text.trim(),'description':d.text.trim(),'category':cat,'currency':currency,'priceMinor':minor,'imageUrl':img.text.trim(),'service':service});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تحديث المنتج')));}
    for(final x in [n,d,price,img])x.dispose();
  }
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
            trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit'){await _edit(context,p);}else if(v=='delete'){final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('حذف الإعلان؟'),content:Text('سيتم حذف «${p.name}» نهائياً.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حذف'))]));if(ok==true){await repo.delete(p.id);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حذف الإعلان')));}}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('تعديل')),PopupMenuItem(value:'delete',child:Text('حذف'))]),
          ));});
      }));
  }
}
