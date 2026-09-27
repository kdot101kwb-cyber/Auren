import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/business/review_intelligence_service.dart';
import '../../../services/business/business_analytics_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'business_growth_screen.dart';

class AurenBusinessDashboardScreen extends StatelessWidget{
 final AurenBusiness business; const AurenBusinessDashboardScreen({super.key,required this.business});
 @override Widget build(BuildContext context){final repo=BusinessRepository();final analytics=BusinessAnalyticsService();return Scaffold(appBar:AppBar(title:const Text('Business Dashboard'),actions:[IconButton(tooltip:'Growth & Outreach',icon:const Icon(Icons.trending_up),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenBusinessGrowthScreen(business:business))))]),body:ListView(padding:const EdgeInsets.all(16),children:[
  Card(child:ListTile(leading:const Icon(Icons.storefront),title:Text(business.name),subtitle:Text(business.businessType+' • '+business.status))),
  StreamBuilder<AurenBusinessAnalytics>(stream:analytics.watchBusiness(business.id),builder:(context,s){final a=s.data;if(a==null)return const SizedBox.shrink();return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Analytics',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Wrap(spacing:8,runSpacing:8,children:[Chip(label:Text('Views \${a.views}')),Chip(label:Text('Messages \${a.messages}')),Chip(label:Text('Leads \${a.leads}')),Chip(label:Text('Saves \${a.saves}')),Chip(label:Text('Engagement \${a.engagementRate.toStringAsFixed(1)}%'))])])));}),
  StreamBuilder<List<AurenBusinessEvent>>(stream:repo.watchEvents(business.id),builder:(context,s){final e=s.data??const <AurenBusinessEvent>[];int count(String t)=>e.where((x)=>x.type==t).length;final views=count('view');final leads=count('lead');final saves=count('save');final messages=count('message');return GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,children:[
   _metric('Profile views',views,Icons.visibility_outlined),_metric('Messages',messages,Icons.chat_outlined),_metric('Saves',saves,Icons.bookmark_outline),_metric('Leads',leads,Icons.person_add_alt_1_outlined)]);
  }),
  StreamBuilder<List<AurenBusinessReview>>(stream:repo.watchReviews(business.id),builder:(context,s){final r=s.data??const <AurenBusinessReview>[];final avg=r.isEmpty?0.0:r.map((x)=>x.rating).reduce((a,b)=>a+b)/r.length;final insight=AurenReviewIntelligenceService().analyze(r);
return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 ListTile(leading:const Icon(Icons.star_outline),title:Text(avg.toStringAsFixed(1)),subtitle:Text(r.length.toString()+' Reviews')),
 if(r.isNotEmpty) Wrap(spacing:8,children:[Chip(label:Text('إيجابي ${insight.positive}')),Chip(label:Text('محايد ${insight.neutral}')),Chip(label:Text('سلبي ${insight.negative}'))]),
 if(insight.themes.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),child:Text('أبرز المواضيع: '+insight.themes.join(' • '))),
]));}),
  Card(child:Column(children:[ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('Business AI'),subtitle:const Text('نمو، إعلان، عملاء، موردين وتوسع.')),Wrap(spacing:8,children:[TextButton.icon(onPressed:()=>_ai(context,'حلّل Business '+business.name+' واصنع خطة نمو عملية.'),icon:const Icon(Icons.trending_up),label:const Text('خطة نمو')),TextButton.icon(onPressed:()=>_ai(context,'اكتب 5 إعلانات تسويقية لـ '+business.name+' لجذب عملاء جدد.'),icon:const Icon(Icons.campaign_outlined),label:const Text('إعلانات')),TextButton.icon(onPressed:()=>_ai(context,'ساعد Business '+business.name+' في إيجاد موردين مناسبين وأسواق جديدة.'),icon:const Icon(Icons.public),label:const Text('توسع'))])])),
 ]));}
 void _ai(BuildContext context,String prompt)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt)));
 Widget _metric(String title,int value,IconData icon)=>Card(child:ListTile(leading:Icon(icon),title:Text(value.toString()),subtitle:Text(title)));
}