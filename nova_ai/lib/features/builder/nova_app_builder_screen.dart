import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_runtime.dart';

class NovaAppBuilderScreen extends StatefulWidget {
  const NovaAppBuilderScreen({super.key});

  @override
  State<NovaAppBuilderScreen> createState() => _NovaAppBuilderScreenState();
}

class _NovaAppBuilderScreenState extends State<NovaAppBuilderScreen> {
  final _brief = TextEditingController();
  final _criteria = TextEditingController();
  String _type = 'flutter_app';
  String _stack = 'flutter';
  bool _busy = false;
  String? _message;
  String? _jobId;
  Map<String, dynamic>? _job;

  @override
  void dispose() {
    _brief.dispose();
    _criteria.dispose();
    super.dispose();
  }

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _submit() async {
    if (_brief.text.trim().length < 12) {
      setState(() => _message = 'اكتب وصفاً واضحاً للمشروع، 12 حرفاً على الأقل.');
      return;
    }
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      setState(() => _message = NovaFirebaseRuntime.initializationError ??
          'جهّز Firebase وApp Check أولاً.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureAuth();
      final response = await FirebaseFunctions.instanceFor(region:'us-central1')
          .httpsCallable('submitNovaBuildJob').call(<String, dynamic>{
        'type':_type, 'stack':_stack, 'prompt':_brief.text.trim(),
        'acceptanceCriteria':_criteria.text.split('\n').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(),
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      _jobId = data['jobId'] as String?;
      _message = '${data['message'] ?? 'تم إرسال الطلب'}\nالمعرف: $_jobId';
    } catch (error) {
      _message = 'تعذر تسجيل مهمة البناء: $error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    if (_jobId == null) return;
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureAuth();
      final response = await FirebaseFunctions.instanceFor(region:'us-central1')
          .httpsCallable('getNovaBuildJob').call(<String, dynamic>{'jobId':_jobId});
      setState(() => _job = Map<String, dynamic>.from(response.data as Map));
    } catch (error) {
      setState(() => _message = 'تعذر تحديث الحالة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('مهندس التطبيقات والصفحات', style: TextStyle(fontSize:23, fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      const Text('اكتب فكرتك أو اطلب إصلاح مشروع موجود. التصميم والكود والاختبارات تُسجل كمتطلبات واضحة، ولا نعلن النجاح قبل ظهور نتائج فحص فعلية.'),
      const SizedBox(height:14),
      DropdownButtonFormField<String>(
        value:_type,
        decoration:const InputDecoration(labelText:'المهمة', border:OutlineInputBorder()),
        items:const [
          DropdownMenuItem(value:'flutter_app', child:Text('تصميم وبناء تطبيق Flutter')),
          DropdownMenuItem(value:'web_app', child:Text('تطبيق ويب')),
          DropdownMenuItem(value:'landing_page', child:Text('صفحة هبوط أو موقع')),
          DropdownMenuItem(value:'debug_existing', child:Text('إصلاح أخطاء مشروع موجود')),
          DropdownMenuItem(value:'redesign_existing', child:Text('إعادة تصميم واجهة موجودة')),
        ],
        onChanged:_busy ? null : (v) { if(v != null) setState(() {_type=v; _stack=v=='flutter_app'?'flutter':v=='landing_page'?'static_web':'web';}); },
      ),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(
        value:_stack,
        decoration:const InputDecoration(labelText:'التقنية', border:OutlineInputBorder()),
        items:const [
          DropdownMenuItem(value:'auto', child:Text('اختيار التقنية تلقائياً')),
          DropdownMenuItem(value:'flutter', child:Text('Flutter / Dart')),
          DropdownMenuItem(value:'web', child:Text('Web / JavaScript / TypeScript')),
          DropdownMenuItem(value:'static_web', child:Text('HTML / CSS / JavaScript')),
        ],
        onChanged:_busy ? null : (v) { if(v != null) setState(() => _stack=v); },
      ),
      const SizedBox(height:10),
      TextField(controller:_brief, minLines:5, maxLines:10, decoration:const InputDecoration(labelText:'وصف التطبيق أو الصفحة', hintText:'المستخدمون، الصفحات، الألوان، الميزات، تسجيل الدخول، قاعدة البيانات…', border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:_criteria, minLines:2, maxLines:5, decoration:const InputDecoration(labelText:'شروط النجاح (اختياري، كل شرط في سطر)', hintText:'يفتح دون أخطاء\nتعمل الأزرار\nتجتاز الاختبارات', border:OutlineInputBorder())),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:_busy ? null : _submit, icon:const Icon(Icons.rocket_launch), label:Text(_busy?'جاري الإرسال…':'إنشاء مهمة البناء')),
      if (_jobId != null) OutlinedButton.icon(onPressed:_busy ? null : _refresh, icon:const Icon(Icons.refresh), label:const Text('تحديث حالة المهمة')),
      if (_message != null) Padding(padding:const EdgeInsets.symmetric(vertical:10), child:Text(_message!, textDirection:TextDirection.rtl)),
      if (_job != null) ...[
        Card(child:Padding(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text('الحالة: ${_job!['status']} — المرحلة: ${_job!['stage']}', style:const TextStyle(fontWeight:FontWeight.bold)),
          Text('المحاولات: ${_job!['attempts'] ?? 0}/${_job!['maxAttempts'] ?? 3}'),
          if (_job!['summary'] is String) Text(_job!['summary'] as String),
          if (_job!['error'] is String) Text('الخطأ: ${_job!['error']}', style:const TextStyle(color:Colors.orangeAccent)),
          for (final check in (_job!['checks'] as List? ?? const []))
            Text('• ${check is Map ? check['name'] : check}: ${check is Map ? check['conclusion'] ?? check['status'] : ''}'),
          for (final artifact in (_job!['artifacts'] as List? ?? const []))
            if (artifact is Map && artifact['url'] is String)
              SelectableText('${artifact['name'] ?? 'Artifact'}: ${artifact['url']}'),
        ]))),
      ],
      const SizedBox(height:10),
      const Text('مهم: هذه الواجهة تسجل المهمة وتعرض حالتها. لا يوجد بعد عامل بناء معزول موصول بالطابور، لذلك لن تدّعي أن APK أو موقعاً قد تم بناؤه قبل تفعيل هذا العامل واجتياز الفحوصات.'),
    ],
  );
}
