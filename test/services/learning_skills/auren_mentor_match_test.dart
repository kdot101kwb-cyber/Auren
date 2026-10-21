import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/learning_skills/auren_mentor_match.dart';

void main() {
  test('ranks available mentors by target skills and learner goals deterministically', () {
    const matcher = AurenMentorMatch();
    final result = matcher.rank(
      learnerGoals: ['Build mobile apps'],
      targetSkills: ['Flutter', 'Dart', 'Firebase'],
      mentors: const [
        AurenMentorProfile(id: 'b', skills: ['Dart'], goals: ['Build mobile apps']),
        AurenMentorProfile(id: 'a', skills: ['Flutter', 'Dart', 'Firebase'], goals: ['Build mobile apps']),
        AurenMentorProfile(id: 'offline', skills: ['Flutter', 'Dart', 'Firebase'], available: false),
        AurenMentorProfile(id: 'b', skills: ['Flutter']),
      ],
    );
    expect(result.map((m) => m.mentorId), ['a', 'b']);
    expect(result.first.score, 100);
    expect(result.first.matchedSkills, ['dart', 'firebase', 'flutter']);
  });
  test('validates result limit and handles empty requirements', () {
    const matcher = AurenMentorMatch();
    expect(() => matcher.rank(learnerGoals: [], targetSkills: [], mentors: const [], limit: 0), throwsArgumentError);
    expect(matcher.rank(learnerGoals: [], targetSkills: [], mentors: const []), isEmpty);
  });
}
