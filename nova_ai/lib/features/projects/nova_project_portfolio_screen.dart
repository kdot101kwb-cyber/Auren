import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../firebase_runtime.dart';
import '../debate/nova_debate_screen.dart';

class NovaProjectPortfolioScreen extends StatefulWidget {
  const NovaProjectPortfolioScreen({super.key});
  @override
  State<NovaProjectPortfolioScreen> createState() => _NovaProjectPortfolioScreenState();
}

class _NovaProjectPortfolioScreenState extends State<NovaProjectPortfolioScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final workTitle = TextEditingController();
  final workDescription = TextEditingController();
  final areas = const {'personal':'شخصي','auren':'AUREN','nova':'NOVA','income':'الدخل والاستثمار','content':'المحتوى','research':'البحث','operations':'التشغيل','other':'أخرى'};
  final priorities = const {'low':'منخفضة','normal':'عادية','high':'عالية','critical':'حرجة'};
  final projectStates = const {'idea':'فكرة','active':'نشط','paused':'متوقف مؤقتاً','deferred':'مؤجل','cancelled':'ملغى','completed':'مكتمل'};
  final workStates = const {'backlog':'قائمة الانتظار','planned':'مخطط','in_progress':'قيد العمل','blocked':'متعطل','deferred':'مؤجل','cancelled':'ملغى','completed':'مكتمل'};
  String area = 'nova';
  String priority = 'normal';
  String? selectedId;
  List<Map<String,dynamic>> projects = [];
  List<Map<String,dynamic>> workItems = [];
  bool busy = false;
  String? message;

  FirebaseFunctions get functions => FirebaseFunctions.instanceFor(region:'us-central1');

  @override
  void initState() { super.initState(); loadProjects(); }
  @override
  void dispose() { title.dispose(); description.dispose(); workTitle.dispose(); workDescription.dispose(); super.dispose(); }

  Future<void> ensureOwner() async {
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      throw StateError(NovaFirebaseRuntime.initializationError ?? 'يلزم إعداد Firebase وApp Check.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      throw StateError('سجّل الدخول بالحساب الدائم الموثق لمالك NOVA.');
    }
    final token = await user.getIdTokenResult(true);
    if (token.claims?['novaOwner'] != true) throw StateError('هذا الحساب لا يحمل صلاحية مالك NOVA.');
  }

  String safeError(Object error) {
    if (error is FirebaseFunctionsException) return error.message ?? 'تعذر تنفيذ الطلب (${error.code}).';
    if (error is StateError) return error.message.toString();
    return 'تعذر الاتصال بخدمات NOVA. تحقق من الاتصال ثم أعد المحاولة.';
  }

  Future<void> loadProjects() async {
    setState(() { busy=true; message=null; });
    try {
      await ensureOwner();
      final response = await functions.httpsCallable('listNovaProjects').call({'limit':50});
      final data = Map<String,dynamic>.from(response.data as Map);
      final rows = (data['projects'] as List? ?? const []).map((v)=>Map<String,dynamic>.from(v as Map)).toList();
      if (!mounted) return;
      setState(() {
        projects=rows;
        if (selectedId != null && !rows.any((p)=>p['projectId']==selectedId)) { selectedId=null; workItems=[]; }
        message='تم تحديث محفظة المشاريع.';
      });
      if (selectedId != null) await loadWorkItems(selectedId!);
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
    finally { if (mounted) setState(()=>busy=false); }
  }

  Future<void> createProject() async {
    if (title.text.trim().isEmpty || busy) { setState(()=>message='اكتب اسم المشروع.'); return; }
    setState(()=>busy=true);
    try {
      await ensureOwner();
      final response = await functions.httpsCallable('createNovaProject').call({
        'title':title.text.trim(),'description':description.text.trim(),'area':area,'priority':priority,
      });
      final data=Map<String,dynamic>.from(response.data as Map);
      title.clear(); description.clear();
      if (mounted) setState(()=>message='سُجل المشروع كفكرة. درجة الأولوية: ${data['priorityScore']}. لم يبدأ التنفيذ.');
      await loadProjects();
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
    finally { if (mounted) setState(()=>busy=false); }
  }

  Future<void> loadWorkItems(String id) async {
    try {
      await ensureOwner();
      final response=await functions.httpsCallable('listNovaProjectWorkItems').call({'projectId':id});
      final data=Map<String,dynamic>.from(response.data as Map);
      if (mounted && selectedId==id) setState(()=>workItems=(data['workItems'] as List? ?? const []).map((v)=>Map<String,dynamic>.from(v as Map)).toList());
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
  }

  Future<String?> askReason(String titleText) async {
    final controller=TextEditingController();
    final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(titleText,textDirection:TextDirection.rtl),
      content:TextField(controller:controller,autofocus:true,minLines:2,maxLines:4,textDirection:TextDirection.rtl,decoration:const InputDecoration(hintText:'اكتب السبب أو الدليل',border:OutlineInputBorder())),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:const Text('تأكيد'))],
    ));
    controller.dispose();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> changeProject(Map<String,dynamic> project,String next) async {
    final needsReason=['paused','deferred','cancelled','completed'].contains(next);
    final reason=needsReason?await askReason('سبب ${projectStates[next]} المشروع'):'';
    if (needsReason && (reason==null || reason.isEmpty)) return;
    setState(()=>busy=true);
    try {
      await ensureOwner();
      await functions.httpsCallable('updateNovaProjectStatus').call({'projectId':project['projectId'],'status':next,'decisionNote':reason ?? ''});
      if (mounted) setState(()=>message='تم تحديث حالة المشروع.');
      await loadProjects();
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
    finally { if (mounted) setState(()=>busy=false); }
  }

  void openCouncil(Map<String,dynamic> project) {
    final promptText='راجع مشروع ${project['title']}، وناقش هل نبدأ أو نؤجل أو نعيد تصميمه. لا تفترض أن المشروع معتمد للتنفيذ.';
    final contextText=[
      'Project ID: ${project['projectId']}',
      'Area: ${project['area']}',
      'Current status: ${project['status']}',
      'Priority: ${project['priority']}',
      'Priority score: ${project['priorityScore']}/100',
      'Description: ${project['description'] ?? ''}',
      'Owner decision is required for every lifecycle change. Debate approval must not start execution.',
    ].join('\n');
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>NovaDebateScreen(initialPrompt:promptText,initialContext:contextText),
    ));
  }

  Future<void> editPriority(Map<String,dynamic> project) async {
    var strategicValue=(project['strategicValue'] as num?)?.toInt() ?? 3;
    var urgency=(project['urgency'] as num?)?.toInt() ?? 3;
    var confidence=(project['confidence'] as num?)?.toInt() ?? 3;
    var effort=(project['effort'] as num?)?.toInt() ?? 3;
    var selectedPriority='${project['priority'] ?? 'normal'}';
    final accepted=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>AlertDialog(
      title:const Text('تقييم أولوية المشروع'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        _prioritySlider('القيمة الاستراتيجية',strategicValue,(v)=>refresh(()=>strategicValue=v)),
        _prioritySlider('الاستعجال',urgency,(v)=>refresh(()=>urgency=v)),
        _prioritySlider('الثقة في النجاح',confidence,(v)=>refresh(()=>confidence=v)),
        _prioritySlider('الجهد المطلوب',effort,(v)=>refresh(()=>effort=v)),
        DropdownButtonFormField<String>(
          initialValue:selectedPriority,
          decoration:const InputDecoration(labelText:'تصنيف الأولوية'),
          items:priorities.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),
          onChanged:(v)=>refresh(()=>selectedPriority=v ?? 'normal'),
        ),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ التقييم')),
      ],
    )));
    if (accepted!=true || !mounted) return;
    setState(()=>busy=true);
    try {
      await ensureOwner();
      final response=await functions.httpsCallable('updateNovaProjectPriority').call({
        'projectId':project['projectId'],
        'strategicValue':strategicValue,'urgency':urgency,'confidence':confidence,
        'effort':effort,'priority':selectedPriority,
      });
      final data=Map<String,dynamic>.from(response.data as Map);
      if (mounted) setState(()=>message='تم تحديث التقييم. درجة الأولوية: ${data['priorityScore']}/100.');
      await loadProjects();
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
    finally { if (mounted) setState(()=>busy=false); }
  }

  Widget _prioritySlider(String label,int value,ValueChanged<int> onChanged)=>Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(label)),Text('$value/5')]),
      Slider(value:value.toDouble(),min:1,max:5,divisions:4,onChanged:(v)=>onChanged(v.round())),
    ],
  );

  Future<void> addWorkItem() async {
    if (selectedId==null || workTitle.text.trim().isEmpty || busy) return;
    setState(()=>busy=true);
    try {
      await ensureOwner();
      await functions.httpsCallable('addNovaProjectWorkItem').call({
        'projectId':selectedId,'title':workTitle.text.trim(),'description':workDescription.text.trim(),'requiresOwnerApproval':true,
      });
      workTitle.clear(); workDescription.clear();
      if (mounted) setState(()=>message='أضيفت المهمة إلى قائمة الانتظار؛ لم يبدأ تنفيذها.');
      await loadWorkItems(selectedId!);
      await loadProjects();
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
    finally { if (mounted) setState(()=>busy=false); }
  }

  Future<void> changeWork(Map<String,dynamic> item,String next) async {
    final needsReason=['blocked','deferred','cancelled','completed'].contains(next);
    final reason=needsReason?await askReason('سبب أو دليل: ${workStates[next]}'):'';
    if (needsReason && (reason==null || reason.isEmpty)) return;
    final id=selectedId;
    if (id==null) return;
    setState(()=>busy=true);
    try {
      await ensureOwner();
      await functions.httpsCallable('updateNovaProjectWorkItem').call({
        'projectId':id,'workItemId':item['workItemId'],'status':next,'decisionNote':reason ?? '',
      });
      if (mounted) setState(()=>message='تم تحديث حالة المهمة.');
      await loadWorkItems(id);
      await loadProjects();
    } catch (error) { if (mounted) setState(()=>message=safeError(error)); }
    finally { if (mounted) setState(()=>busy=false); }
  }

  List<String> projectTransitions(String state)=>switch(state) {
    'idea'=>['active','deferred','cancelled'],
    'active'=>['paused','deferred','cancelled','completed'],
    'paused'=>['active','deferred','cancelled'],
    'deferred'=>['idea','active','cancelled'],
    _=>const[],
  };
  List<String> workTransitions(String state)=>switch(state) {
    'backlog'=>['planned','in_progress','deferred','cancelled'],
    'planned'=>['in_progress','blocked','deferred','cancelled'],
    'in_progress'=>['blocked','deferred','cancelled','completed'],
    'blocked'=>['planned','in_progress','deferred','cancelled'],
    'deferred'=>['planned','cancelled'],
    _=>const[],
  };

  @override
  Widget build(BuildContext context) {
    Map<String,dynamic>? selected;
    for (final project in projects) {
      if (project['projectId']==selectedId) { selected=project; break; }
    }
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('محفظة مشاريع NOVA',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      const Text('إدارة مشاريع NOVA وAUREN والدخل والمحتوى والبحث. الترتيب استرشادي والقرار النهائي لك.'),
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('مشروع جديد',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        TextField(controller:title,textDirection:TextDirection.rtl,decoration:const InputDecoration(labelText:'اسم المشروع')),
        TextField(controller:description,minLines:2,maxLines:3,textDirection:TextDirection.rtl,decoration:const InputDecoration(labelText:'الوصف والنتيجة المطلوبة')),
        DropdownButtonFormField<String>(initialValue:area,decoration:const InputDecoration(labelText:'المجال'),items:areas.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),onChanged:(v)=>setState(()=>area=v ?? 'other')),
        DropdownButtonFormField<String>(initialValue:priority,decoration:const InputDecoration(labelText:'الأولوية الأولية'),items:priorities.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),onChanged:(v)=>setState(()=>priority=v ?? 'normal')),
        const SizedBox(height:8),
        SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy?null:createProject,icon:const Icon(Icons.add),label:const Text('إضافة كفكرة — دون تنفيذ'))),
      ]))),
      Row(children:[const Expanded(child:Text('ترتيب المشاريع حسب الأولوية',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold))),IconButton(onPressed:busy?null:loadProjects,icon:const Icon(Icons.refresh))]),
      if (projects.isEmpty) const Text('لا توجد مشاريع مسجلة بعد.'),
      for (final project in projects) Card(child:InkWell(
        onTap:()=>setState((){selectedId='${project['projectId']}';workItems=[];loadWorkItems(selectedId!);}),
        child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text('${project['title']}',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold))),Text('${project['priorityScore']}/100',style:const TextStyle(fontWeight:FontWeight.bold))]),
          Text('${areas[project['area']] ?? project['area']} • ${priorities[project['priority']] ?? project['priority']} • ${projectStates[project['status']] ?? project['status']}'),
          if (project['description']!=null && '${project['description']}'.isNotEmpty) Text('${project['description']}',maxLines:2,overflow:TextOverflow.ellipsis,textDirection:TextDirection.rtl),
          Row(children:[
            TextButton(onPressed:busy?null:()=>editPriority(project),child:const Text('تقييم الأولوية')),
            TextButton.icon(onPressed:()=>openCouncil(project),icon:const Icon(Icons.balance),label:const Text('ناقش')),
            const Spacer(),
            PopupMenuButton<String>(enabled:!busy && projectTransitions('${project['status']}').isNotEmpty,onSelected:(s)=>changeProject(project,s),itemBuilder:(ctx)=>projectTransitions('${project['status']}').map((s)=>PopupMenuItem(value:s,child:Text(projectStates[s] ?? s))).toList()),
          ]),
          if (selectedId==project['projectId']) const Text('المشروع المحدد',style:TextStyle(color:Colors.deepPurpleAccent)),
        ])),
      )),
      if (selected!=null) ...[
        Text('قائمة أعمال: ${selected['title']}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        TextField(controller:workTitle,textDirection:TextDirection.rtl,decoration:const InputDecoration(labelText:'مهمة جديدة')),
        TextField(controller:workDescription,textDirection:TextDirection.rtl,decoration:const InputDecoration(labelText:'تفاصيل (اختياري)')),
        OutlinedButton.icon(onPressed:busy?null:addWorkItem,icon:const Icon(Icons.playlist_add),label:const Text('إضافة مهمة')),
        if (workItems.isEmpty) const Text('لا توجد مهام في هذا المشروع بعد.'),
        for (final item in workItems) Card(child:ListTile(
          title:Text('${item['title']}',textDirection:TextDirection.rtl),
          subtitle:Text(workStates[item['status']] ?? '${item['status']}',textDirection:TextDirection.rtl),
          trailing:PopupMenuButton<String>(enabled:!busy && workTransitions('${item['status']}').isNotEmpty,onSelected:(s)=>changeWork(item,s),itemBuilder:(ctx)=>workTransitions('${item['status']}').map((s)=>PopupMenuItem(value:s,child:Text(workStates[s] ?? s))).toList()),
        )),
      ],
      if (message!=null) Padding(padding:const EdgeInsets.all(12),child:Text(message!,textDirection:TextDirection.rtl)),
      if (busy) const Center(child:Padding(padding:EdgeInsets.all(12),child:CircularProgressIndicator())),
    ]);
  }
}
