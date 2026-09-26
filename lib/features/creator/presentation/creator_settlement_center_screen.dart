import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AurenCreatorSettlementCenterScreen extends StatefulWidget {
  const AurenCreatorSettlementCenterScreen({super.key});
  @override State<AurenCreatorSettlementCenterScreen> createState()=>_AurenCreatorSettlementCenterScreenState();
}

class _AurenCreatorSettlementCenterScreenState extends State<AurenCreatorSettlementCenterScreen>{
  String _filter='pending';
  bool _loading=false;
  bool _earningsMode=false;
  List<Map<String,dynamic>> _items=[];

  @override void initState(){super.initState();_load();}

  Future<void> _load()async{
    if(FirebaseAuth.instance.currentUser==null)return;
    setState(()=>_loading=true);
    try{
      final name=_earningsMode?'listCreatorEarnings':'listCreatorWithdrawals';
      final c=FirebaseFunctions.instance.httpsCallable(name);
      final r=await c.call({'status':_filter});
      final data=Map<String,dynamic>.from(r.data as Map);
      _items=(data['items'] as List? ?? const [])
          .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('تعذر تحميل البيانات: $e')),
      );
    }finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _setWithdrawalStatus(Map<String,dynamic> item,String status)async{
    try{
      final c=FirebaseFunctions.instance.httpsCallable('setCreatorWithdrawalStatus');
      await c.call({'withdrawalId':item['id'],'status':status,'note':''});
      await _load();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('تعذر تحديث الحالة: $e')),
      );
    }
  }

  Future<void> _settleEarning(Map<String,dynamic> item)async{
    try{
      final c=FirebaseFunctions.instance.httpsCallable('settleCreatorEarning');
      await c.call({'earningId':item['id']});
      await _load();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('تعذر تسوية الأرباح: $e')),
      );
    }
  }

  List<String> get _statuses=>_earningsMode
      ? const ['pending_settlement','settled']
      : const ['pending','approved','paid','failed'];

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Creator Settlement Center')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Settlement Center',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
      const SizedBox(height:6),
      const Text('لوحة تشغيلية للأرباح وطلبات السحب. الوصول يتطلب Admin claim.'),
      const SizedBox(height:12),
      SegmentedButton<bool>(
        segments:const [
          ButtonSegment(value:false,label:Text('Withdrawals'),icon:Icon(Icons.payments_outlined)),
          ButtonSegment(value:true,label:Text('Earnings'),icon:Icon(Icons.account_balance_wallet_outlined)),
        ],
        selected:{_earningsMode},
        onSelectionChanged:(v){
          setState(()=>_earningsMode=v.first);
          _filter=_earningsMode?'pending_settlement':'pending';
          _load();
        },
      ),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(
        value:_filter,
        decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'الحالة'),
        items:_statuses.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
        onChanged:(v){if(v!=null){setState(()=>_filter=v);_load();}},
      ),
      const SizedBox(height:16),
      if(_loading)const Center(child:CircularProgressIndicator()),
      if(!_loading&&_items.isEmpty)
        const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد سجلات.'))),
      ..._items.map((x){
        final amount=((x['amountMinor'] as num?)?.toInt()??0)/100;
        final status=(x['status']??'').toString();
        if(_earningsMode){
          return Card(child:ListTile(
            title:Text('${amount.toStringAsFixed(2)} ${x['currency']??''}'),
            subtitle:Text('${x['creatorUid']??''}\n$status • ${x['type']??'support'}'),
            isThreeLine:true,
            trailing:status=='pending_settlement'
                ? IconButton(
                    tooltip:'Settle',
                    icon:const Icon(Icons.check_circle_outline),
                    onPressed:()=>_settleEarning(x),
                  )
                : const Icon(Icons.verified_outlined),
          ));
        }
        return Card(child:ListTile(
          title:Text('${amount.toStringAsFixed(2)} ${x['currency']??''}'),
          subtitle:Text('${x['creatorUid']??''}\n$status • ${x['method']??''}'),
          isThreeLine:true,
          trailing:PopupMenuButton<String>(
            onSelected:(v)=>_setWithdrawalStatus(x,v),
            itemBuilder:(_)=>[
              if(status=='pending')const PopupMenuItem(value:'approved',child:Text('Approve')),
              if(status=='pending'||status=='approved')const PopupMenuItem(value:'failed',child:Text('Fail')),
              if(status=='approved')const PopupMenuItem(value:'paid',child:Text('Mark Paid')),
            ],
          ),
        ));
      }),
    ]),
  );
}
