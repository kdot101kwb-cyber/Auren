import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenBusinessDashboardScreen extends StatelessWidget {
  final AurenBusiness business;
  const AurenBusinessDashboardScreen({super.key,required this.business});
  @override Widget build(BuildContext context){
    final repo=BusinessRepository();
    return Scaffold(appBar:AppBar(title:const Text('Business Dashboard')),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:ListTile(leading:const Icon(Icons.storefront),title:Text(business.name),subtitle:Text(business.businessType+' • '+business.status))),
      StreamBuilder<List<AurenBusinessReview>>(stream:repo.watchReviews(business.id),builder:(context,s){
        final reviews=s.data??const <AurenBusinessReview>[];
        final avg=reviews.isEmpty?0.0:reviews.map((x)=>x.rating).reduce((a,b)=>a+b)/reviews.length;
        return Row(children:[Expanded(child:Card(child:ListTile(title:Text(reviews.length.toString()),subtitle:const Text('Reviews'),leading:const Icon(Icons.rate_review_outlined)))),Expanded(child:Card(child:ListTile(title:Text(avg.toStringAsFixed(1)),subtitle:const Text('Average'),leading:const Icon(Icons.star_outline))))]);
      }),
      Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('Business AI'),subtitle:const Text('حلّل النشاط، اكتب إعلاناً، اجذب عملاء واقترح فرص نمو.'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'حلّل Business التالي: '+business.name+'. اقترح خطة عملية لجذب العملاء، تحسين العرض، كتابة إعلان، إيجاد موردين وفرص توسع.'))))),
      Card(child:ListTile(leading:const Icon(Icons.chat_outlined),title:const Text('Customer Conversations'),subtitle:const Text('تابع التواصل مع العملاء عبر Messenger.'))),
    ]));
  }
}