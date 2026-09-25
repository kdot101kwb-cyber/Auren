import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/business/business_repository.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_analytics_service.dart';

class AurenBusinessAnalyticsScreen extends StatelessWidget {
  const AurenBusinessAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid=FirebaseAurenAuthService().currentUserId;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لعرض تحليلات نشاطك.')));
    return Scaffold(
      appBar:AppBar(title:const Text('Business Analytics')),
      body:StreamBuilder<List<AurenBusiness>>(
        stream:BusinessRepository().watchPublic(),
        builder:(context,snapshot){
          final businesses=(snapshot.data??const <AurenBusiness>[]).where((b)=>b.ownerId==uid).toList();
          if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
          if(businesses.isEmpty)return const Center(child:Text('أنشئ Business أولاً عشان تظهر التحليلات.'));
          return ListView(padding:const EdgeInsets.all(16),children:[
            const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('تحليلات أولية من أحداث النشاط المسجلة داخل AUREN. الأرقام الحالية وصفية وليست توقعات.'))),
            ...businesses.map((business)=>StreamBuilder<AurenBusinessAnalytics>(
              stream:BusinessAnalyticsService().watchBusiness(business.id),
              builder:(context,analytics){
                final a=analytics.data;
                if(a==null)return const Card(child:ListTile(title:Text('جاري تحميل التحليلات…')));
                return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(business.name,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
                  const SizedBox(height:12),
                  Wrap(spacing:8,runSpacing:8,children:[
                    _metric('Views',a.views),_metric('Saves',a.saves),_metric('Reviews',a.reviews),_metric('Contacts',a.contacts)
                  ]),
                  const SizedBox(height:12),
                  LinearProgressIndicator(value:(a.engagementRate/100).clamp(0,1)),
                  const SizedBox(height:6),
                  Text('Engagement: '+a.engagementRate.toStringAsFixed(1)+'%'),
                ])));
              },
            )),
          ]);
        },
      ),
    );
  }
  static Widget _metric(String label,int value)=>Chip(
    avatar:const Icon(Icons.insights_outlined,size:18),
    label:Text(label+': '+value.toString()),
  );
}
