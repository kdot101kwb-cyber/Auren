import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/decision_room_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenDecisionRoomScreen extends StatefulWidget{const AurenDecisionRoomScreen({super.key});@override State<AurenDecisionRoomScreen> createState()=>_AurenDecisionRoomScreenState();}
class _AurenDecisionRoomScreenState extends State<AurenDecisionRoomScreen>{
 final _auth=FirebaseAurenAuthService(),_question=TextEditingController();final _options=<TextEditingController>[TextEditingController(),TextEditingController()];AurenDecisionRoom? _room;bool _loading=false;
 @override void dispose(){_question.dispose();for(final c in _options)c.dispose();super.dispose();}
 Future<void> _build()async{final uid=_auth.currentUserId;if(uid==null)return;setState(()=>_loading=true);try{final room=await DecisionRoomService().build(uid,question:_question.text,options:_options.map((x)=>x.text).toList());if(mounted)setState(()=>_room=room);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر بناء غرفة القرار: '+e.toString())));}finally{if(mounted)setState(()=>_loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AUREN Decision Room')),body:ListView(padding:const EdgeInsets.all(20),children:[
 const Text('خلّي القرار واضح',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('اكتب السؤال والخيارات. AUREN يساعدك في المقارنة، والقرار النهائي ليك.'),const SizedBox(height:18),
 TextField(controller:_question,decoration:const InputDecoration(labelText:'شنو القرار؟',border:OutlineInputBorder())),const SizedBox(height:12),
 ..._options.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:e.value,decoration:InputDecoration(labelText:'الخيار '+(e.key+1).toString(),border:const OutlineInputBorder())))),
 if(_options.length<5)TextButton.icon(onPressed:()=>setState(()=>_options.add(TextEditingController())),icon:const Icon(Icons.add),label:const Text('إضافة خيار')),
 FilledButton.icon(onPressed:_loading?null:_build,icon:const Icon(Icons.compare_arrows),label:Text(_loading?'جاري التحليل…':'حلّل القرار')),
 if(_room!=null)...[const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('المقارنة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:10),
 ..._room!.options.map((o)=>Card(child:ListTile(title:Text(o.title),subtitle:Text(o.detail+'\n\nنقاط القوة: '+o.pros.join(' • ')+'\nنقاط الانتباه: '+o.cons.join(' • ')),trailing:Text(o.fit.toString()+'%')))),
 const SizedBox(height:8),Text('أعلى توافق في هذه المقارنة: '+_room!.recommendation,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(_room!.reasoning)]))),const SizedBox(height:12),
 FilledButton.tonalIcon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'ساعدني أفهم القرار بدون اتخاذه بدلاً مني: '+_room!.question+'. الخيارات: '+_room!.options.map((o)=>o.title).join('، ')+'. اعرض المخاطر والمعلومات الناقصة ثم انتظر موافقتي.'))),icon:const Icon(Icons.chat_outlined),label:const Text('ناقش القرار مع AUREN'))]
 ]));
}