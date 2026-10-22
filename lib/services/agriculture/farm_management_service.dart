/// Offline-first domain helpers for AUREN Agriculture & Livestock AI.
///
/// No network or Firestore dependency: draft planning and validation remain
/// available offline; callers may persist through the existing repository.
enum FarmTaskStatus { planned, inProgress, done, skipped }

class CropAdviceRequest {
  const CropAdviceRequest({required this.crop, required this.growthStage, required this.observations, this.location = ''});
  final String crop, growthStage, observations, location;
}
class CropAdviceSummary {
  const CropAdviceSummary({required this.title, required this.steps, required this.cautions, this.isSpecialistRequired = false});
  final String title;
  final List<String> steps, cautions;
  final bool isSpecialistRequired;
}
class LivestockCareLog {
  const LivestockCareLog({required this.animalGroup, required this.observedAt, required this.observation, this.nextCheckAt, this.needsVeterinaryReview = false});
  final String animalGroup, observation;
  final DateTime observedAt;
  final DateTime? nextCheckAt;
  final bool needsVeterinaryReview;
  bool isFollowUpDue(DateTime now) => nextCheckAt != null && !nextCheckAt!.isAfter(now);
}
class FarmOperationTask {
  const FarmOperationTask({required this.title, required this.dueAt, required this.status, this.cropOrAnimal = '', this.notes = ''});
  final String title, cropOrAnimal, notes;
  final DateTime dueAt;
  final FarmTaskStatus status;
  bool isOverdue(DateTime now) => status != FarmTaskStatus.done && status != FarmTaskStatus.skipped && dueAt.isBefore(now);
}
class AgriculturalMarketObservation {
  const AgriculturalMarketObservation({required this.commodity, required this.market, required this.price, required this.currency, required this.unit, required this.observedAt, required this.sourceName, required this.sourceReference});
  final String commodity, market, currency, unit, sourceName, sourceReference;
  final double price;
  final DateTime observedAt;
  bool get hasTraceableSource => sourceName.trim().isNotEmpty && sourceReference.trim().isNotEmpty;

  /// Missing source metadata is never treated as verified market intelligence.
  bool isStale(DateTime now, {Duration maxAge = const Duration(days: 7)}) {
    final age = now.toUtc().difference(observedAt.toUtc());
    // Future-dated observations are untrusted until their timestamp is checked.
    return age.isNegative || age > maxAge;
  }
}
class FarmResourceNeed {
  const FarmResourceNeed({required this.name, required this.quantity, required this.unit, this.availableQuantity = 0});
  final String name, unit;
  final double quantity, availableQuantity;
  double get shortage => (quantity - availableQuantity).clamp(0, double.infinity).toDouble();
}
class FarmResourcePlan {
  const FarmResourcePlan(this.needs);
  final List<FarmResourceNeed> needs;
  List<FarmResourceNeed> get shortages => needs.where((need) => need.shortage > 0).toList(growable: false);
}

/// Conservative, general guidance only; not a crop diagnosis or prescription.
class AgricultureFarmManagementService {
  const AgricultureFarmManagementService();

  CropAdviceSummary buildCropChecklist(CropAdviceRequest request) {
    final crop = request.crop.trim(), stage = request.growthStage.trim(), observations = request.observations.trim();
    if (crop.isEmpty || stage.isEmpty || observations.isEmpty) throw ArgumentError('المحصول ومرحلة النمو والملاحظات مطلوبة.');
    return CropAdviceSummary(
      title: 'قائمة متابعة عامة: $crop — $stage',
      steps: const [
        'افحص رطوبة التربة قبل الري وسجّل كمية المياه وتوقيتها.',
        'راقب النباتات في أكثر من جزء من الحقل وسجّل أي تغير جديد.',
        'راجع بطاقة البذور أو السماد وتعليمات المنتج قبل أي استخدام.',
        'قارن الملاحظات بتاريخ سابق لتحديد ما إذا كانت الحالة تتغير.',
      ],
      cautions: const [
        'هذه قائمة عامة وليست تشخيصاً للآفات أو الأمراض أو توصية بجرعة كيميائية.',
        'لا تعتمد على أسعار أو طقس غير موثق؛ تحقق من مصدر محلي حديث.',
        'اطلب مراجعة مهندس زراعي عند انتشار الأعراض أو تدهور المحصول.',
      ],
    );
  }

  LivestockCareLog createLivestockLog({required String animalGroup, required DateTime observedAt, required String observation, DateTime? nextCheckAt, bool needsVeterinaryReview = false}) {
    if (animalGroup.trim().isEmpty || observation.trim().isEmpty) throw ArgumentError('مجموعة الحيوانات والملاحظة مطلوبتان.');
    if (nextCheckAt != null && nextCheckAt.isBefore(observedAt)) throw ArgumentError('موعد المتابعة لا يمكن أن يسبق وقت الملاحظة.');
    return LivestockCareLog(animalGroup: animalGroup.trim(), observedAt: observedAt, observation: observation.trim(), nextCheckAt: nextCheckAt, needsVeterinaryReview: needsVeterinaryReview);
  }

  FarmOperationTask createTask({required String title, required DateTime dueAt, String cropOrAnimal = '', String notes = ''}) {
    final cleanTitle = title.trim();
    final cleanCropOrAnimal = cropOrAnimal.trim();
    final cleanNotes = notes.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 160 ||
        cleanCropOrAnimal.length > 160 || cleanNotes.length > 4000) {
      throw ArgumentError('عنوان المهمة أو النشاط المرتبط أو الملاحظات غير صالحة.');
    }
    return FarmOperationTask(title: cleanTitle, dueAt: dueAt, status: FarmTaskStatus.planned, cropOrAnimal: cleanCropOrAnimal, notes: cleanNotes);
  }

  AgriculturalMarketObservation validateMarketObservation(AgriculturalMarketObservation observation) {
    if (observation.commodity.trim().isEmpty || observation.market.trim().isEmpty || observation.currency.trim().isEmpty || observation.unit.trim().isEmpty) {
      throw ArgumentError('المحصول والسوق والعملة والوحدة مطلوبة.');
    }
    if (!observation.price.isFinite || observation.price < 0) throw ArgumentError('السعر يجب أن يكون رقماً صالحاً غير سالب.');
    if (!observation.hasTraceableSource) throw ArgumentError('اسم المصدر ومرجعه مطلوبان لتوثيق السعر.');
    return observation;
  }

  FarmResourcePlan planResources(List<FarmResourceNeed> needs) {
    for (final need in needs) {
      if (need.name.trim().isEmpty || need.unit.trim().isEmpty) throw ArgumentError('اسم المورد ووحدته مطلوبان.');
      if (!need.quantity.isFinite || !need.availableQuantity.isFinite || need.quantity < 0 || need.availableQuantity < 0) {
        throw ArgumentError('كميات الموارد يجب أن تكون أرقاماً صالحة غير سالبة.');
      }
    }
    return FarmResourcePlan(List<FarmResourceNeed>.unmodifiable(needs));
  }
}
