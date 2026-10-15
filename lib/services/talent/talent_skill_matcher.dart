/// Pure, deterministic matching logic shared by Talent and Opportunity flows.
class TalentSkillEvaluation {
  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;

  const TalentSkillEvaluation({
    required this.score,
    required this.matchedSkills,
    required this.missingSkills,
  });
}

class TalentSkillMatcher {
  const TalentSkillMatcher._();

  static String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static TalentSkillEvaluation evaluate({
    required Iterable<String> verifiedSkills,
    required Iterable<String> requiredSkills,
  }) {
    final verified = verifiedSkills.map(normalize).where((s) => s.isNotEmpty).toSet();
    final required = requiredSkills.map(normalize).where((s) => s.isNotEmpty).toSet();
    if (required.isEmpty) {
      return const TalentSkillEvaluation(score: 0, matchedSkills: [], missingSkills: []);
    }
    final matched = verified.intersection(required).toList()..sort();
    final missing = required.difference(verified).toList()..sort();
    final score = ((matched.length / required.length) * 100).round().clamp(0, 100).toInt();
    return TalentSkillEvaluation(score: score, matchedSkills: matched, missingSkills: missing);
  }
}
