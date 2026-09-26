import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AurenCreatorSettlementCenterScreen extends StatefulWidget {
  const AurenCreatorSettlementCenterScreen({super.key});
  @override State<AurenCreatorSettlementCenterScreen> createState()=>_AurenCreatorSettlementCenterScreenState();
}
class _AurenCreatorSettlementCenterScreenState extends State<AurenCreatorSettlementCenterScreen>{
  String _filter='pending'; bool _loading=false; List<Map<String,dynamic>> _items=[];
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{
    if(FirebaseAuth.instance.currentUser==null)return;
    setState(()=>_loading=true);
    try{
      final c=FirebaseFunctions.instance.httpsCallable('listCreatorWithdrawals');
      final r=await c.call({'status':_filter});
      final data=Map<String,dynamic>.from(r.data as Map);
      _items=(data['items'] as List? ?? const []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحميل التسويات: $e')));}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _setStatus(Map<String,dynamic> item,String status)async{
    try{
      final c=FirebaseFunctions.instance.httpsCallable('setCreatorWithdrawalStatus');
      await c.call({'withdrawalId':item['id'],'status':status});
      await _load();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحديث الحالة: $e')));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Creator Settlement Center')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Settlement Center',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
      const SizedBox(height:6),const Text('لوحة تشغيلية لمعالجة طلبات السحب. الوصول يتطلب Admin claim.'),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:_filter,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'الحالة'),
        items:const ['pending','approved','paid','failed'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null){setState(()=>_filter=v);_load();}}),
      const SizedBox(height:16),
      if(_loading)const Center(child:CircularProgressIndicator()),
      if(!_loading&&_items.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد طلبات.'))),
      ..._items.map((x){
        final amount=((x['amountMinor'] as num?)?.toInt()??0)/100;
        final status=(x['status']??'').toString();
        return Card(child:ListTile(
          title:Text('${amount.toStringAsFixed(2)} ${x['currency']??''}'),
          subtitle:Text('${x['creatorUid']??''}\n$status • ${x['method']??''}'),
          isThreeLine:true,
          trailing:PopupMenuButton<String>(onSelected:(v)=>_setStatus(x,v),itemBuilder:(_)=>[
            if(status=='pending')const PopupMenuItem(value:'approved',child:Text('Approve')),
            if(status=='pending'||status=='approved')const PopupMenuItem(value:'failed',child:Text('Fail')),
            if(status=='approved')const PopupMenuItem(value:'paid',child:Text('Mark Paid')),
          ]),
        ));
      }),
    ]),
  );
}
