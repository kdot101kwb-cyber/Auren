import 'package:cloud_firestore/cloud_firestore.dart';

class AurenPlace {
  final String id, name, city, country, description, category, imageUrl;
  const AurenPlace({required this.id, required this.name, required this.city, required this.country, required this.description, required this.category, required this.imageUrl});
  factory AurenPlace.fromMap(String id, Map<String,dynamic> d) => AurenPlace(
    id:id, name:d['name'] ?? '', city:d['city'] ?? '', country:d['country'] ?? '',
    description:d['description'] ?? '', category:d['category'] ?? 'Place', imageUrl:d['imageUrl'] ?? '',
  );
}

class AurenTrip {
  final String id, ownerId, title, destination, status;
  final DateTime? startDate, endDate, createdAt;
  final int travelers;
  final List<String> placeIds;
  const AurenTrip({required this.id, required this.ownerId, required this.title, required this.destination, required this.status, required this.travelers, required this.placeIds, this.startDate, this.endDate, this.createdAt});
  factory AurenTrip.fromMap(String id, Map<String,dynamic> d) {
    DateTime? date(dynamic v) => v is Timestamp ? v.toDate() : null;
    return AurenTrip(
      id:id, ownerId:d['ownerId'] ?? '', title:d['title'] ?? '', destination:d['destination'] ?? '',
      status:d['status'] ?? 'planned', travelers:d['travelers'] ?? 1,
      placeIds:List<String>.from(d['placeIds'] ?? const []), startDate:date(d['startDate']), endDate:date(d['endDate']), createdAt:date(d['createdAt']),
    );
  }
}
