/// Local-first planning primitives for farm operations.
///
/// These calculations organize user-entered data; they are not agronomic,
/// veterinary, or irrigation recommendations.
class FarmOperationTask {
  final String id;
  final String title;
  final DateTime dueAt;
  final String status;
  final String note;

  FarmOperationTask({
    required String id,
    required String title,
    required this.dueAt,
    String status = 'planned',
    String note = '',
  }) : id = id.trim(),
       title = title.trim(),
       status = status.trim(),
       note = note.trim() {
    if (this.id.isEmpty || this.id.length > 128) {
      throw ArgumentError('A valid task id is required.');
    }
    if (this.title.isEmpty || this.title.length > 160 || this.note.length > 1000) {
      throw ArgumentError('Task title or note is invalid.');
    }
    if (!const {'planned', 'in_progress', 'completed', 'cancelled'}.contains(this.status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported status.');
    }
  }

  FarmOperationTask withStatus(String nextStatus) {
    const transitions = {
      'planned': {'in_progress', 'cancelled'},
      'in_progress': {'completed', 'cancelled'},
      'completed': <String>{},
      'cancelled': <String>{},
    };
    final allowedNext = transitions[status];
    if (allowedNext == null) {
      throw StateError('The current task has an unsupported status.');
    }
    if (!allowedNext.contains(nextStatus)) {
      if (nextStatus != 'planned' &&
          nextStatus != 'in_progress' &&
          nextStatus != 'completed' &&
          nextStatus != 'cancelled') {
        throw ArgumentError.value(nextStatus, 'nextStatus', 'Unsupported status.');
      }
      throw StateError('Task status transition is not allowed.');
    }
    return FarmOperationTask(
      id: id,
      title: title,
      dueAt: dueAt,
      status: nextStatus,
      note: note,
    );
  }

  static FarmOperationTask create({
    required String id,
    required String title,
    required DateTime dueAt,
    String note = '',
  }) {
    final cleanId = id.trim();
    final cleanTitle = title.trim();
    final cleanNote = note.trim();
    if (cleanId.isEmpty || cleanId.length > 128) {
      throw ArgumentError('A valid task id is required.');
    }
    if (cleanTitle.isEmpty || cleanTitle.length > 160 || cleanNote.length > 1000) {
      throw ArgumentError('Task title or note is invalid.');
    }
    return FarmOperationTask(
      id: cleanId,
      title: cleanTitle,
      dueAt: dueAt,
      note: cleanNote,
    );
  }
}

/// Converts a user-entered irrigation depth into a volume, not a crop-water
/// recommendation. 1 mm over 1 square metre equals 1 litre.
class IrrigationVolumeEstimate {
  final double areaSquareMeters;
  final double depthMillimeters;
  final double volumeLiters;

  IrrigationVolumeEstimate({
    required this.areaSquareMeters,
    required this.depthMillimeters,
    required this.volumeLiters,
  }) {
    if (!areaSquareMeters.isFinite ||
        areaSquareMeters <= 0 ||
        areaSquareMeters > 100000000) {
      throw ArgumentError('Area must be positive and within the supported range.');
    }
    if (!depthMillimeters.isFinite ||
        depthMillimeters < 0 ||
        depthMillimeters > 1000) {
      throw ArgumentError('Depth must be between 0 and 1000 mm.');
    }
    final expectedVolume = areaSquareMeters * depthMillimeters;
    if (!volumeLiters.isFinite || volumeLiters != expectedVolume) {
      throw ArgumentError('Volume must equal area multiplied by depth.');
    }
  }

  factory IrrigationVolumeEstimate.fromInputs({
    required double areaSquareMeters,
    required double depthMillimeters,
  }) {
    if (!areaSquareMeters.isFinite ||
        areaSquareMeters <= 0 ||
        areaSquareMeters > 100000000) {
      throw ArgumentError('Area must be positive and within the supported range.');
    }
    if (!depthMillimeters.isFinite ||
        depthMillimeters < 0 ||
        depthMillimeters > 1000) {
      throw ArgumentError('Depth must be between 0 and 1000 mm.');
    }
    return IrrigationVolumeEstimate(
      areaSquareMeters: areaSquareMeters,
      depthMillimeters: depthMillimeters,
      volumeLiters: areaSquareMeters * depthMillimeters,
    );
  }
}

/// A measured harvest/storage lot. All amounts use the same unit selected by
/// the user (for example kg); no currency or commodity conversion is implied.
class HarvestStorageLot {
  final String id;
  final String crop;
  final String unit;
  final double harvestedQuantity;
  final double storedQuantity;
  final double lossQuantity;

  HarvestStorageLot({
    required String id,
    required String crop,
    required String unit,
    required this.harvestedQuantity,
    required this.storedQuantity,
    required this.lossQuantity,
  }) : id = id.trim(),
       crop = crop.trim(),
       unit = unit.trim() {
    if (this.id.isEmpty || this.id.length > 128 ||
        this.crop.isEmpty || this.crop.length > 120 ||
        this.unit.isEmpty || this.unit.length > 24) {
      throw ArgumentError('Lot identity, crop and unit are required.');
    }
    for (final value in [harvestedQuantity, storedQuantity, lossQuantity]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError('Lot quantities must be finite and non-negative.');
      }
    }
    if (storedQuantity + lossQuantity > harvestedQuantity) {
      throw ArgumentError('Stored quantity plus losses cannot exceed harvest.');
    }
  }

