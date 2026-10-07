import 'package:flutter/material.dart';
import '../../../services/talent/talent_repository.dart';

class AurenTalentVerificationScreen extends StatefulWidget {
 final String talentId, ownerId; final List<String> currentEvidence;
 const AurenTalentVerificationScreen({super.key, required this.talentId, required this.ownerId, this.currentEvidence=const []});
 @override State<AurenTalentVerificationScreen> createState()=>_AurenTalentVerificationScreenState();
}
class _AurenTalentVerificationScreenState extends State<AurenTalentVerificationScreen>{
 final repo=TalentRepository(); final controller=TextEditingController(); bool saving=false;
 @override void initState(){super.initState(); controller.text=widget.currentEvidence.join(', ');}
 @override void dispose(){controller.dispose();super.dispose();}
 Future<void> _save() async { final values=controller.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toSet().take(10).toList(); setState(()=>saving=true); try { await repo.updateVerificationEvidence(talentId:widget.talentId, ownerId:widget.ownerId, evidence:values); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ أدلة التحقق.'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ الأدلة: $e'))); } finally {if(mounted)setState(()=>saving=false);} }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Talent Verification')),body:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('أدلة التحقق',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('أضف روابط أو نتائج أو شهادات أو مقاطع تثبت مهاراتك. الإضافة لا تعني اعتماداً رسمياً؛ الاعتماد النهائي يحتاج جهة موثوقة.'),const SizedBox(height:16),TextField(controller:controller,maxLines:6,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'الأدلة، افصل بينها بفاصلة')),const SizedBox(height:16),FilledButton.icon(onPressed:saving?null:_save,icon:const Icon(Icons.verified_outlined),label:Text(saving?'جارٍ الحفظ...':'حفظ الأدلة'))])));
}