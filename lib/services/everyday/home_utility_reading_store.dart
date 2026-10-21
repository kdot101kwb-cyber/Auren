import 'package:shared_preferences/shared_preferences.dart';
import 'home_utility_ledger_service.dart';
import 'uid_scoped_json_list_store.dart';

class AurenHomeUtilityReadingStore {
  AurenHomeUtilityReadingStore({SharedPreferences? preferences})
      : _store = AurenUidScopedJsonListStore<AurenUtilityReading>(
          keyPrefix: 'auren_home_utility_readings_v1_', preferences: preferences);
  final AurenUidScopedJsonListStore<AurenUtilityReading> _store;

  Future<List<AurenUtilityReading>> loadReadings(String uid) async {
    final values = await _store.load(uid, decode: _fromJson, validate: (v) => v.validate());
    final issue = AurenHomeUtilityLedger.validateSeries(values);
    if (issue != null) throw FormatException('Stored meter history is invalid: $issue');
    return AurenHomeUtilityLedger.ordered(values);
  }

  Future<void> saveReading(String uid, AurenUtilityReading reading) async {
    final issue = reading.validate();
    if (issue != null) throw ArgumentError(issue);
    final values = (await loadReadings(uid)).toList();
    final index = values.indexWhere((v) => v.id == reading.id);
    if (index < 0) { values.add(reading); } else { values[index] = reading; }
    final seriesIssue = AurenHomeUtilityLedger.validateSeries(values);
    if (seriesIssue != null) throw ArgumentError(seriesIssue);
    await _store.saveAll(uid, values, encode: _toJson, validate: (v) => v.validate());
  }

  static Map<String, dynamic> _toJson(AurenUtilityReading v) => {
    'id': v.id, 'meterId': v.meterId, 'kind': v.kind.name, 'value': v.value,
    'unit': v.unit, 'recordedAt': v.recordedAt.toUtc().toIso8601String(),
    'label': v.label, 'note': v.note,
  };

  static AurenUtilityReading _fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'other';
    final kind = switch (kindName) {
      'electricity' => AurenUtilityKind.electricity,
      'water' => AurenUtilityKind.water,
      'gas' => AurenUtilityKind.gas,
      'other' => AurenUtilityKind.other,
      _ => throw const FormatException('Unknown utility kind.'),
    };
    return AurenUtilityReading(
      id: json['id'] as String, meterId: json['meterId'] as String, kind: kind,
      value: (json['value'] as num).toDouble(), unit: json['unit'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      label: json['label'] as String? ?? '', note: json['note'] as String? ?? '',
    );
  }
}