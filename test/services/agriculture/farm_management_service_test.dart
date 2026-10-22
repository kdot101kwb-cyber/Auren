import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/agriculture/farm_management_service.dart';

void main() {
  const service = AgricultureFarmManagementService();
  group('AUREN Agriculture & Livestock AI domain services', () {
    test('crop checklist requires context and stays general/safe', () {
      expect(() => service.buildCropChecklist(const CropAdviceRequest(crop: '', growthStage: 'seedling', observations: 'yellow leaves')), throwsArgumentError);
      final result = service.buildCropChecklist(const CropAdviceRequest(crop: 'sorghum', growthStage: 'seedling', observations: 'yellow leaves on a few plants'));
      expect(result.title, contains('sorghum'));
      expect(result.cautions.any((item) => item.contains('تشخيص')), isTrue);
    });
    test('livestock log validates and reports follow-up due time', () {
      final log = service.createLivestockLog(animalGroup: 'goats', observedAt: DateTime.utc(2026, 10, 20), observation: 'reduced appetite; record only', nextCheckAt: DateTime.utc(2026, 10, 21), needsVeterinaryReview: true);
      expect(log.isFollowUpDue(DateTime.utc(2026, 10, 22)), isTrue);
      expect(log.needsVeterinaryReview, isTrue);
      expect(() => service.createLivestockLog(animalGroup: 'goats', observedAt: DateTime.utc(2026, 10, 21), observation: 'check', nextCheckAt: DateTime.utc(2026, 10, 20)), throwsArgumentError);
      expect(() => service.createLivestockLog(animalGroup: ' ', observedAt: DateTime.utc(2026, 10, 21), observation: 'check'), throwsArgumentError);
      expect(() => service.createLivestockLog(animalGroup: 'goats', observedAt: DateTime.utc(2026, 10, 21), observation: ' '), throwsArgumentError);
    });
    test('farm operations flag overdue tasks but not completed tasks', () {
      final task = service.createTask(title: 'inspect irrigation', dueAt: DateTime.utc(2026, 10, 20), cropOrAnimal: 'sorghum');
      expect(task.isOverdue(DateTime.utc(2026, 10, 20)), isFalse, reason: 'a task is not overdue at its exact due instant');
      expect(task.isOverdue(DateTime.utc(2026, 10, 21)), isTrue);
      final skipped = FarmOperationTask(title: 'skipped', dueAt: DateTime.utc(2026, 10, 20), status: FarmTaskStatus.skipped);
      expect(skipped.isOverdue(DateTime.utc(2026, 10, 21)), isFalse);
      final done = FarmOperationTask(title: 'completed', dueAt: DateTime.utc(2026, 10, 20), status: FarmTaskStatus.done);
      expect(done.isOverdue(DateTime.utc(2026, 10, 21)), isFalse);
    });
    test('market observations require traceable source and date metadata', () {
      final observation = AgriculturalMarketObservation(commodity: 'sorghum', market: 'sample market', price: 120, currency: 'SDG', unit: 'sack', observedAt: DateTime.utc(2026, 10, 20), sourceName: 'Cooperative bulletin', sourceReference: 'bulletin-2026-10-20');
      expect(service.validateMarketObservation(observation).observedAt, DateTime.utc(2026, 10, 20));
      expect(observation.isStale(DateTime.utc(2026, 10, 21)), isFalse);
      expect(observation.isStale(DateTime.utc(2026, 10, 27)), isFalse, reason: 'the seven-day boundary is inclusive');
      expect(observation.isStale(DateTime.utc(2026, 10, 27, 0, 0, 1)), isTrue);
      expect(observation.isStale(DateTime.utc(2026, 11, 1)), isTrue);
      expect(observation.isStale(DateTime.utc(2026, 10, 19)), isTrue, reason: 'future-dated market observations must not be treated as current');
      expect(() => service.validateMarketObservation(AgriculturalMarketObservation(commodity: 'sorghum', market: 'sample market', price: 120, currency: 'SDG', unit: 'sack', observedAt: DateTime.utc(2026, 10, 20), sourceName: '', sourceReference: '')), throwsArgumentError);
      expect(() => service.validateMarketObservation(AgriculturalMarketObservation(commodity: 'sorghum', market: 'sample market', price: -1, currency: 'SDG', unit: 'sack', observedAt: DateTime.utc(2026, 10, 20), sourceName: 'source', sourceReference: 'ref')), throwsArgumentError);
      expect(() => service.validateMarketObservation(AgriculturalMarketObservation(commodity: 'sorghum', market: 'sample market', price: double.nan, currency: 'SDG', unit: 'sack', observedAt: DateTime.utc(2026, 10, 20), sourceName: 'source', sourceReference: 'ref')), throwsArgumentError);
      expect(() => service.validateMarketObservation(AgriculturalMarketObservation(commodity: 'sorghum', market: 'sample market', price: double.infinity, currency: 'SDG', unit: 'sack', observedAt: DateTime.utc(2026, 10, 20), sourceName: 'source', sourceReference: 'ref')), throwsArgumentError);
    });
    test('resource planner calculates shortages without inventing prices', () {
      final plan = service.planResources(const [FarmResourceNeed(name: 'seed', quantity: 20, availableQuantity: 12, unit: 'kg'), FarmResourceNeed(name: 'water', quantity: 100, availableQuantity: 100, unit: 'L')]);
      expect(plan.shortages, hasLength(1));
      expect(plan.shortages.single.shortage, 8);
      expect(() => service.planResources(const [FarmResourceNeed(name: 'seed', quantity: -2, unit: 'kg')]), throwsArgumentError);
      expect(() => service.planResources([FarmResourceNeed(name: 'seed', quantity: double.infinity, unit: 'kg')]), throwsArgumentError);
      expect(() => service.planResources(const [FarmResourceNeed(name: ' ', quantity: 1, unit: 'kg')]), throwsArgumentError);
    });
  });
}
