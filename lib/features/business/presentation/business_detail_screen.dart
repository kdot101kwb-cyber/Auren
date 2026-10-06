import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'business_dashboard_screen.dart';
import 'business_products_screen.dart';

class AurenBusinessDetailScreen extends StatefulWidget {
  final AurenBusiness business;
  const AurenBusinessDetailScreen({super.key, required this.business});
  @override State<AurenBusinessDetailScreen> createState() => _AurenBusinessDetailScreenState();
}

class _AurenBusinessDetailScreenState extends State<AurenBusinessDetailScreen> {
  bool saving = false;
  final _repo = BusinessRepository();
  @override void initState(){super.initState();final uid=FirebaseAuth.instance.currentUser?.uid;if(uid!=null&&!widget.business.ownerId.isEmpty){_repo.recordEvent(business:widget.business,viewerUid:uid,type:'view');}}
  Future<void> edit() async {
    final n=TextEditingController(text:widget.business.name);
    final d=TextEditingController(text:widget.business.description);
    final city=TextEditingController(text:widget.business.city);
    final country=TextEditingController(text:widget.business.country);
    final phone=TextEditingController(text:widget.business.phone);
    final web=TextEditingController(text:widget.business.website);
    final img=TextEditingController(text:widget.business.imageUrl);
    String cat=widget.business.category; String type=widget.business.businessType; String status=widget.business.status;
    const types=['Company','Store','Restaurant','Freelancer','Service Provider','Factory','Farm','Creator Business','NGO/Organization']; const statuses=['active','temporarily_closed','permanently_closed','suspended'];
    final cats=['Retail','Food','Services','Technology','Manufacturing','Education','Travel','Creative','Agriculture','Other'];
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>Padding(
      padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),
      child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('تعديل Business',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        TextField(controller:n,decoration:const InputDecoration(labelText:'اسم النشاط')),
        TextField(controller:d,maxLines:3,decoration:const InputDecoration(labelText:'الوصف')),
        DropdownButtonFormField<String>(initialValue:cat,items:cats.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setModal(()=>cat=v!),decoration:const InputDecoration(labelText:'التصنيف')),DropdownButtonFormField<String>(initialValue:types.contains(type)?type:types.first,items:types.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setModal(()=>type=v!),decoration:const InputDecoration(labelText:'نوع النشاط')),DropdownButtonFormField<String>(initialValue:statuses.contains(status)?status:statuses.first,items:statuses.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setModal(()=>status=v!),decoration:const InputDecoration(labelText:'الحالة')),
        TextField(controller:city,decoration:const InputDecoration(labelText:'المدينة')),
        TextField(controller:country,decoration:const InputDecoration(labelText:'الدولة')),
        TextField(controller:phone,decoration:const InputDecoration(labelText:'الهاتف')),
        TextField(controller:web,decoration:const InputDecoration(labelText:'الموقع الإلكتروني')),
        TextField(controller:img,decoration:const InputDecoration(labelText:'رابط الصورة')),
        const SizedBox(height:16),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ التعديلات')),
      ])),
    )));
    for(final c in [n,d,city,country,phone,web,img]) c.dispose();
    if(ok!=true)return;
    setState(()=>saving=true);
    try {
      await BusinessRepository().update(id:widget.business.id,name:n.text,description:d.text,category:cat,city:city.text,country:country.text,phone:phone.text,website:web.text,imageUrl:img.text,businessType:type,status:status);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تحديث Business')));
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التحديث: $e'))); }
    finally { if(mounted)setState(()=>saving=false); }
  }

  @override Widget build(BuildContext context) {
    final b=widget.business; final own=FirebaseAuth.instance.currentUser?.uid==b.ownerId;
    return Scaffold(
      appBar:AppBar(title:const Text('Business'),actions:[
        if(own) IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenBusinessDashboardScreen(business:b))),icon:const Icon(Icons.analytics_outlined)),
        if(own) IconButton(onPressed:saving?null:edit,icon:const Icon(Icons.edit_outlined)),
        if(own) IconButton(onPressed:()async{final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('حذف النشاط؟'),content:const Text('لا يمكن التراجع عن هذا الإجراء.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حذف'))]));if(ok==true){await BusinessRepository().delete(b.id);if(context.mounted)Navigator.pop(context);}},icon:const Icon(Icons.delete_outline))
      ]),
      body:ListView(padding:const EdgeInsets.all(20),children:[
        if(b.imageUrl.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.network(b.imageUrl,height:220,fit:BoxFit.cover)),
        const SizedBox(height:16),
        Row(children:[Expanded(child:Text(b.name,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold))),if(b.verified)const Icon(Icons.verified)]),
        const SizedBox(height:8),Wrap(spacing:8,children:[Chip(label:Text(b.category)),Chip(label:Text(b.businessType)),if(b.status!='active')Chip(label:Text(b.status))]),
        if(b.description.isNotEmpty)Padding(padding:const EdgeInsets.only(top:16),child:Text(b.description)),
        if(b.city.isNotEmpty||b.country.isNotEmpty)ListTile(leading:const Icon(Icons.location_on_outlined),title:const Text('الموقع'),subtitle:Text([b.city,b.country].where((x)=>x.isNotEmpty).join(' • '))),
        if(b.phone.isNotEmpty)ListTile(leading:const Icon(Icons.phone_outlined),title:const Text('الهاتف'),subtitle:Text(b.phone)),
        if(b.website.isNotEmpty)ListTile(leading:const Icon(Icons.language),title:const Text('الموقع الإلكتروني'),subtitle:Text(b.website)),
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenBusinessProductsScreen(businessId:b.id,businessName:b.name))),icon:const Icon(Icons.inventory_2_outlined),label:const Text('المنتجات والخدمات')),
        const SizedBox(height:16),
        if (own) Padding(padding:const EdgeInsets.only(top:12),child:OutlinedButton.icon(onPressed:()async{final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;final ctl=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('طلب توثيق'),content:TextField(controller:ctl,maxLines:4,decoration:const InputDecoration(labelText:'معلومات التحقق')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('إرسال'))]));if(ok==true){await _repo.requestVerification(businessId:b.id,ownerId:uid,note:ctl.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إرسال طلب التوثيق')));}},icon:const Icon(Icons.verified_outlined),label:const Text('طلب توثيق'))),if (!own) Padding(padding:const EdgeInsets.only(top:8),child:OutlinedButton.icon(onPressed:()async{
          final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;
          const reasons=['معلومات مضللة','احتيال أو نصب','محتوى غير مناسب','انتحال هوية','نشاط غير قانوني','أخرى'];
          String reason=reasons.first;
          final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
            title:const Text('الإبلاغ عن Business'),
            content:DropdownButtonFormField<String>(initialValue:reason,items:reasons.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setD(()=>reason=v!)),
            actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('إبلاغ'))],
          )));
          if(ok==true){await _repo.report(businessId:b.id,reporterUid:uid,reason:reason);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إرسال البلاغ')));}
        },icon:const Icon(Icons.flag_outlined),label:const Text('الإبلاغ'))),if (!own) StreamBuilder<bool>(
          stream:_repo.watchSaved(FirebaseAuth.instance.currentUser?.uid ?? '',b.id),
          builder:(context,s)=>IconButton(
            onPressed:FirebaseAuth.instance.currentUser?.uid==null?null:()async{
              await _repo.toggleSaved(FirebaseAuth.instance.currentUser!.uid,b.id);
              if(mounted)setState((){});
            },
            icon:Icon(s.data==true?Icons.bookmark:Icons.bookmark_border),
          ),
        ),
        StreamBuilder<List<AurenBusinessReview>>(
          stream:_repo.watchReviews(b.id),
          builder:(context,s){
            final reviews=s.data??const <AurenBusinessReview>[];
            final avg=reviews.isEmpty?0.0:reviews.map((r)=>r.rating).reduce((a,b)=>a+b)/reviews.length;
            return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('⭐ '+avg.toStringAsFixed(1)+'  ('+reviews.length.toString()+')'),
              if(!own)TextButton(onPressed:()async{
                final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;
                int rating=5;final ctl=TextEditingController();
                final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
                  title:const Text('تقييم Business'),
                  content:Column(mainAxisSize:MainAxisSize.min,children:[
                    DropdownButtonFormField<int>(initialValue:rating,items:[1,2,3,4,5].map((x)=>DropdownMenuItem(value:x,child:Text('$x نجوم'))).toList(),onChanged:(v)=>setD(()=>rating=v!)),
                    TextField(controller:ctl,maxLines:3,decoration:const InputDecoration(labelText:'تعليق')),
                  ]),
                  actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))],
                )));
                if(ok==true)await _repo.upsertReview(businessId:b.id,userId:uid,rating:rating,text:ctl.text);
                ctl.dispose();
              },child:const Text('أضف تقييمك')),
              ...reviews.take(5).map((r)=>ListTile(contentPadding:EdgeInsets.zero,title:Text('★'*r.rating),subtitle:Text(r.text.isEmpty?'بدون تعليق':r.text))),
            ])));
          },
        ),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:own?null:()async{final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null||b.ownerId.isEmpty)return;try{await _repo.recordEvent(business:b,viewerUid:uid,type:'lead');await _repo.recordEvent(business:b,viewerUid:uid,type:'message');final conversation=await ConversationRepository().getOrCreateDirectConversation(uid:uid,otherUid:b.ownerId,otherTitle:b.name);if(!context.mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(conversationId:conversation.id,initialPrompt:'مرحباً '+b.name+'، أريد الاستفسار عن خدماتكم.')));}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر فتح المحادثة: $e')));}},icon:const Icon(Icons.chat_bubble_outline),label:const Text('تواصل مع Business'))
      ])
    );
  }
}
