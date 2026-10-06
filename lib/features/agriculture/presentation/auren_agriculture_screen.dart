import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agriculture/auren_agriculture_repository.dart';

class AurenAgricultureScreen extends StatefulWidget {
  const AurenAgricultureScreen({super.key});
  @override State<AurenAgricultureScreen> createState() => _AurenAgricultureScreenState();
}

class _AurenAgricultureScreenState extends State<AurenAgricultureScreen> {
  final _repo = AurenAgricultureRepository();
  final _location = TextEditingController();
  String _type = 'all';

  @override
  void dispose() { _location.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final type = _type == 'all' ? null : _type;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN AgriTech, Industry & Innovation AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AUREN AgriTech, Industry & Innovation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('من الزراعة والثروة الحيوانية إلى التصنيع والاختراعات والبحث والطاقة وإعادة التدوير.'),
                const SizedBox(height: 14),
                TextField(
                  controller: _location,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'الولاية / المدينة / المنطقة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  for (final item in const {
                    'all':'الكل','crop':'محاصيل','horticulture':'بستنة ومحاصيل بستانية','orchard':'بساتين وأشجار مثمرة','floriculture':'زراعة الزهور','greenhouse':'بيوت محمية','nursery':'مشاتل وشتلات','medicinal_plants':'نباتات طبية وعطرية','agroforestry':'زراعة حراجية','climate_smart':'زراعة ذكية مناخياً','seeds':'بذور وأصناف','livestock':'الثروة الحيوانية','poultry':'دواجن','dairy':'ألبان','aquaculture':'أسماك واستزراع','beekeeping':'نحل وعسل','fisheries':'مصايد وأسماك','veterinary':'بيطرة وصحة حيوانية','animal_nutrition':'تغذية وأعلاف','breeding':'تربية وتناسل','farm':'مزارع','soil':'التربة','fertilizer':'الأسمدة','nutrients':'العناصر الغذائية','potassium':'البوتاسيوم','nitrogen':'النيتروجين','phosphorus':'الفوسفور','pest':'الآفات','plant_disease':'أمراض النبات','irrigation':'الري',
                    'manufacturing':'تصنيع','invention':'اختراعات','research':'بحث','energy':'طاقة','recycling':'تدوير','design':'تصميم','business':'دراسة جدوى','production':'خط إنتاج','costing':'التكاليف','supply_chain':'الموردون','quality':'الجودة','feasibility':'دراسة الجدوى'
                  }.entries)
                    ChoiceChip(label: Text(item.value), selected: _type == item.key, onSelected: (_) => setState(() => _type = item.key)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded),
                  SizedBox(width: 8),
                  Text('AUREN AI الزراعي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 8),
                const Text('إرشادات أولية حسب نوع النشاط. لا تستبدل فحص المختص أو الطبيب البيطري.'),
                const SizedBox(height: 10),
                Text(_aiAdvice(_type), style: const TextStyle(height: 1.45)),
              ]),
            ),
          ),
          FilledButton.icon(
            onPressed: () => _askAi(context),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('اسأل AUREN AI عن الحالة'),
          ),
          if (_type == 'design' || _type == 'business' || _type == 'production' || _type == 'costing' || _type == 'supply_chain' || _type == 'quality' || _type == 'feasibility') ...[
            const SizedBox(height: 16),
            Text(_type == 'design' ? 'AUREN Design Studio' : 'AUREN Business & Production Studio', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            _businessStudios(),
          ],
          const SizedBox(height: 16),
          const Text('السوق والفرص', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          StreamBuilder<List<AurenAgricultureRecord>>(
            stream: _repo.watchOpportunities(),
            builder: (context, snapshot) => _records(snapshot.data ?? const [], Icons.storefront_outlined),
          ),
          const SizedBox(height: 16),
          const Text('المعلومات المحلية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          StreamBuilder<List<AurenAgricultureRecord>>(
            stream: _repo.watchRecords(type: type, location: _location.text),
            builder: (context, snapshot) => _records(snapshot.data ?? const [], Icons.agriculture_outlined),
          ),
          if (uid != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addNote(context, uid),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('إضافة ملاحظة للحقل / المزرعة'),
            ),
          ],
        ],
      ),
    );
  }


  String _aiAdvice(String type) {
    switch (type) {
      case 'crop':
        return 'المحاصيل: راقب رطوبة التربة، حالة الأوراق، الآفات والطقس قبل قرار الري أو المعالجة.';
      case 'livestock':
        return 'الثروة الحيوانية: إدارة القطيع، التغذية، الماء، السكن، الصحة والوقاية مع الرجوع للطبيب البيطري عند المرض.';
      case 'veterinary':
        return 'البيطرة: راقب الأعراض والسلوك والحرارة والتغذية، واعزل الحالة المشتبه بها واستعن بطبيب بيطري للتشخيص والعلاج.';
      case 'animal_nutrition':
        return 'تغذية الحيوان: راعِ النوع والعمر والإنتاج والماء وجودة العلف وتوازن الطاقة والبروتين والمعادن والفيتامينات.';
      case 'breeding':
        return 'التربية والتناسل: سجّل السلالات والأعمار ودورات التناسل والولادات والأداء، مع خطة صحية بيطرية.';
      case 'poultry':
        return 'الدواجن: راقب العلف والماء والتهوية والحرارة والنفوق والنمو، مع إجراءات الأمن الحيوي.';
      case 'dairy':
        return 'الألبان: راقب التغذية والماء وصحة الضرع والنظافة وجودة الحليب والإنتاج.';
      case 'aquaculture':
        return 'الاستزراع السمكي: راقب جودة الماء والأكسجين والكثافة والتغذية والنمو والأمراض.';
      case 'soil':
        return 'التربة: قيّم القوام ودرجة الحموضة والملوحة والمادة العضوية والعناصر الغذائية قبل إضافة المدخلات.';
      case 'fertilizer':
        return 'الأسمدة: اربط التسميد بتحليل التربة واحتياج المحصول وتوقيت التطبيق وتجنب الجرعات العشوائية.';
      case 'nutrients':
        return 'العناصر الغذائية: راقب N-P-K والعناصر الصغرى وأعراض النقص، واعتمد التحليل قبل المعالجة.';
      case 'potassium':
        return 'البوتاسيوم: قيّم تحليل التربة والمحصول وأعراض النقص ومصدر السماد قبل تحديد أي إضافة؛ الجرعة ليست واحدة لكل أرض.';
      case 'nitrogen':
        return 'النيتروجين: اربط الجرعة بالمحصول ومرحلة النمو وتحليل التربة لتقليل الهدر والتلوث.';
      case 'phosphorus':
        return 'الفوسفور: اعتمد على تحليل التربة واحتياج المحصول وتجنب الإفراط الذي قد يسبب خسائر بيئية.';
      case 'pest':
        return 'الآفات: حدّد الآفة ومراحلها وراقب الانتشار وابدأ بالإدارة المتكاملة قبل أي مبيد.';
      case 'plant_disease':
        return 'أمراض النبات: صِف الأعراض ومكانها وتطورها والطقس والري، ولا تعتمد على التشخيص من الوصف وحده.';
      case 'irrigation':
        return 'الري: اربط الكمية والتوقيت بنوع التربة والمحصول والطقس ومرحلة النمو وكفاءة النظام.';
      case 'horticulture':
        return 'البستنة: اختر الصنف والموقع ونظام الري وفق المناخ والتربة، وراقب الإزهار والإثمار والآفات وجودة الثمار.';
      case 'orchard':
        return 'البساتين: خطط للأصناف والتلقيح والري والتقليم والتغذية ومكافحة الآفات وإدارة ما بعد الحصاد.';
      case 'floriculture':
        return 'زراعة الزهور: راقب الصنف والضوء والحرارة والرطوبة والري وجودة التربة ومراحل الإزهار والتسويق.';
      case 'greenhouse':
        return 'البيوت المحمية: راقب الحرارة والرطوبة والتهوية والري والتغذية والآفات، واربط القرارات ببيانات البيئة.';
      case 'nursery':
        return 'المشاتل: ركز على جودة البذور والشتلات والوسط الزراعي والري والتغذية والأمراض والتدرج قبل النقل.';
      case 'medicinal_plants':
        return 'النباتات الطبية والعطرية: وثّق النوع والصنف وظروف الزراعة والحصاد والتجفيف والتخزين، ولا تفترض فوائد علاجية دون دليل.';
      case 'agroforestry':
        return 'الزراعة الحراجية: وازن بين الأشجار والمحاصيل والماء والتربة والتنوع الحيوي ودورة الإنتاج.';
      case 'climate_smart':
        return 'الزراعة الذكية مناخياً: حسّن كفاءة الماء والمدخلات، وراقب مخاطر الحرارة والجفاف والفيضانات وتوقيت العمليات.';
      case 'seeds':
        return 'البذور والأصناف: قارن الصنف والملاءمة المحلية وجودة البذور ومصدرها ومقاومتها وظروف التخزين قبل الزراعة.';
      case 'beekeeping':
        return 'تربية النحل: راقب صحة الطوائف، الغذاء، الماء، الملكة، الآفات، التهوية والمراعي، واستعن بمختص عند الاشتباه بمرض.';
      case 'fisheries':
        return 'المصايد والأسماك: راقب النوع والموسم والمخزون وجودة المياه وسلامة الصيد والتبريد وسلسلة القيمة.';
      case 'farm':
        return 'المزرعة: اجمع بيانات الماء والتربة والمحاصيل والمخزون والتكاليف، ثم استخدمها لاتخاذ قرارات أدق.';
      case 'manufacturing':
        return 'التصنيع: ابدأ بالمواصفات والمواد والعملية، ثم النموذج الأولي والاختبارات والسلامة قبل الإنتاج.';
      case 'invention':
        return 'الاختراعات: وثّق المشكلة والحل، ارسم النموذج، اختبر الفكرة، ثم راجع قابلية التصنيع والملكية الفكرية.';
      case 'research':
        return 'البحث: حدد السؤال والفرضية والبيانات وطريقة الاختبار، وميّز النتائج المقاسة عن الافتراضات.';
      case 'energy':
        return 'الطاقة: قِس الاستهلاك والقدرة المطلوبة ومصدر الطاقة والتخزين والسلامة قبل اختيار النظام.';
      case 'recycling':
        return 'إعادة التدوير: صنّف المواد، افصلها، قيّم إمكانية إعادة الاستخدام والتدوير، وراعِ السلامة والتخلص النظامي.';
      case 'feasibility':
        return 'دراسة الجدوى: السوق، الجانب الفني، الاستثمار والتشغيل، التكاليف، نقطة التعادل، التدفقات النقدية، المخاطر وخطة التنفيذ، مع تخصيصها للزراعة أو الثروة الحيوانية أو التصنيع أو الطاقة أو إعادة التدوير أو التصميم أو الاختراعات.';
      case 'design':
        return 'التصميم: صمّم الملابس والأحذية والمباني والأثاث والمنتجات والواجهات والمساحات. ابدأ بالاحتياج والمقاسات والخامات والميزانية، ثم التصور والنموذج والمراجعة الفنية.';
      default:
        return 'حدد المجال والمشكلة والموقع، ثم سجّل الملاحظات والبيانات والصور والمواد أو المواصفات بانتظام ليصبح التحليل أكثر فائدة.';
    }
  }


  Widget _businessStudios() {
    final studios = _type == 'design'
        ? const [
            ('Fashion & Footwear', 'ملابس، أحذية، حقائب، مقاسات وخامات', Icons.checkroom_outlined),
            ('Architecture & Space', 'مبانٍ، غرف، مكاتب، محلات ومساحات', Icons.architecture_outlined),
            ('Product & Industrial', 'منتجات، أجهزة، أثاث وعبوات', Icons.inventory_2_outlined),
            ('Brand & Visual Identity', 'شعار، هوية، تغليف، إعلانات وواجهات', Icons.brush_outlined),
            ('3D Prototype & Design-to-Make', 'نموذج أولي، مواد، مواصفات وتجهيز للتصنيع', Icons.view_in_ar_outlined),
          ]
        : const [
            ('Feasibility Study', 'دراسة جدوى كاملة لكل القطاعات', Icons.analytics_outlined),
            ('Agriculture Feasibility', 'محاصيل، أرض، ماء، إنتاجية، تكاليف وتسويق', Icons.agriculture_outlined),
            ('Livestock Feasibility', 'القطيع، الأعلاف، الصحة، الإنتاج والتكاليف', Icons.pets_outlined),
            ('Manufacturing Feasibility', 'السوق، خط الإنتاج، المعدات، CAPEX وOPEX', Icons.precision_manufacturing_outlined),
            ('Energy & Recycling Feasibility', 'التقنية، الاستثمار، التشغيل والعائد', Icons.bolt_outlined),
            ('Production Line Planner', 'خط الإنتاج، مراحل التشغيل، المعدات، العمالة والطاقة', Icons.precision_manufacturing_outlined),
            ('Cost & Unit Economics', 'تكلفة الوحدة، الاستثمار، التشغيل، الهدر والتسعير', Icons.calculate_outlined),
            ('Supplier & Materials Plan', 'الخامات، الكميات، الموردون، البدائل والمخزون', Icons.local_shipping_outlined),
            ('Quality & Launch Plan', 'الجودة، الاختبارات، التعبئة، التوزيع وخطة الإطلاق', Icons.verified_outlined),
          ];
    return Column(children: studios.map((s) => Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(s.$3)),
        title: Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(s.$2),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => _openBusinessPrompt(s.$1),
      ),
    )).toList());
  }

  Future<void> _openBusinessPrompt(String studio) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(studio),
        content: TextField(
          controller: controller,
          minLines: 5,
          maxLines: 9,
          decoration: const InputDecoration(
            hintText: 'اسم المشروع، القطاع، المنتج أو النشاط، الموقع، السوق، الطاقة الإنتاجية، الميزانية، الأرض أو المبنى، الموارد، العمالة وأي معلومات متوفرة...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                final advice = await _repo.requestAiAdvice(
                  type: _type == 'design' ? 'design' : _type,
                  location: _location.text,
                  observations: 'Studio: ' + studio + '\n' + controller.text.trim(),
                );
                if (context.mounted) Navigator.pop(context, advice);
              } catch (_) {
                if (context.mounted) Navigator.pop(context, 'تعذر الوصول إلى المستشار حالياً. حاول مرة أخرى.');
              }
            },
            child: const Text('ابدأ التحليل'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AUREN AI'),
        content: SingleChildScrollView(child: Text(result)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
      ),
    );
  }

  Widget _records(List<AurenAgricultureRecord> rows, IconData icon) {
    if (rows.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد بيانات متاحة حالياً.')));
    }
    return Column(children: rows.take(20).map((r) => Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text([r.type, r.location, r.status].where((x) => x.isNotEmpty).join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    )).toList());
  }

  Future<void> _askAi(BuildContext context) async {
    final observations = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحليل AUREN AI'),
        content: TextField(
          controller: observations,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'اكتب الحالة أو المشكلة أو الفكرة التي تريد تحليلها في المجال المختار...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () async {
            if (observations.text.trim().isEmpty) return;
            try {
              final advice = await _repo.requestAiAdvice(
                type: _type == 'all' ? 'farm' : _type,
                location: _location.text,
                observations: observations.text,
                material: '',
                invention: _type == 'invention' ? observations.text : '',
              );
              if (context.mounted) Navigator.pop(context, advice);
            } catch (_) {
              if (context.mounted) Navigator.pop(context, 'تعذر الوصول إلى المستشار حالياً. حاول مرة أخرى.');
            }
          }, child: const Text('تحليل')),
        ],
      ),
    );
    observations.dispose();
    if (!mounted || result == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نتيجة AUREN AI'),
        content: SingleChildScrollView(child: Text(result)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
      ),
    );
  }

  Future<void> _addNote(BuildContext context, String uid) async {
    final title = TextEditingController();
    final note = TextEditingController();
    final type = ValueNotifier('field');
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ملاحظة زراعية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
          TextField(controller: note, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'الملاحظة')),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(valueListenable: type, builder: (_, v, __) => DropdownButton<String>(
            value: v, isExpanded: true,
            items: const [DropdownMenuItem(value:'field',child:Text('حقل')),DropdownMenuItem(value:'livestock',child:Text('مواشي')),DropdownMenuItem(value:'farm',child:Text('مزرعة'))],
            onChanged: (x) { if (x != null) type.value = x; },
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () async {
            if (title.text.trim().isEmpty || note.text.trim().isEmpty) return;
            await _repo.saveFieldNote(uid: uid, title: title.text, note: note.text, type: type.value);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('حفظ')),
        ],
      ),
    );
    title.dispose(); note.dispose(); type.dispose();
  }
}
