import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/family/family_pot_repository.dart';

class AurenFamilyScreen extends StatefulWidget {
  const AurenFamilyScreen({super.key});
  @override State<AurenFamilyScreen> createState() => _AurenFamilyScreenState();
}
class _AurenFamilyScreenState extends State<AurenFamilyScreen> {
  final _repo = FamilyPotRepository();
  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _currency = 'USD';
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  @override void dispose() { _name.dispose(); _relation.dispose(); _title.dispose(); _amount.dispose(); super.dispose(); }
  Future<void> _member() async { final uid=_uid; if(uid==null)return; await _repo.addMember(uid:uid,name:_name.text,relation:_relation.text); _name.clear(); _relation.clear(); if(mounted)Navigator.pop(context); }
  Future<void> _pot() async { final uid=_uid; final amount=int.tryParse(_amount.text); if(uid==null||amount==null)return; await _repo.addPotEntry(uid:uid,title:_title.text,amountMinor:amount,currency:_currency); _title.clear(); _amount.clear(); if(mounted)Navigator.pop(context); }
  void _addMember() => showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,16+MediaQuery.viewInsetsOf(context).bottom),child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:_name,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:_relation,decoration:const InputDecoration(labelText:'صلة القرابة')),const SizedBox(height:12),FilledButton(onPressed:_member,child:const Text('حفظ'))])));
  void _addPot() => showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,16+MediaQuery.viewInsetsOf(context).bottom),child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:_title,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:_amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ بالأصغر وحدة')),DropdownButtonFormField<String>(initialValue:_currency,items:const ['USD','SDG','EUR'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>_currency=v??'USD')),const SizedBox(height:12),FilledButton(onPressed:_pot,child:const Text('حفظ'))])));
  @override Widget build(BuildContext context) {
    final uid=_uid; if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لاستخدام مساحة الأسرة.')));
    return Scaffold(appBar:AppBar(title:const Text('AUREN Family')),floatingActionButton:PopupMenuButton<String>(icon:const Icon(Icons.add_circle_outline),onSelected:(v)=>v=='member'?_addMember():_addPot(),itemBuilder:(_)=>const [PopupMenuItem(value:'member',child:Text('إضافة فرد')),PopupMenuItem(value:'pot',child:Text('إضافة للصندوق'))]),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Card(child:ListTile(leading:Icon(Icons.family_restroom),title:Text('Family Hub'),subtitle:Text('أفراد الأسرة والأهداف المشتركة وصندوق الأسرة.'))),
      const SizedBox(height:12),const Text('أفراد الأسرة',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      StreamBuilder<List<Map<String,dynamic>>>(stream:_repo.watchMembers(uid),builder:(_,s){final x=s.data??const [];if(s.hasError)return const ListTile(title:Text('تعذر تحميل أفراد الأسرة.'));if(x.isEmpty)return const ListTile(title:Text('لم تتم إضافة أفراد بعد.'));return Column(children:x.map((m)=>Card(child:ListTile(leading:const Icon(Icons.person_outline),title:Text(m['name'] as String???''),subtitle:Text(m['relation'] as String???''),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>_repo.deleteMember(uid,m['id'] as String)))).toList());}),
      const SizedBox(height:12),const Text('Family Pot',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      StreamBuilder<List<Map<String,dynamic>>>(stream:_repo.watchPot(uid),builder:(_,s){final x=s.data??const [];if(s.hasError)return const ListTile(title:Text('تعذر تحميل الصندوق.'));if(x.isEmpty)return const ListTile(title:Text('لا توجد حركات في الصندوق بعد.'));return Column(children:x.map((m)=>Card(child:ListTile(leading:const Icon(Icons.savings_outlined),title:Text(m['title'] as String???''),subtitle:Text('${m['amountMinor']??0} ${m['currency']??''}')))).toList());}),
    ]));
  }
}