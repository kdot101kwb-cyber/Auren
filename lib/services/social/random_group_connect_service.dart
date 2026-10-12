import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AurenRandomGroupConnectService {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  AurenRandomGroupConnectService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('random_group_connect');

  String _limit(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  Future<String> join({
    required String uid,
    required String country,
    required String language,
    required String interest,
    required String goal,
    int groupSize = 4,
  }) async {
    final normalizedLanguage = language.trim();
    if (uid.isEmpty || normalizedLanguage.isEmpty) {
      throw ArgumentError('A signed-in user and language are required.');
    }
    final size = groupSize.clamp(3, 8).toInt();
    final ref = _requests.doc();
    await ref.set({
      'uid': uid,
      'country': _limit(country.trim(), 80),
      'language': _limit(normalizedLanguage, 60),
      'interest': _limit(interest.trim(), 120),
      'goal': _limit(goal.trim(), 120),
      'groupSize': size,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> watch({
    required String uid,
    required String language,
    int groupSize = 4,
  }) async* {
    Future<List<Map<String, dynamic>>> load() async {
      final callable = _functions.httpsCallable('listAurenRandomGroupCandidates');
      final result = await callable.call<Map<String, dynamic>>({
        'groupSize': groupSize.clamp(3, 8).toInt(),
        'language': language.trim(),
      });
      final candidates = result.data['candidates'];
      if (candidates is! List) return const [];
      return candidates.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }

    yield await load();
    await for (final _ in Stream<int>.periodic(const Duration(seconds: 15), (i) => i)) {
      yield await load();
    }
  }

  Future<String> formGroup({
    required String uid,
    required List<String> requestIds,
  }) async {
    if (uid.isEmpty) throw ArgumentError('A signed-in user is required.');
    final callable = _functions.httpsCallable('formAurenRandomGroup');
    final result = await callable.call<Map<String, dynamic>>({'requestIds': requestIds});
    final groupId = result.data['groupId'];
    if (groupId is! String || groupId.isEmpty) {
      throw StateError('The server did not return a group ID.');
    }
    return groupId;
  }

  Future<String> createMessengerGroup({
    required String groupId,
    required String uid,
    required String title,
  }) async {
    if (groupId.trim().isEmpty || uid.isEmpty) throw ArgumentError('Invalid group.');
    final callable = _functions.httpsCallable('createAurenRandomGroupConversation');
    final result = await callable.call<Map<String, dynamic>>({
      'groupId': groupId,
      'title': title,
    });
    final conversationId = result.data['conversationId'];
    if (conversationId is! String || conversationId.isEmpty) {
      throw StateError('The server did not return a conversation ID.');
    }
    return conversationId;
  }

  Future<void> cancel(String uid, String requestId) async {
    if (uid.isEmpty || requestId.isEmpty) return;
    final ref = _requests.doc(requestId);
    final snap = await ref.get();
    if (snap.exists && snap.data()?['uid'] == uid && snap.data()?['status'] == 'waiting') {
      await ref.update({'status': 'cancelled'});
    }
  }
}
