class TalentScoreBreakdown {
  final int score;
  final int profile;
  final int skills;
  final int achievements;
  final int evidence;
  final int goals;

  const TalentScoreBreakdown({
    required this.score,
    required this.profile,
    required this.skills,
    required this.achievements,
    required this.evidence,
    required this.goals,
  });
}

/// AUREN Talent Score measures the strength of the information available
/// in a talent profile. It is not a ranking of athletic ability and does
/// not replace federation, club, coach, or competition evaluation.
class TalentScoreService {
  static TalentScoreBreakdown calculate({
    required String displayName,
    required String bio,
    required List<String> sports,
    required List<String> skills,
    List<String> verifiedSkills = const [],
    required List<String> achievements,
    required List<String> goals,
    required List<String> verificationEvidence,
    String level = '',
    String discipline = '',
    String city = '',
    String country = '',
  }) {
    int capped(int value, int max) => value > max ? max : value;
    final profile = capped(
      (displayName.trim().isNotEmpty ? 8 : 0) +
          (bio.trim().length >= 40 ? 8 : bio.trim().isNotEmpty ? 4 : 0) +
          (sports.isNotEmpty ? 8 : 0) +
          (level.trim().isNotEmpty ? 3 : 0) +
          (discipline.trim().isNotEmpty ? 3 : 0) +
          (city.trim().isNotEmpty ? 2 : 0) +
          (country.trim().isNotEmpty ? 2 : 0),
      34,
    );
    final verifiedSkillCount = verifiedSkills.isNotEmpty ? verifiedSkills.toSet().length : 0;
    final skillsScore = verifiedSkills.isNotEmpty
        ? capped(verifiedSkillCount * 4, 20)
        : capped(skills.length * 2, 20);
    final achievementsScore = capped(achievements.length * 2, 20);
    final evidenceScore = capped(verificationEvidence.length * 1, 10);
    final goalsScore = capped(goals.length * 2, 16);
    final score = capped(profile + skillsScore + achievementsScore + evidenceScore + goalsScore, 100);
    return TalentScoreBreakdown(
      score: score,
      profile: profile,
      skills: skillsScore,
      achievements: achievementsScore,
      evidence: evidenceScore,
      goals: goalsScore,
    );
  }
}
