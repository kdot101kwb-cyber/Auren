import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AurenSafetyPlace {
  final String id, name, type, city, country;
  const AurenSafetyPlace({required this.id, required this.name, required this.type, required this.city, required this.country});
  factory AurenSafetyPlace.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return AurenSafetyPlace(id: d.id, name: x['name'] ?? '', type: x['type'] ?? 'emergency', city: x['city'] ?? '', country: x['country'] ?? '');
  }
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type, 'city': city, 'country': country};
  factory AurenSafetyPlace.fromJson(Map<String, dynamic> x) => AurenSafetyPlace(id: x['id'] ?? '', name: x['name'] ?? '', type: x['type'] ?? 'emergency', city: x['city'] ?? '', country: x['country'] ?? '');
}

class AurenOfflineSafetyService {
  AurenOfflineSafetyService._();
  static final instance = AurenOfflineSafetyService._();
  final _db = FirebaseFirestore.instance;
  static const _placesPrefix = 'auren.safety.places.';
  static const _routesPrefix = 'auren.safety.routes.';

  String _areaKey(String city, String country) => 'auren.safety.places.${city.trim().toLowerCase()}|${country.trim().toLowerCase()}';
  String _routesKey(String uid) => 'auren.safety.routes.$uid';

  Stream<List<AurenSafetyPlace>> watchPlaces({String city = '', String country = ''}) => _db.collection('safety_places').where('active', isEqualTo: true).limit(100).snapshots().asyncMap((s) async {
    final c = city.toLowerCase().trim(), co = country.toLowerCase().trim();
    final places = s.docs.map(AurenSafetyPlace.fromDoc).where((x) => (c.isEmpty || x.city.toLowerCase() == c) && (co.isEmpty || x.country.toLowerCase() == co)).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_areaKey(city, country), jsonEncode(places.map((x) => x.toJson()).toList()));
    return places;
  });

  Future<List<AurenSafetyPlace>> readCachedPlaces({String city = '', String country = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_areaKey(city, country));
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((x) => AurenSafetyPlace.fromJson(Map<String, dynamic>.from(x))).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String> saveRoute({required String uid, required String name, required List<Map<String, double>> points}) async {
    if (uid.isEmpty || name.trim().isEmpty || points.length < 2 || points.length > 500) throw ArgumentError('بيانات المسار غير صالحة.');
    final ref = _db.collection('users').doc(uid).collection('offline_routes').doc();
    final route = {'id': ref.id, 'ownerId': uid, 'name': name.trim(), 'points': points, 'createdAt': DateTime.now().toIso8601String()};
    final prefs = await SharedPreferences.getInstance();
    final cached = await readCachedRoutes(uid);
    cached.insert(0, route);
    await prefs.setString(_routesKey(uid), jsonEncode(cached.take(50).toList()));
    try {
      await ref.set({'ownerId': uid, 'name': name.trim(), 'points': points, 'createdAt': FieldValue.serverTimestamp()});
    } catch (_) {}
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRoutes(String uid) => _db.collection('users').doc(uid).collection('offline_routes').orderBy('createdAt', descending: true).limit(50).snapshots();

  Future<List<Map<String, dynamic>>> readCachedRoutes(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_routesKey(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheRoutes(String uid, QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (uid.isEmpty) return;
    final rows = snapshot.docs.map((d) {
      final data = d.data();
      return {'id': d.id, 'ownerId': uid, 'name': data['name'] ?? '', 'points': data['points'] ?? const [], 'createdAt': data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toIso8601String() : DateTime.now().toIso8601String()};
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routesKey(uid), jsonEncode(rows));
  }
}
