import 'package:shared_preferences/shared_preferences.dart';
import 'trip_itinerary_service.dart';
import 'uid_scoped_json_list_store.dart';

class AurenTripItineraryStore {
  AurenTripItineraryStore({SharedPreferences? preferences})
      : _store = AurenUidScopedJsonListStore<AurenTripStop>(
          keyPrefix: 'auren_trip_itinerary_v1_', preferences: preferences);
  final AurenUidScopedJsonListStore<AurenTripStop> _store;

  Future<List<AurenTripStop>> loadStops(String uid) async {
    final values = await _store.load(uid, decode: _fromJson, validate: (v) => v.validate());
    final ids = <String>{};
    for (final value in values) {
      if (!ids.add(value.id)) throw const FormatException('Duplicate trip stop id.');
    }
    return AurenTripItineraryPlanner.orderedStops(values);
  }

  Future<void> saveStop(String uid, AurenTripStop stop) async {
    final issue = stop.validate();
    if (issue != null) throw ArgumentError(issue);
    final values = (await loadStops(uid)).toList();
    final index = values.indexWhere((v) => v.id == stop.id);
    if (index < 0) { values.add(stop); } else { values[index] = stop; }
    await _store.saveAll(uid, values, encode: _toJson, validate: (v) => v.validate());
  }

  Future<AurenTripStop> setStopCompleted(String uid, String stopId, bool completed) async {
    final values = await loadStops(uid);
    final index = values.indexWhere((v) => v.id == stopId);
    if (index < 0) throw ArgumentError('Trip stop was not found.');
    final updated = values[index].copyWith(completed: completed);
    await saveStop(uid, updated);
    return updated;
  }

  static Map<String, dynamic> _toJson(AurenTripStop v) => {
    'id': v.id, 'title': v.title, 'location': v.location,
    'plannedAt': v.plannedAt?.toUtc().toIso8601String(),
    'notes': v.notes, 'completed': v.completed,
  };

  static AurenTripStop _fromJson(Map<String, dynamic> json) => AurenTripStop(
    id: json['id'] as String, title: json['title'] as String,
    location: json['location'] as String? ?? '',
    plannedAt: json['plannedAt'] == null ? null : DateTime.parse(json['plannedAt'] as String),
    notes: json['notes'] as String? ?? '', completed: json['completed'] as bool? ?? false,
  );
}