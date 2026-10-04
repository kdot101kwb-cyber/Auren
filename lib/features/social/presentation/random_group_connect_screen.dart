import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/random_group_connect_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenRandomGroupConnectScreen extends StatefulWidget { const AurenRandomGroupConnectScreen({super.key}); @override State<AurenRandomGroupConnectScreen> createState()=>_AurenRandomGroupConnectScreenState(); }
class _AurenRandomGroupConnectScreenState extends State<AurenRandomGroupConnectScreen>{
 final auth=FirebaseAurenAuthService(); final service=AurenRandomGroupConnectService(); final country=TextEditingController(); final language=TextEditingController(); final interest=TextEditingController(); int size=4; String? requestId; String? groupId;
 @override void dispose(){country.dispose();language.dispose();interest.dispose();super.dispose();}
 Future<void> join()async{final uid=auth.currentUserId;if(uid==null||language.text.trim().isEmpty)return;requestId=await service.join(uid:uid,country:country.text,language:language.text,interest:interest.text,goal:'social group',groupSize:size);if(mounted)setState((){});}
 @override
 Widget build(BuildContext context) {
   final uid = auth.currentUserId;
   if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
   return Scaffold(
     appBar: AppBar(title: const Text('Random Group Connect')),
     body: ListView(
       padding: const EdgeInsets.all(16),
       children: [
         const Text('كوّن مجموعة عشوائية صغيرة للتعارف والنقاش حسب اللغة والاهتمام.'),
         const SizedBox(height: 16),
         _f(country, 'الدولة'),
         _f(language, 'اللغة'),
         _f(interest, 'الاهتمام'),
         DropdownButtonFormField<int>(
           value: size,
           decoration: const InputDecoration(labelText: 'حجم المجموعة', border: OutlineInputBorder()),
           items: [3, 4, 5, 6, 8].map((n) => DropdownMenuItem(value: n, child: Text('$n أشخاص'))).toList(),
           onChanged: (v) => setState(() => size = v ?? 4),
         ),
         const SizedBox(height: 12),
         FilledButton(onPressed: requestId == null ? join : null, child: Text(requestId == null ? 'انضم للانتظار' : 'بانتظار المجموعة')),
         const Divider(height: 32),
         StreamBuilder<List<Map<String, dynamic>>>(
           stream: service.watch(uid: uid, language: language.text, groupSize: size),
           builder: (context, snap) {
             final rows = snap.data ?? const <Map<String, dynamic>>[];
             return Column(
               children: rows.map((r) {
                 return Card(
                   child: ListTile(
                     title: Text('مجموعة ${r['groupSize']} أشخاص'),
                     subtitle: Text([r['country'], r['language'], r['interest']].whereType<String>().where((x) => x.isNotEmpty).join(' • ')),
                     trailing: TextButton(
                       onPressed: () async {
                         final gid = await service.formGroup(
                           requestId: r['id'] as String,
                           uid: uid,
                           memberUids: [r['uid'] as String],
                         );
                         final conversationId = await service.createMessengerGroup(
                           groupId: gid,
                           uid: uid,
                           title: 'AUREN Random Group',
                         );
                         if (!mounted) return;
                         Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: conversationId)));
                       },
                       child: const Text('انضم'),
                     ),
                   ),
                 );
               }).toList(),
             );
           },
         ),
       ],
     ),
   );
 }

 Widget _f(TextEditingController c,String l)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,decoration:InputDecoration(labelText:l,border:const OutlineInputBorder())));
}
