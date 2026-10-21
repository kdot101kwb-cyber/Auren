import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/learning_skills/auren_career_pathways.dart';

void main() {
  test('shows role readiness, missing skills and actionable next steps', () {
    const pathways = AurenCareerPathways();
    final result = pathways.build(acquiredSkills: ['Dart', 'Git'], roles: const [
      AurenCareerRole(id: 'mobile', title: 'Mobile Developer', requiredSkills: ['Dart', 'Flutter', 'Git'], nextSteps: ['Build a portfolio app']),
      AurenCareerRole(id: 'data', title: 'Data Analyst', requiredSkills: ['SQL', 'Python']),
    ]);
    expect(result.first.roleId, 'mobile');
    expect(result.first.readinessPercent, 67);
    expect(result.first.skillGaps, ['Flutter']);
    expect(result.first.nextSteps, ['Learn Flutter', 'Build a portfolio app']);
    expect(result.last.readinessPercent, 0);
  });
  test('rejects duplicate career role IDs', () {
    expect(() => const AurenCareerPathways().build(acquiredSkills: [], roles: const [
      AurenCareerRole(id: 'x', title: 'One', requiredSkills: []),
      AurenCareerRole(id: 'x', title: 'Two', requiredSkills: []),
    ]), throwsArgumentError);
  });
}
