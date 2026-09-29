import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class CropPlan {
  final String id;
  final String crop;
  final String fieldName;
  final double areaHa;
  final DateTime plantingDate;
  final int cycleDays;
  final DateTime expectedHarvestDate;
  final double waterMmPerWeek;
  final double fertilizerKgPerHa;
  final List<String> tasks;
  final Map<String, dynamic> data;

  const CropPlan({
    required this.id,
    required this.crop,
    required this.fieldName,
    required this.areaHa,
    required this.plantingDate,
    required this.cycleDays,
    required this.expectedHarvestDate,
    required this.waterMmPerWeek,
    required this.fertilizerKgPerHa,
    required this.tasks,
    required this.data,
  });

  double get expectedHarvestKg => (data['expectedYieldKgPerHa'] as num?)?.toDouble() == null
      ? 0
      : ((data['expectedYieldKgPerHa'] as num).toDouble() * areaHa);

  Map<String, dynamic> toJson() => {
        'crop': crop,
        'fieldName': fieldName,
        'areaHa': areaHa,
        'plantingDate': plantingDate.toIso8601String(),
        'cycleDays': cycleDays,
        'expectedHarvestDate': expectedHarvestDate.toIso8601String(),
        'waterMmPerWeek': waterMmPerWeek,
        'fertilizerKgPerHa': fertilizerKgPerHa,
        'tasks': tasks,
        ...data,
      };

  factory CropPlan.fromNote(String id, Map<String, dynamic> doc) {
    final raw = (doc['note'] ?? '{}').toString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CropPlan(
      id: id,
      crop: (json['crop'] ?? '').toString(),
      fieldName: (json['fieldName'] ?? '').toString(),
      areaHa: (json['areaHa'] as num?)?.toDouble() ?? 0,
      plantingDate: DateTime.tryParse((json['plantingDate'] ?? '').toString()) ?? DateTime.now(),
      cycleDays: (json['cycleDays'] as num?)?.toInt() ?? 0,
      expectedHarvestDate: DateTime.tryParse((json['expectedHarvestDate'] ?? '').toString()) ?? DateTime.now(),
      waterMmPerWeek: (json['waterMmPerWeek'] as num?)?.toDouble() ?? 0,
      fertilizerKgPerHa: (json['fertilizerKgPerHa'] as num?)?.toDouble() ?? 0,
      tasks: (json['tasks'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      data: json,
    );
  }
}

class CropIntelligenceService {
  final FirebaseFirestore db;
  CropIntelligenceService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  CropPlan calculatePlan({
    required String crop,
    required String fieldName,
    required double areaHa,
    required DateTime plantingDate,
    required int cycleDays,
    required double waterMmPerWeek,
    required double fertilizerKgPerHa,
    double expectedYieldKgPerHa = 0,
  }) {
    final safeArea = areaHa.clamp(0.01, 100000.0);
    final safeCycle = cycleDays.clamp(1, 730);
    final harvest = plantingDate.add(Duration(days: safeCycle));
    final tasks = <String>[
      'فحص التربة قبل الزراعة',
      'متابعة الإنبات بعد الزراعة',
      'فحص الآفات والأمراض أسبوعياً',
      'مراجعة الري والطقس أسبوعياً',
      'تقييم النمو قبل التسميد التالي',
      'تأكيد جاهزية الحصاد قبل الموعد المتوقع',
    ];
    return CropPlan(
      id: '',
      crop: crop.trim(),
      fieldName: fieldName.trim(),
      areaHa: safeArea.toDouble(),
      plantingDate: plantingDate,
      cycleDays: safeCycle,
      expectedHarvestDate: harvest,
      waterMmPerWeek: waterMmPerWeek.clamp(0, 500).toDouble(),
      fertilizerKgPerHa: fertilizerKgPerHa.clamp(0, 5000).toDouble(),
      tasks: tasks,
      data: {
        'expectedYieldKgPerHa': expectedYieldKgPerHa.clamp(0, 100000).toDouble(),
        'totalWaterMmPerWeek': (waterMmPerWeek * safeArea).toDouble(),
        'totalFertilizerKg': (fertilizerKgPerHa * safeArea).toDouble(),
      },
    );
  }

  Future<String> savePlan({
    required String uid,
    required CropPlan plan,
  }) async {
    final ref = db.collection('users').doc(uid).collection('agricultureNotes').doc();
    await ref.set({
      'title': 'Crop Plan • \${plan.crop} • \${plan.fieldName}',
      'note': jsonEncode(plan.toJson()),
      'type': 'field',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<CropPlan>> watchPlans(String uid) {
    return db.collection('users').doc(uid).collection('agricultureNotes')
        .where('type', isEqualTo: 'field')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final plans = <CropPlan>[];
      for (final doc in snapshot.docs) {
        try {
          if ((doc.data()['title'] ?? '').toString().startsWith('Crop Plan •')) {
            plans.add(CropPlan.fromNote(doc.id, doc.data()));
          }
        } catch (_) {}
      }
      return plans;
    });
  }

  Future<void> deletePlan(String uid, String planId) {
    return db.collection('users').doc(uid).collection('agricultureNotes').doc(planId).delete();
  }
}