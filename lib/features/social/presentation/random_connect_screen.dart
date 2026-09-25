import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/social/random_ai_service.dart';
import '../../../services/social/random_call_service.dart';
import '../../../services/social/random_connect_safety_service.dart';
import '../../../services/social/random_connect_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'random_call_screen.dart';

class AurenRandomConnectScreen extends StatefulWidget {
  const AurenRandomConnectScreen({super.key});
  @override State<AurenRandomConnectScreen> createState()=>_AurenRandomConnectScreenState();
}

class _AurenRandomConnectScreenState extends State<AurenRandomConnectScreen> {
  final auth=FirebaseAurenAuthService(), service=AurenRandomConnectService(), safety=AurenRandomConnectSafetyService(), callService=AurenRandomCallService();
  final name=TextEditingController(),country=TextEditingController(),language=TextEditingController(),interest=TextEditingController(),goal=TextEditingController(),activity=TextEditingController(),topic=TextEditingController(),minAge=TextEditingController(),maxAge=TextEditingController();
  String? requestId; bool busy=false; String discoveryMode='all'; final Set<String> skippedIds=<String>{}; Timer? presenceTimer;

  @override void initState(){super.initState();_presence(true);presenceTimer=Timer.periodic(const Duration(seconds:30),(_)=>_presence(true));}
  Future<void> _presence(bool online)async{final uid=auth.currentUserId;if(uid==null)return;try{await service.setPresence(uid,online:online);}catch(_){}} 
  @override void dispose(){presenceTimer?.cancel();_presence(false);for(final c in [name,country,language,interest,goal,activity,topic,minAge,maxAge])c.dispose();super.dispose();}
  void msg(String s){if(!mounted)return;ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text(s)));}
  int? _age(TextEditingController c){final v=int.tryParse(c.text.trim());return v!=null&&v>=13&&v<=120?v:null;}

  Future<void> join()async{
    final uid=auth.currentUserId;if(uid==null||language.text.trim().isEmpty){msg('اكتب اللغة أولاً.');return;}
    setState(()=>busy=true);
    try{
      skippedIds.clear();
      final id=await service.join(uid:uid,displayName:name.text,country:country.text,language:language.text,interest:interest.text,goal:goal.text,age:_age(minAge),activity:activity.text,topic:topic.text);
      if(mounted)setState(()=>requestId=id);
    }catch(_){msg('تعذر بدء البحث.');}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> cancel()async{final uid=auth.currentUserId,id=requestId;if(uid==null||id==null)return;setState(()=>busy=true);try{await service.cancel(uid,id);if(mounted)setState(()=>requestId=null);}catch(_){msg('تعذر الإلغاء.');}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> _endCurrentRequest()async{final uid=auth.currentUserId,id=requestId;if(uid==null||id==null)return;try{await service.finishRequest(uid,id);}catch(_){}}
  Future<void> rematch()async{await _endCurrentRequest();if(mounted)setState(()=>requestId=null);await join();}

  Future<void> connect(AurenRandomMatch m)async{
    final uid=auth.currentUserId;if(uid==null||busy)return;setState(()=>busy=true);
    try{
      final other=await service.connect(uid,m.id);
      if(other==null){setState(()=>skippedIds.add(m.id));msg('الشخص لم يعد متاحاً.');return;}
      await service.recordSession(uid:uid,otherUid:other,otherName:m.displayName,action:'connect',kind:'messenger');
      final c=await ConversationRepository().getOrCreateDirectConversation(uid:uid,otherUid:other,otherTitle:m.displayName);
      if(mounted)await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>MessengerScreen(conversationId:c.id)));
      await _endCurrentRequest();
    }catch(_){msg('تعذر فتح المحادثة.');}finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> startCall(AurenRandomMatch m,String kind)async{
    final uid=auth.currentUserId;if(uid==null||busy||m.uid.isEmpty||m.uid==uid)return;setState(()=>busy=true);
    try{
      await service.recordSession(uid:uid,otherUid:m.uid,otherName:m.displayName,action:'call',kind:kind);
      final callId=await callService.create(callerUid:uid,calleeUid:m.uid,kind:kind);
      if(mounted)await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>AurenRandomCallScreen(callId:callId,caller:true,kind:kind,otherName:m.displayName)));
      await _endCurrentRequest();
    }catch(_){msg('تعذر بدء المكالمة.');}finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> history()async{final uid=auth.currentUserId;if(uid==null)return;await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(c)=>SafeArea(child:SizedBox(height:MediaQuery.of(c).size.height*.72,child:StreamBuilder<List<Map<String,dynamic>>>(stream:service.watchHistory(uid),builder:(c,s){final rows=s.data??const <Map<String,dynamic>>[];return Column(children:[const Padding(padding:EdgeInsets.all(16),child:Text('سجل Random Connect',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),Expanded(child:rows.isEmpty?const Center(child:Text('لسه ما عندك جلسات.')):ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i){final x=rows[i];return ListTile(title:Text((x['otherName'] as String?)??'AUREN User'),subtitle:Text((x['action']??'connect').toString()+' • '+(x['kind']??'text').toString()));}))]);}))));}

  Future<void> notifications()async{final uid=auth.currentUserId;if(uid==null)return;await showModalBottomSheet<void>(context:context,builder:(c)=>SafeArea(child:StreamBuilder<List<Map<String,dynamic>>>(stream:service.watchNotifications(uid),builder:(c,s){final rows=s.data??const <Map<String,dynamic>>[];return SizedBox(height:420,child:rows.isEmpty?const Center(child:Text('ما في إشعارات Random.')):ListView.builder(itemCount:rows.length,itemBuilder:(_,i){final x=rows[i],id=(x['id']??'').toString();return ListTile(title:Text((x['title']??'Random').toString()),subtitle:Text((x['body']??'').toString()),trailing:x['read']==true?null:const Icon(Icons.circle,size:10),onTap:()=>service.markNotificationRead(uid,id));}));}))));}

  void showAi(){final items=AurenRandomAiService.startersFor(interest:interest.text,goal:goal.text,topic:topic.text);showModalBottomSheet<void>(context:context,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('AUREN AI — بداية المحادثة',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(AurenRandomAiService.safetyPrompt()),const SizedBox(height:8),...items.take(6).map((x)=>ListTile(leading:const Icon(Icons.auto_awesome),title:Text(x),onTap:(){Navigator.pop(c);msg(x);})),]))));}

  Future<void> report(AurenRandomMatch m)async{final uid=auth.currentUserId;if(uid==null||uid==m.uid)return;final reason=await showDialog<String>(context:context,builder:(c)=>SimpleDialog(title:const Text('الإبلاغ عن المستخدم'),children:[for(final v in ['محتوى غير مناسب','إزعاج أو إساءة','احتيال','أخرى'])SimpleDialogOption(onPressed:()=>Navigator.pop(c,v),child:Text(v))]));if(reason==null)return;try{await safety.reportUser(reporterUid:uid,reportedUid:m.uid,reason:reason);msg('تم إرسال البلاغ.');}catch(_){msg('تعذر إرسال البلاغ.');}}
  Future<void> block(AurenRandomMatch m)async{final uid=auth.currentUserId;if(uid==null||uid==m.uid)return;try{await safety.block(uid:uid,blockedUid:m.uid);setState(()=>skippedIds.add(m.id));msg('تم الحظر وإخفاء المستخدم.');}catch(_){msg('تعذر الحظر.');}}

  Widget field(TextEditingController c,String label)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  Widget presence(AurenRandomMatch m)=>StreamBuilder<AurenRandomPresence>(stream:service.watchPresence(m.uid),builder:(c,s){final online=s.data?.online==true;return Row(children:[Icon(Icons.circle,size:9,color:online?Colors.green:Colors.grey),const SizedBox(width:5),Text(online?'متصل الآن':'غير متصل',style:const TextStyle(fontSize:12))]);});

  @override Widget build(BuildContext context){
    final me=auth.currentUserId;if(me==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final min=_age(minAge),max=_age(maxAge);
    return Scaffold(
      appBar:AppBar(title:const Text('Random Connect'),actions:[IconButton(onPressed:notifications,icon:const Icon(Icons.notifications_outlined)),IconButton(onPressed:history,icon:const Icon(Icons.history)),IconButton(onPressed:showAi,icon:const Icon(Icons.auto_awesome))]),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('تواصل عشوائياً: نص، صوت، فيديو، حسب اللغة والدولة والاهتمام والهدف والنشاط والموضوع.'),
        const SizedBox(height:10),
        ...[field(name,'الاسم الظاهر'),field(country,'الدولة'),field(language,'اللغة'),field(interest,'الاهتمام'),field(goal,'الهدف'),field(activity,'النشاط الحالي'),field(topic,'موضوع المحادثة'),field(minAge,'العمر الأدنى'),field(maxAge,'العمر الأعلى')],
        Wrap(spacing:8,runSpacing:8,children:[
          for(final item in const [['all','الكل'],['language','لغة'],['country','دولة'],['interest','اهتمام'],['goal','هدف'],['topic','موضوع']])
            ChoiceChip(label:Text(item[1]),selected:discoveryMode==item[0],onSelected:(_)=>setState(()=>discoveryMode=item[0])),
        ]),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:busy?null:(requestId==null?join:cancel),icon:Icon(requestId==null?Icons.radar:Icons.close),label:Text(requestId==null?'ابدأ البحث':'إلغاء الانتظار')),
        if(requestId!=null)Padding(padding:const EdgeInsets.all(14),child:Column(children:[const CircularProgressIndicator(),const SizedBox(height:8),const Text('AUREN يبحث عن شخص مناسب…'),TextButton(onPressed:rematch,child:const Text('إنهاء والبحث من جديد'))])),
        const Divider(height:28),
        StreamBuilder<List<AurenRandomMatch>>(stream:service.watchWaiting(country:discoveryMode=='country'?country.text:'',language:language.text,interest:discoveryMode=='interest'?interest.text:'',goal:discoveryMode=='goal'?goal.text:'',minAge:min,maxAge:max,activity:activity.text,topic:discoveryMode=='topic'?topic.text:''),builder:(context,snapshot){
          final items=(snapshot.data??const <AurenRandomMatch>[]).where((x)=>x.uid!=me&&!skippedIds.contains(x.id)).toList();
          if(items.isEmpty)return Column(children:[const Padding(padding:EdgeInsets.all(24),child:Text('ما في أشخاص متاحين بالمطابقة الحالية.')),if(skippedIds.isNotEmpty)OutlinedButton(onPressed:()=>setState(skippedIds.clear),child:const Text('إظهار المتخطاة'))]);
          return Column(children:[
            Align(alignment:Alignment.centerLeft,child:Text('أفضل المطابقات ('+items.length.toString()+')',style:Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height:8),
            ...items.map((m)=>Card(child:ListTile(
              leading:CircleAvatar(backgroundImage:m.photoUrl.isNotEmpty?NetworkImage(m.photoUrl):null,child:m.photoUrl.isEmpty?const Icon(Icons.person_outline):null),
              title:Text(m.displayName),
              subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text([m.country,m.language,m.interest,m.goal,m.activity,m.topic].where((v)=>v.isNotEmpty).join(' • ')),presence(m)]),
              onTap:()=>profile(m),
              trailing:PopupMenuButton<String>(onSelected:(v){if(v=='connect')connect(m);if(v=='audio')startCall(m,'audio');if(v=='video')startCall(m,'video');if(v=='skip')setState(()=>skippedIds.add(m.id));if(v=='report')report(m);if(v=='block')block(m);},itemBuilder:(_)=>const[PopupMenuItem(value:'connect',child:Text('Connect / Messenger')),PopupMenuItem(value:'audio',child:Text('Voice call')),PopupMenuItem(value:'video',child:Text('Video call')),PopupMenuItem(value:'skip',child:Text('التالي / تخطي')),PopupMenuItem(value:'report',child:Text('Report')),PopupMenuItem(value:'block',child:Text('Block'))]),
            ))),
          ]);
        }),
      ]),
    );
  }

  void profile(AurenRandomMatch m){
    final score=service.matchScore(m,country:country.text,language:language.text,interest:interest.text,goal:goal.text,activity:activity.text,topic:topic.text);
    final reasons=service.matchReasons(m,country:country.text,language:language.text,interest:interest.text,goal:goal.text,activity:activity.text,topic:topic.text);
    showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[CircleAvatar(radius:30,backgroundImage:m.photoUrl.isNotEmpty?NetworkImage(m.photoUrl):null,child:m.photoUrl.isEmpty?const Icon(Icons.person):null),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m.displayName,style:Theme.of(c).textTheme.titleLarge),Text(m.age==null?'العمر غير ظاهر':'العمر: '+m.age.toString()),presence(m)]))]),
      const SizedBox(height:12),Text('درجة المطابقة: '+score.toString()+'%'),Text(reasons.isEmpty?'مطابقة عامة':reasons.join(' • ')),const SizedBox(height:12),
      Wrap(spacing:8,children:[FilledButton.icon(onPressed:(){Navigator.pop(c);connect(m);},icon:const Icon(Icons.chat_bubble_outline),label:const Text('Connect')),OutlinedButton(onPressed:(){Navigator.pop(c);startCall(m,'audio');},child:const Text('Voice')),OutlinedButton(onPressed:(){Navigator.pop(c);startCall(m,'video');},child:const Text('Video'))]),
    ]))));
  }
}
