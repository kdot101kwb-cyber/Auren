import 'package:cloud_functions/cloud_functions.dart';

class EducationGamificationService {
  EducationGamificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> recordActivity({
    required String type,
    required String eventId,
    required String sourceId,
  }) async {
    final result = await _functions
        .httpsCallable('recordAurenEducationActivity')
        .call({
      'type': type,
      'eventId': eventId,
      'sourceId': sourceId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> recordQuiz({
    required String quizId,
    String? courseId,
  }) => recordActivity(
    type: 'quiz',
    eventId: 'quiz:${quizId}:completed',
    sourceId: courseId ?? quizId,
  );

  Future<Map<String, dynamic>> recordLanguage({
    required String activityId,
    String? language,
  }) => recordActivity(
    type: 'language',
    eventId: 'language:${activityId}:completed',
    sourceId: language ?? activityId,
  );

  Future<Map<String, dynamic>> recordVoiceTutor({
    required String sessionId,
    String? lessonId,
  }) => recordActivity(
    type: 'voiceTutor',
    eventId: 'voiceTutor:${sessionId}:completed',
    sourceId: lessonId ?? sessionId,
  );

  Future<Map<String, dynamic>> getProfile() async {
    final result = await _functions
        .httpsCallable('getAurenEducationGamification')
        .call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final result = await _functions
        .httpsCallable('getAurenEducationLeaderboard')
        .call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final users = (data['entries'] as List? ?? const []);
    return users
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
