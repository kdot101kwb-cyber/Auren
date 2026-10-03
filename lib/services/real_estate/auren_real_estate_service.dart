import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/property.dart';

class AurenRealEstateService {
  final FirebaseFirestore _db;
  AurenRealEstateService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _c => _db.collection('properties');

  Stream<List<AurenProperty>> watchPublic({
    String query = '',
    String city = '',
    String listingType = 'All',
    String type = 'All',
  }) =>
      _c.where('visibility', isEqualTo: 'public')
          .where('status', isEqualTo: 'active')
          .limit(100)
          .snapshots()
          .map((s) {
        final q = query.trim().toLowerCase();
        final c = city.trim().toLowerCase();
        final list = s.docs
            .map((d) => AurenProperty.fromMap(d.id, d.data()))
            .where((p) => listingType == 'All' || p.listingType == listingType)
            .where((p) => type == 'All' || p.type == type)
            .where((p) => c.isEmpty ||
                p.city.toLowerCase().contains(c) ||
                p.country.toLowerCase().contains(c))
            .where((p) => q.isEmpty ||
                [p.title, p.description, p.city, p.country, p.type]
                    .join(' ')
                    .toLowerCase()
                    .contains(q))
            .toList();
        list.sort((a, b) => b.verified.toString().compareTo(a.verified.toString()));
        return list;
      });

  Future<String> publish({
    required String ownerId,
    required String title,
    required String description,
    required String city,
    required String country,
    required String type,
    required String listingType,
    required String currency,
    required int priceMinor,
    required int bedrooms,
    required int bathrooms,
    required int areaSqm,
    required String imageUrl,
  }) async {
    final uid = ownerId.trim();
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCity = city.trim();
    final cleanCountry = country.trim();
    final cleanCurrency = currency.trim().toUpperCase();
    if (uid.isEmpty || uid.length > 128) throw ArgumentError('معرّف صاحب العقار غير صالح.');
    if (cleanTitle.isEmpty || cleanTitle.length > 160) throw ArgumentError('عنوان العقار مطلوب (حتى 160 حرفاً).');
    if (cleanDescription.length > 3000) throw ArgumentError('وصف العقار طويل جداً.');
    if (cleanCity.isEmpty || cleanCity.length > 100 || cleanCountry.isEmpty || cleanCountry.length > 100) {
      throw ArgumentError('المدينة والدولة مطلوبتان.');
    }
    if (!{'Apartment', 'House', 'Villa', 'Office', 'Shop', 'Land', 'Warehouse'}.contains(type)) {
      throw ArgumentError('نوع العقار غير صالح.');
    }
    if (!{'sale', 'rent'}.contains(listingType)) throw ArgumentError('نوع العرض يجب أن يكون بيعاً أو إيجاراً.');
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(cleanCurrency)) throw ArgumentError('رمز العملة يجب أن يتكون من 3 أحرف.');
    if (priceMinor < 0 || bedrooms < 0 || bathrooms < 0 || areaSqm < 0) {
      throw ArgumentError('السعر والمساحات والغرف لا يمكن أن تكون سالبة.');
    }
    if (bedrooms > 100 || bathrooms > 100 || areaSqm > 1000000) {
      throw ArgumentError('بيانات العقار خارج النطاق المسموح.');
    }
    final cleanImageUrl = imageUrl.trim();
    if (cleanImageUrl.length > 2048 ||
        (cleanImageUrl.isNotEmpty && !cleanImageUrl.startsWith('https://'))) {
      throw ArgumentError('رابط صورة العقار غير صالح.');
    }
    final ref = _c.doc();
    await ref.set({
      'ownerId': uid,
      'title': cleanTitle,
      'description': cleanDescription,
      'city': cleanCity,
      'country': cleanCountry,
      'type': type,
      'listingType': listingType,
      'currency': cleanCurrency,
      'priceMinor': priceMinor,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqm': areaSqm,
      'imageUrl': cleanImageUrl,
      'verified': false,
      'status': 'active',
      'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final propertyId = id.trim();
    if (propertyId.isEmpty || propertyId.length > 128) throw ArgumentError('معرّف العقار غير صالح.');
    const allowed = {
      'title', 'description', 'city', 'country', 'type', 'listingType',
      'currency', 'priceMinor', 'bedrooms', 'bathrooms', 'areaSqm', 'imageUrl',
    };
    if (data.isEmpty || data.keys.any((key) => !allowed.contains(key))) {
      throw ArgumentError('حقول تحديث العقار غير صالحة.');
    }
    final patch = Map<String, dynamic>.from(data);
    for (final key in ['title', 'description', 'city', 'country', 'type', 'listingType', 'currency', 'imageUrl']) {
      if (patch.containsKey(key) && patch[key] is! String) throw ArgumentError('قيمة أحد الحقول النصية غير صالحة.');
    }
    if (patch['title'] != null) {
      patch['title'] = (patch['title'] as String).trim();
      if ((patch['title'] as String).isEmpty || (patch['title'] as String).length > 160) throw ArgumentError('عنوان العقار غير صالح.');
    }
    if (patch['description'] != null) {
      patch['description'] = (patch['description'] as String).trim();
      if ((patch['description'] as String).length > 3000) throw ArgumentError('وصف العقار طويل جداً.');
    }
    if (patch.containsKey('type') && !{'Apartment', 'House', 'Villa', 'Office', 'Shop', 'Land', 'Warehouse'}.contains(patch['type'])) throw ArgumentError('نوع العقار غير صالح.');
    if (patch.containsKey('listingType') && !{'sale', 'rent'}.contains(patch['listingType'])) throw ArgumentError('نوع العرض غير صالح.');
    if (patch.containsKey('currency')) {
      patch['currency'] = (patch['currency'] as String).trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(patch['currency'] as String)) throw ArgumentError('رمز العملة غير صالح.');
    }
    for (final key in ['priceMinor', 'bedrooms', 'bathrooms', 'areaSqm']) {
      if (patch.containsKey(key)) {
        final value = patch[key];
        if (value is! int || value < 0) throw ArgumentError('قيمة السعر أو المساحة أو الغرف غير صالحة.');
      }
    }
    await _c.doc(propertyId).update(patch);
  }

  Future<void> delete(String id) async {
    final propertyId = id.trim();
    if (propertyId.isEmpty || propertyId.length > 128) throw ArgumentError('معرّف العقار غير صالح.');
    await _c.doc(propertyId).delete();
  }

  Future<void> toggleSaved(String uid, String propertyId) async {
    final userId = uid.trim();
    final id = propertyId.trim();
    if (userId.isEmpty || userId.length > 128) throw ArgumentError('معرّف المستخدم غير صالح.');
    if (id.isEmpty || id.length > 128) throw ArgumentError('معرّف العقار غير صالح.');
    final ref = _db.collection('users').doc(userId).collection('savedProperties').doc(id);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    } else {
      await ref.set({'propertyId': id, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<Set<String>> watchSavedIds(String uid) {
    final userId = uid.trim();
    if (userId.isEmpty || userId.length > 128) throw ArgumentError('معرّف المستخدم غير صالح.');
    return _db.collection('users').doc(userId).collection('savedProperties')
        .snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }
}
