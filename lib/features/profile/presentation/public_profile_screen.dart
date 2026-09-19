import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/follow_repository.dart';
class AurenPublicProfileScreen extends StatelessWidget{
 final AurenUserProfile profile;
 const AurenPublicProfileScreen({super.key,required this.profile});
 @override Widget build(BuildContext context){
  final me=FirebaseAurenAuthService().currentUserId;
  return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(padding:const EdgeInsets.all(20),children:[
   const CircleAvatar(radius:48,child:Icon(Icons.person,size:48)),const SizedBox(height:16),
   Text(profile.displayName,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
   Text(profile.uid,style:Theme.of(context).textTheme.bodySmall),
   const SizedBox(height:20),
   if(me!=null&&me!=profile.uid)StreamBuilder<bool>(stream:FollowRepository().watchFollowing(me,profile.uid),builder:(context,s)=>FilledButton.icon(onPressed:s.data==null?null:()=>FollowRepository().toggle(me,profile.uid,s.data!),icon:Icon(s.data==true?Icons.person_remove:Icons.person_add),label:Text(s.data==true?'Following':'Follow'))),
   if(me!=null)Row(children:[Expanded(child:StreamBuilder<int>(stream:FollowRepository().watchFollowers(profile.uid),builder:(_,s)=>_stat('Followers',s.data??0))),Expanded(child:StreamBuilder<int>(stream:FollowRepository().watchFollowingCount(profile.uid),builder:(_,s)=>_stat('Following',s.data??0)))])
  ]));}
 static Widget _stat(String label,int value)=>Column(children:[Text('$value',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text(label)]);
}