import 'package:cloud_firestore/cloud_firestore.dart';

class CropDiseaseAnalysis {
  final String id, crop, symptom, severity, result;
  final List<String> actions;
  final DateTime? createdAt;
  const CropDiseaseAnalysis({required this.id, required this.crop, required this.symptom, required this.severity, required this.result, required this.actions, required this.createdAt});
  factory CropDiseaseAnalysis.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {}; final a = d['actions'];
    return CropDiseaseAnalysis(id: doc.id, crop: (d['crop'] ?? '').toString(), symptom: (d['symptom'] ?? '').toString(), severity: (d['severity'] ?? 'medium').toString(), result: (d['result'] ?? '').toString(), actions: a is List ? a.map((e) => e.toString()).toList() : const [], createdAt: (d['createdAt'] as Timestamp?)?.toDate());
  }
}
class CropDiseaseIntelligenceService {
  final FirebaseFirestore db;
  CropDiseaseIntelligenceService({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  CropDiseaseAnalysis analyze({required String crop, required String symptom, required String severity}) {
    final s = symptom.toLowerCase(); final findings = <String>[];
    if (s.contains('بقع') || s.contains('spot')) findings.add('قد تكون الأسباب فطرية أو بكتيرية أو غيرها؛ يلزم فحص شكل البقع ومكانها.');
    else if (s.contains('اصفرار') || s.contains('yellow')) findings.add('الاصفرار قد يرتبط بنقص عناصر أو مشكلة جذور أو ماء أو مرض؛ العرض وحده لا يكفي للتشخيص.');
    else if (s.contains('ذبول') || s.contains('wilt')) findings.add('الذبول قد ينتج من إجهاد مائي أو مشكلة جذور أو مرض؛ افحص الرطوبة والجذور وانتشار الأعراض.');
    else if (s.contains('حشرة') || s.contains('آفة') || s.contains('insect') || s.contains('pest')) findings.add('قد تكون هناك آفة حشرية؛ افحص آثار التغذية وصوّرها للتعرف الأدق.');
    else findings.add('العرض غير محدد؛ اجمع صورة واضحة وموقع الأعراض ومرحلة النمو وتطور الحالة.');
    final actions = <String>['حدّد المنطقة المصابة قدر الإمكان لمنع الانتشار غير الضروري.', 'صوّر الأوراق والساق والجذور إن أمكن، وسجّل بداية الأعراض والطقس والري.', 'لا تستخدم مبيداً أو جرعة محددة اعتماداً على هذا التحليل وحده؛ راجع الملصق والمختص المحلي.', if (severity == 'high') 'لشدة الحالة، اطلب فحصاً زراعياً محلياً سريعاً.'];
    return CropDiseaseAnalysis(id: '', crop: crop.trim(), symptom: symptom.trim(), severity: severity, result: findings.join(' '), actions: actions, createdAt: null);
  }
  Future<String> save({required String uid, required CropDiseaseAnalysis analysis}) async {
    final ref = db.collection('users').doc(uid).collection('agricultureNotes').doc();
    await ref.set({'title': 'Crop Disease • ' + analysis.crop, 'note': analysis.result + '\n' + analysis.actions.map((e) => '• ' + e).join('\n'), 'type': 'field', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    return ref.id;
  }
  Stream<List<CropDiseaseAnalysis>> watch({required String uid}) => db.collection('users').doc(uid).collection('agricultureNotes').where('type', isEqualTo: 'field').limit(100).snapshots().map((s) => s.docs.where((d) => (d.data()['title'] ?? '').toString().startsWith('Crop Disease •')).map(CropDiseaseAnalysis.fromDoc).toList());
  Future<void> delete({required String uid, required String id}) => db.collection('users').doc(uid).collection('agricultureNotes').doc(id).delete();
}
