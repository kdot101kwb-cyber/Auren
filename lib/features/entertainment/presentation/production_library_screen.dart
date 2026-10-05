import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/entertainment/production_lifecycle_service.dart';

class ProductionLibraryScreen extends StatefulWidget { const ProductionLibraryScreen({super.key}); @override State<ProductionLibraryScreen> createState()=>_ProductionLibraryScreenState(); }
class _ProductionLibraryScreenState extends State<ProductionLibraryScreen> with SingleTickerProviderStateMixin {
 late final TabController _tabs=TabController(length:2,vsync:this); final _service=ProductionLifecycleService(); String? _busyTask;
 @override void dispose(){_tabs.dispose();super.dispose();}
 String _status(String value){const labels={'generation':'قيد الإنشاء','provider_pending':'بانتظار المزود','processing':'معالجة','waiting_provider':'بانتظار المزود','poll_backoff':'إعادة المحاولة تلقائياً','submit_backoff':'إعادة الإرسال تلقائياً','stale_lock_recovered':'تم تحرير العملية العالقة','output':'جاهز','completed':'مكتمل','failed':'فشل','cancelled':'ملغى'};return labels[value]??value;}
 Future<void> _act(String path,bool cancel) async {
  final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
    title:Text(cancel?'إلغاء الإنتاج':'إعادة الإنتاج'),
    content:Text(cancel?'هل تريد إلغاء عملية الإنتاج الحالية؟':'هل تريد بدء محاولة جديدة لهذه العملية؟'),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('لا')),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(cancel?'إلغاء':'إعادة المحاولة')),
    ],
  ))??false;
  if(!ok)return;setState(()=>_busyTask=path);try{if(cancel){await _service.cancel(path);}else{await _service.retry(path);}if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(cancel?'تم إلغاء الإنتاج':'تمت إعادة المحاولة')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التنفيذ: $e')));}finally{if(mounted)setState(()=>_busyTask=null);}}
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('يجب تسجيل الدخول.')));return Scaffold(appBar:AppBar(title:const Text('Production Library'),bottom:TabBar(controller:_tabs,tabs:const[Tab(text:'History'),Tab(text:'Outputs')])),body:TabBarView(controller:_tabs,children:[
 StreamBuilder<List<Map<String,dynamic>>>(stream:_service.watchHistory(uid),builder:(context,snap){if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final items=snap.data??const[];if(items.isEmpty)return const Center(child:Text('لا توجد عمليات إنتاج بعد.'));return ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final x=items[i];final path=x['taskPath']?.toString();final status=x['status']?.toString()??'';final busy=path!=null&&_busyTask==path;return Card(child:ListTile(title:Text(x['title']?.toString()??'Production'),subtitle:Text(_status(status)+' • '+(x['event']?.toString()??'')),trailing:Row(mainAxisSize:MainAxisSize.min,children:[if(['generation','provider_pending','processing','waiting_provider','poll_backoff','submit_backoff'].contains(status)&&path!=null)IconButton(onPressed:busy?null:()=>_act(path,true),icon:const Icon(Icons.close)),if(['failed','cancelled','waiting_provider'].contains(status)&&path!=null)IconButton(onPressed:busy?null:()=>_act(path,false),icon:const Icon(Icons.refresh))])));});}),
 StreamBuilder<List<Map<String,dynamic>>>(stream:_service.watchOutputs(uid),builder:(context,snap){if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final items=snap.data??const[];if(items.isEmpty)return const Center(child:Text('مكتبة النتائج فارغة.'));return ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final x=items[i];final out=Map<String,dynamic>.from(x['output']??{});final ref=(out['url']??out['storagePath']??out['externalId']??'').toString();return Card(child:ListTile(leading:const Icon(Icons.video_library_outlined),title:Text(x['title']?.toString()??'Output'),subtitle:Text(x['type']?.toString()??'production'),trailing:IconButton(icon:const Icon(Icons.open_in_new),onPressed:ref.isEmpty?null:() async {final uri=Uri.tryParse(ref);if(uri!=null&&await canLaunchUrl(uri)){await launchUrl(uri,mode:LaunchMode.externalApplication);}})));});})
]) ); }
}
