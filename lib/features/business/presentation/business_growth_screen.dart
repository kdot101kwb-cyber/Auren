import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_growth_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenBusinessGrowthScreen extends StatefulWidget{
 final AurenBusiness business; const AurenBusinessGrowthScreen({super.key,required this.business});
 @override State<AurenBusinessGrowthScreen> createState()=>_AurenBusinessGrowthScreenState();
}
class _AurenBusinessGrowthScreenState extends State<AurenBusinessGrowthScreen>{
 final service=AurenGrowthService();
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Business Growth & Outreach'),actions:[IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'حلّل نشاط '+widget.business.name+' وابنِ خطة نمو تشمل العملاء، التسويق، الشراكات والتوسع.'))))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 Card(child:ListTile(leading:const Icon(Icons.trending_up),title:Text(widget.business.name),subtitle:const Text('Growth Engine • Outreach • Campaigns'))),
 Row(children:[Expanded(child:_action('خطة نمو',Icons.insights_outlined,'حلّل نشاطي وابنِ خطة نمو من 30 يوماً')),Expanded(child:_action('عملاء',Icons.people_alt_outlined,'حدّد لي شرائح العملاء المناسبة وكيف أصل إليها'))]),
 const SizedBox(height:8),
 Row(children:[Expanded(child:_action('حملة',Icons.campaign_outlined,'اكتب حملة تسويقية كاملة لهذا النشاط')),Expanded(child:_action('شراكات',Icons.handshake_outlined,'اقترح أنواع شركاء يمكن أن ينمو معهم النشاط'))]),
 const SizedBox(height:18),const Text('Campaigns',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),
 StreamBuilder<List<Map<String,dynamic>>>(stream:service.watchCampaigns(widget.business.id),builder:(context,s){
   if(s.hasError)return Text('تعذر تحميل الحملات: ${s.error}');
   final items=s.data??const [];
   if(items.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('لا توجد حملات بعد. أنشئ أول حملة من الزر أدناه.')));
   return Column(children:items.map((c)=>Card(child:ListTile(title:Text(c['name']?.toString()??''),subtitle:Text((c['channel']?.toString()??'')+' • '+(c['status']?.toString()??'draft')),trailing:PopupMenuButton<String>(onSelected:(v)=>service.updateCampaignStatus(businessId:widget.business.id,campaignId:c['id'].toString(),status:v),itemBuilder:(_)=>const[PopupMenuItem(value:'active',child:Text('تشغيل')),PopupMenuItem(value:'paused',child:Text('إيقاف مؤقت')),PopupMenuItem(value:'completed',child:Text('إكمال'))])))).toList());
 }),
 const SizedBox(height:12),FilledButton.icon(onPressed:()=>_newCampaign(context),icon:const Icon(Icons.add),label:const Text('إنشاء حملة')),
 ]);
 Widget _action(String title,IconData icon,String prompt)=>Padding(padding:const EdgeInsets.all(4),child:OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt+' لنشاط '+widget.business.name))),icon:Icon(icon),label:Text(title)));
 Future<void> _newCampaign(BuildContext context)async{
   final n=TextEditingController(),g=TextEditingController(),a=TextEditingController(),m=TextEditingController();String channel='Social';
   final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('حملة جديدة'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'اسم الحملة')),TextField(controller:g,decoration:const InputDecoration(labelText:'الهدف')),TextField(controller:a,decoration:const InputDecoration(labelText:'الجمهور')),DropdownButtonFormField<String>(value:channel,items:const['Social','Messenger','Email','Community','Creator'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>channel=v!,decoration:const InputDecoration(labelText:'القناة')),TextField(controller:m,maxLines:4,decoration:const InputDecoration(labelText:'الرسالة'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]));
   if(ok!=true)return;final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;
   try{await service.createCampaign(businessId:widget.business.id,ownerId:uid,name:n.text,goal:g.text,audience:a.text,channel:channel,message:m.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء الحملة كمسودة.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء الحملة: $e')));}
   n.dispose();g.dispose();a.dispose();m.dispose();
 }
}
