import 'package:flutter/material.dart';
import '../../../services/local/local_intelligence_service.dart';
import '../../../core/models/business.dart';
import '../../../core/models/opportunity.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenLocalIntelligenceScreen extends StatefulWidget{
 const AurenLocalIntelligenceScreen({super.key});
 @override State<AurenLocalIntelligenceScreen> createState()=>_AurenLocalIntelligenceScreenState();
}
class _AurenLocalIntelligenceScreenState extends State<AurenLocalIntelligenceScreen>{
 final city=TextEditingController(),country=TextEditingController();
 String c='',co='';
 @override void dispose(){city.dispose();country.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Local Intelligence')),body:ListView(padding:const EdgeInsets.all(16),children:[
 Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[TextField(controller:city,decoration:const InputDecoration(labelText:'المدينة',prefixIcon:Icon(Icons.location_city))),TextField(controller:country,decoration:const InputDecoration(labelText:'الدولة',prefixIcon:Icon(Icons.public))),const SizedBox(height:10),FilledButton.icon(onPressed:(){setState((){c=city.text;co=country.text;});},icon:const Icon(Icons.search),label:const Text('استكشف منطقتي'))])),
 if(c.isNotEmpty||co.isNotEmpty) StreamBuilder<AurenLocalSnapshot>(stream:AurenLocalIntelligenceService().watch(city:c,country:co),builder:(context,s){
   if(s.hasError)return Text('تعذر تحميل البيانات المحلية: ${s.error}');
   if(!s.hasData)return const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));
   final x=s.data!; return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:Text([x.city,x.country].where((v)=>v.isNotEmpty).join(' • ')),subtitle:Text('${x.businesses.length} Business • ${x.opportunities.length} Opportunities'),trailing:IconButton(icon:const Icon(Icons.chat_outlined),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'حلّل لي المشهد المحلي في ${[x.city,x.country].where((v)=>v.isNotEmpty).join('، ')}: الأعمال، الفرص، الخدمات والاحتياجات المحتملة.')))))),
    const SizedBox(height:10),const Text('Businesses',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    ...x.businesses.take(8).map((b)=>Card(child:ListTile(leading:const Icon(Icons.storefront_outlined),title:Text(b.name),subtitle:Text([b.category,b.businessType,b.city].where((v)=>v.isNotEmpty).join(' • '))))),
    const SizedBox(height:10),const Text('Opportunities',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    ...x.opportunities.take(8).map((o)=>Card(child:ListTile(leading:const Icon(Icons.work_outline),title:Text(o.title),subtitle:Text([o.category,o.type,o.city].where((v)=>v.isNotEmpty).join(' • '))))),
   ]);
 }),
 ]));
}
