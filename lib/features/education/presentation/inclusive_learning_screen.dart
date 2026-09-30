import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/inclusive_learning_service.dart';

class InclusiveLearningScreen extends StatefulWidget{const InclusiveLearningScreen({super.key});@override State<InclusiveLearningScreen> createState()=>_InclusiveLearningScreenState();}
class _InclusiveLearningScreenState extends State<InclusiveLearningScreen>{
 final service=InclusiveLearningService(); AccessibilityNeed need=AccessibilityNeed.none; String language='العربية'; bool captions=true,audioDescription=false,reducedMotion=false,largeText=false,highContrast=false,voiceControl=false,saving=false; double pace=1.0;
 Future<void> _save() async{final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;setState(()=>saving=true);await service.saveProfile(uid,InclusiveLearningProfile(need:need,language:language,captions:captions,audioDescription:audioDescription,reducedMotion:reducedMotion,largeText:largeText,highContrast:highContrast,voiceControl:voiceControl,pace:pace));if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ إعدادات التعلم الميسر')));}}
 @override Widget build(BuildContext context){return Scaffold(appBar:AppBar(title:const Text('Inclusive Learning')),body:ListView(padding:const EdgeInsets.all(16),children:[
  const Card(child:Padding(padding:EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.accessibility_new,size:38),SizedBox(height:10),Text('تعلم بالطريقة المناسبة لك',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),SizedBox(height:6),Text('AUREN يكيّف الدرس والسرعة وطريقة العرض حسب تفضيلاتك واحتياجك.')] ))),
  const SizedBox(height:14),
  DropdownButtonFormField<AccessibilityNeed>(value:need,decoration:const InputDecoration(labelText:'طريقة الدعم المفضلة'),items:AccessibilityNeed.values.map((x)=>DropdownMenuItem(value:x,child:Text(_label(x)))).toList(),onChanged:(v)=>setState(()=>need=v??AccessibilityNeed.none)),
  DropdownButtonFormField<String>(value:language,decoration:const InputDecoration(labelText:'لغة التعلم'),items:const ['العربية','English','Français','Español','Português','Türkçe'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>language=v??language)),
  SwitchListTile(title:const Text('الترجمة النصية'),value:captions,onChanged:(v)=>setState(()=>captions=v)),
  SwitchListTile(title:const Text('الوصف الصوتي'),value:audioDescription,onChanged:(v)=>setState(()=>audioDescription=v)),
  SwitchListTile(title:const Text('تحكم صوتي'),value:voiceControl,onChanged:(v)=>setState(()=>voiceControl=v)),
  SwitchListTile(title:const Text('نص أكبر'),value:largeText,onChanged:(v)=>setState(()=>largeText=v)),
  SwitchListTile(title:const Text('تباين أعلى'),value:highContrast,onChanged:(v)=>setState(()=>highContrast=v)),
  SwitchListTile(title:const Text('تقليل الحركة'),value:reducedMotion,onChanged:(v)=>setState(()=>reducedMotion=v)),
  Text('سرعة التعلم: ${pace.toStringAsFixed(1)}x'),Slider(value:pace,min:.5,max:1.5,divisions:10,onChanged:(v)=>setState(()=>pace=v)),
  FilledButton.icon(onPressed:saving?null:_save,icon:const Icon(Icons.save_outlined),label:Text(saving?'جارٍ الحفظ...':'حفظ الإعدادات')),
 ]); }
 static String _label(AccessibilityNeed x){switch(x){case AccessibilityNeed.none:return 'بدون دعم إضافي';case AccessibilityNeed.lowVision:return 'ضعف البصر';case AccessibilityNeed.blind:return 'فقدان البصر';case AccessibilityNeed.hardOfHearing:return 'ضعف السمع';case AccessibilityNeed.deaf:return 'فقدان السمع';case AccessibilityNeed.speech:return 'النطق والكلام';case AccessibilityNeed.auditory:return 'الصوتيات والسمع';case AccessibilityNeed.learningDifficulty:return 'صعوبات التعلم';case AccessibilityNeed.motor:return 'الإعاقة الحركية';}}
}
