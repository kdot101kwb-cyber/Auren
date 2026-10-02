import 'package:cloud_firestore/cloud_firestore.dart';

class AurenEmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool primary;

  const AurenEmergencyContact({required this.id, required this.name, required this.phone, required this.relation, required this.primary});

  factory AurenEmergencyContact.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AurenEmergencyContact(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      relation: data['relation'] as String? ?? '',
      primary: data['primary'] as bool? ?? false,
    );
  }
}

class AurenEmergencyContactsRepository {
  final FirebaseFirestore _db;
  AurenEmergencyContactsRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String uid) => _db.collection('users').doc(uid).collection('emergency_contacts');

  Stream<List<AurenEmergencyContact>> watch(String uid) => _ref(uid)
      .orderBy('createdAt', descending: false)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(AurenEmergencyContact.fromDoc).toList());

  Future<void> add({required String uid, required String name, required String phone, String relation = '', bool primary = false}) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (uid.isEmpty || cleanName.isEmpty || cleanName.length > 120 || cleanPhone.isEmpty || cleanPhone.length > 40 || relation.trim().length > 80) {
      throw ArgumentError('بيانات جهة الاتصال غير صالحة.');
    }
    await _ref(uid).doc().set({
      'ownerId': uid, 'name': cleanName, 'phone': cleanPhone, 'relation': relation.trim(),
      'primary': primary, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String uid, String contactId) async {
    if (uid.isEmpty || contactId.isEmpty) throw ArgumentError('جهة الاتصال غير صالحة.');
    await _ref(uid).doc(contactId).delete();
  }

  Future<void> setPrimary(String uid, String contactId) async {
    if (uid.isEmpty || contactId.isEmpty) throw ArgumentError('جهة الاتصال غير صالحة.');
    final batch = _db.batch();
    final contacts = await _ref(uid).limit(10).get();
    for (final doc in contacts.docs) {
      batch.update(doc.reference, {'primary': doc.id == contactId, 'updatedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
}
