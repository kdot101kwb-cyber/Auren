import 'package:cloud_firestore/cloud_firestore.dart';

class SoilAnalysis {
  final String id, crop, field, summary;
  final double ph, ec, nitrogen, phosphorus, potassium, organicMatter;
  final List<String> actions;
  final DateTime? createdAt;
  const SoilAnalysis({required this.id, required this.crop, required this.field, required this.ph, required this.ec, required this.nitrogen, required this.phosphorus, required this.potassium, required this.organicMatter, required this.summary, required this.actions, required this.createdAt});
  factory SoilAnalysis.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final a = d['actions'];
    return SoilAnalysis(id: doc.id, crop: (d['crop'] ?? '').toString(), field: (d['field'] ?? '').toString(), ph: (d['ph'] as num?)?.toDouble() ?? 7, ec: (d['ec'] as num?)?.toDouble() ?? 0, nitrogen: (d['nitrogen'] as num?)?.toDouble() ?? 0, phosphorus: (d['phosphorus'] as num?)?.toDouble() ?? 0, potassium: (d['potassium'] as num?)?.toDouble() ?? 0, organicMatter: (d['organicMatter'] as num?)?.toDouble() ?? 0, summary: (d['summary'] ?? '').toString(), actions: a is List ? a.map((e) => e.toString()).toList() : const [], createdAt: (d['createdAt'] as Timestamp?)?.toDate());
  }
}
class SoilIntelligenceService {
  final FirebaseFirestore db;
  SoilIntelligenceService({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  SoilAnalysis calculate({required String crop, required String field, required double ph, required double ec, required double nitrogen, required double phosphorus, required double potassium, required double organicMatter}) {
    final flags = <String>[];
    if (ph < 5.5) flags.add('التربة حمضية نسبياً؛ راجع احتياج المحصول للتعديل.');
    if (ph > 8.0) flags.add('التربة قلوية نسبياً؛ راجع الملوحة والعناصر الدقيقة.');
    if (ec > 4) flags.add('EC مرتفع؛ افحص ملوحة مياه الري والتربة قبل زيادة الأسمدة.');
    if (nitrogen < 20) flags.add('النيتروجين منخفض وفق المؤشر المبسط؛ راجع تحليل المختبر.');
    if (phosphorus < 10) flags.add('الفوسفور منخفض وفق المؤشر المبسط؛ راجع تحليل المختبر.');
    if (potassium < 100) flags.add('البوتاسيوم منخفض وفق المؤشر المبسط؛ راجع تحليل المختبر.');
    if (organicMatter < 1) flags.add('المادة العضوية منخفضة وفق المؤشر المبسط؛ راجع إدارة المواد العضوية.');
    final actions = <String>['قارن النتائج بتحليل مختبر محلي والوحدات قبل قرار التسميد.', if (flags.isNotEmpty) 'عالج العوامل ذات الأولوية ثم أعد القياس.', 'سجّل المحصول ومرحلة النمو ومصدر مياه الري لتحسين التوصية.'];
    return SoilAnalysis(id: '', crop: crop.trim(), field: field.trim(), ph: ph, ec: ec, nitrogen: nitrogen, phosphorus: phosphorus, potassium: potassium, organicMatter: organicMatter, summary: flags.isEmpty ? 'لا تظهر مؤشرات واضحة خارج الحدود المبسطة المدخلة.' : flags.join(' '), actions: actions, createdAt: null);
  }
  Future<String> save({required String uid, required SoilAnalysis analysis}) async {
    final ref = db.collection('users').doc(uid).collection('agricultureNotes').doc();
    await ref.set({'title': 'Soil Analysis • ' + (analysis.field.isEmpty ? analysis.crop : analysis.field), 'note': analysis.summary + '\n' + analysis.actions.map((e) => '• ' + e).join('\n'), 'type': 'field', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
    return ref.id;
  }
  Stream<List<SoilAnalysis>> watch({required String uid}) => db.collection('users').doc(uid).collection('agricultureNotes').where('type', isEqualTo: 'field').limit(100).snapshots().map((s) => s.docs.where((d) => (d.data()['title'] ?? '').toString().startsWith('Soil Analysis •')).map(SoilAnalysis.fromDoc).toList());
  Future<void> delete({required String uid, required String id}) => db.collection('users').doc(uid).collection('agricultureNotes').doc(id).delete();
}
