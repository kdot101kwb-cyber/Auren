import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class IrrigationPlan {
  final String id, crop, field;
  final double areaHa, soilWaterMm, weeklyCropNeedMm, rainfallMm, efficiency, irrigationMm, weeklyWaterM3;
  final List<String> checks;
  final DateTime createdAt;
  const IrrigationPlan({required this.id,required this.crop,required this.field,required this.areaHa,required this.soilWaterMm,required this.weeklyCropNeedMm,required this.rainfallMm,required this.efficiency,required this.irrigationMm,required this.weeklyWaterM3,required this.checks,required this.createdAt});
  Map<String,dynamic> toJson()=>{'crop':crop,'field':field,'areaHa':areaHa,'soilWaterMm':soilWaterMm,'weeklyCropNeedMm':weeklyCropNeedMm,'rainfallMm':rainfallMm,'efficiency':efficiency,'irrigationMm':irrigationMm,'weeklyWaterM3':weeklyWaterM3,'checks':checks,'createdAt':createdAt.toIso8601String()};
  factory IrrigationPlan.fromNote(String id,Map<String,dynamic> d){final j=jsonDecode((d['note']??'{}').toString()) as Map<String,dynamic>;return IrrigationPlan(id:id,crop:(j['crop']??'').toString(),field:(j['field']??'').toString(),areaHa:(j['areaHa'] as num?)?.toDouble()??0,soilWaterMm:(j['soilWaterMm'] as num?)?.toDouble()??0,weeklyCropNeedMm:(j['weeklyCropNeedMm'] as num?)?.toDouble()??0,rainfallMm:(j['rainfallMm'] as num?)?.toDouble()??0,efficiency:(j['efficiency'] as num?)?.toDouble()??0,irrigationMm:(j['irrigationMm'] as num?)?.toDouble()??0,weeklyWaterM3:(j['weeklyWaterM3'] as num?)?.toDouble()??0,checks:(j['checks'] as List?)?.map((e)=>e.toString()).toList()??const[],createdAt:DateTime.tryParse((j['createdAt']??'').toString())??DateTime.now());}
}
class IrrigationIntelligenceService{
 final FirebaseFirestore db; IrrigationIntelligenceService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 IrrigationPlan calculate({required String crop,required String field,required double areaHa,required double soilWaterMm,required double weeklyCropNeedMm,required double rainfallMm,required double efficiencyPercent}){
  final a=areaHa.clamp(.01,100000).toDouble(); final e=efficiencyPercent.clamp(30,100)/100;
  final net=(weeklyCropNeedMm.clamp(0,500)-rainfallMm.clamp(0,500)-soilWaterMm.clamp(0,500)).clamp(0,500).toDouble(); final gross=net/e;
  return IrrigationPlan(id:'',crop:crop.trim(),field:field.trim(),areaHa:a,soilWaterMm:soilWaterMm,weeklyCropNeedMm:weeklyCropNeedMm,rainfallMm:rainfallMm,efficiency:e*100,irrigationMm:gross,weeklyWaterM3:gross*a*10,checks:const['تحقق من رطوبة التربة قبل الري','راجع توقعات المطر قبل تشغيل النظام','افحص التسرب والضغط والمضخات','عدّل الخطة حسب مرحلة نمو المحصول والطقس'],createdAt:DateTime.now());
 }
 Future<String> save(String uid,IrrigationPlan p)async{final ref=db.collection('users').doc(uid).collection('agricultureNotes').doc();await ref.set({'title':'Irrigation Plan • '+p.crop+' • '+p.field,'note':jsonEncode(p.toJson()),'type':'field','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});return ref.id;}
 Stream<List<IrrigationPlan>> watch(String uid)=>db.collection('users').doc(uid).collection('agricultureNotes').where('type',isEqualTo:'field').limit(100).snapshots().map((s){final out=<IrrigationPlan>[];for(final d in s.docs){try{if((d.data()['title']??'').toString().startsWith('Irrigation Plan •'))out.add(IrrigationPlan.fromNote(d.id,d.data()));}catch(_){}}out.sort((a,b)=>b.createdAt.compareTo(a.createdAt));return out;});
 Future<void> delete(String uid,String id)=>db.collection('users').doc(uid).collection('agricultureNotes').doc(id).delete();
}