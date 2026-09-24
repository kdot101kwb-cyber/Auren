import 'package:flutter/material.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../core/models/business.dart';
import '../../../services/personal_ai/local_intelligence_service.dart';

class AurenLocalIntelligenceScreen extends StatefulWidget {
  const AurenLocalIntelligenceScreen({super.key});
  @override State<AurenLocalIntelligenceScreen> createState()=>_AurenLocalIntelligenceScreenState();
}
class _AurenLocalIntelligenceScreenState extends State<AurenLocalIntelligenceScreen>{
  final _city=TextEditingController(); final _country=TextEditingController();
  String _category='All';
  static const _categories=['All','Retail','Food','Services','Technology','Manufacturing','Education','Travel','Creative','Agriculture','Other'];
  @override void dispose(){_city.dispose();_country.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Local Intelligence')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('ذكاء AUREN المحلي',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      const Text('اكتب المدينة والدولة، وAUREN يجمع الأنشطة العامة المتاحة ويرتبها محليًا بدون طلب موقع دقيق.'),
      const SizedBox(height:16),
      TextField(controller:_city,decoration:const InputDecoration(labelText:'المدينة',prefixIcon:Icon(Icons.location_city))),
      const SizedBox(height:10),
      TextField(controller:_country,decoration:const InputDecoration(labelText:'الدولة',prefixIcon:Icon(Icons.public))),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:_category,items:_categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>_category=v??'All'),decoration:const InputDecoration(labelText:'الفئة')),
      const SizedBox(height:16),
      if(_city.text.trim().isEmpty && _country.text.trim().isEmpty)
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[const Icon(Icons.travel_explore,size:40),const SizedBox(height:8),const Text('أدخل موقعًا عامًا للبدء.'),const SizedBox(height:10),FilledButton.icon(onPressed:(){setState((){});},icon:const Icon(Icons.search),label:const Text('اكتشف محليًا'))])))
      else
        StreamBuilder<AurenLocalSnapshot>(
          stream:LocalIntelligenceService().watch(city:_city.text,country:_country.text,category:_category),
          builder:(context,s){
            final data=s.data;
            if(data==null)return const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));
            return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Card(child:ListTile(leading:const Icon(Icons.insights_outlined),title:Text(data.summary),subtitle:Text('${data.city} • ${data.country}'))),
              const SizedBox(height:8),
              if(data.businesses.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد نتائج كافية. جرّب مدينة/فئة أخرى أو اسأل AUREN عبر Messenger.')))
              else ...data.businesses.map((b)=>_businessCard(context,b)),
              const SizedBox(height:8),
              FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'حلّل لي الخدمات والفرص المحلية في ${data.city}، ${data.country} ضمن فئة ${data.category}. استخدم البيانات العامة المتاحة في AUREN ووضح ما يحتاج تحققًا إضافيًا.'))),icon:const Icon(Icons.auto_awesome),label:const Text('حلّل منطقتي مع AUREN'))
            ]);
          }
        )
    ]));
  Widget _businessCard(BuildContext context,AurenBusiness b)=>Card(child:ListTile(
    leading:CircleAvatar(child:Icon(b.verified?Icons.verified:Icons.storefront_outlined)),
    title:Text(b.name,maxLines:1,overflow:TextOverflow.ellipsis),
    subtitle:Text([b.category,b.businessType].where((x)=>x.isNotEmpty).join(' • ')),
    trailing:const Icon(Icons.chevron_right),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'أريد معلومات أكثر عن Business: ${b.name}. اربط لي خدماته بالفرص والأهداف المناسبة.')),
  ));
}
