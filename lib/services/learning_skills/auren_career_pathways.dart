import '../talent/talent_skill_matcher.dart';

class AurenCareerRole {
  const AurenCareerRole({required this.id, required this.title, required this.requiredSkills, this.nextSteps = const []});
  final String id;
  final String title;
  final List<String> requiredSkills;
  final List<String> nextSteps;
}

class AurenCareerPathway {
  const AurenCareerPathway({required this.roleId, required this.title, required this.readinessPercent, required this.matchedSkills, required this.skillGaps, required this.nextSteps});
  final String roleId;
  final String title;
  final int readinessPercent;
  final List<String> matchedSkills;
  final List<String> skillGaps;
  final List<String> nextSteps;
}

class AurenCareerPathways {
  const AurenCareerPathways();

  List<AurenCareerPathway> build({required Iterable<String> acquiredSkills, required Iterable<AurenCareerRole> roles, int limit = 10}) {
    if (limit < 1 || limit > 50) throw ArgumentError.value(limit, 'limit', 'must be 1–50');
    final results = <AurenCareerPathway>[];
    final ids = <String>{};
    for (final role in roles) {
      if (role.id.trim().isEmpty || role.title.trim().isEmpty || !ids.add(role.id)) {
        throw ArgumentError('Career roles require unique IDs and non-empty titles');
      }
      final evaluation = TalentSkillMatcher.evaluate(verifiedSkills: acquiredSkills, requiredSkills: role.requiredSkills);
      final missingDisplay = <String>[];
      final normalizedToDisplay = {for (final skill in role.requiredSkills) TalentSkillMatcher.normalize(skill): skill.trim()};
      for (final missing in evaluation.missingSkills) {
        missingDisplay.add(normalizedToDisplay[missing] ?? missing);
      }
      results.add(AurenCareerPathway(roleId: role.id, title: role.title, readinessPercent: evaluation.score,
        matchedSkills: List.unmodifiable(evaluation.matchedSkills), skillGaps: List.unmodifiable(missingDisplay),
        nextSteps: List.unmodifiable([...missingDisplay.map((s) => 'Learn $s'), ...role.nextSteps].take(20))));
    }
    results.sort((a, b) => b.readinessPercent != a.readinessPercent ? b.readinessPercent.compareTo(a.readinessPercent) : a.title.compareTo(b.title));
    return List.unmodifiable(results.take(limit));
  }
}
