import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/agriculture/agriculture_weather_intelligence_service.dart';
import '../../../services/agriculture/pest_monitoring_service.dart';
import '../../../services/agriculture/smart_farm_alerts_service.dart';

class AgricultureFinalIntelligenceScreen extends StatefulWidget {
 const AgricultureFinalIntelligenceScreen({super.key});
 @override State<AgricultureFinalIntelligenceScreen> createState()=>_AgricultureFinalIntelligenceScreenState();
}
class _AgricultureFinalIntelligenceScreenState extends State<AgricultureFinalIntelligenceScreen>{
 final loc=TextEditingController(),crop=TextEditingController(),temp=TextEditingController(text:'30'),rain=TextEditingController(text:'0'),wind=TextEditingController(text:'10'),moist=TextEditingController(text:'30'),days=TextEditingController(text:'0'),pest=TextEditingController(),sym=TextEditingController();
 String sev='medium'; WeatherRisk? weather; PestObservation? pestResult;
 final ws=AgricultureWeatherIntelligenceService(); final ps=PestMonitoringService(); final asv=SmartFarmAlertsService();
 double n(TextEditingController c)=>double.tryParse(c.text)??0; int i(TextEditingController c)=>int.tryParse(c.text)??0;
 @override void dispose(){for(final c in[loc,crop,temp,rain,wind,moist,days,pest,sym])c.dispose();super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('AUREN Smart Farm AI')),body:ListView(padding:const EdgeInsets.all(16),children:[
  const Text('الطقس والمخاطر الذكية',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:8),
  _f(loc,'الموقع'),_f(crop,'المحصول'),
  Row(children:[Expanded(child:_f(temp,'الحرارة °C')),const SizedBox(width:8),Expanded(child:_f(rain,'الأمطار mm')),const SizedBox(width:8),Expanded(child:_f(wind,'الرياح km/h'))]),
  FilledButton.icon(onPressed:()=>setState(()=>weather=ws.analyze(location:loc.text,crop:crop.text,rainfallMm:n(rain),temperatureC:n(temp),windKmh:n(wind))),icon:const Icon(Icons.cloud_outlined),label:const Text('حلل الطقس')),
  if(weather!=null)_card('النتيجة',weather!.summary,weather!.alerts),
  const Divider(height:32),const Text('مراقبة الآفات',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),_f(pest,'الآفة إن عُرفت'),_f(sym,'الأعراض'),
  DropdownButtonFormField<String>(value:sev,decoration:const InputDecoration(labelText:'الشدة',border:OutlineInputBorder()),items:const[DropdownMenuItem(value:'low',child:Text('منخفضة')),DropdownMenuItem(value:'medium',child:Text('متوسطة')),DropdownMenuItem(value:'high',child:Text('عالية'))],onChanged:(x){if(x!=null)setState(()=>sev=x);}),
  const SizedBox(height:8),FilledButton.icon(onPressed:()=>setState(()=>pestResult=ps.create(crop:crop.text,pest:pest.text,symptoms:sym.text,severity:sev)),icon:const Icon(Icons.bug_report_outlined),label:const Text('سجل وقيّم الآفة')),
  if(pestResult!=null)_card('المراقبة',pestResult!.action,['الأعراض: ${pestResult!.symptoms}','الشدة: ${pestResult!.severity}']),
  const Divider(height:32),const Text('تنبيهات المزرعة',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const Text('تنبيهات أولية من الطقس والرطوبة وآخر فحص.'),
  _f(moist,'رطوبة التربة %'),_f(days,'أيام منذ آخر فحص'),
  FilledButton.icon(onPressed:(){final a=asv.generate(temperatureC:n(temp),soilMoisture:n(moist),rainfallMm:n(rain),daysSinceLastInspection:i(days));showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('التنبيهات'),content:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:a.isEmpty?[const Text('لا توجد تنبيهات وفق البيانات المدخلة.')]:a.map((x)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Text('• ${x.title}: ${x.message}'))).toList())),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('تم'))]));},icon:const Icon(Icons.notifications_active_outlined),label:const Text('أنشئ التنبيهات'))
 ]));
 Widget _f(TextEditingController x,String l)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:x,keyboardType:TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:l,border:const OutlineInputBorder())));
 Widget _card(String t,String s,List<String>a)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(s),...a.map((x)=>Padding(padding:const EdgeInsets.only(top:6),child:Text('• $x')))])));
}