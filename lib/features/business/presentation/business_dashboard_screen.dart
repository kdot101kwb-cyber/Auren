import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenBusinessDashboardScreen extends StatelessWidget{
 final AurenBusiness business; const AurenBusinessDashboardScreen({super.key,required this.business});
 @override Widget build(BuildContext context){final repo=BusinessRepository();return Scaffold(appBar:AppBar(title:const Text('Business Dashboard')),body:ListView(padding:const EdgeInsets.all(16),children:[
  Card(child:ListTile(leading:const Icon(Icons.storefront),title:Text(business.name),subtitle:Text(business.businessType+' • '+business.status))),
  StreamBuilder<List<AurenBusinessEvent>>(stream:repo.watchEvents(business.id),builder:(context,s){final e=s.data??const <AurenBusinessEvent>[];int count(String t)=>e.where((x)=>x.type==t).length;return GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,children:[
   _metric('Profile views',count('view'),Icons.visibility_outlined),_metric('Messages',count('message'),Icons.chat_outlined),_metric('Saves',count('save'),Icons.bookmark_outline),_metric('Leads',count('lead'),Icons.person_add_alt_1_outlined)]);
  }),
  StreamBuilder<List<AurenBusinessReview>>(stream:repo.watchReviews(business.id),builder:(context,s){final r=s.data??const <AurenBusinessReview>[];final avg=r.isEmpty?0.0:r.map((x)=>x.rating).reduce((a,b)=>a+b)/r.length;return Card(child:ListTile(leading:const Icon(Icons.star_outline),title:Text(avg.toStringAsFixed(1)),subtitle:Text(r.length.toString()+' Reviews')));}),
  Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('Business AI'),subtitle:const Text('نمو، إعلان، عملاء، موردين وتوسع.'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'حلّل Business '+business.name+' واصنع خطة نمو عملية تشمل العملاء والإعلان والموردين والتوسع.')))),
 ]));}
 Widget _metric(String title,int value,IconData icon)=>Card(child:ListTile(leading:Icon(icon),title:Text(value.toString()),subtitle:Text(title)));
}