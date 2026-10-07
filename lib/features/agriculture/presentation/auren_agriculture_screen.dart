import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agriculture/auren_agriculture_repository.dart';
import '../widgets/gaez_v5_card.dart';

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
          const AurenGaezV5Card(),
          const SizedBox(height: 16),
          _investmentHub(),
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
            _toolButton(Icons.science_outlined, 'حساب الأسمدة', _showFertilizerTool),
            _toolButton(Icons.biotech_outlined, 'تحليل N-P-K', _showNpkTool),
            _toolButton(Icons.science_outlined, 'pH والملوحة', _showSoilPhSalinityTool),
            _toolButton(Icons.eco_outlined, 'المادة العضوية', _showOrganicMatterTool),
            _toolButton(Icons.layers_outlined, 'كمية محسن التربة', _showSoilAmendmentTool),
            _toolButton(Icons.blender_outlined, 'خلطة السماد', _showFertilizerBlendTool),
            _toolButton(Icons.view_column_outlined, 'تقسيم جرعات السماد', _showFertilizerSplitTool),
            _toolButton(Icons.search_outlined, 'مؤشر نقص العناصر', _showNutrientDeficiencyTool),
            _toolButton(Icons.monitor_weight_outlined, 'توازن العناصر', _showNutrientBalanceTool),
            _toolButton(Icons.grass_outlined, 'كثافة الزراعة', _showPlantDensityTool),
            _toolButton(Icons.grass_outlined, 'كمية التقاوي', _showSeedRateTool),
            _toolButton(Icons.grid_3x3_outlined, 'عدد النباتات', _showPlantCountTool),
            _toolButton(Icons.water_drop_outlined, 'كفاءة استخدام المياه', _showWaterProductivityTool),
            _toolButton(Icons.agriculture_outlined, 'تقدير الإنتاج', _showProductionEstimateTool),
            _toolButton(Icons.calculate_outlined, 'تكلفة الوحدة', _showCostTool),
            _toolButton(Icons.inventory_2_outlined, 'المخزون', _showInventoryTool),
            _toolButton(Icons.event_note_outlined, 'خطة الموسم', _showSeasonTool),
            _toolButton(Icons.scale_outlined, 'الإنتاجية', _showYieldTool),
            _toolButton(Icons.percent_outlined, 'فاقد الحصاد', _showHarvestLossTool),
            _toolButton(Icons.attach_money_outlined, 'الإيراد المتوقع', _showRevenueTool),
            _toolButton(Icons.balance_outlined, 'نقطة التعادل', _showBreakEvenTool),
            _toolButton(Icons.account_balance_wallet_outlined, 'هامش الربح', _showProfitMarginTool),
            _toolButton(Icons.warehouse_outlined, 'سعة التخزين', _showStorageTool),
            _toolButton(Icons.grain_outlined, 'احتياج العلف', _showFeedNeedTool),
            _toolButton(Icons.pets_outlined, 'احتياج الماء للماشية', _showLivestockWaterTool),
            _toolButton(Icons.egg_outlined, 'إنتاج البيض', _showEggProductionTool),
            _toolButton(Icons.local_drink_outlined, 'إنتاج الحليب', _showMilkProductionTool),
            _toolButton(Icons.home_work_outlined, 'مساحة البيت المحمي', _showGreenhouseTool),
            _toolButton(Icons.calculate_outlined, 'تحويل معدل السماد', _showFertilizerUnitTool),
            _toolButton(Icons.verified_outlined, 'تصحيح التقاوي', _showSeedCorrectionTool),
            _toolButton(Icons.science_outlined, 'خطة أخذ عينات التربة', _showSoilSamplingTool),
            _toolButton(Icons.percent_outlined, 'فاقد ما بعد الحصاد', _showPostHarvestLossTool),
            _toolButton(Icons.sell_outlined, 'الكمية القابلة للبيع', _showMarketableQuantityTool),
            _toolButton(Icons.calendar_today_outlined, 'مدة التخزين', _showStorageDurationTool),
            _toolButton(Icons.thermostat_outlined, 'حمل التبريد', _showCoolingTool),
            _toolButton(Icons.local_shipping_outlined, 'حجم النقل', _showTransportLoadTool),
            _toolButton(Icons.people_outline, 'احتياج العمالة', _showLaborNeedTool),
            _toolButton(Icons.schedule_outlined, 'ساعات التشغيل', _showOperatingHoursTool),
            _toolButton(Icons.swap_horiz_outlined, 'تحويل مساحة', _showAreaConversionTool),
            _toolButton(Icons.scale_outlined, 'تحويل وزن', _showWeightConversionTool),
            _toolButton(Icons.water_drop_outlined, 'تحويل حجم المياه', _showWaterVolumeConversionTool),
            _toolButton(Icons.calendar_month_outlined, 'جدولة الري اليومية', _showDailyIrrigationScheduleTool),
            _toolButton(Icons.grid_view_outlined, 'تقسيم مياه الري', _showIrrigationSectorTool),
            _toolButton(Icons.verified_outlined, 'تصحيح التقاوي المتقدم', _showAdvancedSeedCorrectionTool),
            _toolButton(Icons.map_outlined, 'المساحة من التقاوي', _showAreaFromSeedTool),
            _toolButton(Icons.delete_sweep_outlined, 'هدر التخزين', _showStorageWasteTool),
            _toolButton(Icons.grain_outlined, 'معامل تحويل العلف', _showFeedConversionTool),
            _toolButton(Icons.hive_outlined, 'تقدير إنتاج العسل', _showHoneyProductionTool),
            _toolButton(Icons.set_meal_outlined, 'احتياج علف الأسماك', _showAquacultureFeedTool),
            _toolButton(Icons.water_outlined, 'كتلة الأسماك', _showFishBiomassTool),
            _toolButton(Icons.health_and_safety_outlined, 'معدل نفوق الدواجن', _showPoultryMortalityTool),
            _toolButton(Icons.monitor_weight_outlined, 'زيادة وزن القطيع', _showLivestockWeightGainTool),
            _toolButton(Icons.local_drink_outlined, 'إنتاج الحليب للفرد', _showMilkPerAnimalTool),
            _toolButton(Icons.inventory_2_outlined, 'احتياج عبوات التعبئة', _showPackagingTool),
            _toolButton(Icons.timelapse_outlined, 'فاقد التخزين اليومي', _showDailyStorageLossTool),
            _toolButton(Icons.local_gas_station_outlined, 'استهلاك وقود الآلات', _showMachineryFuelTool),
            _toolButton(Icons.bolt_outlined, 'استهلاك الكهرباء الزراعي', _showFarmElectricityTool),
            _toolButton(Icons.pets_outlined, 'كفاءة إنتاج القطيع', _showHerdProductivityTool),
            _toolButton(Icons.eco_outlined, 'كفاءة الأرض', _showLandProductivityTool),
            _toolButton(Icons.grass_outlined, 'استهلاك العلف للفرد', _showFeedPerAnimalTool),
            _toolButton(Icons.water_outlined, 'استهلاك الماء للفرد', _showWaterPerAnimalTool),
            _toolButton(Icons.scale_outlined, 'معدل النمو اليومي', _showDailyGrowthRateTool),
            _toolButton(Icons.thermostat_outlined, 'مؤشر حرارة البيت المحمي', _showGreenhouseTemperatureTool),
            _toolButton(Icons.air_outlined, 'تهوية البيت المحمي', _showGreenhouseVentilationTool),
            _toolButton(Icons.wb_sunny_outlined, 'طاقة البيت المحمي', _showGreenhouseEnergyTool),
            _toolButton(Icons.shopping_bag_outlined, 'تكلفة التعبئة', _showPackagingCostTool),
            _toolButton(Icons.receipt_long_outlined, 'تكلفة النقل', _showTransportCostTool),
            _toolButton(Icons.build_outlined, 'تكلفة تشغيل الآلة', _showMachineOperatingCostTool),
            _toolButton(Icons.square_foot_outlined, 'تحويل المساحة', _showAreaConverterTool),
            _toolButton(Icons.scale_outlined, 'تحويل الوزن', _showWeightConverterTool),
            _toolButton(Icons.water_outlined, 'تحويل حجم المياه', _showWaterVolumeConverterTool),
            _toolButton(Icons.schedule_outlined, 'جدولة الري اليومية', _showIrrigationScheduleTool),
            _toolButton(Icons.call_split_outlined, 'تقسيم مياه الري', _showIrrigationSectorTool),
            _toolButton(Icons.grass_outlined, 'تقدير المساحة من التقاوي', _showSeedAreaTool),
            _toolButton(Icons.inventory_2_outlined, 'فاقد التخزين', _showStorageLossTool),
            _toolButton(Icons.inventory_outlined, 'احتياج التعبئة', _showPackagingTool),
            _toolButton(Icons.local_gas_station_outlined, 'استهلاك الوقود', _showFuelConsumptionTool),
            _toolButton(Icons.calculate_outlined, 'تكلفة العمالة', _showLaborCostTool),
          _toolButton(Icons.square_foot_outlined, 'مساحة الأرض من الأبعاد', _showFarmAreaTool),
            _toolButton(Icons.fence_outlined, 'طول السور', _showFenceLengthTool),
            _toolButton(Icons.water_drop_outlined, 'عدد نقاط التنقيط', _showEmitterCountTool),
            _toolButton(Icons.linear_scale_outlined, 'طول خطوط التنقيط', _showDriplineLengthTool),
            _toolButton(Icons.speed_outlined, 'معدل تدفق الري', _showIrrigationFlowTool),
            _toolButton(Icons.timer_outlined, 'زمن تشغيل المضخة', _showPumpRuntimeTool),
            _toolButton(Icons.set_meal_outlined, 'كثافة تخزين الأسماك', _showFishStockingDensityTool),
            _toolButton(Icons.paid_outlined, 'احتياج علف الدواجن', _showPoultryFeedCostTool),
            _toolButton(Icons.hive_outlined, 'بقاء طوائف النحل', _showBeeSurvivalTool),
            _toolButton(Icons.home_work_outlined, 'سعة البيت المحمي', _showGreenhouseCapacityTool),

          ]),
        ]),
      ),
    );
  }


  Future<void> _showFarmAreaTool() async {
    final length=TextEditingController(), width=TextEditingController();
    final result=await _twoFieldTool(title:'مساحة الأرض من الأبعاد',first:length,second:width,firstLabel:'الطول بالمتر',secondLabel:'العرض بالمتر',actionLabel:'احسب',calculate:(){
      final l=double.tryParse(length.text.trim())??0,w=double.tryParse(width.text.trim())??0;
      if(l<=0||w<=0)return 'أدخل أبعاداً أكبر من صفر.';
      return 'المساحة: ${(l*w).toStringAsFixed(2)} متر مربع.';
    });
    length.dispose();width.dispose();if(mounted&&result!=null)_showResult('مساحة الأرض',result);
  }

  Future<void> _showFenceLengthTool() async {
    final length=TextEditingController(), width=TextEditingController();
    final result=await _twoFieldTool(title:'طول السور أو خط المياه',first:length,second:width,firstLabel:'الطول بالمتر',secondLabel:'العرض بالمتر',actionLabel:'احسب',calculate:(){
      final l=double.tryParse(length.text.trim())??0,w=double.tryParse(width.text.trim())??0;
      if(l<=0||w<=0)return 'أدخل أبعاداً أكبر من صفر.';
      return 'المحيط التقريبي: ${(2*(l+w)).toStringAsFixed(2)} متر.';
    });
    length.dispose();width.dispose();if(mounted&&result!=null)_showResult('طول السور',result);
  }

  Future<void> _showEmitterCountTool() async {
    final line=TextEditingController(), spacing=TextEditingController(text:'0.3');
    final result=await _twoFieldTool(title:'عدد نقاط التنقيط',first:line,second:spacing,firstLabel:'طول خط التنقيط بالمتر',secondLabel:'المسافة بين النقاط بالمتر',actionLabel:'احسب',calculate:(){
      final l=double.tryParse(line.text.trim())??0,s=double.tryParse(spacing.text.trim())??0;
      if(l<=0||s<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'عدد النقاط التقريبي: ${(l/s).ceil()} نقطة.';
    });
    line.dispose();spacing.dispose();if(mounted&&result!=null)_showResult('نقاط التنقيط',result);
  }

  Future<void> _showDriplineLengthTool() async {
    final rows=TextEditingController(), rowLength=TextEditingController();
    final result=await _twoFieldTool(title:'طول خطوط التنقيط',first:rows,second:rowLength,firstLabel:'عدد الخطوط',secondLabel:'طول الخط بالمتر',actionLabel:'احسب',calculate:(){
      final r=double.tryParse(rows.text.trim())??0,l=double.tryParse(rowLength.text.trim())??0;
      if(r<=0||l<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'إجمالي طول الخطوط: ${(r*l).toStringAsFixed(2)} متر.';
    });
    rows.dispose();rowLength.dispose();if(mounted&&result!=null)_showResult('خطوط التنقيط',result);
  }

  Future<void> _showIrrigationFlowTool() async {
    final volume=TextEditingController(), time=TextEditingController();
    final result=await _twoFieldTool(title:'معدل تدفق الري',first:volume,second:time,firstLabel:'حجم المياه باللتر',secondLabel:'الزمن بالدقائق',actionLabel:'احسب',calculate:(){
      final v=double.tryParse(volume.text.trim())??0,t=double.tryParse(time.text.trim())??0;
      if(v<=0||t<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'معدل التدفق: ${(v/t).toStringAsFixed(2)} لتر/دقيقة.';
    });
    volume.dispose();time.dispose();if(mounted&&result!=null)_showResult('تدفق الري',result);
  }

  Future<void> _showPumpRuntimeTool() async {
    final volume=TextEditingController(), flow=TextEditingController();
    final result=await _twoFieldTool(title:'زمن تشغيل المضخة',first:volume,second:flow,firstLabel:'حجم المياه المطلوب باللتر',secondLabel:'تدفق المضخة لتر/دقيقة',actionLabel:'احسب',calculate:(){
      final v=double.tryParse(volume.text.trim())??0,f=double.tryParse(flow.text.trim())??0;
      if(v<=0||f<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'زمن التشغيل: ${(v/f).toStringAsFixed(2)} دقيقة.';
    });
    volume.dispose();flow.dispose();if(mounted&&result!=null)_showResult('زمن المضخة',result);
  }

  Future<void> _showFishStockingDensityTool() async {
    final fish=TextEditingController(), volume=TextEditingController();
    final result=await _twoFieldTool(title:'كثافة تخزين الأسماك',first:fish,second:volume,firstLabel:'عدد الأسماك',secondLabel:'حجم الماء بالمتر المكعب',actionLabel:'احسب',calculate:(){
      final f=double.tryParse(fish.text.trim())??0,v=double.tryParse(volume.text.trim())??0;
      if(f<=0||v<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'الكثافة: ${(f/v).toStringAsFixed(2)} سمكة/م³. هذه قيمة تخطيطية؛ النوع والحجم وجودة المياه مهمة.';
    });
    fish.dispose();volume.dispose();if(mounted&&result!=null)_showResult('كثافة الأسماك',result);
  }

  Future<void> _showPoultryFeedCostTool() async {
    final birds=TextEditingController(), feed=TextEditingController();
    final result=await _twoFieldTool(title:'احتياج علف الدواجن',first:birds,second:feed,firstLabel:'عدد الطيور',secondLabel:'العلف لكل طائر بالكجم',actionLabel:'احسب',calculate:(){
      final b=double.tryParse(birds.text.trim())??0,f=double.tryParse(feed.text.trim())??0;
      if(b<=0||f<0)return 'أدخل عدداً صحيحاً للطيور وكمية علف غير سالبة.';
      return 'إجمالي العلف: ${(b*f).toStringAsFixed(2)} كجم.';
    });
    birds.dispose();feed.dispose();if(mounted&&result!=null)_showResult('علف الدواجن',result);
  }

  Future<void> _showBeeSurvivalTool() async {
    final initial=TextEditingController(), losses=TextEditingController();
    final result=await _twoFieldTool(title:'بقاء طوائف النحل',first:initial,second:losses,firstLabel:'عدد الطوائف في البداية',secondLabel:'عدد الطوائف المفقودة',actionLabel:'احسب',calculate:(){
      final i=double.tryParse(initial.text.trim())??0,l=double.tryParse(losses.text.trim())??0;
      if(i<=0||l<0||l>i)return 'تحقق من القيم المدخلة.';
      return 'الطوائف المتبقية: ${(i-l).toStringAsFixed(0)}\\nمعدل البقاء: ${((i-l)/i*100).toStringAsFixed(1)}%.';
    });
    initial.dispose();losses.dispose();if(mounted&&result!=null)_showResult('بقاء النحل',result);
  }

  Future<void> _showGreenhouseCapacityTool() async {
    final area=TextEditingController(), plantArea=TextEditingController(text:'0.25');
    final result=await _twoFieldTool(title:'سعة البيت المحمي',first:area,second:plantArea,firstLabel:'المساحة بالمتر المربع',secondLabel:'المساحة التقريبية للنبات بالمتر المربع',actionLabel:'احسب',calculate:(){
      final a=double.tryParse(area.text.trim())??0,s=double.tryParse(plantArea.text.trim())??0;
      if(a<=0||s<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'السعة النظرية: ${(a/s).floor()} نبات. اطرح الممرات والخدمات قبل اعتماد العدد النهائي.';
    });
    area.dispose();plantArea.dispose();if(mounted&&result!=null)_showResult('سعة البيت المحمي',result);
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

  Future<void> _showFertilizerTool() async {
    final area = TextEditingController(text: '1000');
    final dose = TextEditingController(text: '100');
    final nitrogen = TextEditingController(text: '20');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حاسبة الأسمدة'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المساحة م²'),
            ),
            TextField(
              controller: dose,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'معدل السماد كجم/هكتار'),
            ),
            TextField(
              controller: nitrogen,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'نسبة النيتروجين في السماد %'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final a = double.tryParse(area.text.trim()) ?? 0;
              final d = double.tryParse(dose.text.trim()) ?? 0;
              final n = double.tryParse(nitrogen.text.trim()) ?? 0;
              if (a <= 0 || d <= 0 || n < 0 || n > 100) {
                Navigator.pop(context, 'أدخل قيماً صحيحة، ونسبة النيتروجين بين 0 و100%.');
                return;
              }
              final hectares = a / 10000;
              final fertilizerKg = hectares * d;
              final nutrientKg = fertilizerKg * n / 100;
              Navigator.pop(
                context,
                'كمية السماد التقديرية: ${fertilizerKg.toStringAsFixed(2)} كجم.\\n'
                'النيتروجين المضاف تقريباً: ${nutrientKg.toStringAsFixed(2)} كجم.\\n\\n'
                'هذا حساب كمي فقط، وليس توصية تسميد. تحديد الجرعة المناسبة يحتاج تحليل التربة والمحصول ومرحلة النمو ومصدر السماد.',
              );
            },
            child: const Text('احسب'),
          ),
        ],
      ),
    );
    area.dispose();
    dose.dispose();
    nitrogen.dispose();
    if (mounted && result != null) _showResult('حساب الأسمدة', result);
  }

  Future<void> _showNpkTool() async {
    final area = TextEditingController(text: '1000');
    final n = TextEditingController(text: '40');
    final p = TextEditingController(text: '20');
    final k = TextEditingController(text: '30');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحليل N-P-K'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المساحة م²'),
            ),
            TextField(
              controller: n,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'احتياج N كجم/هكتار'),
            ),
            TextField(
              controller: p,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'احتياج P كجم/هكتار'),
            ),
            TextField(
              controller: k,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'احتياج K كجم/هكتار'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final a = double.tryParse(area.text.trim()) ?? 0;
              final nv = double.tryParse(n.text.trim()) ?? 0;
              final pv = double.tryParse(p.text.trim()) ?? 0;
              final kv = double.tryParse(k.text.trim()) ?? 0;
              if (a <= 0 || nv < 0 || pv < 0 || kv < 0) {
                Navigator.pop(context, 'أدخل قيماً صحيحة.');
                return;
              }
              final factor = a / 10000;
              Navigator.pop(
                context,
                'الاحتياج التقديري للمساحة:\\n'
                'N: ${(nv * factor).toStringAsFixed(2)} كجم\\n'
                'P: ${(pv * factor).toStringAsFixed(2)} كجم\\n'
                'K: ${(kv * factor).toStringAsFixed(2)} كجم\\n\\n'
                'هذه أداة حساب كمية وليست تشخيصاً للتربة. التحليل المخبري وتوصية المهندس الزراعي يحددان الجرعة الفعلية.',
              );
            },
            child: const Text('احسب'),
          ),
        ],
      ),
    );
    area.dispose();
    n.dispose();
    p.dispose();
    k.dispose();
    if (mounted && result != null) _showResult('تحليل N-P-K', result);
  }

  Future<void> _showSoilPhSalinityTool() async {
    final ph = TextEditingController(text: '7');
    final ec = TextEditingController(text: '1');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('فحص pH وملوحة التربة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ph, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'درجة pH')),
          TextField(controller: ec, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'EC الملوحة dS/m')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final p = double.tryParse(ph.text.trim());
            final e = double.tryParse(ec.text.trim());
            if (p == null || e == null || p < 0 || p > 14 || e < 0) { Navigator.pop(context, 'أدخل pH بين 0 و14 وقيمة EC غير سالبة.'); return; }
            final phLabel = p < 5.5 ? 'حامضية مرتفعة' : p < 6.5 ? 'حامضية خفيفة' : p <= 7.5 ? 'قريبة من المتعادلة' : p <= 8.5 ? 'قلوية خفيفة' : 'قلوية مرتفعة';
            final salinity = e < 2 ? 'ملوحة منخفضة غالباً' : e < 4 ? 'ملوحة تحتاج انتباهاً' : 'ملوحة مرتفعة';
            Navigator.pop(context, 'pH: ${p.toStringAsFixed(2)} — $phLabel.\nEC: ${e.toStringAsFixed(2)} dS/m — $salinity.\n\nالتفسير الفعلي يعتمد على طريقة القياس والمحصول ونوع التربة. استخدم تحليل مختبر زراعي قبل قرارات المعالجة أو الغسيل.');
          }, child: const Text('حلّل')),
        ],
      ),
    );
    ph.dispose();
    ec.dispose();
    if (mounted && result != null) _showResult('pH والملوحة', result);
  }

  Future<void> _showOrganicMatterTool() async {
    final area = TextEditingController(text: '1000');
    final depth = TextEditingController(text: '0.2');
    final bulkDensity = TextEditingController(text: '1.3');
    final organic = TextEditingController(text: '2');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تقدير كمية المادة العضوية في التربة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: area, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المساحة م²')),
          TextField(controller: depth, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'عمق الطبقة بالمتر')),
          TextField(controller: bulkDensity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الكثافة الظاهرية g/cm³')),
          TextField(controller: organic, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المادة العضوية %')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final a = double.tryParse(area.text.trim()) ?? 0;
            final d = double.tryParse(depth.text.trim()) ?? 0;
            final bd = double.tryParse(bulkDensity.text.trim()) ?? 0;
            final om = double.tryParse(organic.text.trim()) ?? 0;
            if (a <= 0 || d <= 0 || bd <= 0 || om < 0 || om > 100) { Navigator.pop(context, 'أدخل قيماً صحيحة، ونسبة المادة العضوية بين 0 و100%.'); return; }
            final soilMassTonnes = a * d * bd;
            final organicTonnes = soilMassTonnes * (om / 100);
            Navigator.pop(context, 'كتلة التربة التقديرية في الطبقة: ${soilMassTonnes.toStringAsFixed(2)} طن تقريباً.\nالمادة العضوية الموجودة تقريباً: ${organicTonnes.toStringAsFixed(2)} طن.\n\nهذه كمية تقديرية مبنية على الكثافة الظاهرية؛ لا تعني أن الكمية نفسها يجب إضافتها كسماد أو كمبوست.');
          }, child: const Text('احسب')),
        ],
      ),
    );
    area.dispose(); depth.dispose(); bulkDensity.dispose(); organic.dispose();
    if (mounted && result != null) _showResult('المادة العضوية', result);
  }

  Future<void> _showSoilAmendmentTool() async {
    final area = TextEditingController(text: '1000');
    final rate = TextEditingController(text: '2');
    final result = await _twoFieldTool(
      title: 'كمية محسن التربة', first: area, second: rate, firstLabel: 'المساحة م²', secondLabel: 'معدل الإضافة كجم/م²', actionLabel: 'احسب',
      calculate: () {
        final a = double.tryParse(area.text.trim()) ?? 0;
        final r = double.tryParse(rate.text.trim()) ?? 0;
        if (a <= 0 || r < 0) return 'أدخل مساحة صحيحة ومعدل إضافة غير سالب.';
        final kg = a * r;
        return 'الكمية الإجمالية التقديرية: ${kg.toStringAsFixed(2)} كجم (${(kg / 1000).toStringAsFixed(2)} طن).\n\nاستخدم معدل الإضافة من تحليل التربة أو توصية مختص؛ الأداة لا تحدد جرعة الجير أو الجبس أو الكمبوست من تلقاء نفسها.';
      },
    );
    area.dispose(); rate.dispose();
    if (mounted && result != null) _showResult('كمية محسن التربة', result);
  }
  Future<void> _showFertilizerBlendTool() async {
    final need = TextEditingController(text: '50'); final area = TextEditingController(text: '1000'); final pct = TextEditingController(text: '20');
    final result = await showDialog<String>(context: context,builder: (_) => AlertDialog(title: const Text('خلطة السماد'),content: Column(mainAxisSize: MainAxisSize.min,children: [
      TextField(controller: need,keyboardType: const TextInputType.numberWithOptions(decimal: true),decoration: const InputDecoration(labelText: 'العنصر المطلوب كجم/هكتار')),
      TextField(controller: area,keyboardType: const TextInputType.numberWithOptions(decimal: true),decoration: const InputDecoration(labelText: 'المساحة م²')),
      TextField(controller: pct,keyboardType: const TextInputType.numberWithOptions(decimal: true),decoration: const InputDecoration(labelText: 'نسبة العنصر في السماد %'))]),actions: [
      TextButton(onPressed: () => Navigator.pop(context),child: const Text('إلغاء')),FilledButton(onPressed: () {
        final n = double.tryParse(need.text.trim()) ?? 0; final a = double.tryParse(area.text.trim()) ?? 0; final p = double.tryParse(pct.text.trim()) ?? 0;
        if(n < 0 || a <= 0 || p <= 0 || p > 100){Navigator.pop(context,'أدخل قيماً صحيحة ونسبة عنصر بين 0 و100%.');return;}
        final kg = n * (a / 10000) / (p / 100); Navigator.pop(context,'كمية السماد التقديرية: ' + kg.toStringAsFixed(2) + ' كجم.\n\nهذه حسبة كمية فقط وليست توصية تسميد.');
      },child: const Text('احسب'))]));
    need.dispose(); area.dispose(); pct.dispose(); if(mounted && result != null)_showResult('خلطة السماد',result);
  }
  Future<void> _showFertilizerSplitTool() async {
    final total=TextEditingController(text:'100'); final first=TextEditingController(text:'40'); final second=TextEditingController(text:'30');
    final result=await showDialog<String>(context:context,builder:(_)=>AlertDialog(title:const Text('تقسيم جرعات السماد'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:total,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'إجمالي الكمية كجم')),
      TextField(controller:first,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الدفعة الأولى %')),
      TextField(controller:second,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الدفعة الثانية %'))]),actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:(){final t=double.tryParse(total.text.trim())??0;final a=double.tryParse(first.text.trim())??0;final b=double.tryParse(second.text.trim())??0;if(t<0||a<0||b<0||a+b>100){Navigator.pop(context,'أدخل قيماً صحيحة.');return;}final c=100-a-b;Navigator.pop(context,'الدفعة الأولى: ${(t*a/100).toStringAsFixed(2)} كجم.\\nالدفعة الثانية: ${(t*b/100).toStringAsFixed(2)} كجم.\\nالمتبقي: ${(t*c/100).toStringAsFixed(2)} كجم.\\n\\nالتوقيت يعتمد على المحصول ونوع السماد والتربة وطريقة الري.');},child:const Text('قسّم'))]));
    total.dispose();first.dispose();second.dispose();if(mounted&&result!=null)_showResult('تقسيم جرعات السماد',result);
  }

  Future<void> _showNutrientDeficiencyTool() async {
    final nutrient=TextEditingController();final symptom=TextEditingController();
    final result=await _twoFieldTool(title:'مؤشر نقص العناصر',first:nutrient,second:symptom,firstLabel:'العنصر المشتبه به (N/P/K/حديد...)',secondLabel:'وصف العرض',actionLabel:'حلّل',calculate:(){final n=nutrient.text.trim();final s=symptom.text.trim();if(n.isEmpty||s.isEmpty)return 'اكتب العنصر ووصف العرض.';return 'العنصر: $n\\nالعرض: $s\\n\\nهذا مؤشر أولي فقط؛ الأعراض قد تتشابه مع pH أو الملوحة أو مشاكل الجذور والآفات. التأكيد يحتاج فحصاً وتحليلاً مناسباً.';});
    nutrient.dispose();symptom.dispose();if(mounted&&result!=null)_showResult('مؤشر نقص العناصر',result);
  }
  Future<void> _showNutrientBalanceTool() async {
    final n=TextEditingController(text:'100'); final p=TextEditingController(text:'50'); final k=TextEditingController(text:'100');
    final result=await showDialog<String>(context:context,builder:(_) => AlertDialog(title:const Text('توازن N-P-K'),content:Column(mainAxisSize:MainAxisSize.min,children: [
      TextField(controller:n,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'N كجم/هكتار')),
      TextField(controller:p,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'P كجم/هكتار')),
      TextField(controller:k,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'K كجم/هكتار'))]),actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:(){
        final nv=double.tryParse(n.text.trim())??0; final pv=double.tryParse(p.text.trim())??0; final kv=double.tryParse(k.text.trim())??0;
        if(nv<0||pv<0||kv<0||nv+pv+kv<=0){Navigator.pop(context,'أدخل قيماً صحيحة.');return;}
        final total=nv+pv+kv; Navigator.pop(context,'N: '+(nv/total*100).toStringAsFixed(1)+'%\nP: '+(pv/total*100).toStringAsFixed(1)+'%\nK: '+(kv/total*100).toStringAsFixed(1)+'%\n\nهذا مؤشر نسبي للمقارنة فقط، وليس وصفة تسميد.');
      },child:const Text('احسب'))]));
    n.dispose();p.dispose();k.dispose();if(mounted&&result!=null)_showResult('توازن N-P-K',result);
  }
  Future<void> _showPlantDensityTool() async {
    final area=TextEditingController(text:'1000'); final spacing=TextEditingController(text:'0.5');
    final result=await _twoFieldTool(title:'كثافة الزراعة',first:area,second:spacing,firstLabel:'المساحة م²',secondLabel:'المسافة بين النباتات م',actionLabel:'احسب',calculate:(){
      final a=double.tryParse(area.text.trim())??0; final s=double.tryParse(spacing.text.trim())??0;
      if(a<=0||s<=0)return 'أدخل قيماً أكبر من صفر.';
      return 'الكثافة التقريبية: ${(a/(s*s)).toStringAsFixed(0)} نبات.\n\nراعِ مسافة الصفوف والممرات ونمط الزراعة.';
    }); area.dispose();spacing.dispose();if(mounted&&result!=null)_showResult('كثافة الزراعة',result);
  }

  Future<void> _showSeedRateTool() async {
    final area = TextEditingController(text: '1000'); final rate = TextEditingController(text: '80');
    final result = await _twoFieldTool(title: 'كمية التقاوي', first: area, second: rate, firstLabel: 'المساحة م²', secondLabel: 'معدل التقاوي كجم/هكتار', actionLabel: 'احسب', calculate: () {
      final a = double.tryParse(area.text.trim()) ?? 0; final r = double.tryParse(rate.text.trim()) ?? 0;
      if (a <= 0 || r < 0) return 'أدخل مساحة صحيحة ومعدل تقاوي غير سالب.';
      return 'كمية التقاوي التقريبية: ${(a / 10000 * r).toStringAsFixed(2)} كجم.\n\nيمكن تعديلها حسب نسبة الإنبات والنقاوة وطريقة الزراعة والصنف.';
    });
    area.dispose(); rate.dispose(); if (mounted && result != null) _showResult('كمية التقاوي', result);
  }

  Future<void> _showPlantCountTool() async {
    final area = TextEditingController(text: '1000'); final row = TextEditingController(text: '1'); final plant = TextEditingController(text: '0.5');
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('عدد النباتات'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: area, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المساحة م²')),
      TextField(controller: row, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المسافة بين الصفوف م')),
      TextField(controller: plant, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المسافة بين النباتات م')),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: () {
        final a = double.tryParse(area.text.trim()) ?? 0; final r = double.tryParse(row.text.trim()) ?? 0; final p = double.tryParse(plant.text.trim()) ?? 0;
        if (a <= 0 || r <= 0 || p <= 0) { Navigator.pop(context, 'أدخل قيماً أكبر من صفر.'); return; }
        Navigator.pop(context, 'العدد النظري للنباتات: ${(a / (r * p)).floor()} نبات.\n\nالعدد الفعلي يتأثر بالممرات ونمط الزراعة ونسبة الإنبات.');
      }, child: const Text('احسب')),
    ]));
    area.dispose(); row.dispose(); plant.dispose(); if (mounted && result != null) _showResult('عدد النباتات', result);
  }

  Future<void> _showWaterProductivityTool() async {
    final production = TextEditingController(text: '1000'); final water = TextEditingController(text: '500');
    final result = await _twoFieldTool(title: 'كفاءة استخدام المياه', first: production, second: water, firstLabel: 'الإنتاج كجم', secondLabel: 'المياه المستخدمة م³', actionLabel: 'احسب', calculate: () {
      final p = double.tryParse(production.text.trim()) ?? 0; final w = double.tryParse(water.text.trim()) ?? 0;
      if (p < 0 || w <= 0) return 'أدخل إنتاجاً غير سالب وكمية مياه أكبر من صفر.';
      return 'إنتاجية المياه: ${(p / w).toStringAsFixed(2)} كجم/م³.\n\nهذا مؤشر للمقارنة بين المواسم أو الحقول، وليس معياراً ثابتاً لكل المحاصيل.';
    });
    production.dispose(); water.dispose(); if (mounted && result != null) _showResult('كفاءة استخدام المياه', result);
  }
  Future<void> _showHarvestLossTool() async {
    final harvested = TextEditingController(text: '1000'); final loss = TextEditingController(text: '5');
    final result = await _twoFieldTool(title: 'فاقد الحصاد', first: harvested, second: loss, firstLabel: 'الإنتاج قبل الفرز كجم', secondLabel: 'نسبة الفاقد %', actionLabel: 'احسب', calculate: () {
      final h = double.tryParse(harvested.text.trim()) ?? 0; final l = double.tryParse(loss.text.trim()) ?? -1;
      if (h < 0 || l < 0 || l > 100) return 'أدخل إنتاجاً صحيحاً ونسبة فاقد بين 0 و100%.';
      return 'الفاقد التقريبي: ${(h*l/100).toStringAsFixed(2)} كجم.\nالصافي بعد الفاقد: ${(h*(1-l/100)).toStringAsFixed(2)} كجم.';
    }); harvested.dispose(); loss.dispose(); if (mounted && result != null) _showResult('فاقد الحصاد', result);
  }

  Future<void> _showRevenueTool() async {
    final qty = TextEditingController(text: '1000'); final price = TextEditingController(text: '2');
    final result = await _twoFieldTool(title: 'الإيراد المتوقع', first: qty, second: price, firstLabel: 'الكمية القابلة للبيع', secondLabel: 'سعر الوحدة', actionLabel: 'احسب', calculate: () {
      final q = double.tryParse(qty.text.trim()) ?? 0; final p = double.tryParse(price.text.trim()) ?? 0;
      if (q < 0 || p < 0) return 'أدخل قيماً غير سالبة.';
      return 'الإيراد الإجمالي المتوقع: ${(q*p).toStringAsFixed(2)} من عملتك.';
    }); qty.dispose(); price.dispose(); if (mounted && result != null) _showResult('الإيراد المتوقع', result);
  }

  Future<void> _showBreakEvenTool() async {
    final fixed = TextEditingController(text: '1000'); final contribution = TextEditingController(text: '2');
    final result = await _twoFieldTool(title: 'نقطة التعادل', first: fixed, second: contribution, firstLabel: 'التكاليف الثابتة', secondLabel: 'هامش المساهمة للوحدة', actionLabel: 'احسب', calculate: () {
      final f = double.tryParse(fixed.text.trim()) ?? 0; final c = double.tryParse(contribution.text.trim()) ?? 0;
      if (f < 0 || c <= 0) return 'أدخل تكلفة ثابتة غير سالبة وهامش مساهمة أكبر من صفر.';
      return 'نقطة التعادل: ${(f/c).ceil()} وحدة تقريباً.';
    }); fixed.dispose(); contribution.dispose(); if (mounted && result != null) _showResult('نقطة التعادل', result);
  }

  Future<void> _showProfitMarginTool() async {
    final revenue = TextEditingController(text: '2000'); final cost = TextEditingController(text: '1400');
    final result = await _twoFieldTool(title: 'هامش الربح', first: revenue, second: cost, firstLabel: 'الإيراد', secondLabel: 'التكلفة الإجمالية', actionLabel: 'احسب', calculate: () {
      final r = double.tryParse(revenue.text.trim()) ?? 0; final c = double.tryParse(cost.text.trim()) ?? 0;
      if (r <= 0 || c < 0) return 'أدخل إيراداً أكبر من صفر وتكلفة غير سالبة.';
      final profit = r-c; return 'الربح: ${profit.toStringAsFixed(2)}.\nهامش الربح: ${(profit/r*100).toStringAsFixed(2)}%.';
    }); revenue.dispose(); cost.dispose(); if (mounted && result != null) _showResult('هامش الربح', result);
  }

  Future<void> _showStorageTool() async {
    final daily = TextEditingController(text: '500'); final days = TextEditingController(text: '10');
    final result = await _twoFieldTool(title: 'سعة التخزين', first: daily, second: days, firstLabel: 'كمية يومية كجم', secondLabel: 'عدد أيام التخزين', actionLabel: 'احسب', calculate: () {
      final d = double.tryParse(daily.text.trim()) ?? 0; final n = double.tryParse(days.text.trim()) ?? 0;
      if (d < 0 || n <= 0) return 'أدخل كمية غير سالبة وعدد أيام أكبر من صفر.';
      return 'السعة الأساسية: ${(d*n).toStringAsFixed(2)} كجم.\nأضف هامشاً مناسباً للمناولة والفقد حسب نوع المنتج.';
    }); daily.dispose(); days.dispose(); if (mounted && result != null) _showResult('سعة التخزين', result);
  }

  Future<void> _showFeedNeedTool() async {
    final animals = TextEditingController(text: '20'); final feed = TextEditingController(text: '5');
    final result = await _twoFieldTool(title: 'احتياج العلف', first: animals, second: feed, firstLabel: 'عدد الحيوانات', secondLabel: 'كجم علف/حيوان/يوم', actionLabel: 'احسب', calculate: () {
      final a = double.tryParse(animals.text.trim()) ?? 0; final f = double.tryParse(feed.text.trim()) ?? 0;
      if (a < 0 || f < 0) return 'أدخل قيماً غير سالبة.';
      return 'الاحتياج اليومي التقريبي: ${(a*f).toStringAsFixed(2)} كجم علف.\nهذه حسبة كمية فقط؛ الاحتياج الغذائي يختلف حسب النوع والعمر والوزن والإنتاج.';
    }); animals.dispose(); feed.dispose(); if (mounted && result != null) _showResult('احتياج العلف', result);
  }

  Future<void> _showLivestockWaterTool() async {
    final animals = TextEditingController(text: '20'); final water = TextEditingController(text: '40');
    final result = await _twoFieldTool(title: 'احتياج الماء للماشية', first: animals, second: water, firstLabel: 'عدد الحيوانات', secondLabel: 'لتر/حيوان/يوم', actionLabel: 'احسب', calculate: () {
      final a = double.tryParse(animals.text.trim()) ?? 0; final w = double.tryParse(water.text.trim()) ?? 0;
      if (a < 0 || w < 0) return 'أدخل قيماً غير سالبة.';
      return 'الاحتياج اليومي التقريبي: ${(a*w).toStringAsFixed(0)} لتر.\nالاحتياج الفعلي يتغير مع النوع والوزن والحرارة والعلف والإنتاج.';
    }); animals.dispose(); water.dispose(); if (mounted && result != null) _showResult('احتياج الماء للماشية', result);
  }

  Future<void> _showEggProductionTool() async {
    final hens = TextEditingController(text: '100'); final rate = TextEditingController(text: '80');
    final result = await _twoFieldTool(title: 'إنتاج البيض', first: hens, second: rate, firstLabel: 'عدد الدجاج', secondLabel: 'نسبة الإنتاج %', actionLabel: 'احسب', calculate: () {
      final h = double.tryParse(hens.text.trim()) ?? 0; final r = double.tryParse(rate.text.trim()) ?? 0;
      if (h < 0 || r < 0 || r > 100) return 'أدخل عدداً صحيحاً ونسبة بين 0 و100%.';
      return 'الإنتاج اليومي النظري: ${(h*r/100).toStringAsFixed(0)} بيضة تقريباً.';
    }); hens.dispose(); rate.dispose(); if (mounted && result != null) _showResult('إنتاج البيض', result);
  }

  Future<void> _showMilkProductionTool() async {
    final animals = TextEditingController(text: '20'); final milk = TextEditingController(text: '8');
    final result = await _twoFieldTool(title: 'إنتاج الحليب', first: animals, second: milk, firstLabel: 'عدد الحيوانات الحلوب', secondLabel: 'لتر/حيوان/يوم', actionLabel: 'احسب', calculate: () {
      final a = double.tryParse(animals.text.trim()) ?? 0; final m = double.tryParse(milk.text.trim()) ?? 0;
      if (a < 0 || m < 0) return 'أدخل قيماً غير سالبة.';
      return 'إنتاج الحليب اليومي التقريبي: ${(a*m).toStringAsFixed(2)} لتر.';
    }); animals.dispose(); milk.dispose(); if (mounted && result != null) _showResult('إنتاج الحليب', result);
  }

  Future<void> _showGreenhouseTool() async {
    final plants = TextEditingController(text: '1000'); final spacing = TextEditingController(text: '0.5');
    final result = await _twoFieldTool(title: 'مساحة البيت المحمي', first: plants, second: spacing, firstLabel: 'عدد النباتات', secondLabel: 'المساحة التقريبية/نبات م²', actionLabel: 'احسب', calculate: () {
      final p = double.tryParse(plants.text.trim()) ?? 0; final s = double.tryParse(spacing.text.trim()) ?? 0;
      if (p <= 0 || s <= 0) return 'أدخل قيماً أكبر من صفر.';
      return 'المساحة الصافية التقريبية: ${(p*s).toStringAsFixed(2)} م².\nأضف مساحة للممرات والخدمات والتهوية عند التخطيط الفعلي.';
    }); plants.dispose(); spacing.dispose(); if (mounted && result != null) _showResult('مساحة البيت المحمي', result);
  }
  Future<void> _showFertilizerUnitTool() async {
    final area = TextEditingController(text: '1');
    final rate = TextEditingController(text: '100');
    final result = await _twoFieldTool(title: 'تحويل معدل السماد', first: area, second: rate, firstLabel: 'المساحة م²', secondLabel: 'المعدل كجم/هكتار', actionLabel: 'احسب', calculate: () {
      final a = double.tryParse(area.text.trim()) ?? 0;
      final r = double.tryParse(rate.text.trim()) ?? 0;
      if (a <= 0 || r < 0) return 'أدخل مساحة أكبر من صفر ومعدل غير سالب.';
      return 'المعدل المكافئ: ' + (r / 10000).toStringAsFixed(4) + ' كجم/م².\nالكمية لهذه المساحة: ' + (a * r / 10000).toStringAsFixed(2) + ' كجم.';
    });
    area.dispose(); rate.dispose();
    if (mounted && result != null) _showResult('تحويل معدل السماد', result);
  }

  Future<void> _showSeedCorrectionTool() async {
    final base = TextEditingController();
    final germ = TextEditingController(text: '90');
    final purity = TextEditingController(text: '95');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تصحيح كمية التقاوي'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: base, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الكمية الأساسية كجم')),
          TextField(controller: germ, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نسبة الإنبات %')),
          TextField(controller: purity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نقاوة البذور %')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final b = double.tryParse(base.text.trim()) ?? 0;
            final g = double.tryParse(germ.text.trim()) ?? 0;
            final p = double.tryParse(purity.text.trim()) ?? 0;
            if (b <= 0 || g <= 0 || g > 100 || p <= 0 || p > 100) {
              Navigator.pop(context, 'أدخل كمية موجبة ونسباً بين 1 و100%.');
              return;
            }
            final corrected = b / ((g / 100) * (p / 100));
            Navigator.pop(context, 'الكمية المصححة التقريبية: ' + corrected.toStringAsFixed(2) + ' كجم.\\nالحسبة تعتمد على الإنبات والنقاوة فقط؛ راعِ الصنف وطريقة الزراعة والمسافات ومعدل البذر المحلي.');
          }, child: const Text('احسب')),
        ],
      ),
    );
    base.dispose(); germ.dispose(); purity.dispose();
    if (mounted && result != null) _showResult('تصحيح التقاوي', result);
  }
  Future<void> _showSoilSamplingTool() async {
    final area = TextEditingController(text: '5'); final depth = TextEditingController(text: '20');
    final result = await _twoFieldTool(title: 'خطة أخذ عينات التربة', first: area, second: depth, firstLabel: 'مساحة الحقل هكتار', secondLabel: 'عمق العينة سم', actionLabel: 'احسب', calculate: () {
      final a = double.tryParse(area.text.trim()) ?? 0; final d = double.tryParse(depth.text.trim()) ?? 0;
      if (a <= 0 || d <= 0) return 'أدخل مساحة وعمقاً أكبر من صفر.';
      final samples = (a * 5).ceil().clamp(1, 50);
      return 'ابدأ تقريبياً بـ ' + samples.toString() + ' عينات موزعة على مناطق متجانسة، بعمق ' + d.toStringAsFixed(0) + ' سم.\nالعدد النهائي يعتمد على تجانس الحقل ونظام المختبر.';
    });
    area.dispose(); depth.dispose();
    if (mounted && result != null) _showResult('خطة أخذ عينات التربة', result);
  }

  Future<void> _showPostHarvestLossTool() async {
    final qty = TextEditingController(text: '1000'); final loss = TextEditingController(text: '8');
    final result = await _twoFieldTool(title: 'فاقد ما بعد الحصاد', first: qty, second: loss, firstLabel: 'الكمية كجم', secondLabel: 'نسبة الفاقد %', actionLabel: 'احسب', calculate: () {
      final q = double.tryParse(qty.text.trim()) ?? 0; final l = double.tryParse(loss.text.trim()) ?? 0;
      if (q < 0 || l < 0 || l > 100) return 'أدخل كمية صحيحة ونسبة بين 0 و100%.';
      return 'الفاقد المتوقع: ' + (q * l / 100).toStringAsFixed(2) + ' كجم.\nالمتبقي: ' + (q * (1 - l / 100)).toStringAsFixed(2) + ' كجم.';
    });
    qty.dispose(); loss.dispose();
    if (mounted && result != null) _showResult('فاقد ما بعد الحصاد', result);
  }

  Future<void> _showMarketableQuantityTool() async {
    final qty=TextEditingController(text:'1000'); final rate=TextEditingController(text:'90');
    final result=await _twoFieldTool(title:'الكمية القابلة للبيع',first:qty,second:rate,firstLabel:'الإنتاج كجم',secondLabel:'نسبة القبول %',actionLabel:'احسب',calculate:(){
      final q=double.tryParse(qty.text.trim())??0; final r=double.tryParse(rate.text.trim())??0;
      if(q<0||r<0||r>100)return'أدخل كمية صحيحة ونسبة بين 0 و100%.';
      return'الكمية القابلة للبيع تقريباً: '+(q*r/100).toStringAsFixed(2)+' كجم.';
    });
    qty.dispose();rate.dispose();if(mounted&&result!=null)_showResult('الكمية القابلة للبيع',result);
  }

  Future<void> _showStorageDurationTool() async {
    final capacity=TextEditingController(text:'5000'); final daily=TextEditingController(text:'500');
    final result=await _twoFieldTool(title:'مدة التخزين',first:capacity,second:daily,firstLabel:'سعة التخزين كجم',secondLabel:'الخروج اليومي كجم',actionLabel:'احسب',calculate:(){
      final c=double.tryParse(capacity.text.trim())??0; final d=double.tryParse(daily.text.trim())??0;
      if(c<=0||d<=0)return'أدخل قيماً أكبر من صفر.';
      return'المدة النظرية: '+(c/d).toStringAsFixed(1)+' يوم.\nالمدة الفعلية تتأثر بنوع المنتج والحرارة والرطوبة.';
    });
    capacity.dispose();daily.dispose();if(mounted&&result!=null)_showResult('مدة التخزين',result);
  }

  Future<void> _showCoolingTool() async {
    final mass=TextEditingController(text:'1000'); final factor=TextEditingController(text:'0.02');
    final result=await _twoFieldTool(title:'حمل التبريد',first:mass,second:factor,firstLabel:'كتلة المنتج كجم',secondLabel:'معامل تقديري kW/كجم',actionLabel:'احسب',calculate:(){
      final m=double.tryParse(mass.text.trim())??0; final f=double.tryParse(factor.text.trim())??0;
      if(m<=0||f<=0)return'أدخل قيماً أكبر من صفر.';
      return'الحمل التقديري: '+(m*f).toStringAsFixed(2)+' kW.\nهذه حسبة أولية؛ التصميم يحتاج بيانات حرارية وهندسية فعلية.';
    });
    mass.dispose();factor.dispose();if(mounted&&result!=null)_showResult('حمل التبريد',result);
  }

  Future<void> _showTransportLoadTool() async {
    final qty=TextEditingController(text:'5000'); final capacity=TextEditingController(text:'1000');
    final result=await _twoFieldTool(title:'حجم النقل',first:qty,second:capacity,firstLabel:'الكمية كجم',secondLabel:'حمولة المركبة كجم',actionLabel:'احسب',calculate:(){
      final q=double.tryParse(qty.text.trim())??0; final c=double.tryParse(capacity.text.trim())??0;
      if(q<0||c<=0)return'أدخل كمية غير سالبة وحمولة أكبر من صفر.';
      return'عدد الرحلات التقريبي: '+(q/c).ceil().toString()+' رحلة.';
    });
    qty.dispose();capacity.dispose();if(mounted&&result!=null)_showResult('حجم النقل',result);
  }

  Future<void> _showLaborNeedTool() async {
    final area=TextEditingController(text:'1'); final rate=TextEditingController(text:'5');
    final result=await _twoFieldTool(title:'احتياج العمالة',first:area,second:rate,firstLabel:'المساحة هكتار',secondLabel:'أيام عمل/هكتار',actionLabel:'احسب',calculate:(){
      final a=double.tryParse(area.text.trim())??0; final r=double.tryParse(rate.text.trim())??0;
      if(a<0||r<0)return'أدخل قيماً غير سالبة.';
      return'إجمالي أيام العمل التقريبية: '+(a*r).toStringAsFixed(1)+' يوم-عامل.';
    });
    area.dispose();rate.dispose();if(mounted&&result!=null)_showResult('احتياج العمالة',result);
  }

  Future<void> _showOperatingHoursTool() async {
    final qty=TextEditingController(text:'10000'); final rate=TextEditingController(text:'1000');
    final result=await _twoFieldTool(title:'ساعات التشغيل',first:qty,second:rate,firstLabel:'الكمية المطلوبة',secondLabel:'معدل الإنجاز/ساعة',actionLabel:'احسب',calculate:(){
      final q=double.tryParse(qty.text.trim())??0; final r=double.tryParse(rate.text.trim())??0;
      if(q<0||r<=0)return'أدخل كمية غير سالبة ومعدل أكبر من صفر.';
      return'زمن التشغيل النظري: '+(q/r).toStringAsFixed(2)+' ساعة.';
    });
    qty.dispose();rate.dispose();if(mounted&&result!=null)_showResult('ساعات التشغيل',result);
  }

  Future<void> _showProductionEstimateTool() async {
    final area=TextEditingController(text:'1000'); final rate=TextEditingController(text:'3');
    final result=await _twoFieldTool(title:'تقدير الإنتاج',first:area,second:rate,firstLabel:'المساحة م²',secondLabel:'الإنتاج المتوقع كجم/م²',actionLabel:'احسب',calculate:(){
      final a=double.tryParse(area.text.trim())??0; final y=double.tryParse(rate.text.trim())??0;
      if(a<=0||y<0)return 'أدخل مساحة صحيحة وإنتاجاً غير سالب.';
      final kg=a*y; return 'الإنتاج التقديري: ${kg.toStringAsFixed(1)} كجم (${(kg/1000).toStringAsFixed(2)} طن).\n\nالتقدير يتأثر بالصنف والمناخ والإدارة والآفات والري.';
    }); area.dispose();rate.dispose();if(mounted&&result!=null)_showResult('تقدير الإنتاج',result);
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
      actionLabel: 'تسجيل سريع',
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

  Future<void> _showAreaConverterTool() async {
    final value = TextEditingController();
    final ref = TextEditingController(text: '10000');
    final result = await _twoFieldTool(title: 'تحويل المساحة', first: value, second: ref, firstLabel: 'المساحة بالمتر المربع', secondLabel: 'م² لكل هكتار (10000)', actionLabel: 'احسب', calculate: () {
      final v = double.tryParse(value.text.trim()) ?? 0; final r = double.tryParse(ref.text.trim()) ?? 0;
      if (v <= 0 || r <= 0) return 'أدخل قيماً موجبة.';
      return v.toStringAsFixed(2) + ' م² = ' + (v / r).toStringAsFixed(4) + ' هكتار.';
    });
    value.dispose(); ref.dispose(); if (mounted && result != null) _showResult('تحويل المساحة', result);
  }

  Future<void> _showWeightConverterTool() async {
    final value = TextEditingController();
    final result = await _twoFieldTool(title: 'تحويل الوزن', first: value, second: TextEditingController(text: '1000'), firstLabel: 'الوزن بالكيلوغرام', secondLabel: 'كجم لكل طن', actionLabel: 'احسب', calculate: () {
      final v = double.tryParse(value.text.trim()) ?? 0; if (v < 0) return 'أدخل وزناً صحيحاً.';
      return v.toStringAsFixed(2) + ' كجم = ' + (v / 1000).toStringAsFixed(3) + ' طن.';
    });
    value.dispose(); if (mounted && result != null) _showResult('تحويل الوزن', result);
  }

  Future<void> _showWaterVolumeConverterTool() async {
    final value = TextEditingController();
    final result = await _twoFieldTool(title: 'تحويل حجم المياه', first: value, second: TextEditingController(text: '1000'), firstLabel: 'الحجم باللتر', secondLabel: 'لتر لكل متر مكعب', actionLabel: 'احسب', calculate: () {
      final v = double.tryParse(value.text.trim()) ?? 0; if (v < 0) return 'أدخل حجماً صحيحاً.';
      return v.toStringAsFixed(2) + ' لتر = ' + (v / 1000).toStringAsFixed(3) + ' م³.';
    });
    value.dispose(); if (mounted && result != null) _showResult('تحويل حجم المياه', result);
  }

  Future<void> _showIrrigationScheduleTool() async {
    final daily = TextEditingController(); final events = TextEditingController(text: '2');
    final result = await _twoFieldTool(title: 'جدولة الري اليومية', first: daily, second: events, firstLabel: 'كمية المياه اليومية باللتر', secondLabel: 'عدد الريات في اليوم', actionLabel: 'احسب', calculate: () {
      final d = double.tryParse(daily.text.trim()) ?? 0; final n = int.tryParse(events.text.trim()) ?? 0;
      if (d <= 0 || n <= 0) return 'أدخل كمية يومية وعدد ريات صحيحاً.';
      return 'إجمالي المياه: ' + d.toStringAsFixed(0) + ' لتر/يوم.\\nالتوزيع النظري: ' + (d / n).toStringAsFixed(0) + ' لتر لكل رية.\\nاضبط التوقيت والجرعات حسب التربة والمحصول والطقس وكفاءة النظام.';
    });
    daily.dispose(); events.dispose(); if (mounted && result != null) _showResult('جدولة الري', result);
  }

  Future<void> _showIrrigationSectorTool() async {
    final total = TextEditingController(); final sectors = TextEditingController(text: '4');
    final result = await _twoFieldTool(title: 'تقسيم مياه الري على القطاعات', first: total, second: sectors, firstLabel: 'إجمالي المياه باللتر', secondLabel: 'عدد القطاعات', actionLabel: 'قسّم', calculate: () {
      final t = double.tryParse(total.text.trim()) ?? 0; final s = int.tryParse(sectors.text.trim()) ?? 0;
      if (t <= 0 || s <= 0) return 'أدخل قيماً موجبة.';
      return 'عند التوزيع المتساوي: ' + (t / s).toStringAsFixed(0) + ' لتر لكل قطاع.\\nيمكن تعديل الحصة إذا اختلفت المساحة أو التربة أو المحصول.';
    });
    total.dispose(); sectors.dispose(); if (mounted && result != null) _showResult('تقسيم مياه الري', result);
  }

  Future<void> _showSeedAreaTool() async {
    final seed = TextEditingController(); final rate = TextEditingController();
    final result = await _twoFieldTool(title: 'تقدير المساحة من التقاوي', first: seed, second: rate, firstLabel: 'كمية التقاوي كجم', secondLabel: 'معدل البذر كجم/هكتار', actionLabel: 'احسب', calculate: () {
      final q = double.tryParse(seed.text.trim()) ?? 0; final r = double.tryParse(rate.text.trim()) ?? 0;
      if (q <= 0 || r <= 0) return 'أدخل قيماً موجبة.';
      final ha = q / r; return 'المساحة النظرية: ' + ha.toStringAsFixed(2) + ' هكتار (' + (ha * 10000).toStringAsFixed(0) + ' م²).\\nالتقدير يفترض أن معدل البذر مناسب للصنف وطريقة الزراعة.';
    });
    seed.dispose(); rate.dispose(); if (mounted && result != null) _showResult('المساحة من التقاوي', result);
  }

  Future<void> _showStorageLossTool() async {
    final qty = TextEditingController(); final loss = TextEditingController(text: '5');
    final result = await _twoFieldTool(title: 'فاقد التخزين', first: qty, second: loss, firstLabel: 'الكمية المخزنة كجم', secondLabel: 'نسبة الفاقد %', actionLabel: 'احسب', calculate: () {
      final q = double.tryParse(qty.text.trim()) ?? 0; final p = double.tryParse(loss.text.trim()) ?? 0;
      if (q <= 0 || p < 0 || p > 100) return 'أدخل كمية موجبة ونسبة بين 0 و100%.';
      final lost = q * p / 100; return 'الفاقد التقديري: ' + lost.toStringAsFixed(2) + ' كجم.\\nالكمية المتبقية: ' + (q - lost).toStringAsFixed(2) + ' كجم.';
    });
    qty.dispose(); loss.dispose(); if (mounted && result != null) _showResult('فاقد التخزين', result);
  }

  Future<void> _showPackagingTool() async {
    final qty = TextEditingController(); final pack = TextEditingController(text: '25');
    final result = await _twoFieldTool(title: 'احتياج التعبئة', first: qty, second: pack, firstLabel: 'الكمية كجم', secondLabel: 'وزن العبوة كجم', actionLabel: 'احسب', calculate: () {
      final q = double.tryParse(qty.text.trim()) ?? 0; final p = double.tryParse(pack.text.trim()) ?? 0;
      if (q <= 0 || p <= 0) return 'أدخل قيماً موجبة.'; final n = (q / p).ceil();
      return 'عدد العبوات المطلوبة: ' + n.toString() + '.\\nالسعة الاسمية الإجمالية: ' + (n * p).toStringAsFixed(2) + ' كجم.';
    });
    qty.dispose(); pack.dispose(); if (mounted && result != null) _showResult('احتياج التعبئة', result);
  }

  Future<void> _showFuelConsumptionTool() async {
    final hours = TextEditingController(); final rate = TextEditingController(text: '2');
    final result = await _twoFieldTool(title: 'استهلاك الوقود', first: hours, second: rate, firstLabel: 'ساعات التشغيل', secondLabel: 'استهلاك الوقود لتر/ساعة', actionLabel: 'احسب', calculate: () {
      final h = double.tryParse(hours.text.trim()) ?? 0; final r = double.tryParse(rate.text.trim()) ?? 0;
      if (h <= 0 || r < 0) return 'أدخل ساعات موجبة ومعدل وقود صحيح.'; return 'الاستهلاك التقديري: ' + (h * r).toStringAsFixed(2) + ' لتر.';
    });
    hours.dispose(); rate.dispose(); if (mounted && result != null) _showResult('استهلاك الوقود', result);
  }

  Future<void> _showLaborCostTool() async {
    final workers = TextEditingController(); final days = TextEditingController(); final wage = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('تكلفة العمالة'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: workers, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد العمال')),
        TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد الأيام')),
        TextField(controller: wage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أجر العامل في اليوم')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final w = int.tryParse(workers.text.trim()) ?? 0; final d = int.tryParse(days.text.trim()) ?? 0; final p = double.tryParse(wage.text.trim()) ?? 0;
          if (w <= 0 || d <= 0 || p < 0) { Navigator.pop(context, 'أدخل قيماً صحيحة.'); return; }
          Navigator.pop(context, 'إجمالي تكلفة العمالة: ' + (w * d * p).toStringAsFixed(2) + '\\nهذه لا تشمل النقل أو السكن أو الإضافات أو الضرائب إن وجدت.');
        }, child: const Text('احسب')),
      ],
    ));
    workers.dispose(); days.dispose(); wage.dispose(); if (mounted && result != null) _showResult('تكلفة العمالة', result);
  }

  Future<void> _showAreaConversionTool() async {
    final value = TextEditingController();
    final dummy = TextEditingController(text: '1');
    final result = await _twoFieldTool(
      title: 'تحويل المساحة',
      first: value,
      second: dummy,
      firstLabel: 'القيمة بالمتر المربع',
      secondLabel: 'اتركها 1 للحساب',
      actionLabel: 'حوّل',
      calculate: () {
        final v = double.tryParse(value.text.trim()) ?? 0;
        if (v < 0) return 'أدخل مساحة غير سالبة.';
        return '\$v م² = \${(v / 10000).toStringAsFixed(4)} هكتار.';
      },
    );
    value.dispose(); dummy.dispose();
    if (mounted && result != null) _showResult('تحويل المساحة', result);
  }

  Future<void> _showWeightConversionTool() async {
    final value = TextEditingController();
    final dummy = TextEditingController(text: '1');
    final result = await _twoFieldTool(
      title: 'تحويل الوزن',
      first: value,
      second: dummy,
      firstLabel: 'القيمة بالكيلوجرام',
      secondLabel: 'اتركها 1 للحساب',
      actionLabel: 'حوّل',
      calculate: () {
        final v = double.tryParse(value.text.trim()) ?? 0;
        if (v < 0) return 'أدخل وزناً غير سالب.';
        return '\$v كجم = \${(v / 1000).toStringAsFixed(4)} طن متري.';
      },
    );
    value.dispose(); dummy.dispose();
    if (mounted && result != null) _showResult('تحويل الوزن', result);
  }

  Future<void> _showWaterVolumeConversionTool() async {
    final value = TextEditingController();
    final dummy = TextEditingController(text: '1');
    final result = await _twoFieldTool(
      title: 'تحويل حجم المياه',
      first: value,
      second: dummy,
      firstLabel: 'القيمة باللتر',
      secondLabel: 'اتركها 1 للحساب',
      actionLabel: 'حوّل',
      calculate: () {
        final v = double.tryParse(value.text.trim()) ?? 0;
        if (v < 0) return 'أدخل حجماً غير سالب.';
        return '\$v لتر = \${(v / 1000).toStringAsFixed(4)} م³.';
      },
    );
    value.dispose(); dummy.dispose();
    if (mounted && result != null) _showResult('تحويل حجم المياه', result);
  }

  Future<void> _showDailyIrrigationScheduleTool() async {
    final daily = TextEditingController();
    final events = TextEditingController(text: '2');
    final result = await _twoFieldTool(
      title: 'جدولة الري اليومية',
      first: daily,
      second: events,
      firstLabel: 'كمية المياه اليومية باللتر',
      secondLabel: 'عدد الريات يومياً',
      actionLabel: 'قسّم',
      calculate: () {
        final d = double.tryParse(daily.text.trim()) ?? 0;
        final e = int.tryParse(events.text.trim()) ?? 0;
        if (d <= 0 || e <= 0) return 'أدخل كمية وعدداً أكبر من صفر.';
        return 'الكمية التقريبية لكل رية: \${(d / e).toStringAsFixed(1)} لتر.\nهذه جدولة حسابية فقط؛ التوقيت الفعلي يعتمد على التربة والمحصول والطقس وكفاءة النظام.';
      },
    );
    daily.dispose(); events.dispose();
    if (mounted && result != null) _showResult('جدولة الري اليومية', result);
  }

  Future<void> _showAdvancedSeedCorrectionTool() async {
    final base = TextEditingController();
    final germ = TextEditingController(text: '90');
    final purity = TextEditingController(text: '95');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تصحيح التقاوي بالإنبات والنقاوة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: base, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'معدل التقاوي الأساسي كجم/هكتار')),
          TextField(controller: germ, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نسبة الإنبات %')),
          TextField(controller: purity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نسبة النقاوة %')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final b = double.tryParse(base.text.trim()) ?? 0;
            final g = double.tryParse(germ.text.trim()) ?? 0;
            final p = double.tryParse(purity.text.trim()) ?? 0;
            if (b <= 0 || g <= 0 || g > 100 || p <= 0 || p > 100) {
              Navigator.pop(context, 'أدخل معدل التقاوي ونسباً بين 1 و100%.');
              return;
            }
            final corrected = b / ((g / 100) * (p / 100));
            Navigator.pop(context, 'معدل التقاوي المصحح تقريبياً: ${corrected.toStringAsFixed(2)} كجم/هكتار.\nالنتيجة تقديرية وقد تتأثر بطريقة الزراعة والصنف وحجم البذرة والمسافات.');
          }, child: const Text('احسب')),
        ],
      ),
    );
    base.dispose(); germ.dispose(); purity.dispose();
    if (mounted && result != null) _showResult('تصحيح التقاوي المتقدم', result);
  }

  Future<void> _showAreaFromSeedTool() async {
    final seed = TextEditingController();
    final rate = TextEditingController();
    final result = await _twoFieldTool(
      title: 'تقدير المساحة من كمية التقاوي',
      first: seed,
      second: rate,
      firstLabel: 'كمية التقاوي بالكجم',
      secondLabel: 'معدل التقاوي كجم/هكتار',
      actionLabel: 'احسب',
      calculate: () {
        final s = double.tryParse(seed.text.trim()) ?? 0;
        final r = double.tryParse(rate.text.trim()) ?? 0;
        if (s <= 0 || r <= 0) return 'أدخل قيماً أكبر من صفر.';
        return 'المساحة التقديرية: \${(s / r).toStringAsFixed(3)} هكتار.';
      },
    );
    seed.dispose(); rate.dispose();
    if (mounted && result != null) _showResult('المساحة من التقاوي', result);
  }

  Future<void> _showStorageWasteTool() async {
    final qty = TextEditingController();
    final loss = TextEditingController(text: '5');
    final result = await _twoFieldTool(
      title: 'هدر التخزين',
      first: qty,
      second: loss,
      firstLabel: 'الكمية المخزنة',
      secondLabel: 'نسبة الفاقد %',
      actionLabel: 'احسب',
      calculate: () {
        final q = double.tryParse(qty.text.trim()) ?? 0;
        final l = double.tryParse(loss.text.trim()) ?? 0;
        if (q < 0 || l < 0 || l > 100) return 'أدخل كمية صحيحة ونسبة بين 0 و100%.';
        final waste = q * l / 100;
        return 'الفاقد التقديري: ${waste.toStringAsFixed(2)} من نفس وحدة الكمية.\nالمتبقي: \${(q - waste).toStringAsFixed(2)}.';
      },
    );
    qty.dispose(); loss.dispose();
    if (mounted && result != null) _showResult('هدر التخزين', result);
  }

  Future<void> _showFeedConversionTool() async {
    final feed = TextEditingController();
    final gain = TextEditingController();
    final result = await _twoFieldTool(
      title: 'معامل تحويل العلف FCR',
      first: feed,
      second: gain,
      firstLabel: 'كمية العلف المستهلك كجم',
      secondLabel: 'الزيادة في الوزن كجم',
      actionLabel: 'احسب',
      calculate: () {
        final f = double.tryParse(feed.text.trim()) ?? 0;
        final g = double.tryParse(gain.text.trim()) ?? 0;
        if (f < 0 || g <= 0) return 'أدخل علفاً غير سالب وزيادة وزن أكبر من صفر.';
        return 'FCR التقديري: \${(f / g).toStringAsFixed(2)} كجم علف لكل كجم زيادة.\nيُستخدم للمقارنة التشغيلية وليس معياراً ثابتاً لكل نوع أو عمر.';
      },
    );
    feed.dispose(); gain.dispose();
    if (mounted && result != null) _showResult('معامل تحويل العلف', result);
  }

  Future<void> _showHoneyProductionTool() async {
    final colonies = TextEditingController();
    final yieldPer = TextEditingController(text: '10');
    final result = await _twoFieldTool(
      title: 'تقدير إنتاج العسل',
      first: colonies,
      second: yieldPer,
      firstLabel: 'عدد الطوائف',
      secondLabel: 'كجم عسل تقديري لكل طائفة',
      actionLabel: 'قدّر',
      calculate: () {
        final c = double.tryParse(colonies.text.trim()) ?? 0;
        final y = double.tryParse(yieldPer.text.trim()) ?? 0;
        if (c < 0 || y < 0) return 'أدخل قيماً غير سالبة.';
        return 'الإنتاج التقديري: \${(c * y).toStringAsFixed(2)} كجم عسل.\nالإنتاج الفعلي يتغير بشدة حسب السلالة والمرعى والموسم وصحة الطوائف والإدارة.';
      },
    );
    colonies.dispose(); yieldPer.dispose();
    if (mounted && result != null) _showResult('تقدير إنتاج العسل', result);
  }


  Future<void> _showAquacultureFeedTool() async {
    final biomass = TextEditingController();
    final rate = TextEditingController(text: '2');
    final result = await _twoFieldTool(
      title: 'احتياج علف الأسماك',
      first: biomass,
      second: rate,
      firstLabel: 'كتلة الأسماك الحية كجم',
      secondLabel: 'معدل التغذية % من الكتلة يومياً',
      actionLabel: 'احسب',
      calculate: () {
        final b = double.tryParse(biomass.text.trim()) ?? 0;
        final r = double.tryParse(rate.text.trim()) ?? 0;
        if (b <= 0 || r <= 0 || r > 20) return 'أدخل كتلة صحيحة ومعدل تغذية مناسباً بين 0 و20%.';
        return 'العلف التقديري يومياً: \${(b * r / 100).toStringAsFixed(2)} كجم.\\nالمعدل الفعلي يتغير حسب النوع والحجم وحرارة الماء وجودة العلف.';
      },
    );
    biomass.dispose(); rate.dispose();
    if (mounted && result != null) _showResult('علف الأسماك', result);
  }

  Future<void> _showFishBiomassTool() async {
    final count = TextEditingController();
    final weight = TextEditingController();
    final result = await _twoFieldTool(
      title: 'تقدير كتلة الأسماك',
      first: count,
      second: weight,
      firstLabel: 'عدد الأسماك',
      secondLabel: 'متوسط وزن السمكة بالجرام',
      actionLabel: 'قدّر',
      calculate: () {
        final c = double.tryParse(count.text.trim()) ?? 0;
        final w = double.tryParse(weight.text.trim()) ?? 0;
        if (c <= 0 || w <= 0) return 'أدخل قيماً أكبر من صفر.';
        return 'الكتلة الحية التقريبية: \${(c * w / 1000).toStringAsFixed(2)} كجم.';
      },
    );
    count.dispose(); weight.dispose();
    if (mounted && result != null) _showResult('كتلة الأسماك', result);
  }

  Future<void> _showPoultryMortalityTool() async {
    final start = TextEditingController();
    final dead = TextEditingController();
    final result = await _twoFieldTool(
      title: 'معدل نفوق الدواجن',
      first: start,
      second: dead,
      firstLabel: 'عدد الطيور في البداية',
      secondLabel: 'عدد النافق',
      actionLabel: 'احسب',
      calculate: () {
        final s = double.tryParse(start.text.trim()) ?? 0;
        final d = double.tryParse(dead.text.trim()) ?? 0;
        if (s <= 0 || d < 0 || d > s) return 'أدخل أعداداً صحيحة، والنافق لا يتجاوز العدد الابتدائي.';
        return 'معدل النفوق: \${(d * 100 / s).toStringAsFixed(2)}%.\\nإذا كان النفوق غير معتاد، راجع الطبيب البيطري وإجراءات الأمن الحيوي.';
      },
    );
    start.dispose(); dead.dispose();
    if (mounted && result != null) _showResult('نفوق الدواجن', result);
  }

  Future<void> _showLivestockWeightGainTool() async {
    final start = TextEditingController();
    final end = TextEditingController();
    final days = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('زيادة وزن القطيع'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: start, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الوزن الابتدائي كجم')),
          TextField(controller: end, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الوزن النهائي كجم')),
          TextField(controller: days, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'عدد الأيام')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final a = double.tryParse(start.text.trim()) ?? 0;
            final b = double.tryParse(end.text.trim()) ?? 0;
            final d = double.tryParse(days.text.trim()) ?? 0;
            if (a < 0 || b < 0 || d <= 0 || b < a) {
              Navigator.pop(context, 'أدخل أوزاناً صحيحة ومدة أكبر من صفر.');
              return;
            }
            Navigator.pop(context, 'الزيادة الكلية: \${(b - a).toStringAsFixed(2)} كجم.\\nمتوسط الزيادة اليومية: \${((b - a) / d).toStringAsFixed(3)} كجم/يوم.');
          }, child: const Text('احسب')),
        ],
      ),
    );
    start.dispose(); end.dispose(); days.dispose();
    if (mounted && result != null) _showResult('زيادة الوزن', result);
  }

  Future<void> _showMilkPerAnimalTool() async {
    final milk = TextEditingController();
    final animals = TextEditingController();
    final result = await _twoFieldTool(
      title: 'إنتاج الحليب للفرد',
      first: milk,
      second: animals,
      firstLabel: 'إجمالي الحليب لتر/يوم',
      secondLabel: 'عدد الحيوانات المنتجة',
      actionLabel: 'احسب',
      calculate: () {
        final m = double.tryParse(milk.text.trim()) ?? 0;
        final a = double.tryParse(animals.text.trim()) ?? 0;
        if (m < 0 || a <= 0) return 'أدخل قيماً صحيحة.';
        return 'متوسط الإنتاج: \${(m / a).toStringAsFixed(2)} لتر/حيوان/يوم.';
      },
    );
    milk.dispose(); animals.dispose();
    if (mounted && result != null) _showResult('إنتاج الحليب للفرد', result);
  }

  Future<void> _showDailyStorageLossTool() async {
    final quantity = TextEditingController();
    final rate = TextEditingController(text: '1');
    final days = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('فاقد التخزين اليومي'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الكمية الابتدائية')),
          TextField(controller: rate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'فاقد يومي %')),
          TextField(controller: days, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'عدد الأيام')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            final q = double.tryParse(quantity.text.trim()) ?? 0;
            final r = double.tryParse(rate.text.trim()) ?? 0;
            final d = int.tryParse(days.text.trim()) ?? 0;
            if (q < 0 || r < 0 || r > 100 || d <= 0) {
              Navigator.pop(context, 'أدخل كمية ونسبة صحيحتين وعدد أيام أكبر من صفر.');
              return;
            }
            final remaining = q * math.pow(1 - r / 100, d);
            Navigator.pop(context, 'الكمية المتبقية بعد الفاقد المركب تقريبياً: ${remaining.toStringAsFixed(2)}.\\nهذه محاكاة حسابية؛ الفاقد الفعلي يعتمد على المنتج وظروف التخزين.');
          }, child: const Text('احسب')),
        ],
      ),
    );
    quantity.dispose(); rate.dispose(); days.dispose();
    if (mounted && result != null) _showResult('فاقد التخزين اليومي', result);
  }

  Future<void> _showMachineryFuelTool() async {
    final hours = TextEditingController();
    final rate = TextEditingController();
    final result = await _twoFieldTool(
      title: 'استهلاك وقود الآلات',
      first: hours,
      second: rate,
      firstLabel: 'ساعات التشغيل',
      secondLabel: 'استهلاك الوقود لتر/ساعة',
      actionLabel: 'احسب',
      calculate: () {
        final h = double.tryParse(hours.text.trim()) ?? 0;
        final r = double.tryParse(rate.text.trim()) ?? 0;
        if (h <= 0 || r < 0) return 'أدخل ساعات موجبة واستهلاكاً غير سالب.';
        return 'إجمالي الوقود التقديري: \${(h * r).toStringAsFixed(2)} لتر.';
      },
    );
    hours.dispose(); rate.dispose();
    if (mounted && result != null) _showResult('وقود الآلات', result);
  }

  Future<void> _showFarmElectricityTool() async {
    final power = TextEditingController();
    final hours = TextEditingController();
    final result = await _twoFieldTool(
      title: 'استهلاك الكهرباء الزراعي',
      first: power,
      second: hours,
      firstLabel: 'قدرة الجهاز kW',
      secondLabel: 'ساعات التشغيل',
      actionLabel: 'احسب',
      calculate: () {
        final p = double.tryParse(power.text.trim()) ?? 0;
        final h = double.tryParse(hours.text.trim()) ?? 0;
        if (p <= 0 || h <= 0) return 'أدخل قدرة وساعات أكبر من صفر.';
        return 'الاستهلاك التقريبي: \${(p * h).toStringAsFixed(2)} kWh.';
      },
    );
    power.dispose(); hours.dispose();
    if (mounted && result != null) _showResult('استهلاك الكهرباء', result);
  }

  Future<void> _showHerdProductivityTool() async {
    final output = TextEditingController();
    final animals = TextEditingController();
    final result = await _twoFieldTool(
      title: 'كفاءة إنتاج القطيع',
      first: output,
      second: animals,
      firstLabel: 'إجمالي الإنتاج',
      secondLabel: 'عدد الحيوانات/الطيور المنتجة',
      actionLabel: 'احسب',
      calculate: () {
        final o = double.tryParse(output.text.trim()) ?? 0;
        final a = double.tryParse(animals.text.trim()) ?? 0;
        if (o < 0 || a <= 0) return 'أدخل إنتاجاً غير سالب وعدداً أكبر من صفر.';
        return 'متوسط الإنتاج للفرد: \${(o / a).toStringAsFixed(2)} وحدة/فرد.';
      },
    );
    output.dispose(); animals.dispose();
    if (mounted && result != null) _showResult('إنتاجية القطيع', result);
  }


  Future<void> _showLandProductivityTool() async {
    final output=TextEditingController(); final area=TextEditingController();
    final result=await _twoFieldTool(title:'كفاءة الأرض',first:output,second:area,firstLabel:'الإنتاج الكلي',secondLabel:'المساحة م²',actionLabel:'احسب',calculate:(){
      final o=double.tryParse(output.text.trim())??0; final a=double.tryParse(area.text.trim())??0;
      if(o<0||a<=0)return 'أدخل إنتاجاً غير سالب ومساحة أكبر من صفر.';
      return 'الإنتاج لكل متر مربع: \${(o/a).toStringAsFixed(3)} وحدة/م².';
    });
    output.dispose(); area.dispose(); if(mounted&&result!=null)_showResult('كفاءة الأرض',result);
  }

  Future<void> _showFeedPerAnimalTool() async {
    final feed=TextEditingController(); final animals=TextEditingController();
    final result=await _twoFieldTool(title:'استهلاك العلف للفرد',first:feed,second:animals,firstLabel:'إجمالي العلف كجم',secondLabel:'عدد الحيوانات/الطيور',actionLabel:'احسب',calculate:(){
      final f=double.tryParse(feed.text.trim())??0; final a=double.tryParse(animals.text.trim())??0;
      if(f<0||a<=0)return 'أدخل قيماً صحيحة.';
      return 'متوسط العلف: \${(f/a).toStringAsFixed(3)} كجم/فرد.';
    });
    feed.dispose(); animals.dispose(); if(mounted&&result!=null)_showResult('العلف للفرد',result);
  }

  Future<void> _showWaterPerAnimalTool() async {
    final water=TextEditingController(); final animals=TextEditingController();
    final result=await _twoFieldTool(title:'استهلاك الماء للفرد',first:water,second:animals,firstLabel:'إجمالي الماء لتر/يوم',secondLabel:'عدد الحيوانات/الطيور',actionLabel:'احسب',calculate:(){
      final w=double.tryParse(water.text.trim())??0; final a=double.tryParse(animals.text.trim())??0;
      if(w<0||a<=0)return 'أدخل قيماً صحيحة.';
      return 'متوسط الماء: \${(w/a).toStringAsFixed(2)} لتر/فرد/يوم.';
    });
    water.dispose(); animals.dispose(); if(mounted&&result!=null)_showResult('الماء للفرد',result);
  }

  Future<void> _showDailyGrowthRateTool() async {
    final start=TextEditingController(); final end=TextEditingController();
    final days=TextEditingController();
    final result=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
      title:const Text('معدل النمو اليومي'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:start,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الوزن الابتدائي كجم')),
        TextField(controller:end,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الوزن النهائي كجم')),
        TextField(controller:days,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'عدد الأيام')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:(){
        final a=double.tryParse(start.text.trim())??0,b=double.tryParse(end.text.trim())??0,d=double.tryParse(days.text.trim())??0;
        if(a<0||b<a||d<=0){Navigator.pop(context,'أدخل أوزاناً صحيحة ومدة أكبر من صفر.');return;}
        Navigator.pop(context,'معدل النمو اليومي: \${((b-a)/d).toStringAsFixed(3)} كجم/يوم.');
      },child:const Text('احسب'))],
    ));
    start.dispose();end.dispose();days.dispose();if(mounted&&result!=null)_showResult('معدل النمو',result);
  }

  Future<void> _showGreenhouseTemperatureTool() async {
    final current=TextEditingController(); final target=TextEditingController(text:'25');
    final result=await _twoFieldTool(title:'مؤشر حرارة البيت المحمي',first:current,second:target,firstLabel:'الحرارة الحالية °C',secondLabel:'الحرارة المستهدفة °C',actionLabel:'قارن',calculate:(){
      final c=double.tryParse(current.text.trim())??0,t=double.tryParse(target.text.trim())??0;
      if(c<-30||c>70||t<-30||t>70)return 'أدخل درجات حرارة منطقية.';
      final diff=c-t; final status=diff.abs()<2?'قريبة من الهدف':diff>0?'أعلى من الهدف':'أقل من الهدف';
      return 'الفرق: \${diff.toStringAsFixed(1)} °C — $status.\\nاستخدم التهوية أو التظليل أو التدفئة وفق المحصول والظروف المحلية.';
    });
    current.dispose();target.dispose();if(mounted&&result!=null)_showResult('حرارة البيت المحمي',result);
  }

  Future<void> _showGreenhouseVentilationTool() async {
    final volume=TextEditingController(); final rate=TextEditingController(text:'20');
    final result=await _twoFieldTool(title:'تهوية البيت المحمي',first:volume,second:rate,firstLabel:'حجم البيت المحمي م³',secondLabel:'معدل تبديل الهواء مرة/ساعة',actionLabel:'احسب',calculate:(){
      final v=double.tryParse(volume.text.trim())??0,r=double.tryParse(rate.text.trim())??0;
      if(v<=0||r<=0)return 'أدخل حجماً ومعدل تبديل أكبر من صفر.';
      return 'معدل تدفق الهواء الحسابي: \${(v*r).toStringAsFixed(1)} م³/ساعة.\\nهذه قيمة تخطيطية؛ التصميم الفعلي يعتمد على المناخ والمحصول ومداخل ومخارج الهواء.';
    });
    volume.dispose();rate.dispose();if(mounted&&result!=null)_showResult('تهوية البيت المحمي',result);
  }

  Future<void> _showGreenhouseEnergyTool() async {
    final power=TextEditingController(); final hours=TextEditingController();
    final result=await _twoFieldTool(title:'طاقة البيت المحمي',first:power,second:hours,firstLabel:'قدرة الأجهزة kW',secondLabel:'ساعات التشغيل يومياً',actionLabel:'احسب',calculate:(){
      final p=double.tryParse(power.text.trim())??0,h=double.tryParse(hours.text.trim())??0;
      if(p<=0||h<=0)return 'أدخل قدرة وساعات أكبر من صفر.';
      return 'الاستهلاك اليومي التقريبي: \${(p*h).toStringAsFixed(2)} kWh.';
    });
    power.dispose();hours.dispose();if(mounted&&result!=null)_showResult('طاقة البيت المحمي',result);
  }

  Future<void> _showPackagingCostTool() async {
    final count=TextEditingController(); final cost=TextEditingController();
    final result=await _twoFieldTool(title:'تكلفة التعبئة',first:count,second:cost,firstLabel:'عدد العبوات',secondLabel:'تكلفة العبوة الواحدة',actionLabel:'احسب',calculate:(){
      final c=double.tryParse(count.text.trim())??0,p=double.tryParse(cost.text.trim())??0;
      if(c<0||p<0)return 'أدخل قيماً غير سالبة.';
      return 'تكلفة التعبئة التقديرية: \${(c*p).toStringAsFixed(2)} من نفس وحدة العملة.';
    });
    count.dispose();cost.dispose();if(mounted&&result!=null)_showResult('تكلفة التعبئة',result);
  }

  Future<void> _showTransportCostTool() async {
    final distance=TextEditingController(); final rate=TextEditingController();
    final result=await _twoFieldTool(title:'تكلفة النقل',first:distance,second:rate,firstLabel:'المسافة كم',secondLabel:'تكلفة الكيلومتر',actionLabel:'احسب',calculate:(){
      final d=double.tryParse(distance.text.trim())??0,r=double.tryParse(rate.text.trim())??0;
      if(d<0||r<0)return 'أدخل قيماً غير سالبة.';
      return 'تكلفة النقل التقديرية: \${(d*r).toStringAsFixed(2)} من نفس وحدة العملة.';
    });
    distance.dispose();rate.dispose();if(mounted&&result!=null)_showResult('تكلفة النقل',result);
  }

  Future<void> _showMachineOperatingCostTool() async {
    final hours=TextEditingController(); final rate=TextEditingController();
    final result=await _twoFieldTool(title:'تكلفة تشغيل الآلة',first:hours,second:rate,firstLabel:'ساعات التشغيل',secondLabel:'تكلفة الساعة',actionLabel:'احسب',calculate:(){
      final h=double.tryParse(hours.text.trim())??0,r=double.tryParse(rate.text.trim())??0;
      if(h<0||r<0)return 'أدخل قيماً غير سالبة.';
      return 'تكلفة التشغيل التقديرية: \${(h*r).toStringAsFixed(2)} من نفس وحدة العملة.';
    });
    hours.dispose();rate.dispose();if(mounted&&result!=null)_showResult('تشغيل الآلة',result);
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
      case 'veterinary':        return 'البيطرة: راقب الأعراض والسلوك والحرارة والتغذية، واعزل الحالة المشتبه بها واستعن بطبيب بيطري للتشخيص والعلاج.';
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


  Widget _investmentHub() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.trending_up_rounded),
            SizedBox(width: 8),
            Text('بوابة الاستثمار الزراعي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 6),
          const Text('اكتشف وحلل فرص الاستثمار في الزراعة والثروة الحيوانية والتصنيع والطاقة وإعادة التدوير.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _investmentButton(Icons.search_rounded, 'استكشاف الفرص', () => _showInvestmentExplorer()),
            _investmentButton(Icons.calculate_outlined, 'حاسبة الاستثمار', () => _showInvestmentCalculator()),
            _investmentButton(Icons.auto_awesome_rounded, 'تحليل فرصة بالذكاء الاصطناعي', () => _showInvestmentAi()),
          ]),
        ]),
      ),
    );
  }

  Widget _investmentButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));
  }

  Future<void> _showInvestmentExplorer() async {
    final items = const [
      ('مشاريع المحاصيل', 'أرض • ماء • إنتاج • سوق', Icons.agriculture_outlined),
      ('الثروة الحيوانية', 'أعلاف • قطيع • إنتاج • صحة', Icons.pets_outlined),
      ('التصنيع الزراعي', 'مواد خام • مصنع • سوق • توزيع', Icons.precision_manufacturing_outlined),
      ('الطاقة الزراعية', 'طاقة شمسية • ري • تخزين', Icons.solar_power_outlined),
      ('الاستزراع السمكي', 'مياه • أعلاف • كثافة • سوق', Icons.set_meal_outlined),
      ('إعادة التدوير', 'مخلفات • معالجة • منتج • سوق', Icons.recycling_outlined),
    ];
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('فرص الاستثمار'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: items.map((item) => ListTile(
              leading: CircleAvatar(child: Icon(item.$3)),
              title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(item.$2),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showInvestmentCategory(item.$1);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showInvestmentCategory(String category) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'اكتب الدولة/الموقع، حجم المشروع، رأس المال المتاح، المنتج، الطاقة الإنتاجية والسوق المستهدف...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('حفظ كمسودة'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    await _showResult('مسودة فرصة استثمار', 'القطاع: $category\n\n$result\n\nهذه مسودة تخطيطية وليست عرضاً استثمارياً أو توصية مالية.');
  }

  Future<void> _showInvestmentCalculator() async {
    final capital = TextEditingController();
    final revenue = TextEditingController();
    final operating = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حاسبة الاستثمار'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: capital, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'رأس المال / الاستثمار الأولي')),
            TextField(controller: revenue, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الإيراد السنوي المتوقع')),
            TextField(controller: operating, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'التكلفة التشغيلية السنوية')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final c = double.tryParse(capital.text.trim()) ?? 0;
              final r = double.tryParse(revenue.text.trim()) ?? 0;
              final o = double.tryParse(operating.text.trim()) ?? 0;
              if (c <= 0 || r < 0 || o < 0 || r < o) return;
              final profit = r - o;
              final roi = profit / c * 100;
              final payback = profit > 0 ? c / profit : double.infinity;
              Navigator.pop(context, 'الربح التشغيلي السنوي: ${profit.toStringAsFixed(2)}\nالعائد البسيط على الاستثمار: ${roi.toStringAsFixed(2)}%\nمدة الاسترداد التقريبية: ${payback.isFinite ? payback.toStringAsFixed(2) : 'غير متاحة'} سنة\n\nاستخدم نفس وحدة العملة في جميع المدخلات. هذه حاسبة تقديرية وليست توصية استثمارية.');
            },
            child: const Text('احسب'),
          ),
        ],
      ),
    );
    capital.dispose();
    revenue.dispose();
    operating.dispose();
    if (!mounted || result == null) return;
    await _showResult('نتيجة الاستثمار', result);
  }

  Future<void> _showInvestmentAi() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحليل فرصة استثمارية بالـAI'),
        content: TextField(
          controller: controller,
          minLines: 5,
          maxLines: 9,
          decoration: const InputDecoration(
            hintText: 'صف المشروع: الموقع، الأرض/المبنى، رأس المال، الإنتاج، السوق، الإيرادات والتكاليف والمخاطر...',
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
                  type: 'business',
                  location: _location.text,
                  observations: 'Investment analysis request:\n${controller.text.trim()}',
                );
                if (context.mounted) Navigator.pop(context, advice);
              } catch (_) {
                if (context.mounted) Navigator.pop(context, 'تعذر الوصول إلى محلل الاستثمار حالياً. حاول مرة أخرى.');
              }
            },
            child: const Text('حلل الفرصة'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    await _showResult('تحليل AUREN AI للاستثمار', result);
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