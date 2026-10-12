import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AurenRandomGroupConnectService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  AurenRandomGroupConnectService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference<Map<String, dynamic>> get _c => _db.collection('random_group_connect');

  Future<String> join({
    required String uid,
    required String country,
    required String language,
    required String interest,
    required String goal,
    int groupSize = 4,
  }) async {
    final size = groupSize.clamp(3, 8).toInt();
    final ref = _c.doc();
    await ref.set({
      'uid': uid,
      'country': country.trim(),
      'language': language.trim(),
      'interest': interest.trim(),
      'goal': goal.trim(),
      'groupSize': size,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> watch({
    required String uid,
    required String language,
    required int groupSize,
    required String? requestId,
  }) async* {
    if (requestId == null || requestId.trim().isEmpty) {
      yield const <Map<String, dynamic>>[];
      return;
    }
    while (true) {
      try {
        final result = await _functions.httpsCallable('listAurenRandomGroupCandidates').call({
          'requestId': requestId,
          'groupSize': groupSize.clamp(3, 8).toInt(),
          'language': language.trim(),
        });
        final data = Map<String, dynamic>.from(result.data as Map);
        final raw = data['candidates'] as List? ?? const [];
        yield raw.map((item) {
          final candidate = Map<String, dynamic>.from(item as Map);
          return <String, dynamic>{
            'id': candidate['requestId'],
            'country': candidate['country'] ?? '',
            'language': candidate['language'] ?? '',
            'interest': candidate['interest'] ?? '',
            'goal': candidate['goal'] ?? '',
            'groupSize': groupSize,
          };
        }).toList();
      } catch (_) {
        yield const <Map<String, dynamic>>[];
      }
      await Future<void>.delayed(const Duration(seconds: 20));
    }
  }

  Future<String> formGroup({
    required String requestId,
    required int groupSize,
    required List<String> candidateRequestIds,
  }) async {
    final result = await _functions.httpsCallable('formAurenRandomGroup').call({
      'requestId': requestId,
      'groupSize': groupSize,
      'candidateRequestIds': candidateRequestIds,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final groupId = data['groupId'];
    if (groupId is! String || groupId.isEmpty) {
      throw StateError('The server did not return a valid group ID.');
    }
    return groupId;
  }

  Future<String> createMessengerGroup({
    required String groupId,
    required String uid,
    required String title,
  }) async {
    final result = await _functions.httpsCallable('createAurenRandomGroupConversation').call({
      'groupId': groupId,
      'title': title,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final conversationId = data['conversationId'];
    if (conversationId is! String || conversationId.isEmpty) {
      throw StateError('The server did not return a valid conversation ID.');
    }
    return conversationId;
  }

  Future<void> cancel(String uid, String requestId) async {
    final ref = _c.doc(requestId);
    final snap = await ref.get();
    if (snap.exists && snap.data()?['uid'] == uid && snap.data()?['status'] == 'waiting') {
      await ref.update({'status': 'cancelled'});
    }
  }
}
