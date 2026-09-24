import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/auren_work_execution.dart';
import '../../../core/models/auren_work_action.dart';
import '../../../services/agents/auren_work_agent_repository.dart';
import 'auren_work_artifacts_screen.dart';
import 'auren_work_audit_screen.dart';

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

  @override
  Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final repo=AurenWorkAgentRepository();
    return Scaffold(
      appBar:AppBar(title:const Text('AUREN Real Work Agents'),actions:[
        IconButton(tooltip:'Audit Log',icon:const Icon(Icons.history),onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AurenWorkAuditScreen()))),
        IconButton(tooltip:'Work Center',icon:const Icon(Icons.folder_special_outlined),onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AurenWorkArtifactsScreen()))),
      ]),
      body:StreamBuilder<List<AurenWorkExecution>>(
        stream:repo.watch(uid),
        builder:(context,snapshot){
          final executions=snapshot.data??const <AurenWorkExecution>[];
          return ListView(
            padding:const EdgeInsets.all(16),
            children:[
              const Card(child:Padding(
                padding:EdgeInsets.all(16),
                child:Text('طبقة التنفيذ الحقيقية: AUREN يقرأ سياق التطبيق، يحلل، يقترح إجراءً داخلياً، ثم يمر عبر Preview → موافقة صريحة → Execute → Audit. لا توجد رسائل خارجية أو نشر أو دفع تلقائي.'),
              )),
              const SizedBox(height:12),
              ...agents.map((a)=>Card(child:ListTile(
                leading:const CircleAvatar(child:Icon(Icons.auto_awesome)),
                title:Text(a['title']!),
                subtitle:Text(a['desc']!),
                trailing:const Icon(Icons.play_arrow),
                onTap:()=>_start(context,repo,a),
              ))),
              if(executions.isNotEmpty)...[
                const SizedBox(height:16),
                Text('سجل التنفيذ',style:Theme.of(context).textTheme.titleLarge),
                const SizedBox(height:8),
                ...executions.map((x)=>Card(child:ListTile(
                  title:Text(x.agentId),
                  subtitle:Text(x.status+'\n'+(x.result['summary']??x.error??x.prompt).toString(),maxLines:3,overflow:TextOverflow.ellipsis),
                  isThreeLine:true,
                  trailing:x.result['proposedActions'] is List && (x.result['proposedActions'] as List).isNotEmpty
                    ? const Icon(Icons.bolt)
                    : null,
                  onTap:()=>_details(context,repo,x),
                ))),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _start(BuildContext context,AurenWorkAgentRepository repo,Map<String,String> agent) async{
    final c=TextEditingController();
    final prompt=await showDialog<String>(
      context:context,
      builder:(d)=>AlertDialog(
        title:Text(agent['title']!),
        content:TextField(
          controller:c,maxLines:4,maxLength:4000,
          decoration:const InputDecoration(hintText:'اكتب المهمة التي تريد من الوكيل تنفيذها...'),
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(d),child:const Text('إلغاء')),
          FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('تحليل واقتراح')),
        ],
      ),
    );
    c.dispose();
    if(prompt==null||prompt.isEmpty||!context.mounted)return;
    try{
      await repo.request(agent['id']!,prompt);
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء المهمة. وافق أولاً على التحليل ثم نفّذ الإجراء المقترح.')));
    }catch(e){
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء المهمة: '+e.toString())));
    }
  }

  Future<void> _details(BuildContext context,AurenWorkAgentRepository repo,AurenWorkExecution x) async{
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return;
    await showModalBottomSheet<void>(
      context:context,isScrollControlled:true,
      builder:(sheet)=>SafeArea(
        child:Padding(
          padding:const EdgeInsets.all(20),
          child:SingleChildScrollView(
            child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(x.agentId,style:Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height:8),
              Text('الحالة: '+x.status),
              const SizedBox(height:8),
              Text(x.prompt),
              if(x.result['summary']!=null)...[
                const SizedBox(height:12),Text(x.result['summary'].toString()),
              ],
              if(x.status=='proposed')...[
                const SizedBox(height:12),
                Row(children:[
                  Expanded(child:OutlinedButton(
                    onPressed:()async{await repo.decide(x.id,'cancelled');if(sheet.mounted)Navigator.pop(sheet);},
                    child:const Text('إلغاء'),
                  )),
                  const SizedBox(width:8),
                  Expanded(child:FilledButton(
                    onPressed:()async{await repo.decide(x.id,'approved');if(sheet.mounted)Navigator.pop(sheet);},
                    child:const Text('موافقة على التحليل'),
                  )),
                ]),
              ],
              if(x.status=='approved')...[
                const SizedBox(height:12),
                SizedBox(width:double.infinity,child:FilledButton.icon(
                  onPressed:()async{await repo.execute(x.id);if(sheet.mounted)Navigator.pop(sheet);},
                  icon:const Icon(Icons.play_arrow),label:const Text('تنفيذ التحليل'),
                )),
              ],
              if(x.status=='completed')...[
                const SizedBox(height:18),
                Text('الإجراءات الداخلية المقترحة',style:Theme.of(sheet).textTheme.titleMedium),
                const SizedBox(height:6),
                StreamBuilder<List<AurenWorkAction>>(
                  stream:repo.watchActions(uid,x.id),
                  builder:(context,snapshot){
                    final actions=snapshot.data??const <AurenWorkAction>[];
                    if(actions.isEmpty)return const Text('لا توجد إجراءات قابلة للتنفيذ لهذه المهمة.');
                    return Column(children:actions.map((a)=>_actionCard(sheet,repo,a)).toList());
                  },
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _previewAndApprove(BuildContext context,AurenWorkAgentRepository repo,AurenWorkAction a) async{
    final approved=await showDialog<bool>(
      context:context,
      builder:(dialog)=>AlertDialog(
        title:Row(children:[
          const Icon(Icons.visibility_outlined),
          const SizedBox(width:8),
          Expanded(child:Text(a.title)),
        ]),
        content:SingleChildScrollView(
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(a.preview,style:Theme.of(dialog).textTheme.bodyLarge),
            const SizedBox(height:14),
            Text('المجال: '+a.domain),
            Text('نوع الإجراء: '+a.actionType),
            Text('خارج AUREN: '+(a.externalSideEffects ? 'نعم' : 'لا')),
            const SizedBox(height:12),
            const Text('البيانات التي سيحفظها AUREN:',style:TextStyle(fontWeight:FontWeight.w700)),
            const SizedBox(height:6),
            SelectableText(a.payload.isEmpty ? 'لا توجد بيانات إضافية.' : a.payload.toString()),
            const SizedBox(height:12),
            const Text('الموافقة هنا لا ترسل رسائل، ولا تنشر، ولا تدفع أموالاً. الإجراء الداخلي فقط هو الذي سينفذ.',style:TextStyle(fontSize:12)),
          ]),
        ),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('إلغاء')),
          FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('أوافق')),
        ],
      ),
    );
    if(approved==true){
      try{
        await repo.decideAction(a.id,'approved');
        if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت الموافقة. راجع الإجراء مرة أخيرة ثم نفّذه.')));
      }catch(e){
        if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ الموافقة: '+e.toString())));
      }
    }
  }

  Future<void> _confirmExecute(BuildContext context,AurenWorkAgentRepository repo,AurenWorkAction a) async{
    final confirmed=await showDialog<bool>(
      context:context,
      builder:(dialog)=>AlertDialog(
        title:const Text('تأكيد التنفيذ'),
        content:Text('سيتم الآن تنفيذ الإجراء الداخلي: '+a.title+'. لا توجد آثار خارجية مفعلة لهذا النوع.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('رجوع')),
          FilledButton.icon(onPressed:()=>Navigator.pop(dialog,true),icon:const Icon(Icons.play_arrow),label:const Text('تنفيذ الآن')),
        ],
      ),
    );
    if(confirmed!=true)return;
    try{
      await repo.executeAction(a.id);
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم التنفيذ وحفظ النتيجة في AUREN Audit.')));
    }catch(e){
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل التنفيذ: '+e.toString())));
    }
  }

  Widget _actionCard(BuildContext context,AurenWorkAgentRepository repo,AurenWorkAction a){
    return Card(
      child:Padding(
        padding:const EdgeInsets.all(12),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const Icon(Icons.bolt),
            const SizedBox(width:8),
            Expanded(child:Text(a.title,style:const TextStyle(fontWeight:FontWeight.w700))),
            Text(a.status),
          ]),
          const SizedBox(height:8),
          Text('${a.domain} • ${a.preview}'),
          const SizedBox(height:8),
          if(a.status=='proposed')Row(children:[
            Expanded(child:OutlinedButton(
              onPressed:()async{await repo.decideAction(a.id,'cancelled');},
              child:const Text('إلغاء'),
            )),
            const SizedBox(width:8),
            Expanded(child:FilledButton.icon(
              onPressed:()=>_previewAndApprove(context,repo,a),
              icon:const Icon(Icons.visibility_outlined),
              label:const Text('Preview + موافقة'),
            )),
          ]),
          if(a.status=='approved')SizedBox(
            width:double.infinity,
            child:FilledButton.icon(
              onPressed:()=>_confirmExecute(context,repo,a),
              icon:const Icon(Icons.check_circle),
              label:const Text('تنفيذ الإجراء'),
            ),
          ),
          if(a.status=='completed' && a.result!=null)...[
            const SizedBox(height:6),
            Text('تم: '+a.result.toString()),
          ],
          if(a.error!=null)...[
            const SizedBox(height:6),
            Text('خطأ: '+a.error!),
          ],
        ]),
      ),
    );
  }
}
