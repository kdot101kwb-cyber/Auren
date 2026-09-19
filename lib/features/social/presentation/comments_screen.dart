import 'package:flutter/material.dart';
import '../../../core/models/comment.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/comment_repository.dart';
class AurenCommentsScreen extends StatefulWidget{
 final String postId;
 const AurenCommentsScreen({super.key,required this.postId});
 @override State<AurenCommentsScreen> createState()=>_AurenCommentsScreenState();
}
class _AurenCommentsScreenState extends State<AurenCommentsScreen>{
 final c=TextEditingController(); bool sending=false;
 Future<void> send()async{
  final text=c.text.trim(); final uid=FirebaseAurenAuthService().currentUserId;
  if(text.isEmpty||uid==null||sending)return;
  setState(()=>sending=true);
  try{await CommentRepository().create(AurenComment(id:'comment_${DateTime.now().microsecondsSinceEpoch}',postId:widget.postId,authorId:uid,text:text,createdAt:DateTime.now()));c.clear();}
  finally{if(mounted)setState(()=>sending=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Comments')),body:Column(children:[
  Expanded(child:StreamBuilder(stream:CommentRepository().watch(widget.postId),builder:(context,s){
   if(s.hasError)return Center(child:Text('Could not load comments: ${s.error}')); if(!s.hasData)return const Center(child:CircularProgressIndicator());
   return ListView.builder(padding:const EdgeInsets.all(12),itemCount:s.data!.length,itemBuilder:(c,i){final x=s.data![i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(x.authorId),subtitle:Text(x.text));});
  })),
  SafeArea(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:c,decoration:const InputDecoration(hintText:'Write a comment…'))),IconButton(onPressed:sending?null:send,icon:const Icon(Icons.send))])))
 ]));
 @override void dispose(){c.dispose();super.dispose();}
}