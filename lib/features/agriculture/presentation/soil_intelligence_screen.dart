import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/agriculture/soil_intelligence_service.dart';

class SoilIntelligenceScreen extends StatefulWidget {
  const SoilIntelligenceScreen({super.key});
  @override State<SoilIntelligenceScreen> createState() => _SoilIntelligenceScreenState();
}
class _SoilIntelligenceScreenState extends State<SoilIntelligenceScreen> {
  final crop=TextEditingController(), field=TextEditingController();
  final ph=TextEditingController(text:'7'), ec=TextEditingController(text:'1'), n=TextEditingController(text:'30'), p=TextEditingController(text:'15'), k=TextEditingController(text:'150'), om=TextEditingController(text:'2');
  final service=SoilIntelligenceService(); SoilAnalysis? result;
  @override void dispose(){for(final c in [crop,field,ph,ec,n,p,k,om]) c.dispose(); super.dispose();}
  double v(TextEditingController c)=>double.tryParse(c.text.trim())??0;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Soil Intelligence AI')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('تحليل التربة الذكي',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
    const SizedBox(height:8), const Text('أدخل نتائج القياس. المؤشرات تقريبية ولا تغني عن تحليل مختبر محلي.'),
    const SizedBox(height:12), _f(crop,'المحصول'),_f(field,'الحقل / المزرعة'),
    Row(children:[Expanded(child:_f(ph,'pH')),const SizedBox(width:8),Expanded(child:_f(ec,'EC'))]),
    Row(children:[Expanded(child:_f(n,'N')),const SizedBox(width:8),Expanded(child:_f(p,'P')),const SizedBox(width:8),Expanded(child:_f(k,'K'))]),
    _f(om,'المادة العضوية %'),
    FilledButton.icon(onPressed:(){setState(()=>result=service.calculate(crop:crop.text,field:field.text,ph:v(ph),ec:v(ec),nitrogen:v(n),phosphorus:v(p),potassium:v(k),organicMatter:v(om)));},icon:const Icon(Icons.science_outlined),label:const Text('حلل التربة')),
    if(result!=null) ...[const SizedBox(height:16),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('النتيجة',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(result!.summary),
      const SizedBox(height:10),for(final a in result!.actions) Padding(padding:const EdgeInsets.only(bottom:6),child:Text('• $a')),
    ]))), if(FirebaseAuth.instance.currentUser!=null) FilledButton.icon(onPressed:()async{await service.save(uid:FirebaseAuth.instance.currentUser!.uid,analysis:result!);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ تحليل التربة')));},icon:const Icon(Icons.save_outlined),label:const Text('حفظ التحليل'))
  ]));
  Widget _f(TextEditingController c,String label)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
}
