import 'package:auren/services/agriculture/agriculture_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Farm operations planner', () {
    test('trims task fields and supports open-task status transitions', () {
      final task = FarmOperationTask.create(
        id: ' task-1 ',
        title: ' Planting ',
        dueAt: DateTime.utc(2026, 10, 24),
        note: ' field A ',
      );
      expect(task.id, 'task-1');
      expect(task.title, 'Planting');
      expect(task.note, 'field A');
      expect(task.withStatus('in_progress').status, 'in_progress');
      expect(() => task.withStatus('completed'), throwsStateError);
      expect(() => task.withStatus('unknown'), throwsArgumentError);
      final inProgress = task.withStatus('in_progress');
      expect(inProgress.withStatus('completed').status, 'completed');
      expect(() => inProgress.withStatus('planned'), throwsStateError);
      expect(() => inProgress.withStatus('in_progress'), throwsStateError);
      expect(() => task.withStatus('cancelled').withStatus('planned'), throwsStateError);
    });

    test('rejects empty task titles and prevents reopening closed tasks', () {
      expect(
        () => FarmOperationTask.create(
          id: 'task-1',
          title: ' ',
          dueAt: DateTime.utc(2026, 10, 24),
        ),
        throwsArgumentError,
      );
      final task = FarmOperationTask.create(
        id: 'task-1',
        title: 'Harvest',
        dueAt: DateTime.utc(2026, 10, 24),
      ).withStatus('in_progress').withStatus('completed');
      expect(() => task.withStatus('planned'), throwsStateError);
    });
  });

  group('Irrigation volume calculator', () {
    test('calculates volume transparently from user-entered depth', () {
      final estimate = IrrigationVolumeEstimate.fromInputs(
        areaSquareMeters: 250,
        depthMillimeters: 12,
      );
      expect(estimate.volumeLiters, 3000);
    });

    test('accepts zero depth but rejects invalid or unbounded inputs', () {
      expect(
        IrrigationVolumeEstimate.fromInputs(
          areaSquareMeters: 20,
          depthMillimeters: 0,
        ).volumeLiters,
        0,
      );
      expect(
        () => IrrigationVolumeEstimate.fromInputs(
          areaSquareMeters: double.nan,
          depthMillimeters: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => IrrigationVolumeEstimate.fromInputs(
          areaSquareMeters: 20,
          depthMillimeters: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Harvest and storage ledger', () {
    test('accounts storage and loss without mutating the original lot', () {
      final initial = HarvestStorageLot.create(
        id: 'lot-1',
        crop: 'Sorghum',
        unit: 'kg',
        harvestedQuantity: 100,
      );
      final stored = initial.recordStorage(70);
      final accounted = stored.recordLoss(5);
      expect(initial.storedQuantity, 0);
      expect(stored.storedQuantity, 70);
      expect(accounted.lossQuantity, 5);
      expect(accounted.unaccountedQuantity, 25);
    });

    test('rejects negative quantities and over-accounting', () {
      expect(
        () => HarvestStorageLot.create(
          id: 'lot-2',
          crop: 'Maize',
          unit: 'kg',
          harvestedQuantity: 10,
          storedQuantity: 8,
          lossQuantity: 3,
        ),
        throwsArgumentError,
      );
      final lot = HarvestStorageLot.create(
        id: 'lot-3',
        crop: 'Maize',
        unit: 'kg',
        harvestedQuantity: 10,
      );
      expect(() => lot.recordStorage(11), throwsStateError);
      expect(() => lot.recordLoss(-1), throwsArgumentError);
    });
  });

  group('Produce traceability', () {
    test('appends chronological events immutably', () {
      final harvestedAt = DateTime.utc(2026, 10, 20);
      final packedAt = DateTime.utc(2026, 10, 21);
      final batch = ProduceTraceabilityBatch(
        batchId: 'batch-001',
        product: 'Sesame',
      );
      final withHarvest = batch.append(ProduceTraceEvent.create(
        stage: 'harvested',
        occurredAt: harvestedAt,
        note: 'Recorded by farm operator',
      ));
      final withPacking = withHarvest.append(ProduceTraceEvent.create(
        stage: 'packed',
        occurredAt: packedAt,
        note: 'Packed in sacks',
        location: 'Store A',
      ));
      expect(batch.events, isEmpty);
      expect(withHarvest.events, hasLength(1));
      expect(withPacking.events, hasLength(2));
      expect(withPacking.events.last.location, 'Store A');
    });

    test('rejects out-of-order events and invalid event fields', () {
      final batch = ProduceTraceabilityBatch(
        batchId: 'batch-002',
        product: 'Groundnuts',
        events: [
          ProduceTraceEvent.create(
            stage: 'stored',
            occurredAt: DateTime.utc(2026, 10, 22),
            note: 'Storage record',
          ),
        ],
      );
      expect(
        () => batch.append(ProduceTraceEvent.create(
          stage: 'harvested',
          occurredAt: DateTime.utc(2026, 10, 21),
          note: 'Earlier than existing event',
        )),
        throwsStateError,
      );
      expect(
        () => ProduceTraceEvent.create(
          stage: ' ',
          occurredAt: DateTime.utc(2026, 10, 22),
          note: 'Bad stage',
        ),
        throwsArgumentError,
      );
    });
  });
}
