import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/learning_skills/auren_skill_graph.dart';

void main() {
  test('returns only skills whose prerequisites are met and computes readiness', () {
    final graph = AurenSkillGraph([
      const AurenSkillNode(id: 'dart', name: 'Dart'),
      const AurenSkillNode(id: 'flutter', name: 'Flutter', prerequisites: ['dart']),
      const AurenSkillNode(id: 'firebase', name: 'Firebase', prerequisites: ['dart']),
      const AurenSkillNode(id: 'app', name: 'App delivery', prerequisites: ['flutter', 'firebase']),
    ]);
    expect(graph.recommendNext([]).map((n) => n.id), ['dart']);
    expect(graph.recommendNext(['dart']).map((n) => n.id), ['flutter', 'firebase']);
    expect(graph.readinessPercent(['dart', 'flutter'], 'app'), 33);
    expect(graph.prerequisitesFor('flutter').single.id, 'dart');
  });
  test('rejects unknown prerequisites and cycles', () {
    expect(() => AurenSkillGraph([const AurenSkillNode(id: 'a', name: 'A', prerequisites: ['missing'])]), throwsArgumentError);
    expect(() => AurenSkillGraph([
      const AurenSkillNode(id: 'a', name: 'A', prerequisites: ['b']),
      const AurenSkillNode(id: 'b', name: 'B', prerequisites: ['a']),
    ]), throwsArgumentError);
  });
}
