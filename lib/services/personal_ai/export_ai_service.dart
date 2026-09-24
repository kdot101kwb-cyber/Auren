import 'package:cloud_firestore/cloud_firestore.dart';
import '../business/business_repository.dart';
import '../goals/goal_repository.dart';

class AurenExportPlan {
 final String product, market, origin, destination, mode;
 final List<String> steps, checks;
 const AurenExportPlan({required this.product,required this.market,required this.origin,required this.destination,required this.mode,required this.steps,required this.checks});
 Map<String,dynamic> toMap()=>{'product':product,'market':market,'origin':origin,'destination':destination,'mode':mode,'steps':steps,'checks':checks,'updatedAt':FieldValue.serverTimestamp()};
}
class ExportAiService {
 final BusinessRepository businesses; final GoalRepository goals; final FirebaseFirestore db;
 ExportAiService({BusinessRepository? businesses,GoalRepository? goals,FirebaseFirestore? firestore}):businesses=businesses??BusinessRepository(),goals=goals??GoalRepository(),db=firestore??FirebaseFirestore.instance;
 Future<AurenExportPlan> build(String uid,{required String product,required String destination,required String mode}) async {
  final bs=await businesses.watchPublic().first; final mine=bs.where((b)=>b.ownerId==uid).toList(); final gs=await goals.watch(uid).first; final origin=mine.isNotEmpty?mine.first.country:'';
  final steps=<String>['حدد المنتج والمواصفات والكمية والسعر المستهدف.','تحقق من متطلبات التصدير في بلد المنشأ والاستيراد في '+destination+'.','راجع التصنيف الجمركي والرسوم والضرائب مع جهة مختصة.','جهّز الفاتورة وقائمة التعبئة وشهادة المنشأ وأي شهادات مطلوبة.','اختر طريقة النقل '+mode+' واحسب الشحن والتأمين والمدة.','ابحث عن مشترٍ أو موزع موثوق وابدأ بعرض تجاري واضح.','راجع العقد وشروط التسليم والدفع قبل أي التزام.'];
  if(gs.any((g)=>g.status=='active')) steps.insert(0,'اربط خطة التصدير بأقرب هدف نشط لديك ثم حدّد نتيجة قابلة للقياس.');
  final checks=<String>['صلاحية المنتج للتصدير والاستيراد','التصنيف الجمركي HS والرسوم','المستندات والشهادات','شروط Incoterms','الشحن والتأمين والتخليص','التحقق من المشتري والدفع','القيود والعقوبات ومتطلبات الامتثال'];
  final plan=AurenExportPlan(product:product.trim(),market:destination.trim(),origin:origin,destination:destination.trim(),mode:mode,steps:steps,checks:checks);
  await db.collection('users').doc(uid).collection('export_ai_plans').doc('current').set(plan.toMap()); return plan;
 }
}