import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agriculture/livestock_management_service.dart';

class LivestockManagementScreen extends StatefulWidget {
  const LivestockManagementScreen({super.key});
  @override State<LivestockManagementScreen> createState()=>_LivestockManagementScreenState();
}

class _LivestockManagementScreenState extends State<LivestockManagementScreen> {
  final _service=LivestockManagementService();
  String _species='all';

  @override
  Widget build(BuildContext context) {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null) return const Scaffold(body:Center(child:Text('سجّل الدخول لاستخدام إدارة المواشي.')));
    return Scaffold(
      appBar:AppBar(title:const Text('AUREN Livestock AI')),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_addAnimal(context,uid),icon:const Icon(Icons.add),label:const Text('إضافة حيوان')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('إدارة القطيع',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
            const SizedBox(height:6),
            const Text('تتبّع الحيوانات، الأوزان، التغذية، التحصينات، التناسل والأحداث الصحية.'),
            const SizedBox(height:12),
            Wrap(spacing:8,children:[
              for(final e in const {'all':'الكل','cattle':'أبقار','sheep':'أغنام','goats':'ماعز','camels':'إبل','poultry':'دواجن'}.entries)
                ChoiceChip(label:Text(e.value),selected:_species==e.key,onSelected:(_)=>setState(()=>_species=e.key)),
            ]),
          ])),
          const SizedBox(height:12),
          StreamBuilder<List<LivestockAnimal>>(
            stream:_service.watchAnimals(uid,species:_species),
            builder:(context,s)=>_animals(context,uid,s.data??const []),
          ),
        ],
      ),
    );
  }

  Widget _animals(BuildContext context,String uid,List<LivestockAnimal> animals) {
    if(animals.isEmpty) return const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('لا توجد حيوانات مسجلة بعد.')));
    return Column(children:animals.map((a)=>Card(child:ListTile(
      leading:CircleAvatar(child:Icon(a.status=='deceased'?Icons.close:Icons.pets)),
      title:Text(a.tag),
      subtitle:Text([a.species,a.breed,a.sex,a.weightKg==null?'':'${a.weightKg!.toStringAsFixed(1)} kg',a.status].where((x)=>x.isNotEmpty).join(' • ')),
      trailing:const Icon(Icons.chevron_right),
      onTap:()=>_animalDetails(context,uid,a),
    ))).toList());
  }

  Future<void> _addAnimal(BuildContext context,String uid) async {
    final tag=TextEditingController(),breed=TextEditingController(),weight=TextEditingController();
    String species='cattle',sex='female';
    await showDialog<void>(context:context,builder:(dialogContext)=>StatefulBuilder(builder:(context,setLocal)=>AlertDialog(
      title:const Text('إضافة حيوان'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:tag,decoration:const InputDecoration(labelText:'الرقم / العلامة')),
        DropdownButtonFormField<String>(value:species,decoration:const InputDecoration(labelText:'النوع'),items:const [
          DropdownMenuItem(value:'cattle',child:Text('أبقار')),DropdownMenuItem(value:'sheep',child:Text('أغنام')),DropdownMenuItem(value:'goats',child:Text('ماعز')),DropdownMenuItem(value:'camels',child:Text('إبل')),DropdownMenuItem(value:'poultry',child:Text('دواجن'))],
          onChanged:(v){if(v!=null)setLocal(()=>species=v);}),
        TextField(controller:breed,decoration:const InputDecoration(labelText:'السلالة')),
        DropdownButtonFormField<String>(value:sex,decoration:const InputDecoration(labelText:'الجنس'),items:const [DropdownMenuItem(value:'female',child:Text('أنثى')),DropdownMenuItem(value:'male',child:Text('ذكر'))],onChanged:(v){if(v!=null)setLocal(()=>sex=v);}),
        TextField(controller:weight,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الوزن (كجم)')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('إلغاء')),FilledButton(onPressed:()async{
        if(tag.text.trim().isEmpty)return;
        await _service.addAnimal(uid,tag:tag.text,species:species,breed:breed.text,sex:sex,weightKg:double.tryParse(weight.text.trim()));
        if(dialogContext.mounted)Navigator.pop(dialogContext);
      },child:const Text('حفظ'))],
    )));
    tag.dispose();breed.dispose();weight.dispose();
  }

  Future<void> _animalDetails(BuildContext context,String uid,LivestockAnimal animal) async {
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(sheetContext)=>Padding(
      padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(animal.tag,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
        Text([animal.species,animal.breed,animal.sex,animal.status].where((x)=>x.isNotEmpty).join(' • ')),
        const SizedBox(height:16),
        Wrap(spacing:8,runSpacing:8,children:[
          _eventButton(sheetContext,uid,animal,'weight','⚖️ وزن','الوزن كجم'),
          _eventButton(sheetContext,uid,animal,'feeding','🌾 تغذية','نوع العلف'),
          _eventButton(sheetContext,uid,animal,'vaccination','💉 تحصين','اسم التحصين'),
          _eventButton(sheetContext,uid,animal,'breeding','❤️ تناسل','المعلومة'),
          _eventButton(sheetContext,uid,animal,'observation','📝 ملاحظة','المعلومة'),
        ]),
        const SizedBox(height:12),
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream:_service.watchEvents(uid,animal.id),
          builder:(context,s)=>Column(children:(s.data?.docs??const []).take(8).map((d)=>ListTile(dense:true,title:Text('${d.data()['type'] ?? ''}'),subtitle:Text('${d.data()['data'] ?? ''}'))).toList()),
        ),
      ]),
    ));
  }

  Widget _eventButton(BuildContext context,String uid,LivestockAnimal animal,String type,String label,String hint)=>OutlinedButton(
    onPressed:()=>_recordEvent(context,uid,animal,type,label,hint),child:Text(label));

  Future<void> _recordEvent(BuildContext context,String uid,LivestockAnimal animal,String type,String label,String hint) async {
    final c=TextEditingController();
    await showDialog<void>(context:context,builder:(dialogContext)=>AlertDialog(
      title:Text(label),content:TextField(controller:c,keyboardType:type=='weight'?const TextInputType.numberWithOptions(decimal:true):null,decoration:InputDecoration(hintText:hint)),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('إلغاء')),FilledButton(onPressed:()async{
        if(c.text.trim().isEmpty)return;
        await _service.recordEvent(uid,animalId:animal.id,type:type,data:{type=='weight'?'weightKg':'value':type=='weight'?double.tryParse(c.text.trim()):c.text.trim()});
        if(dialogContext.mounted)Navigator.pop(dialogContext);
      },child:const Text('حفظ'))],
    ));
    c.dispose();
  }
}
