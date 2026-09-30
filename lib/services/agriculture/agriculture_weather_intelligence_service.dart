import 'package:cloud_firestore/cloud_firestore.dart';
class WeatherRisk {
  final String id, location, crop, summary; final double rainfallMm, temperatureC, windKmh;
  final List<String> alerts; final DateTime? createdAt;
  const WeatherRisk({required this.id,required this.location,required this.crop,required this.rainfallMm,required this.temperatureC,required this.windKmh,required this.summary,required this.alerts,required this.createdAt});
  factory WeatherRisk.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()??const{};final a=x['alerts'];return WeatherRisk(id:d.id,location:(x['location']??'').toString(),crop:(x['crop']??'').toString(),rainfallMm:(x['rainfallMm']as num?)?.toDouble()??0,temperatureC:(x['temperatureC']as num?)?.toDouble()??0,windKmh:(x['windKmh']as num?)?.toDouble()??0,summary:(x['summary']??'').toString(),alerts:a is List?a.map((e)=>e.toString()).toList():const[],createdAt:(x['createdAt']as Timestamp?)?.toDate());}
}
class AgricultureWeatherIntelligenceService{
 final FirebaseFirestore db; AgricultureWeatherIntelligenceService({FirebaseFirestore?firestore}):db=firestore??FirebaseFirestore.instance;
 WeatherRisk analyze({required String location,required String crop,required double rainfallMm,required double temperatureC,required double windKmh}){
  final a=<String>[];if(temperatureC>=40)a.add('حرارة مرتفعة جداً؛ راقب الإجهاد الحراري والماء.');if(temperatureC<=5)a.add('برودة شديدة؛ راقب خطر الضرر للمحصول.');if(rainfallMm>=50)a.add('أمطار غزيرة متوقعة/مسجلة؛ راقب تجمع المياه والأمراض الفطرية.');if(windKmh>=40)a.add('رياح قوية؛ افحص تثبيت النباتات والمنشآت والري.');
  return WeatherRisk(id:'',location:location.trim(),crop:crop.trim(),rainfallMm:rainfallMm,temperatureC:temperatureC,windKmh:windKmh,summary:a.isEmpty?'لا توجد إشارة طقس حرجة وفق الحدود المبسطة المدخلة.':a.join(' '),alerts:a,createdAt:null);
 }
 Future<String> save({required String uid,required WeatherRisk risk})async{final r=db.collection('users').doc(uid).collection('agricultureNotes').doc();await r.set({'title':'Weather Risk • '+risk.location,'note':risk.summary+'\n'+risk.alerts.map((e)=>'• '+e).join('\n'),'type':'field','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});return r.id;}
}