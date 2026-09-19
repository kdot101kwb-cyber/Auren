import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/follow_repository.dart';
class AurenPublicProfileScreen extends StatelessWidget{
 final AurenUserProfile profile;
 const AurenPublicProfileScreen({super.key,required this.profile});
 @override Widget build(BuildContext context){
  final me=FirebaseAurenAuthService().currentUserId;final repo=FollowRepository();
  final own=me==profile.uid;
  return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(padding:const EdgeInsets.all(20),children:[
   const CircleAvatar(radius:48,child:Icon(Icons.person,size:48)),const SizedBox(height:16),
   Text(profile.displayName,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
   const SizedBox(height:16),
   Row(children:[Expanded(child:StreamBuilder<int>(stream:repo.followersCount(profile.uid),builder:(_,s)=>Text('${s.data??0} followers'))),Expanded(child:StreamBuilder<int>(stream:repo.followingCount(profile.uid),builder:(_,s)=>Text('${s.data??0} following')))]),
   const SizedBox(height:20),
   if(!own&&me!=null)StreamBuilder<bool>(stream:repo.watchFollowing(me,profile.uid),builder:(context,s){final following=s.data??false;return FilledButton.icon(onPressed:()=>repo.toggle(me,profile.uid,following),icon:Icon(following?Icons.person_remove:Icons.person_add),label:Text(following?'Following':'Follow'));}),
 ]));}
}