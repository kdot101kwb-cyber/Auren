import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/auren_work_execution.dart';
import '../../../services/agents/auren_work_agent_repository.dart';

class AurenRealWorkAgentsScreen extends StatelessWidget {
  const AurenRealWorkAgentsScreen({super.key});
  static const agents=<Map<String,String>>[
    {'id':'Personal AI Agent','title':'Personal AI','desc':'حوّل أهدافك وبياناتك إلى خطوات عملية.'},
    {'id':'Talent Discovery Agent','title':'Talent Discovery','desc':'اكتشف مسارات وفرصاً مناسبة لملفك.'},
    {'id':'Opportunity Match Agent','title':'Opportunity Match','desc':'حلل التطابق بين مهاراتك والفرص.'},
    {'id':'Skill Coach Agent','title':'Skill Coach','desc':'اربط المهارات بالأهداف والفرص.'},
    {'id':'Business Growth Agent','title':'Business Growth','desc':'حلل أصول نشاطك وابنِ خطة نمو.'},
    {'id':'Supplier & Export Agent','title':'Supplier & Export','desc':'قيّم جاهزية المنتجات والتجارة والتصدير.'},
    {'id':'Creator Studio Agent','title':'Creator Studio','desc':'حوّل أصولك الإبداعية إلى خطة محتوى.'},
    {'id':'Campaign Agent','title':'Campaign','desc':'جهّز حملة بدون إطلاق أو إنفاق تلقائي.'},
    {'id':'Partnership Agent','title':'Partnership','desc':'ابنِ خريطة شراكات ورسائل تواصل.'},
    {'id':'Market Intelligence Agent','title':'Market Intelligence','desc':'نظّم البحث والأدلة والخيارات.'},
    {'id':'Travel Agent','title':'Travel','desc':'حلل بيانات السفر وابنِ قالب رحلة.'},
    {'id':'Home & Life Agent','title':'Home & Life','desc':'نظّم أهدافك ومهامك اليومية.'},
  ];

  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final repo=AurenWorkAgentRepository();
    return Scaffold(appBar:AppBar(title:const Text('AUREN Real Work Agents')),body:StreamBuilder<List<AurenWorkExecution>>(
      stream:repo.watch(uid),builder:(context,snapshot){
        final executions=snapshot.data??const <AurenWorkExecution>[];
        return ListView(padding:const EdgeInsets.all(16),children:[
          const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('تشغيل حقيقي داخل AUREN: يقرأ سياق التطبيق، يحلل ويولد نتيجة قابلة للتنفيذ. لا توجد رسائل خارجية أو مدفوعات أو إجراءات حساسة بدون موافقة صريحة.'))),
          const SizedBox(height:12),
          ...agents.map((a)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.auto_awesome)),title:Text(a['title']!),subtitle:Text(a['desc']!),trailing:const Icon(Icons.play_arrow),onTap:()=>_start(context,repo,a)))),
          if(executions.isNotEmpty) ...[
            const SizedBox(height:16),Text('سجل التنفيذ',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),
            ...executions.map((x)=>Card(child:ListTile(title:Text(x.agentId),subtitle:Text(x.status+'\\n'+(x.result['summary']??x.error??x.prompt).toString()),isThreeLine:true,onTap:()=>_details(context,repo,x))))
          ],
        ]);
      }));
  }

  Future<void> _start(BuildContext context,AurenWorkAgentRepository repo,Map<String,String> agent) async{
    final c=TextEditingController();
    final prompt=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:Text(agent['title']!),content:TextField(controller:c,maxLines:4,maxLength:4000,decoration:const InputDecoration(hintText:'اكتب المهمة التي تريد من الوكيل تنفيذها...')),actions:[
      TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),
      FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('اقتراح المهمة'))]));
    c.dispose(); if(prompt==null||prompt.isEmpty||!context.mounted)return;
    try{final id=await repo.request(agent['id']!,prompt);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء المهمة. راجعها في سجل التنفيذ ثم وافق.')));}
    catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء المهمة: '+e.toString())));}
  }

  Future<void> _details(BuildContext context,AurenWorkAgentRepository repo,AurenWorkExecution x) async{
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(x.agentId,style:Theme.of(sheet).textTheme.titleLarge),const SizedBox(height:8),Text('الحالة: '+x.status),const SizedBox(height:8),Text(x.prompt),
      if(x.result.isNotEmpty)...[const SizedBox(height:12),Text(x.result.entries.map((v)=>v.key+': '+v.value.toString()).join('\\n'))],
      if(x.status=='proposed')...[
        const SizedBox(height:12),Row(children:[
          Expanded(child:OutlinedButton(onPressed:()async{await repo.decide(x.id,'cancelled');if(sheet.mounted)Navigator.pop(sheet);},child:const Text('إلغاء'))),
          const SizedBox(width:8),Expanded(child:FilledButton(onPressed:()async{await repo.decide(x.id,'approved');if(sheet.mounted)Navigator.pop(sheet);},child:const Text('موافقة')))
        ])],
      if(x.status=='approved')...[
        const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()async{await repo.execute(x.id);if(sheet.mounted)Navigator.pop(sheet);},icon:const Icon(Icons.play_arrow),label:const Text('تنفيذ')))
      ],
    ]))));
  }
}