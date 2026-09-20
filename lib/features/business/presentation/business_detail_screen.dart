import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';

class AurenBusinessDetailScreen extends StatefulWidget {
  final AurenBusiness business;
  const AurenBusinessDetailScreen({super.key, required this.business});
  @override State<AurenBusinessDetailScreen> createState() => _AurenBusinessDetailScreenState();
}

class _AurenBusinessDetailScreenState extends State<AurenBusinessDetailScreen> {
  bool saving = false;
  Future<void> edit() async {
    final n=TextEditingController(text:widget.business.name);
    final d=TextEditingController(text:widget.business.description);
    final city=TextEditingController(text:widget.business.city);
    final country=TextEditingController(text:widget.business.country);
    final phone=TextEditingController(text:widget.business.phone);
    final web=TextEditingController(text:widget.business.website);
    final img=TextEditingController(text:widget.business.imageUrl);
    String cat=widget.business.category;
    final cats=['Retail','Food','Services','Technology','Manufacturing','Education','Travel','Creative','Agriculture','Other'];
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),
      child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('تعديل Business',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم النشاط')),
        TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),
        DropdownButtonFormField<String>(value:cat,items:cats.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setModal(()=>cat=v!),decoration:const InputDecoration(labelText:'التصنيف')),
        TextField(controller:city,decoration:const InputDecoration(labelText:'المدينة')),
        TextField(controller:country,decoration:const InputDecoration(labelText:'الدولة')),
        TextField(controller:phone,decoration:const InputDecoration(labelText:'الهاتف')),
        TextField(controller:web,decoration:const InputDecoration(labelText:'الموقع الإلكتروني')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'رابط الصورة')),
        const SizedBox(height:16),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ التعديلات')),
      ])),
    )));
    for(final c in [n,d,city,country,phone,web,img]) c.dispose();
    if(ok!=true)return;
    setState(()=>saving=true);
    try {
      await BusinessRepository().update(id:widget.business.id,name:n.text,description:d.text,category:cat,city:city.text,country:country.text,phone:phone.text,website:web.text,imageUrl:img.text);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تحديث Business')));
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التحديث: $e'))); }
    finally { if(mounted)setState(()=>saving=false); }
  }

  @override Widget build(BuildContext context) {
    final b=widget.business; final own=FirebaseAuth.instance.currentUser?.uid==b.ownerId;
    return Scaffold(
      appBar:AppBar(title:const Text('Business'),actions:[
        if(own) IconButton(onPressed:saving?null:edit,icon:const Icon(Icons.edit_outlined)),
        if(own) IconButton(onPressed:()async{final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('حذف النشاط؟'),content:const Text('لا يمكن التراجع عن هذا الإجراء.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف'))]));if(ok==true){await BusinessRepository().delete(b.id);if(context.mounted)Navigator.pop(context);}},icon:const Icon(Icons.delete_outline))
      ]),
      body:ListView(padding:const EdgeInsets.all(20),children:[
        if(b.imageUrl.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.network(b.imageUrl,height:220,fit:BoxFit.cover)),
        const SizedBox(height:16),
        Row(children:[Expanded(child:Text(b.name,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold))),if(b.verified)const Icon(Icons.verified)]),
        const SizedBox(height:8),Chip(label:Text(b.category)),
        if(b.description.isNotEmpty)Padding(padding:const EdgeInsets.only(top:16),child:Text(b.description)),
        if(b.city.isNotEmpty||b.country.isNotEmpty)ListTile(leading:const Icon(Icons.location_on_outlined),title:const Text('الموقع'),subtitle:Text([b.city,b.country].where((x)=>x.isNotEmpty).join(' • '))),
        if(b.phone.isNotEmpty)ListTile(leading:const Icon(Icons.phone_outlined),title:const Text('الهاتف'),subtitle:Text(b.phone)),
        if(b.website.isNotEmpty)ListTile(leading:const Icon(Icons.language),title:const Text('الموقع الإلكتروني'),subtitle:Text(b.website)),
        const SizedBox(height:16),
        FilledButton.icon(onPressed:own?null:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('التواصل المباشر بالـ Messenger سنوصله في دفعة Messenger/Business التالية.'))),icon:const Icon(Icons.chat_bubble_outline),label:const Text('تواصل مع Business'))
      ])
    );
  }
}
