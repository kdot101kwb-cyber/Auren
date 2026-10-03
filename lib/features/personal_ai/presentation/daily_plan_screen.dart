import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/daily_plan_service.dart';

class AurenDailyPlanScreen extends StatefulWidget{
  const AurenDailyPlanScreen({super.key});
  @override State<AurenDailyPlanScreen> createState()=>_AurenDailyPlanScreenState();
}

class _AurenDailyPlanScreenState extends State<AurenDailyPlanScreen>{
  final _auth=FirebaseAurenAuthService();
  final _service=DailyPlanService();
  AurenDailyPlan? _plan;
  bool _loading=false;

  Future<void> _build()async{
    final uid=_auth.currentUserId;
    if(uid==null)return;
    setState(()=>_loading=true);
    try{
      final p=await _service.build(uid);
      if(mounted)setState(()=>_plan=p);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر بناء خطة اليوم: $e')));
    }finally{
      if(mounted)setState(()=>_loading=false);
    }
  }

  @override Widget build(BuildContext context){
    final uid=_auth.currentUserId;
    return Scaffold(
      appBar:AppBar(title:const Text('Daily Plan')),
      body:ListView(
        padding:const EdgeInsets.all(20),
        children:[
          const Text('خطة اليوم مع AUREN',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          const Text('خطة صغيرة مرتبطة بهدفك، ويمكنك تعليم كل خطوة كمكتملة.'),
          const SizedBox(height:20),
          FilledButton.icon(onPressed:_loading?null:_build,icon:const Icon(Icons.today),label:Text(_loading?'جاري البناء…':'ابنِ خطة اليوم')),
          if(uid!=null)...[
            const SizedBox(height:20),
            StreamBuilder<List<DailyPlanTask>>(
              stream:_service.watchTasks(uid),
              builder:(context,snapshot){
                if(snapshot.hasError)return const Card(child:ListTile(leading:Icon(Icons.error_outline),title:Text('تعذر تحميل المهام'),subtitle:Text('حاول مرة أخرى.')));
                final tasks=snapshot.data??const <DailyPlanTask>[];
                if(tasks.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('لا توجد مهام اليوم بعد. ابنِ خطة اليوم للبدء.')));
                final done=tasks.where((t)=>t.completed).length;
                return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('تقدم اليوم: $done/${tasks.length}',style:const TextStyle(fontWeight:FontWeight.bold)),
                  const SizedBox(height:8),
                  LinearProgressIndicator(value:done/tasks.length),
                  const SizedBox(height:8),
                  ...tasks.map((task)=>CheckboxListTile(
                    value:task.completed,
                    contentPadding:EdgeInsets.zero,
                    title:Text(task.title),
                    secondary:CircleAvatar(radius:15,child:Text('${task.order+1}')),
                    onChanged:(value)=>_service.setTaskCompleted(uid,task.id,value==true),
                  )),
                ])));
              },
            ),
          ],
          if(_plan!=null)...[
            const SizedBox(height:20),
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(_plan!.goalTitle,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
              const SizedBox(height:8),
              Text(_plan!.focus),
            ]))),
          ],
        ],
      ),
    );
  }
}