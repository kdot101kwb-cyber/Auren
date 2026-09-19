import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/users/user_repository.dart';
class AurenProfileScreen extends StatelessWidget{
 const AurenProfileScreen({super.key});
 @override Widget build(BuildContext context){
  final uid=FirebaseAurenAuthService().currentUserId;
  if(uid==null)return const Scaffold(body:Center(child:Text('Sign in required')));
  return Scaffold(appBar:AppBar(title:const Text('Profile')),body:StreamBuilder(
   stream:UserRepository().watch(uid),builder:(context,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final p=s.data!;
    return ListView(padding:const EdgeInsets.all(20),children:[
     const CircleAvatar(radius:42,child:Icon(Icons.person,size:42)),const SizedBox(height:16),
     Text(p.displayName,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
     const Text('Connect. Create. Achieve.'),const SizedBox(height:24),
     Card(child:ListTile(leading:const Icon(Icons.edit),title:const Text('Edit profile'),onTap:()=>showDialog(context:context,builder:(_)=>_EditNameDialog(uid:uid,current:p.displayName)))),
     Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('AI Profile'),subtitle:const Text('Personal • Creator • Professional • Business'))),
     Card(child:ListTile(leading:const Icon(Icons.people_outline),title:const Text('Social Graph'),subtitle:const Text('Followers, following and communities'))),
    ]);
   }));
 }
}
class _EditNameDialog extends StatefulWidget{final String uid,current;const _EditNameDialog({required this.uid,required this.current});@override State<_EditNameDialog> createState()=>_EditNameDialogState();}
class _EditNameDialogState extends State<_EditNameDialog>{late final c=TextEditingController(text:widget.current);bool saving=false;Future<void>save()async{if(c.text.trim().isEmpty)return;setState(()=>saving=true);await UserRepository().updateDisplayName(widget.uid,c.text);if(mounted)Navigator.pop(context);}@override Widget build(BuildContext context)=>AlertDialog(title:const Text('Edit profile'),content:TextField(controller:c,autofocus:true,decoration:const InputDecoration(labelText:'Display name')),actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:saving?null:save,child:const Text('Save'))]);@override void dispose(){c.dispose();super.dispose();}}
