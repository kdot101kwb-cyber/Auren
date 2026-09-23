import 'package:cloud_firestore/cloud_firestore.dart';

class AurenNextFiveSnapshot {
  final int learningTracks;
  final int trips;
  final bool hasAiConversation;
  final int? completedLessons;
  final List<String> tripNames;

  const AurenNextFiveSnapshot({
    required this.learningTracks,
    required this.trips,
    required this.hasAiConversation,
    required this.completedLessons,
    required this.tripNames,
  });

  String get nextMove {
    if (!hasAiConversation) return 'ابدأ محادثة مع AUREN AI، ثم استخدم Search وDiscover لتحديد ما تحتاجه.';
    if (learningTracks == 0) return 'اختر مسار تعلم مرتبطًا بهدفك من Education.';
    if (trips == 0) return 'استخدم Discover لاختيار مكان، ثم أنشئ أول رحلة في Travel.';
    return 'اربط التعلم والسفر والبحث والاكتشاف بخطوة واحدة جديدة.';
  }

  String toPrompt() => 'أنت AUREN AI. اربط الوحدات الخمس التالية في خطة عملية واحدة. '
      'Messenger: ${hasAiConversation ? 'لدي محادثة AI' : 'لا توجد محادثة AI بعد'}. '
      'Education: $learningTracks مسارات تعلم مسجلة'
      '${completedLessons == null ? '' : '، $completedLessons دروس مكتملة'}. '
      'Travel: $trips رحلات'
      '${tripNames.isEmpty ? '' : ' — ${tripNames.join('، ')}'}. '
      'Universal Search وDiscover متاحان لاكتشاف الأشخاص والمحتوى والأعمال والأماكن والفرص. '
      'اقترح خطوة واحدة قابلة للتنفيذ تربط هذه الوحدات بهدف المستخدم.';
}

class AurenNextFiveRepository {
  final FirebaseFirestore db;
  AurenNextFiveRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Future<QuerySnapshot<Map<String, dynamic>>?> _safeQuery(
    Future<QuerySnapshot<Map<String, dynamic>>> request,
  ) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _safeDoc(
    Future<DocumentSnapshot<Map<String, dynamic>>> request,
  ) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Future<AurenNextFiveSnapshot> load(String uid) async {
    final results = await Future.wait([
      _safeQuery(db.collection('users').doc(uid).collection('enrollments').limit(100).get()),
      _safeQuery(db.collection('trips').where('ownerId', isEqualTo: uid).limit(50).get()),
      _safeDoc(db.collection('conversations').doc('ai_$uid').get()),
    ]);

    final enrollments = results[0] as QuerySnapshot<Map<String, dynamic>>?;
    final trips = results[1] as QuerySnapshot<Map<String, dynamic>>?;
    final ai = results[2] as DocumentSnapshot<Map<String, dynamic>>?;

    final completed = (enrollments?.docs ?? const []).fold<int>(
      0,
      (sum, d) => sum + ((d.data()['completedLessons'] as num?)?.toInt() ?? 0),
    );

    return AurenNextFiveSnapshot(
      learningTracks: enrollments?.docs.length ?? 0,
      trips: trips?.docs.length ?? 0,
      hasAiConversation: ai?.exists ?? false,
      completedLessons: enrollments?.docs.isEmpty == true ? null : completed,
      tripNames: (trips?.docs ?? const [])
          .map((d) => d.data()['title']?.toString().trim() ?? '')
          .where((v) => v.isNotEmpty)
          .take(5)
          .toList(),
    );
  }
}
