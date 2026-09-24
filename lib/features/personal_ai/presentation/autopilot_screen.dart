import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/autopilot_service.dart';

class AurenAutopilotScreen extends StatefulWidget {
  const AurenAutopilotScreen({super.key});
  @override State<AurenAutopilotScreen> createState()=>_AurenAutopilotScreenState();
}
class _AurenAutopilotScreenState extends State<AurenAutopilotScreen> {
  final _auth=FirebaseAurenAuthService();
  final _service=AutopilotService();
  String? _uid;
  bool _busy=false;
  @override void initState(){super.initState();_uid=_auth.currentUserId;}

  Future<void> _build() async {
    final uid=_uid;if(uid==null||_busy)return;
    setState(()=>_busy=true);
    try { await _service.build(uid); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم بناء خطة Autopilot من سياقك الحالي.'))); }
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر بناء الخطة: $e')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override Widget build(BuildContext context){
    final uid=_uid;if(uid==null)return const Scaffold(body:Center(child:Text('Sign in required.')));
    return Scaffold(appBar:AppBar(title:const Text('AUREN Autopilot')),body:StreamBuilder<AurenAutopilotPlan?>(
      stream:_service.watch(uid),builder:(context,snapshot){
        final plan=snapshot.data;
        return ListView(padding:const EdgeInsets.all(16),children:[
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Row(children:[Icon(Icons.shield_outlined),SizedBox(width:8),Expanded(child:Text('Autopilot تحت سيطرتك',style:TextStyle(fontWeight:FontWeight.bold)))]),
            const SizedBox(height:8),const Text('AUREN يجهز المسار ويقترح الخطوة التالية، ولا يتجاوز موافقتك على الإجراءات الحساسة.'),
            const SizedBox(height:12),FilledButton.icon(onPressed:_busy?null:_build,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.auto_awesome),label:const Text('ابنِ خطة الآن')),
          ]))),
          if(plan!=null)...[
            const SizedBox(height:12),
            Card(child:ListTile(leading:const Icon(Icons.flag_outlined),title:Text(plan.goal),subtitle:Text(plan.summary))),
            ...plan.steps.map((step)=>Card(child:ListTile(
              leading:CircleAvatar(child:Text('${step.order}')),
              title:Text(step.title),
              subtitle:Text('${step.action}\n${step.module} • ${step.requiresApproval?'يتطلب موافقة':'لا يحتاج موافقة مسبقة'}'),
              isThreeLine:true,
              trailing:step.requiresApproval?const Icon(Icons.lock_outline):const Icon(Icons.arrow_forward),
            ))),
            const Card(child:ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('حدود الأمان'),subtitle:Text('لا تنفيذ صامت للأموال أو الرسائل أو الصلاحيات أو أي إجراء حساس. هذه الأفعال تمر عبر Action Center.'))),
          ] else const Card(child:ListTile(title:Text('ما في خطة حالية'),subtitle:Text('اضغط ابنِ خطة الآن ليجمع AUREN السياق ويحدد المسار التالي.'))),
        ]);
      }));
  }
}