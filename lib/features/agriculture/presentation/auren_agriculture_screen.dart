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
          _quickTools(),
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


  Widget _quickTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('أدوات زراعية سريعة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('أدوات عملية للحساب والتخطيط بدون الحاجة إلى اتصال خارجي.'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _toolButton(Icons.water_drop_outlined, 'تقدير الري', _showIrrigationTool),
            _toolButton(Icons.schedule_outlined, 'خطة الري', _showIrrigationPlanTool),
            _toolButton(Icons.solar_power_outlined, 'الري بالطاقة الشمسية', _showSolarIrrigationTool),
            _toolButton(Icons.waterfall_chart_outlined, 'المضخة والتصريف', _showPumpTool),
            _toolButton(Icons.water_outlined, 'حجم الخزان', _showTankTool),
            _toolButton(Icons.grass_outlined, 'احتياج المحصول للمياه', _showCropWaterNeedTool),
            _toolButton(Icons.calculate_outlined, 'تكلفة الوحدة', _showCostTool),
            _toolButton(Icons.inventory_2_outlined, 'المخزون', _showInventoryTool),
            _toolButton(Icons.event_note_outlined, 'خطة الموسم', _showSeasonTool),
            _toolButton(Icons.scale_outlined, 'الإنتاجية', _showYieldTool),
          ]),
        ]),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _showIrrigationTool() async {
    final area = TextEditingController();
    final depth = TextEditingController(text: '5');
    final result = await _twoFieldTool(
      title: 'تقدير كمية الري',
      first: area,
      second: depth,
      firstLabel: 'المساحة بالمتر المربع',
      secondLabel: 'عمق الري بالملليمتر',
      actionLabel: 'احسب',
      calculate: () {
        final a = double.tryParse(area.text.trim()) ?? 0;
        final d = double.tryParse(depth.text.trim()) ?? 0;
        if (a <= 0 || d <= 0) return 'أدخل أرقاماً صحيحة أكبر من صفر.';
        final liters = a * d;
        return 'التقدير النظري: ${liters.toStringAsFixed(0)} لتر.\nيجب تعديل الرقم حسب كفاءة نظام الري والتربة والطقس والمحصول.';
      },
    );
    area.dispose();
    depth.dispose();
    if (mounted && result != null) _showResult('تقدير الري', result);
  }

  Future<void> _showIrrigationPlanTool() async {
    final crop = TextEditingController();
    final area = TextEditingController();
    final depth = TextEditingController(text: '5');
    final efficiency = TextEditingController(text: '80');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطة ري أولية'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: crop, decoration: const InputDecoration(labelText: 'المحصول / النشاط')),
            TextField(
              controller: area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المساحة بالمتر المربع'),
            ),
            TextField(
              controller: depth,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'عمق الري المستهدف بالملليمتر'),
            ),
            TextField(
              controller: efficiency,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'كفاءة النظام % (مثلاً 80)'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),

          FilledButton(
            onPressed: () {
              final name = crop.text.trim();
              final a = double.tryParse(area.text.trim()) ?? 0;
              final d = double.tryParse(depth.text.trim()) ?? 0;
              final e = double.tryParse(efficiency.text.trim()) ?? 0;
              if (name.isEmpty || a <= 0 || d <= 0 || e <= 0 || e > 100) {
                Navigator.pop(context, 'أدخل المحصول والقيم الصحيحة، وكفاءة بين 1 و100%.');
                return;
              }
              final theoretical = a * d;
              final applied = theoretical / (e / 100);
              final note = e < 60
                  ? 'الكفاءة منخفضة نسبياً؛ افحص التسرب والتوزيع والضغط.'
                  : 'اضبط التوقيت والكمية حسب التربة والطقس ومرحلة نمو $name.';
              Navigator.pop(
                context,
                'المحصول: $name\\n'
                'الاحتياج النظري: ${theoretical.toStringAsFixed(0)} لتر لكل رية\\n'
                'الكمية التقريبية بعد احتساب الكفاءة: ${applied.toStringAsFixed(0)} لتر\\n\\n'
                '$note\\n'
                'هذه خطة تقديرية وليست توصية ري نهائية.',
              );
            },
            child: const Text('أنشئ الخطة'),
          ),
        ],
      ),
    );
    crop.dispose();
    area.dispose();
    depth.dispose();
    efficiency.dispose();
    if (mounted && result != null) _showResult('خطة الري', result);
  }

  Future<void> _showSolarIrrigationTool() async {
    final power = TextEditingController(text: '1');
    final hours = TextEditingController(text: '6');
    final loadHours = TextEditingController(text: '5');
    final efficiency = TextEditingController(text: '75');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تقدير الري بالطاقة الشمسية'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: power,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'قدرة المضخة بالكيلوواط'),
            ),
            TextField(
              controller: hours,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'ساعات الشمس الفعالة يومياً'),
            ),
            TextField(
              controller: loadHours,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'ساعات تشغيل المضخة يومياً'),
            ),
            TextField(
              controller: efficiency,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'كفاءة المنظومة % (مثلاً 75)'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final p = double.tryParse(power.text.trim()) ?? 0;
              final sun = double.tryParse(hours.text.trim()) ?? 0;
              final run = double.tryParse(loadHours.text.trim()) ?? 0;
              final eff = double.tryParse(efficiency.text.trim()) ?? 0;
              if (p <= 0 || sun <= 0 || run <= 0 || eff <= 0 || eff > 100) {
                Navigator.pop(context, 'أدخل قيماً صحيحة، وكفاءة بين 1 و100%.');
                return;
              }
              final dailyEnergy = p * run;
              final panelKw = dailyEnergy / (sun * (eff / 100));
              final panelCount = (panelKw / 0.55).ceil();
              final inverterKw = p * 1.25;
              Navigator.pop(
                context,
                'الاستهلاك التقريبي: ${dailyEnergy.toStringAsFixed(2)} kWh/يوم.\\n'
                'قدرة الألواح التقديرية: ${panelKw.toStringAsFixed(2)} kWp.\\n'
                'إذا استخدمت ألواحاً بقدرة 550W: حوالي $panelCount لوحاً.\\n'
                'قدرة العاكس المقترحة مبدئياً: ${inverterKw.toStringAsFixed(2)} kW.\\n\\n'
                'هذه حسبة أولية فقط؛ التصميم النهائي يحتاج قدرة المضخة الفعلية، التصريف، الرفع، ساعات الشمس المحلية، نوع العاكس/المضخة، الكابلات والخزانات والتظليل، ويجب مراجعته مع مختص طاقة ومياه.',
              );
            },
            child: const Text('احسب النظام'),
          ),
        ],
      ),
    );
    power.dispose();
    hours.dispose();
    loadHours.dispose();
    efficiency.dispose();
    if (mounted && result != null) _showResult('الري بالطاقة الشمسية', result);
  }

  Future<void> _showPumpTool() async {
    final flow = TextEditingController(text: '10');
    final head = TextEditingController(text: '20');
    final efficiency = TextEditingController(text: '60');
    final hours = TextEditingController(text: '5');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تقدير المضخة والتصريف'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: flow,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'التصريف المطلوب لتر/دقيقة'),
            ),
            TextField(
              controller: head,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرفع الكلي بالمتر'),
            ),
            TextField(
              controller: efficiency,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'كفاءة المضخة/النظام %'),
            ),
            TextField(
              controller: hours,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'ساعات التشغيل يومياً'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final q = double.tryParse(flow.text.trim()) ?? 0;
              final h = double.tryParse(head.text.trim()) ?? 0;
              final e = double.tryParse(efficiency.text.trim()) ?? 0;
              final t = double.tryParse(hours.text.trim()) ?? 0;
              if (q <= 0 || h <= 0 || e <= 0 || e > 100 || t <= 0) {
                Navigator.pop(context, 'أدخل قيماً صحيحة، والكفاءة بين 1 و100%.');
                return;
              }
              final flowM3s = q / 60000;
              final hydraulicKw = 9.81 * flowM3s * h;
              final inputKw = hydraulicKw / (e / 100);
              final dailyM3 = q * t * 60 / 1000;
              Navigator.pop(
                context,
                'المياه المضخوخة يومياً: ${dailyM3.toStringAsFixed(2)} م³.\\n'
                'القدرة الهيدروليكية النظرية: ${hydraulicKw.toStringAsFixed(2)} kW.\\n'
                'القدرة الكهربائية التقديرية: ${inputKw.toStringAsFixed(2)} kW.\\n\\n'
                'استخدم هذه النتيجة لتقدير حجم النظام فقط؛ اختيار المضخة النهائي يعتمد على منحنى المضخة، الرفع الديناميكي، الأنابيب، الفواقد وجودة المياه.',
              );
            },
            child: const Text('احسب'),
          ),
        ],
      ),
    );
    flow.dispose();
    head.dispose();
    efficiency.dispose();
    hours.dispose();
    if (mounted && result != null) _showResult('المضخة والتصريف', result);
  }

  Future<void> _showTankTool() async {
    final daily = TextEditingController(text: '10');
    final days = TextEditingController(text: '2');
    final reserve = TextEditingController(text: '20');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تقدير حجم خزان المياه'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: daily,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الاستهلاك/الاحتياج اليومي م³'),
            ),
            TextField(
              controller: days,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'أيام التخزين المطلوبة'),
            ),
            TextField(
              controller: reserve,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'احتياطي إضافي %'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final d = double.tryParse(daily.text.trim()) ?? 0;
              final n = double.tryParse(days.text.trim()) ?? 0;
              final r = double.tryParse(reserve.text.trim()) ?? 0;
              if (d <= 0 || n <= 0 || r < 0 || r > 100) {
                Navigator.pop(context, 'أدخل قيماً صحيحة، والاحتياطي بين 0 و100%.');
                return;
              }
              final base = d * n;
              final tank = base * (1 + r / 100);
              Navigator.pop(
                context,
                'الحجم الأساسي للتخزين: ${base.toStringAsFixed(2)} م³.\\n'
                'الحجم التقديري مع الاحتياطي: ${tank.toStringAsFixed(2)} م³.\\n\\n'
                'للاختيار النهائي راعِ مصدر المياه، معدل التعبئة، التبخر، جودة المياه، مساحة التركيب وسعة الخزان الفعلية.',
              );
            },
            child: const Text('احسب'),
          ),
        ],
      ),
    );
    daily.dispose();
    days.dispose();
    reserve.dispose();
    if (mounted && result != null) _showResult('حجم الخزان', result);
  }

  Future<void> _showCropWaterNeedTool() async {
    final area = TextEditingController(text: '1000');
    final depth = TextEditingController(text: '5');
    final efficiency = TextEditingController(text: '70');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('احتياج المحصول للمياه'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'مساحة الزراعة م²'),
            ),
            TextField(
              controller: depth,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'عمق المياه المطلوب يومياً mm'),
            ),
            TextField(
              controller: efficiency,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'كفاءة نظام الري %'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final a = double.tryParse(area.text.trim()) ?? 0;
              final d = double.tryParse(depth.text.trim()) ?? 0;
              final e = double.tryParse(efficiency.text.trim()) ?? 0;
              if (a <= 0 || d <= 0 || e <= 0 || e > 100) {
                Navigator.pop(context, 'أدخل قيماً صحيحة، والكفاءة بين 1 و100%.');
                return;
              }
              final netLiters = a * d;
              final grossLiters = netLiters / (e / 100);
              Navigator.pop(
                context,
                'الاحتياج النظري: ${netLiters.toStringAsFixed(0)} لتر/يوم.\\n'
                'المياه المطلوبة بعد احتساب كفاءة الري: ${grossLiters.toStringAsFixed(0)} لتر/يوم '
                '(${(grossLiters / 1000).toStringAsFixed(2)} م³/يوم).\\n\\n'
                'هذا تقدير أولي؛ الاحتياج الحقيقي يتغير حسب المحصول، المناخ، التربة، مرحلة النمو والأمطار.',
              );
            },
            child: const Text('احسب'),
          ),
        ],
      ),
    );
    area.dispose();
    depth.dispose();
    efficiency.dispose();
    if (mounted && result != null) _showResult('احتياج المحصول للمياه', result);
  }

  Future<void> _showCostTool() async {
    final total = TextEditingController();
    final units = TextEditingController();
    final result = await _twoFieldTool(
      title: 'تكلفة الوحدة',
      first: total,
      second: units,
      firstLabel: 'إجمالي التكلفة',
      secondLabel: 'عدد الوحدات المنتجة',
      actionLabel: 'احسب',
      calculate: () {
        final t = double.tryParse(total.text.trim()) ?? 0;
        final u = double.tryParse(units.text.trim()) ?? 0;
        if (t < 0 || u <= 0) return 'أدخل تكلفة صحيحة وعدد وحدات أكبر من صفر.';
        return 'تكلفة الوحدة التقريبية: ${(t / u).toStringAsFixed(2)}.\nلا تشمل هذه الأداة التسعير أو هامش الربح أو الضرائب تلقائياً.';
      },
    );
    total.dispose();
    units.dispose();
    if (mounted && result != null) _showResult('تكلفة الوحدة', result);
  }

  Future<void> _showYieldTool() async {
    final area = TextEditingController();
    final production = TextEditingController();
    final result = await _twoFieldTool(
      title: 'حساب الإنتاجية',
      first: production,
      second: area,
      firstLabel: 'الإنتاج الكلي',
      secondLabel: 'المساحة',
      actionLabel: 'احسب',
      calculate: () {
        final p = double.tryParse(production.text.trim()) ?? 0;
        final a = double.tryParse(area.text.trim()) ?? 0;
        if (p < 0 || a <= 0) return 'أدخل إنتاجاً صحيحاً ومساحة أكبر من صفر.';
        return 'الإنتاجية: ${(p / a).toStringAsFixed(2)} وحدة لكل وحدة مساحة.';
      },
    );
    area.dispose();
    production.dispose();
    if (mounted && result != null) _showResult('الإنتاجية', result);
  }

  Future<void> _showInventoryTool() async {
    final item = TextEditingController();
    final quantity = TextEditingController();
    final result = await _twoFieldTool(
      title: 'سجل مخزون سريع',
      first: item,
      second: quantity,
      firstLabel: 'اسم الصنف',
      secondLabel: 'الكمية الحالية',
      actionLabel: 'حفظ محلي',
      calculate: () {
        final name = item.text.trim();
        final q = double.tryParse(quantity.text.trim()) ?? 0;
        if (name.isEmpty || q < 0) return 'أدخل اسم الصنف وكمية صحيحة.';
        return 'تم تجهيز سجل: $name — كمية $q.\nهذه النسخة لا تحفظ في السحابة بعد.';
      },
    );
    item.dispose();
    quantity.dispose();
    if (mounted && result != null) _showResult('المخزون', result);
  }

  Future<void> _showSeasonTool() async {
    final crop = TextEditingController();
    final days = TextEditingController(text: '90');
    final result = await _twoFieldTool(
      title: 'خطة موسم أولية',
      first: crop,
      second: days,
      firstLabel: 'المحصول / النشاط',
      secondLabel: 'مدة الموسم بالأيام',
      actionLabel: 'أنشئ الخطة',
      calculate: () {
        final name = crop.text.trim();
        final d = int.tryParse(days.text.trim()) ?? 0;
        if (name.isEmpty || d <= 0) return 'أدخل النشاط ومدة موجبة.';
        final stages = [
          'تجهيز الموقع والمدخلات',
          'الزراعة/البداية والمتابعة',
          'الري والتغذية والمراقبة',
          'الآفات والأمراض والجودة',
          'الحصاد أو الإنتاج وما بعد الحصاد',
        ];
        return 'خطة $name لمدة $d يوم:\n\n${stages.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}\n\nعدّل المواعيد حسب الصنف والمناخ والموقع.';
      },
    );
    crop.dispose();
    days.dispose();
    if (mounted && result != null) _showResult('خطة الموسم', result);
  }

  Future<String?> _twoFieldTool({
    required String title,
    required TextEditingController first,
    required TextEditingController second,
    required String firstLabel,
    required String secondLabel,
    required String actionLabel,
    required String Function() calculate,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: first, decoration: InputDecoration(labelText: firstLabel)),
          TextField(controller: second, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: secondLabel)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, calculate()), child: Text(actionLabel)),
        ],
      ),
    );
  }

  Future<void> _showResult(String title, String result) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(result)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
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
