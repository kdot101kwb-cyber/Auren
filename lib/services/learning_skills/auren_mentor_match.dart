import '../talent/talent_skill_matcher.dart';

class AurenMentorProfile {
  const AurenMentorProfile({required this.id, required this.skills, this.goals = const [], this.available = true});
  final String id;
  final List<String> skills;
  final List<String> goals;
  final bool available;
}

class AurenMentorMatchResult {
  const AurenMentorMatchResult({required this.mentorId, required this.score, required this.matchedSkills, required this.goalMatches});
  /// Local profile identifier only; this matcher never exposes contact details.
  final String mentorId;
  final int score;
  final List<String> matchedSkills;
  final List<String> goalMatches;
}

class AurenMentorMatch {
  const AurenMentorMatch();

  List<AurenMentorMatchResult> rank({
    required Iterable<String> learnerGoals,
    required Iterable<String> targetSkills,
    required Iterable<AurenMentorProfile> mentors,
    int limit = 10,
  }) {
    if (limit < 1 || limit > 50) throw ArgumentError.value(limit, 'limit', 'must be 1–50');
    final goals = learnerGoals.map(TalentSkillMatcher.normalize).where((s) => s.isNotEmpty).toSet();
    final skills = targetSkills.map(TalentSkillMatcher.normalize).where((s) => s.isNotEmpty).toSet();
    final results = <AurenMentorMatchResult>[];
    final seen = <String>{};
    for (final mentor in mentors) {
      final id = mentor.id.trim();
      if (!mentor.available || id.isEmpty || !seen.add(id)) continue;
      final normalizedSkills = mentor.skills.map(TalentSkillMatcher.normalize).where((s) => s.isNotEmpty).toSet();
      final matched = normalizedSkills.intersection(skills).toList()..sort();
      final mentorGoals = mentor.goals.map(TalentSkillMatcher.normalize).where((s) => s.isNotEmpty).toSet();
      final goalMatches = mentorGoals.intersection(goals).toList()..sort();
      final skillScore = skills.isEmpty ? 0 : (matched.length / skills.length * 80).round();
      final goalScore = goals.isEmpty ? 0 : (goalMatches.length / goals.length * 20).round();
      results.add(AurenMentorMatchResult(mentorId: id, score: (skillScore + goalScore).clamp(0, 100), matchedSkills: List.unmodifiable(matched), goalMatches: List.unmodifiable(goalMatches)));
    }
    results.sort((a, b) => b.score != a.score ? b.score.compareTo(a.score) : a.mentorId.compareTo(b.mentorId));
    return List.unmodifiable(results.take(limit));
  }
}
