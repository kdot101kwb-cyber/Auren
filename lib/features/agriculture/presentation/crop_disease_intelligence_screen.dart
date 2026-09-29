import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/agriculture/crop_disease_intelligence_service.dart';

class CropDiseaseIntelligenceScreen extends StatefulWidget {
  const CropDiseaseIntelligenceScreen({super.key});
  @override State<CropDiseaseIntelligenceScreen> createState()=>_CropDiseaseIntelligenceScreenState();
}
class _CropDiseaseIntelligenceScreenState extends State<CropDiseaseIntelligenceScreen>{
  final crop=TextEditingController(); final symptom=TextEditingController(); String severity='medium'; final service=CropDiseaseIntelligenceService(); CropDiseaseAnalysis? result;
  @override void dispose(){crop.dispose();symptom.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Crop Disease AI')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('ذكاء أمراض وآفات المحاصيل',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),
    const Text('تحليل احتمالي للأعراض، وليس تشخيصاً مؤكداً. الصور والفحص المحلي يحسّنان الدقة.'),
    const SizedBox(height:12),TextField(controller:crop,decoration:const InputDecoration(labelText:'المحصول',border:OutlineInputBorder())),
    const SizedBox(height:8),TextField(controller:symptom,minLines:4,maxLines:7,decoration:const InputDecoration(labelText:'الأعراض (مثلاً: بقع، اصفرار، ذبول، حشرات)',border:OutlineInputBorder())),
    const SizedBox(height:8),DropdownButtonFormField<String>(value:severity,decoration:const InputDecoration(labelText:'الشدة',border:OutlineInputBorder()),items:const[DropdownMenuItem(value:'low',child:Text('منخفضة')),DropdownMenuItem(value:'medium',child:Text('متوسطة')),DropdownMenuItem(value:'high',child:Text('عالية'))],onChanged:(x){if(x!=null)setState(()=>severity=x);}),
    const SizedBox(height:10),FilledButton.icon(onPressed:(){setState(()=>result=service.analyze(crop:crop.text,symptom:symptom.text,severity:severity));},icon:const Icon(Icons.health_and_safety_outlined),label:const Text('حلل الحالة')),
    if(result!=null)...[const SizedBox(height:16),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('التحليل الأولي',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(result!.result),const SizedBox(height:10),for(final a in result!.actions)Padding(padding:const EdgeInsets.only(bottom:6),child:Text('• $a'))]))),
    if(FirebaseAuth.instance.currentUser!=null)FilledButton.icon(onPressed:()async{await service.save(uid:FirebaseAuth.instance.currentUser!.uid,analysis:result!);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ تحليل الحالة')));},icon:const Icon(Icons.save_outlined),label:const Text('حفظ التحليل'))
  ]));
}
