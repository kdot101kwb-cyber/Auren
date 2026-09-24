import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';

class AurenDataInsight {
  final String title, value, explanation, source;
  const AurenDataInsight({required this.title, required this.value, required this.explanation, required this.source});
}
class AurenDataExplanation {
  final DateTime generatedAt;
  final int goalCount, activeGoalCount, enabledMemoryCount, averageProgress;
  final List<AurenDataInsight> insights;
  const AurenDataExplanation({required this.generatedAt, required this.goalCount, required this.activeGoalCount, required this.enabledMemoryCount, required this.averageProgress, required this.insights});
}
class ExplainMyDataService {
  final GoalRepository _goals;
  final MemoryRepository _memory;
  ExplainMyDataService({GoalRepository? goals, MemoryRepository? memory})
      : _goals = goals ?? GoalRepository(), _memory = memory ?? MemoryRepository();

  Future<AurenDataExplanation> build(String uid) async {
    if (uid.trim().isEmpty) throw ArgumentError('uid is required');
    final goals = await _goals.watch(uid).first;
    final memories = await _memory.watch(uid).first;
    final active = goals.where((g) => g.status == 'active').toList();
    final enabled = memories.where((m) => m.enabled).toList();
    final average = active.isEmpty ? 0 : (active.fold<int>(0, (sum, g) => sum + g.progress) / active.length).round();
    final insights = <AurenDataInsight>[
      AurenDataInsight(title: 'الأهداف', value: '${goals.length}', explanation: active.isEmpty ? 'لا توجد أهداف نشطة حاليًا.' : '${average}% متوسط تقدم الأهداف النشطة.', source: 'users/{uid}/goals'),
      AurenDataInsight(title: 'الذاكرة المفعّلة', value: '${enabled.length}', explanation: 'هذه هي الذكريات التي يسمح إعدادها باستخدامها ضمن السياق الشخصي.', source: 'users/{uid}/memory'),
    ];
    if (active.isNotEmpty) {
      final top = [...active]..sort((a, b) => b.progress.compareTo(a.progress));
      insights.add(AurenDataInsight(title: 'أعلى تقدم', value: '${top.first.progress}%', explanation: 'الهدف: ${top.first.title}', source: 'users/{uid}/goals/${top.first.id}'));
    }
    if (enabled.isNotEmpty) {
      final latest = [...enabled]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      insights.add(AurenDataInsight(title: 'آخر ذاكرة مفعّلة', value: latest.first.key, explanation: 'آخر تحديث: ${latest.first.value}', source: 'users/{uid}/memory/${latest.first.id}'));
    }
    return AurenDataExplanation(generatedAt: DateTime.now(), goalCount: goals.length, activeGoalCount: active.length, enabledMemoryCount: enabled.length, averageProgress: average, insights: insights);
  }
}