  double get unaccountedQuantity =>
      harvestedQuantity - storedQuantity - lossQuantity;

  factory HarvestStorageLot.create({
    required String id,
    required String crop,
    required String unit,
    required double harvestedQuantity,
    double storedQuantity = 0,
    double lossQuantity = 0,
  }) {
    final cleanId = id.trim();
    final cleanCrop = crop.trim();
    final cleanUnit = unit.trim();
    if (cleanId.isEmpty || cleanId.length > 128 ||
        cleanCrop.isEmpty || cleanCrop.length > 120 ||
        cleanUnit.isEmpty || cleanUnit.length > 24) {
      throw ArgumentError('Lot identity, crop and unit are required.');
    }
    for (final value in [harvestedQuantity, storedQuantity, lossQuantity]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError('Lot quantities must be finite and non-negative.');
      }
    }
    if (storedQuantity + lossQuantity > harvestedQuantity) {
      throw ArgumentError('Stored quantity plus losses cannot exceed harvest.');
    }
    return HarvestStorageLot(
      id: cleanId,
      crop: cleanCrop,
      unit: cleanUnit,
      harvestedQuantity: harvestedQuantity,
      storedQuantity: storedQuantity,
      lossQuantity: lossQuantity,
    );
  }

  HarvestStorageLot recordStorage(double quantity) {
    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError('Storage quantity must be positive.');
    }
    if (storedQuantity + lossQuantity + quantity > harvestedQuantity) {
      throw StateError('Storage quantity exceeds the unaccounted harvest.');
    }
    return HarvestStorageLot(
      id: id,
      crop: crop,
      unit: unit,
      harvestedQuantity: harvestedQuantity,
      storedQuantity: storedQuantity + quantity,
      lossQuantity: lossQuantity,
    );
  }

  HarvestStorageLot recordLoss(double quantity) {
    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError('Loss quantity must be positive.');
    }
    if (storedQuantity + lossQuantity + quantity > harvestedQuantity) {
      throw StateError('Loss quantity exceeds the unaccounted harvest.');
    }
    return HarvestStorageLot(
      id: id,
      crop: crop,
      unit: unit,
      harvestedQuantity: harvestedQuantity,
      storedQuantity: storedQuantity,
      lossQuantity: lossQuantity + quantity,
    );
  }
}

class ProduceTraceEvent {
  final String stage;
  final DateTime occurredAt;
  final String note;
  final String? location;

  ProduceTraceEvent({
    required String stage,
    required this.occurredAt,
    required String note,
    String? location,
  }) : stage = stage.trim(),
       note = note.trim(),
       location = location?.trim().isEmpty ?? true ? null : location?.trim() {
    if (this.stage.isEmpty || this.stage.length > 60 ||
        this.note.length > 1000 ||
        (this.location?.length ?? 0) > 160) {
      throw ArgumentError('Trace event fields are invalid.');
    }
  }

  factory ProduceTraceEvent.create({
    required String stage,
    required DateTime occurredAt,
    required String note,
    String? location,
  }) {
    final cleanStage = stage.trim();
    final cleanNote = note.trim();
    final cleanLocation = location?.trim();
    if (cleanStage.isEmpty || cleanStage.length > 60 ||
        cleanNote.length > 1000 ||
        (cleanLocation?.length ?? 0) > 160) {
      throw ArgumentError('Trace event fields are invalid.');
    }
    return ProduceTraceEvent(
      stage: cleanStage,
      occurredAt: occurredAt,
      note: cleanNote,
      location: cleanLocation == null || cleanLocation.isEmpty
          ? null
          : cleanLocation,
    );
  }
}

/// Append-only in-memory traceability record; persistence and sharing are left
/// to an explicitly authorized repository layer.
class ProduceTraceabilityBatch {
  final String batchId;
  final String product;
  final List<ProduceTraceEvent> events;

  ProduceTraceabilityBatch({
    required String batchId,
    required String product,
    List<ProduceTraceEvent> events = const [],
  }) : batchId = batchId.trim(),
       product = product.trim(),
       events = List.unmodifiable(events) {
    if (this.batchId.isEmpty || this.batchId.length > 128 ||
        this.product.isEmpty || this.product.length > 120) {
      throw ArgumentError('Batch id and product are required.');
    }
    for (var i = 1; i < this.events.length; i++) {
      if (this.events[i].occurredAt.isBefore(this.events[i - 1].occurredAt)) {
        throw ArgumentError('Trace events must be chronological.');
      }
    }
  }

  ProduceTraceabilityBatch append(ProduceTraceEvent event) {
    if (events.isNotEmpty && event.occurredAt.isBefore(events.last.occurredAt)) {
      throw StateError('A trace event cannot predate the latest event.');
    }
    return ProduceTraceabilityBatch(
      batchId: batchId,
      product: product,
      events: [...events, event],
    );
  }
}
