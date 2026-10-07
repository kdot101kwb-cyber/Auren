import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_engine_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentEngineScreen extends StatefulWidget{
  final String? opportunityId; final String? opportunityTitle; final String? opportunityDescription; final List<String> opportunitySkills;
  const AurenTalentEngineScreen({super.key,this.opportunityId,this.opportunityTitle,this.opportunityDescription,this.opportunitySkills=const []});
  @override State<AurenTalentEngineScreen> createState()=>_AurenTalentEngineScreenState();
}
class _AurenTalentEngineScreenState extends State<AurenTalentEngineScreen>{
  final _service=AurenTalentEngineService(); final _query=TextEditingController();
  bool _loading=false; String? _invitingUid; String? _respondingInvitationId; List<AurenTalentCandidate> _results=[];
  @override void dispose(){_query.dispose();super.dispose();}
  Future<void> _scout() async{
    final uid=FirebaseAuth.instance.currentUser?.uid;
    final q=_query.text.trim();
    final inOpportunityMode=widget.opportunityId!=null;
    if(uid==null || (inOpportunityMode && widget.opportunitySkills.isEmpty) || (!inOpportunityMode && q.isEmpty))return;
    setState(()=>_loading=true);
    try{
      final r=inOpportunityMode
          ? await _service.matchOpportunity(
              title:widget.opportunityTitle?.trim()??'',
              description:widget.opportunityDescription?.trim()??'',
              skills:widget.opportunitySkills,
              excludeUid:uid,
            )
          : await _service.scout(query:q,excludeUid:uid);
      if(mounted)setState(()=>_results=r);
    } catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('تعذر تشغيل الكشاف: $e')),
      );
    } finally{
      if(mounted)setState(()=>_loading=false);
    }
  }
  Future<void> _respond(String id,String status) async {
    final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null||_respondingInvitationId!=null)return;
    setState(()=>_respondingInvitationId=id);
    try{await _service.respondToInvitation(invitationId:id,talentUid:uid,status:status);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='accepted'?'تم قبول الدعوة.':'تم رفض الدعوة.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحديث الدعوة: $e')));}
    finally{if(mounted)setState(()=>_respondingInvitationId=null);}
  }

  Future<void> _invite(AurenTalentCandidate candidate) async {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    final oid=widget.opportunityId; final title=widget.opportunityTitle;
    if(uid==null||oid==null||title==null||_invitingUid!=null)return;
    setState(()=>_invitingUid=candidate.uid);
    try{
      await _service.inviteToOpportunity(ownerId:uid,talentUid:candidate.uid,opportunityId:oid,opportunityTitle:title);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إرسال الدعوة للمواهب.')));
    } catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الدعوة: $e')));
    } finally{
      if(mounted)setState(()=>_invitingUid=null);
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('AUREN Talent Engine'),actions:[IconButton(icon:const Icon(Icons.auto_awesome),tooltip:'AI Scout',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'أنت AI Scout في AUREN. ساعدني في تحديد نوع الموهبة التي أحتاجها، المهارات المطلوبة، ثم اقترح طريقة البحث والتواصل بأمان.'))))]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('AI Talent Scout',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        Text(widget.opportunityId!=null
            ? 'مطابقة المواهب لهذه الفرصة تعتمد على المهارات الموثقة فقط.'
            : 'اكتب المهارة أو الدور أو الخدمة التي تبحث عنها، وAUREN يبحث في الملفات المهنية القابلة للاكتشاف.'),
        if(widget.opportunityId==null) ...[
          const SizedBox(height:14),
          TextField(controller:_query,onSubmitted:(_)=>_scout(),maxLines:2,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'مثال: Flutter developer • مصمم • مدرس لغة')),
        ],
        const SizedBox(height:12),
        SizedBox(width:double.infinity,child:FilledButton.icon(
          onPressed:_loading?null:_scout,
          icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.search),
          label:Text(_loading?'جاري البحث...':widget.opportunityId!=null?'ابحث عن أفضل المطابقات':'ابحث عن المواهب'),
        )),
      ]))),
      if(widget.opportunityId==null) ...[
        const SizedBox(height:18),
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('دعوات الفرص',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          StreamBuilder<List<Map<String,dynamic>>>(stream: _service.watchInvitations(FirebaseAuth.instance.currentUser?.uid??''),builder:(context,snap){
            if(snap.hasError)return Padding(
              padding:const EdgeInsets.all(8),
              child:Text('تعذر تحميل الدعوات: ${snap.error}'),
            );
            if(!snap.hasData)return const Padding(padding:EdgeInsets.all(8),child:CircularProgressIndicator());
            final items=snap.data!;
            if(items.isEmpty)return const Text('لا توجد دعوات جديدة.');
            String statusLabel(dynamic value)=>switch(value?.toString()){
              'pending'=>'بانتظار ردك',
              'accepted'=>'تم القبول',
              'declined'=>'تم الرفض',
              _=>'حالة غير معروفة',
            };
            return Column(children:items.map((inv)=>ListTile(
              title:Text(inv['opportunityTitle']?.toString()??'فرصة'),
              subtitle:Text(statusLabel(inv['status'])),
              trailing:inv['status']=='pending'?Wrap(children:[
                IconButton(tooltip:'قبول',icon:_respondingInvitationId==inv['id'].toString()?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.check),onPressed:_respondingInvitationId==null?()=>_respond(inv['id'].toString(),'accepted'):null),
                IconButton(tooltip:'رفض',icon:const Icon(Icons.close),onPressed:_respondingInvitationId==null?()=>_respond(inv['id'].toString(),'declined'):null),
              ]):null,
            )).toList());
          }),
        ]))),
      ],
      const SizedBox(height:10),
      if(!_loading&&_results.isEmpty)
        Padding(
          padding:const EdgeInsets.all(20),
          child:Text(
            widget.opportunityId!=null
                ? 'لا توجد مطابقات بمهارات موثقة لهذه الفرصة.'
                : 'ابدأ بمهارة أو دور محدد.',
          ),
        ),
      ..._results.map((candidate)=>Card(child:ListTile(
        leading:CircleAvatar(child:Text('${candidate.score}')),
        title:Text(candidate.headline.isEmpty?'AUREN Professional':candidate.headline),
        subtitle:Text('${candidate.reasons.join(' • ')}\n${[...candidate.verifiedSkills,...candidate.services].take(5).join(' • ')}'),
        isThreeLine:true,
        trailing:(widget.opportunityId!=null)?IconButton(
          icon:_invitingUid==candidate.uid
              ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2))
              : const Icon(Icons.mail_outline),
          tooltip:'دعوة للفرصة',
          onPressed:_invitingUid==null?()=>_invite(candidate):null,
        ):candidate.showContact?IconButton(icon:const Icon(Icons.chat_outlined),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'أريد التواصل مع صاحب هذا الملف بخصوص: ${_query.text.trim()}')))):null,
      ))),
    ]));
}
